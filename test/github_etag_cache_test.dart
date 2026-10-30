import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:obtainium/services/github_etag_cache.dart';

void main() {
  late Directory dir;
  late GitHubEtagCache cache;
  const url = 'https://api.github.com/repos/o/r/releases?per_page=100';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('etag_cache_test');
    cache = GitHubEtagCache(directory: () async => dir, maxEntries: 3);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('stores a 200 with an ETag and answers the 304 from cache', () async {
    expect(await cache.lookup(url), isNull);

    final fresh = Response(
      '[{"tag_name":"v1"}]',
      200,
      headers: {'etag': 'W/"abc"'},
    );
    expect(await cache.resolve(url, fresh, null), same(fresh));

    final cached = await cache.lookup(url);
    expect(cached?.etag, 'W/"abc"');

    final notModified = Response(
      '',
      304,
      headers: {'x-ratelimit-remaining': '42'},
    );
    final resolved = await cache.resolve(url, notModified, cached);
    expect(resolved.statusCode, 200);
    expect(resolved.body, '[{"tag_name":"v1"}]');
    // Rate-limit headers come from the live 304.
    expect(resolved.headers['x-ratelimit-remaining'], '42');
  });

  test('leaves other responses alone and skips ETag-less ones', () async {
    final noEtag = Response('[]', 200);
    await cache.resolve(url, noEtag, null);
    expect(await cache.lookup(url), isNull);

    final error = Response('nope', 404, headers: {'etag': '"x"'});
    expect(await cache.resolve(url, error, null), same(error));
    expect(await cache.lookup(url), isNull);

    // A 304 with nothing cached is passed through for the caller to handle.
    final orphan = Response('', 304);
    expect(await cache.resolve(url, orphan, null), same(orphan));
  });

  test('a corrupt entry reads as a cache miss', () async {
    await cache.resolve(
      url,
      Response('[]', 200, headers: {'etag': '"1"'}),
      null,
    );
    for (final f in dir.listSync().whereType<File>()) {
      f.writeAsStringSync('not gzip');
    }
    expect(await cache.lookup(url), isNull);
  });

  test('prunes the least recently used entries past the cap', () async {
    for (var i = 0; i < 5; i++) {
      await cache.resolve(
        '$url&page=$i',
        Response('[$i]', 200, headers: {'etag': '"$i"'}),
        null,
      );
    }
    final files = dir.listSync().whereType<File>().toList();
    expect(files.length, 5);
    var t = DateTime(2026, 1, 1);
    for (final f in files) {
      f.setLastModifiedSync(t = t.add(const Duration(minutes: 1)));
    }
    final oldest = files.take(2).map((f) => f.path).toSet();
    await cache.pruneForTest();
    final remaining = dir.listSync().whereType<File>().map((f) => f.path);
    expect(remaining.length, 3);
    expect(remaining.toSet().intersection(oldest), isEmpty);
  });

  test('prunes oldest entries past the byte cap', () async {
    final small = GitHubEtagCache(directory: () async => dir, maxBytes: 1);
    await small.resolve(
      url,
      Response('[]', 200, headers: {'etag': '"1"'}),
      null,
    );
    expect(dir.listSync().whereType<File>(), isNotEmpty);
    await small.pruneForTest();
    expect(dir.listSync().whereType<File>(), isEmpty);
  });
}
