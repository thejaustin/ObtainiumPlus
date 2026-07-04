import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SafePrefs type-tolerant reads (issue #217)', () {
    test('coerces int-stored values read as double and vice versa', () async {
      SharedPreferences.setMockInitialValues({
        'storedAsInt': 3,
        'storedAsDouble': 2.5,
      });
      final prefs = await SharedPreferences.getInstance();

      // getDouble('storedAsInt') would throw a TypeError; safeDouble coerces.
      expect(prefs.safeDouble('storedAsInt'), 3.0);
      expect(prefs.safeInt('storedAsDouble'), 3); // .round()
      expect(prefs.safeDouble('storedAsDouble'), 2.5);
      expect(prefs.safeInt('storedAsInt'), 3);
    });

    test('returns null (not a throw) for missing or mistyped keys', () async {
      SharedPreferences.setMockInitialValues({
        'aString': 'hello',
        'aBool': true,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.safeDouble('missing'), isNull);
      expect(prefs.safeInt('missing'), isNull);
      expect(prefs.safeBool('missing'), isNull);
      expect(prefs.safeDouble('aString'), isNull);
      expect(prefs.safeInt('aString'), isNull);
      expect(prefs.safeBool('aString'), isNull);
      expect(prefs.safeBool('aBool'), isTrue);
    });

    test('safeString/safeStringList tolerate mistyped values', () async {
      SharedPreferences.setMockInitialValues({
        'aString': 'hello',
        'anInt': 7,
        'aList': ['a', 'b'],
      });
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.safeString('aString'), 'hello');
      expect(prefs.safeString('anInt'), isNull);
      expect(prefs.safeStringList('aList'), ['a', 'b']);
      expect(prefs.safeStringList('aString'), isNull);
    });

    test('safeEnum rejects out-of-range indexes instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'valid': 1,
        'tooBig': 99, // e.g. enum lost members between app versions
        'negative': -1,
      });
      final prefs = await SharedPreferences.getInstance();
      const values = ['zero', 'one', 'two'];

      expect(prefs.safeEnum('valid', values), 'one');
      expect(prefs.safeEnum('tooBig', values), isNull);
      expect(prefs.safeEnum('negative', values), isNull);
      expect(prefs.safeEnum('missing', values), isNull);
    });
  });
}
