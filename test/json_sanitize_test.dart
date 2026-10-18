import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/app_utils.dart';

class _WithToJson {
  Map<String, dynamic> toJson() => {'speed': double.nan, 'ok': 1.5};
}

// #240/#241: JsonUnsupportedObjectError "Converting object to an encodable
// object failed: NaN" from app data reaching jsonEncode.
void main() {
  test('NaN and infinities become null at any depth', () {
    final encoded = safeJsonEncode({
      'a': double.nan,
      'b': [double.infinity, 2.0],
      'c': {'d': double.negativeInfinity},
      'e': {1.0, double.nan},
    });
    expect(jsonDecode(encoded), {
      'a': null,
      'b': [null, 2.0],
      'c': {'d': null},
      'e': [1.0, null],
    });
  });

  test('NaN inside a toJson() result is sanitized', () {
    final encoded = safeJsonEncode({'item': _WithToJson()});
    expect(jsonDecode(encoded), {
      'item': {'speed': null, 'ok': 1.5},
    });
  });

  test('plain values pass through unchanged', () {
    expect(sanitizeJsonValue(3), 3);
    expect(sanitizeJsonValue('x'), 'x');
    expect(sanitizeJsonValue(null), isNull);
    expect(sanitizeJsonValue(true), isTrue);
  });
}
