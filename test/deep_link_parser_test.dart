import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/deep_link_parser.dart';

void main() {
  final app = {
    'id': 'moe.shizuku.privileged.api',
    'url': 'https://github.com/RikkaApps/Shizuku',
    'author': 'RikkaApps',
    'name': 'Shizuku',
    'preferredApkIndex': 0,
    'additionalSettings': jsonEncode({
      'apkFilterRegEx': r'release.*\.apk$',
      'about': 'Use system APIs directly 100% & more?',
    }),
  };

  test('encodeURIComponent app link (catalog sites) decodes to JSON', () {
    final link = parseObtainiumDeepLink(
      Uri.parse('obtainium://app/${Uri.encodeComponent(jsonEncode(app))}'),
    );
    expect(link.action, 'app');
    expect(jsonDecode(link.data), app);
  });

  test('apps link with a list decodes', () {
    final link = parseObtainiumDeepLink(
      Uri.parse(
        'obtainium://apps/${Uri.encodeComponent(jsonEncode([app, app]))}',
      ),
    );
    expect(link.action, 'apps');
    expect(jsonDecode(link.data), [app, app]);
  });

  test('raw JSON with an unencoded ? and # is not truncated', () {
    const json =
        '{"id":"x","url":"https://example.com/a?b=c#frag","name":"X 100%"}';
    final link = parseObtainiumDeepLink(Uri.parse('obtainium://app/$json'));
    expect(jsonDecode(link.data), jsonDecode(json));
  });

  test('payload holding a literal %25 survives decoding', () {
    final withPercent = {'id': 'y', 'url': 'https://e.com/a%25b', 'name': 'Y'};
    final link = parseObtainiumDeepLink(
      Uri.parse(
        'obtainium://app/${Uri.encodeComponent(jsonEncode(withPercent))}',
      ),
    );
    expect(jsonDecode(link.data), withPercent);
  });

  test('add link with a plain URL keeps its query', () {
    final link = parseObtainiumDeepLink(
      Uri.parse('obtainium://add/https://github.com/o/r?x=y'),
    );
    expect(link.action, 'add');
    expect(link.data, 'https://github.com/o/r?x=y');
  });

  test('add link with an encoded URL is decoded', () {
    final link = parseObtainiumDeepLink(
      Uri.parse(
        'obtainium://add/${Uri.encodeComponent('https://github.com/o/r')}',
      ),
    );
    expect(link.data, 'https://github.com/o/r');
  });

  test('add link via ?url= query', () {
    final link = parseObtainiumDeepLink(
      Uri.parse(
        'obtainium://add?url=${Uri.encodeQueryComponent('https://g.com/o/r?a=1')}',
      ),
    );
    expect(link.data, 'https://g.com/o/r?a=1');
  });

  test('refresh keeps its query id and host is case-insensitive', () {
    final uri = Uri.parse('obtainium://REFRESH?id=abc');
    final link = parseObtainiumDeepLink(uri);
    expect(link.action, 'refresh');
    expect(uri.queryParameters['id'], 'abc');
  });
  test('plain add URL keeps meaningful escapes', () {
    final link = parseObtainiumDeepLink(
      Uri.parse('obtainium://add/https://e.com/a%20b?q=a%26b'),
    );
    expect(link.data, 'https://e.com/a%20b?q=a%26b');
  });

  test('tracking query or fragment after an encoded app payload', () {
    final encoded = Uri.encodeComponent(jsonEncode(app));
    for (final suffix in ['?utm_source=x', '#x']) {
      final link = parseObtainiumDeepLink(
        Uri.parse('obtainium://app/$encoded$suffix'),
      );
      expect(jsonDecode(link.data), app, reason: suffix);
    }
  });

  test('real catalog link (apps.obtainium.imranr.dev) parses', () {
    // Copied verbatim from the community catalog page, 2026-11-11.
    const href =
        'obtainium://app/%7B%22id%22%3A%22com.deniscerri.ytdl%22%2C%22url%22%3A%22https%3A%2F%2Fgithub.com%2Fdeniscerri%2Fytdlnis%22%2C%22author%22%3A%22deniscerri%22%2C%22name%22%3A%22YTDLnis%22%2C%22additionalSettings%22%3A%22%7B%5C%22apkFilterRegEx%5C%22%3A%5C%22universal-github%5C%22%2C%5C%22appName%5C%22%3A%5C%22YTDLnis%5C%22%2C%5C%22appAuthor%5C%22%3A%5C%22deniscerri%5C%22%2C%5C%22about%5C%22%3A%5C%22Android%20Video%2FAudio%20Downloader%20app%20using%20yt-dlp%5C%22%7D%22%7D';
    final uri = Uri.parse(href);
    // The old handler passed this still-encoded path to jsonDecode.
    expect(() => jsonDecode(uri.path.substring(1)), throwsFormatException);
    final parsed = jsonDecode(parseObtainiumDeepLink(uri).data) as Map;
    expect(parsed['id'], 'com.deniscerri.ytdl');
    expect(parsed['url'], 'https://github.com/deniscerri/ytdlnis');
  });
}
