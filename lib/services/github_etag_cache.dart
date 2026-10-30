// Conditional-request cache for GitHub API responses.
//
// GitHub answers `If-None-Match` with an empty 304 when nothing changed, so a
// repeat update check of an unchanged repo transfers almost nothing instead of
// a release list that can run to hundreds of KB. With a token, those 304s also
// don't count against the rate limit.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

class GitHubCachedResponse {
  const GitHubCachedResponse(this.etag, this.body);
  final String etag;
  final String body;
}

class GitHubEtagCache {
  GitHubEtagCache({
    Future<Directory> Function()? directory,
    this.maxEntries = 600,
    this.maxBytes = 40 * 1024 * 1024,
  }) : _directory = directory ?? _defaultDirectory;

  static final GitHubEtagCache instance = GitHubEtagCache();

  final Future<Directory> Function() _directory;

  /// Least recently used entries are pruned past this many cached URLs or
  /// this many bytes on disk (entries are gzipped; a busy repo's release list
  /// is a few hundred KB).
  final int maxEntries;
  final int maxBytes;

  Directory? _dir;
  int _writesSincePrune = 0;

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getTemporaryDirectory()).path}/github_etag_cache');

  Future<Directory> _cacheDir() async {
    final dir = _dir ??= await _directory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(String url) async =>
      File('${(await _cacheDir()).path}/${sha1.convert(utf8.encode(url))}.gz');

  /// The cached response for [url], if any. Send its [GitHubCachedResponse.etag]
  /// as `If-None-Match`, then pass it to [resolve].
  Future<GitHubCachedResponse?> lookup(String url) async {
    final entry = await _read(url);
    final etag = entry?['etag'];
    final body = entry?['body'];
    if (etag is! String || body is! String) return null;
    return GitHubCachedResponse(etag, body);
  }

  /// Turns a 304 for [url] back into the [cached] 200 response. Returns
  /// [response] unchanged for any other status, and stores a fresh 200 that
  /// carries an ETag.
  Future<Response> resolve(
    String url,
    Response response,
    GitHubCachedResponse? cached,
  ) async {
    if (response.statusCode == 304) {
      final body = cached?.body;
      if (body == null) return response;
      // Touch so pruning keeps entries that are still in use.
      try {
        await (await _fileFor(url)).setLastModified(DateTime.now());
      } catch (_) {}
      return Response(
        body,
        200,
        // The 304 carries the current rate-limit headers; keep those.
        headers: {
          'content-type': 'application/json; charset=utf-8',
          ...response.headers,
        },
        request: response.request,
      );
    }
    final etag = response.headers['etag'];
    if (response.statusCode == 200 && etag != null && etag.isNotEmpty) {
      await _write(url, etag, response.body);
    }
    return response;
  }

  Future<Map<String, dynamic>?> _read(String url) async {
    try {
      final file = await _fileFor(url);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(
        utf8.decode(gzip.decode(await file.readAsBytes())),
      );
      if (decoded is! Map<String, dynamic> || decoded['url'] != url) {
        return null;
      }
      return decoded;
    } catch (_) {
      // A corrupt or half-written entry just means a full request.
      return null;
    }
  }

  Future<void> _write(String url, String etag, String body) async {
    try {
      final file = await _fileFor(url);
      final tmp = File('${file.path}.${DateTime.now().microsecondsSinceEpoch}');
      await tmp.writeAsBytes(
        gzip.encode(
          utf8.encode(jsonEncode({'url': url, 'etag': etag, 'body': body})),
        ),
      );
      await tmp.rename(file.path);
      if (++_writesSincePrune >= 50) {
        _writesSincePrune = 0;
        await _prune();
      }
    } catch (_) {
      // Caching is best-effort.
    }
  }

  Future<void> _prune() async {
    final files = await (await _cacheDir())
        .list()
        .where((e) => e is File && e.path.endsWith('.gz'))
        .cast<File>()
        .toList();
    final stats = [for (final f in files) MapEntry(f, await f.stat())]
      ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
    var count = stats.length;
    var bytes = stats.fold<int>(0, (sum, e) => sum + e.value.size);
    for (final entry in stats) {
      if (count <= maxEntries && bytes <= maxBytes) break;
      try {
        await entry.key.delete();
        count--;
        bytes -= entry.value.size;
      } catch (_) {}
    }
  }

  /// Test hook: prune now regardless of the write counter.
  Future<void> pruneForTest() => _prune();
}
