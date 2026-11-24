// HTTP client creation, streaming requests, redirect/error handling.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/services/pin_store.dart';

// ========================================================================
// HttpService — HTTP client creation, streaming requests, and error mapping.
// ========================================================================

class HttpService {
  static const int maxRedirects = 10;

  /// Headers that may be forwarded to a different origin on redirect.
  /// Source-configured auth headers (e.g. PRIVATE-TOKEN, X-Api-Key) and other
  /// caller-supplied headers are dropped, since a redirect can point at an
  /// arbitrary third-party host.
  static const Set<String> safeRedirectHeaders = {
    'accept',
    'accept-charset',
    'accept-encoding',
    'accept-language',
    'cache-control',
    'content-length',
    'content-type',
    'if-modified-since',
    'if-none-match',
    'if-range',
    'origin',
    'pragma',
    'range',
    'referer',
    'user-agent',
    'x-requested-with',
  };

  static String extractRootHost(String host) {
    final parts = host.split('.');
    return parts.length > 2 ? parts.sublist(parts.length - 2).join('.') : host;
  }

  static final Map<String, Future<SecurityContext>> _pinnedContexts = {};

  /// Pinning applies when the request says so, else the app-wide setting.
  static bool defaultCertificatePinning = false;

  /// The trust context for [host] from the pin store (user sets and built-in
  /// pins), or null when no pin set covers it.
  Future<SecurityContext?> _createCertPinning(String url) async {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') return null;
    final store = PinStore.instance;
    await store.ensureLoaded();
    final resolved = store.resolve(uri.host);
    if (resolved == null) return null;
    return _pinnedContexts.putIfAbsent(
      '${resolved.id}:${resolved.revision}',
      () async {
        final context = SecurityContext();
        for (final certificate in resolved.certificates) {
          final pem = await certificate.loadPem();
          context.setTrustedCertificatesBytes(utf8.encode(pem));
        }
        return context;
      },
    );
  }

  /* Basically RuStore switched partially (and in the future it may be fully)
     to russian government Mintsifry CA, which isnt trusted by Android nor
     Chrome Root Store. This is workaround to trust Mintsifry CA for network
     requests made to RuStore domains and subdomains
   */
  Future<SecurityContext> _ruStoreWorkaroundSecurityContext() async {
    final securityContext = SecurityContext(withTrustedRoots: true);
    final cert = await rootBundle.load(
      'assets/ca-certs/russian-mintsifry-root.crt',
    );
    securityContext.setTrustedCertificatesBytes(cert.buffer.asUint8List());
    return securityContext;
  }

  Future<HttpClient> createHttpClient(
    Map<String, dynamic> additionalSettings,
  ) async {
    final insecure = additionalSettings['allowInsecure'] == true;
    final url = additionalSettings['url'] as String;
    final pinning =
        (additionalSettings['enableCertificatePinning'] as bool?) ??
        defaultCertificatePinning;
    SecurityContext? securityContext;
    var pinned = false;
    final host = Uri.parse(url).host;
    if (pinning) {
      securityContext = await _createCertPinning(url);
      pinned = securityContext != null;
    }
    if (securityContext == null && extractRootHost(host) == 'rustore.ru') {
      securityContext = await _ruStoreWorkaroundSecurityContext();
    }
    final client = securityContext != null
        ? HttpClient(context: securityContext)
        : HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    if (insecure) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              // Pinned hosts must still reject bad certificates in insecure mode.
              !pinned;
    }
    return client;
  }

  /// Whether two URIs share the same origin (scheme, host, and port — Dart
  /// normalizes default ports for http/https, so explicit and implicit
  /// default ports compare equal).
  static bool isSameOrigin(Uri a, Uri b) =>
      a.scheme.toLowerCase() == b.scheme.toLowerCase() &&
      a.host.toLowerCase() == b.host.toLowerCase() &&
      a.port == b.port;

  String ensureAbsoluteUrl(String ambiguousUrl, Uri referenceAbsoluteUrl) {
    try {
      ambiguousUrl = ambiguousUrl.trim();
      if (Uri.parse(ambiguousUrl).isAbsolute) {
        return ambiguousUrl;
      }
    } on FormatException {
      // Non-parsable URL, fall through to resolve logic below
    }
    return referenceAbsoluteUrl.resolve(ambiguousUrl).toString();
  }

  /// Performs an HTTP request with redirect following, returning the final URL, client, and streamed response.
  Future<MapEntry<Uri, MapEntry<HttpClient, HttpClientResponse>>>
  sourceRequestStreamResponse(
    String method,
    Map<String, String>? requestHeaders,
    Map<String, dynamic> additionalSettings, {
    bool followRedirects = true,
    Object? postBody,
  }) async {
    final url = additionalSettings['url'] as String;
    var currentUrl = Uri.parse(url);
    var redirectCount = 0;
    List<Cookie> cookies = [];
    while (redirectCount < maxRedirects) {
      // Build the client from the hop's URL so certificate pinning and other
      // host-specific contexts follow redirects instead of sticking to the
      // original URL.
      final hopSettings = Map<String, dynamic>.from(additionalSettings)
        ..['url'] = currentUrl.toString();
      final httpClient = await createHttpClient(hopSettings);
      try {
        final request = await httpClient.openUrl(method, currentUrl);
        if (requestHeaders != null) {
          requestHeaders.forEach((key, value) {
            request.headers.set(key, value);
          });
        }
        request.cookies.addAll(cookies);
        request.followRedirects = false;
        if (postBody != null) {
          if (postBody is String) {
            request.write(postBody);
          } else {
            request.headers.contentType = ContentType.json;
            request.write(safeJsonEncode(postBody));
          }
        }
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );

        if (followRedirects &&
            (response.statusCode >= 300 && response.statusCode <= 399)) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location != null) {
            final nextUrl = Uri.parse(ensureAbsoluteUrl(location, currentUrl));
            if (currentUrl.scheme == 'https' &&
                nextUrl.scheme == 'http' &&
                additionalSettings['allowInsecure'] != true &&
                additionalSettings['allowInsecureRedirects'] != true) {
              // Never follow a redirect that downgrades to cleartext HTTP.
              throw ObtainiumError(tr('insecureRedirect'));
            }
            if (!isSameOrigin(currentUrl, nextUrl)) {
              // Do not forward credentials or any other caller-supplied
              // headers to a different origin; keep only protocol-level ones.
              requestHeaders = requestHeaders == null
                  ? null
                  : Map<String, String>.fromEntries(
                      requestHeaders.entries.where(
                        (e) =>
                            safeRedirectHeaders.contains(e.key.toLowerCase()),
                      ),
                    );
              cookies = [];
            } else {
              cookies = response.cookies;
            }
            currentUrl = nextUrl;
            redirectCount++;
            httpClient.close();
            continue;
          }
        }

        return MapEntry(currentUrl, MapEntry(httpClient, response));
      } catch (e) {
        // Never leak the client when a request or redirect handling throws.
        httpClient.close(force: true);
        rethrow;
      }
    }
    throw ObtainiumError(tr('tooManyRedirects'));
  }

  Future<http.Response> httpClientResponseStreamToFinalResponse(
    HttpClient httpClient,
    String method,
    String url,
    HttpClientResponse response,
  ) async {
    try {
      // A server that stalls mid-body would otherwise hold the request (and
      // an update-check worker) forever.
      final bytes =
          (await response
                  .fold<BytesBuilder>(BytesBuilder(), (b, d) => b..add(d))
                  .timeout(const Duration(seconds: 60)))
              .toBytes();

      final headers = <String, String>{};
      response.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      return http.Response.bytes(
        bytes,
        response.statusCode,
        headers: headers,
        request: http.Request(method, Uri.parse(url)),
      );
    } finally {
      httpClient.close();
    }
  }

  ObtainiumError getHttpError(http.Response res) {
    if (res.statusCode == 404) return NoReleasesError();
    if (res.statusCode == 429) {
      final retryAfter = res.headers['retry-after'];
      final secs = retryAfter != null ? int.tryParse(retryAfter) : null;
      if (secs != null) return RateLimitError((secs / 60).ceil());
      return RateLimitError(1);
    }
    // 403 Forbidden: treat as a rate limit when the server says so explicitly
    // (Retry-After header, or x-ratelimit-remaining: 0 as GitHub uses).
    // Anything else is a hard access-denied error — not a transient rate limit —
    // so batch update loops don't back off on Cloudflare blocks, and the user
    // sees "403 Forbidden" rather than the misleading "try again in 1 minute".
    if (res.statusCode == 403) {
      final retryAfter = res.headers['retry-after'];
      final secs = retryAfter != null ? int.tryParse(retryAfter) : null;
      if (secs != null) return RateLimitError((secs / 60).ceil());
      if (res.headers['x-ratelimit-remaining'] == '0') {
        final reset = int.tryParse(res.headers['x-ratelimit-reset'] ?? '');
        if (reset != null) {
          final secsLeft =
              reset - DateTime.now().millisecondsSinceEpoch ~/ 1000;
          return RateLimitError((secsLeft / 60).ceil().clamp(1, 60));
        }
        return RateLimitError(1);
      }
      final reason = res.reasonPhrase != null && res.reasonPhrase!.isNotEmpty
          ? res.reasonPhrase!
          : tr('errorWithHttpStatusCode', args: ['403']);
      return ObtainiumHttpError(403, reason);
    }
    return ObtainiumError(
      (res.reasonPhrase != null && res.reasonPhrase!.isNotEmpty)
          ? res.reasonPhrase!
          : tr('errorWithHttpStatusCode', args: [res.statusCode.toString()]),
      code: 'HTTP_ERROR',
    );
  }
}

/// Delegates to [HttpService.ensureAbsoluteUrl].
String ensureAbsoluteUrl(String ambiguousUrl, Uri referenceAbsoluteUrl) =>
    HttpService().ensureAbsoluteUrl(ambiguousUrl, referenceAbsoluteUrl);

/// Delegates to [HttpService.createHttpClient].
Future<HttpClient> createHttpClient(
  Map<String, dynamic> additionalSettings,
) async => await HttpService().createHttpClient(additionalSettings);

// ------------------------------------------------------------------------
// More top-level delegation helpers (continued)
// ------------------------------------------------------------------------

/// Delegates to [HttpService.sourceRequestStreamResponse].
Future<MapEntry<Uri, MapEntry<HttpClient, HttpClientResponse>>>
sourceRequestStreamResponse(
  String method,
  Map<String, String>? requestHeaders,
  Map<String, dynamic> additionalSettings, {
  bool followRedirects = true,
  Object? postBody,
}) => HttpService().sourceRequestStreamResponse(
  method,
  requestHeaders,
  additionalSettings,
  followRedirects: followRedirects,
  postBody: postBody,
);

/// Delegates to [HttpService.httpClientResponseStreamToFinalResponse].
Future<http.Response> httpClientResponseStreamToFinalResponse(
  HttpClient httpClient,
  String method,
  String url,
  HttpClientResponse response,
) => HttpService().httpClientResponseStreamToFinalResponse(
  httpClient,
  method,
  url,
  response,
);

/// Delegates to [HttpService.getHttpError].
ObtainiumError getObtainiumHttpError(http.Response res) =>
    HttpService().getHttpError(res);

/// Throws an [ObtainiumError] carrying [res]'s status code unless the response
/// is a 200 OK.
void ensureHttpSuccess(http.Response res) {
  if (res.statusCode != 200) {
    throw getObtainiumHttpError(res);
  }
}
