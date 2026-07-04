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
  });
}
