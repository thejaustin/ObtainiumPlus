import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every literal `tr('key')` / `plural('key')` in lib/ must exist in en.json;
/// a missing key shows its raw name in the UI.
void main() {
  test('all literal translation keys used in lib/ exist in en.json', () {
    final en =
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    final keyRe = RegExp(r"""\b(?:tr|plural)\(\s*'([A-Za-z0-9_]+)'""");
    final missing = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in keyRe.allMatches(f.readAsStringSync())) {
        final key = m.group(1)!;
        if (!en.containsKey(key)) missing.add('$key (${f.path})');
      }
    }
    expect(missing, isEmpty);
  });
}
