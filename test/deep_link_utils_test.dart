import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/deep_link_utils.dart';

void main() {
  test('decodes a percent-encoded app JSON link (store buttons)', () {
    final json = jsonEncode({
      'id': 'com.example.app',
      'url': 'https://github.com/example/app',
      'author': 'example',
      'name': 'App',
      'additionalSettings': jsonEncode({'includePrereleases': false}),
    });
    final uri = Uri.parse('obtainium://app/${Uri.encodeComponent(json)}');
    expect(jsonDecode(deepLinkData(uri))['id'], 'com.example.app');
  });

  test('decodes an encoded add URL, keeping its own query string', () {
    const url = 'https://github.com/example/app/releases?q=1&x=2';
    final uri = Uri.parse('obtainium://add/${Uri.encodeComponent(url)}');
    expect(uri.host, 'add');
    expect(deepLinkData(uri), url);
  });

  test('plain unencoded add URLs still work', () {
    expect(
      deepLinkData(Uri.parse('obtainium://add/https://github.com/example/app')),
      'https://github.com/example/app',
    );
  });

  test('?url= wins and malformed escapes are kept as-is', () {
    expect(
      deepLinkData(Uri.parse('obtainium://add?url=https://example.org/a')),
      'https://example.org/a',
    );
    expect(deepLinkData(Uri.parse('obtainium://add/100%25')), '100%');
    expect(deepLinkData(Uri.parse('obtainium://app')), '');
  });
}
