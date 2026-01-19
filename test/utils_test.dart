import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/app_utils.dart';

void main() {
  group('AppUtils Tests', () {
    test('tryParseDateTime should parse valid dates', () {
      expect(tryParseDateTime('2023-10-26T12:00:00Z'), isNotNull);
      expect(tryParseDateTime('2023-10-26'), isNotNull);
    });

    test('tryParseDateTime should return null for invalid dates', () {
      expect(tryParseDateTime('invalid-date'), isNull);
      expect(tryParseDateTime('2023/10/26'), isNull); // Flutter DateTime expects hyphens
      expect(tryParseDateTime(''), isNull);
    });

    test('tryParseDateTime should return null for null input', () {
      expect(tryParseDateTime(null), isNull);
    });
  });
}
