# Feature Specification: Cronet Phase 2 — Download Pipeline & Streaming Architecture

**Status:** Draft  
**Author:** Antigravity (Elephant Agent)  
**Target Repository:** ObtainiumPlus (`~/projects/ObtainiumPlus`)  
**Predecessor:** Phase 1 (Metadata requests via `HttpClientFactory`, commit `80bc82f8` upstream / 2026-10-30 session)

---

## 1. Problem Statement & Motivation

### Current State
In ObtainiumPlus, metadata checks (`SourceUtils.httpRequest`) run through `HttpClientFactory.clientFor()`, utilizing embedded Cronet (`package:cronet_http`) on Android. This ensures metadata checks respect Android user-installed CAs (e.g. AdGuard, corporate/internal root certs, Russian Mintsifry) and system proxies.

However, **Phase 2 (APK & binary downloads)** is still unresolved:
- `AppFileService.downloadFile` and `apps_provider.dart` stream downloads using `HttpService.sourceRequestStreamResponse`, which binds exclusively to `dart:io.HttpClient` and `dart:io.HttpClientResponse`.
- `AppFileService.getSHA256` and `checkETagHeader` directly construct `IOClient(createHttpClient(allowInsecure: allowInsecure))`.
- As a consequence:
  1. Users with internal package repositories, corporate proxies, or custom user CAs cannot download APKs, even though metadata update checks succeed.
  2. Each download opens an independent raw TCP/TLS socket via `dart:io`, skipping Cronet's connection pool, HTTP/2 multiplexing, and optimized socket transport.

### Goals
1. Route binary APK downloads through embedded Cronet when available, honoring user CAs and system proxies.
2. Maintain strict streaming semantics: chunks are piped directly to disk (`tempDownloadedFile.part`) with zero in-memory buffering of entire files.
3. Preserve essential `dart:io` exceptions:
   - Certificate-pinned hosts (`HttpClientFactory.isPinnedHost`, e.g., Google Play endpoints).
   - Insecure TLS (`allowInsecure == true`), as Cronet strictly enforces valid TLS.
   - Fallback when Cronet fails to initialize on uncertified or legacy Android environments.
4. Correctly handle cross-origin redirects (e.g., GitHub Releases -> AWS S3 / Cloudflare CDN) so that sensitive authentication headers (`Authorization`, custom tokens) are stripped before reaching external CDNs.

---

## 2. Architecture & Design

### 2.1 Unified Streaming Abstraction: `StreamedHttpResponse`
Currently, `sourceRequestStreamResponse` returns:
```dart
MapEntry<Uri, MapEntry<HttpClient, HttpClientResponse>>
```
Because Cronet produces `package:http.StreamedResponse` (or `cronet_http.CronetClient`), callers should not be bound to concrete `dart:io.HttpClientResponse`.

We define an abstract interface or wrapper:
```dart
abstract class StreamedHttpResponse {
  int get statusCode;
  String? get reasonPhrase;
  int? get contentLength;
  Map<String, String> get headers;
  Stream<List<int>> get byteStream;
  Uri get responseUrl;
  void close();
}
```

Two concrete adapters implement this interface:
1. `IoStreamedHttpResponse`: Wraps `HttpClient` + `HttpClientResponse`.
2. `CronetStreamedHttpResponse`: Wraps `http.Client` + `http.StreamedResponse`.

### 2.2 Client Selection via `HttpClientFactory`
`HttpClientFactory` is extended with:
```dart
static Future<StreamedHttpResponse> openStream({
  required String method,
  required Uri url,
  Map<String, String>? headers,
  bool allowInsecure = false,
  bool followRedirects = true,
});
```

**Selection Matrix:**
| Condition | Engine | Rationale |
| :--- | :--- | :--- |
| `HttpClientFactory.isPinnedHost(url.host)` | `dart:io` | Enforces certificate fingerprint matching via `createHttpClient` |
| `allowInsecure == true` | `dart:io` | Cronet cannot bypass strict TLS verification |
| Standard Android Host + Cronet Available | `embedded Cronet` | Respects user CAs, system proxies, HTTP/2 |
| Non-Android platform / Cronet init error | `dart:io` | Graceful fallback |

### 2.3 Redirect and Header Sanitization
When following redirects:
- Cronet's internal redirect handling can blindly forward `Authorization: Bearer ...` to CDN endpoints (such as S3), causing `400 Bad Request`.
- To prevent credential leaks and CDN rejections:
  - If headers contain `Authorization` or private API tokens, redirects must either be intercepted manually (disabling automatic redirect follow on the initial request when auth headers exist) OR evaluated per-hop using `Uri.resolve` and origin comparison (`!isSameOrigin(originalUri, redirectedUri)`).

### 2.4 Streaming Disk I/O & Resume Semantics
- Download writes chunk-by-chunk to `tempDownloadedFile` (`.part`) via `IOSink`.
- Buffer size: 256KB (`BytesBuilder`) before flushing to minimize Android FUSE filesystem call overhead.
- HTTP Range (`bytes=rangeStart-`): If server returns `206 Partial Content`, append to `.part`. If server returns `200 OK` or `416 Range Not Satisfiable`, reset file pointer and stream fresh.
- Stream cancellation: When `isCancelled()` evaluates to true or download is aborted, cancel the `StreamSubscription`, close the sink, release `_activeDownloadPaths`, and clean up `.part` if incomplete.

---

## 3. Affected Components & Files

1. **`lib/services/http_client_factory.dart`**:
   - Add streaming request dispatcher (`openStream`).
   - Expose unified stream lifecycle management.
2. **`lib/services/http_service.dart`**:
   - Migrate `sourceRequestStreamResponse` to delegate to `HttpClientFactory.openStream`.
   - Implement `IoStreamedHttpResponse` and `CronetStreamedHttpResponse`.
3. **`lib/services/app_file_service.dart`**:
   - Update `downloadFile` to consume `StreamedHttpResponse`.
   - Update `getSHA256` and `checkETagHeader` to use `HttpClientFactory.clientFor`.
4. **`lib/providers/apps_provider.dart`**:
   - Update `downloadFile` and probe calls to consume `StreamedHttpResponse`.
5. **`test/services/cronet_downloads_test.dart`**:
   - Unit tests covering client selection, header sanitization on redirect, range resumption, and stream error handling.

---

## 4. Risks & Mitigations

1. **Memory Exhaustion on Large APKs**:
   - *Risk:* Calling `.bodyBytes` or buffering `StreamedResponse` in RAM will crash on low-memory devices during 500MB+ app downloads.
   - *Mitigation:* Explicit rule: Never call `response.stream.toBytes()`. Pipe `response.stream` chunk-by-chunk into `IOSink` with a bounded 256KB flush buffer.
2. **CDN Authorization Rejection on Redirect**:
   - *Risk:* GitHub/GitLab release downloads redirecting to AWS S3/Google Cloud Storage will fail if the Authorization header is retained.
   - *Mitigation:* Follow the existing Obtainium origin check (`isSameOrigin`). If cross-origin, strip `Authorization` before dispatching the redirected request.
3. **FUSE File Locking in Android Termux / Shared Storage**:
   - *Risk:* Shared storage (`/storage/emulated/0`) locks files if sink is not closed in `finally` block.
   - *Mitigation:* Wrap all stream and sink operations in `try/finally` guaranteeing `sink.close()` and `response.close()`.
