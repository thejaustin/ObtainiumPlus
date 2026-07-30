import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/utils/version_utils.dart';

void main() {
  group('Standard version format detection (issue #218)', () {
    test('patch-style versions like 1.4.3-p15 match a standard format', () {
      // Obtainium+ itself is versioned this way; before the p[0-9]+ suffix
      // was added, this returned empty and version detection got
      // auto-disabled for the app (perpetual "update available" prompt).
      expect(findStandardFormatsForVersion('1.4.3-p15', true), isNotEmpty);
      expect(findStandardFormatsForVersion('1.4.3-p1', true), isNotEmpty);
      expect(findStandardFormatsForVersion('1.4.3p15', true), isNotEmpty);
    });

    test('different patch versions share a common format but differ', () {
      var a = findStandardFormatsForVersion('1.4.3-p15', true);
      var b = findStandardFormatsForVersion('1.4.3-p16', true);
      var common = a.intersection(b);
      expect(common, isNotEmpty);
      // No common pattern should treat the two as the same version string.
      for (var pattern in common) {
        var r = RegExp(pattern);
        var m1 = r.firstMatch('1.4.3-p15');
        var m2 = r.firstMatch('1.4.3-p16');
        expect(m1, isNotNull);
        expect(m2, isNotNull);
        expect(
          '1.4.3-p15'.substring(m1!.start, m1.end) ==
              '1.4.3-p16'.substring(m2!.start, m2.end),
          isFalse,
          reason: 'pattern $pattern conflated p15 and p16',
        );
      }
    });

    test('previously supported formats still match', () {
      expect(findStandardFormatsForVersion('1.2.3', true), isNotEmpty);
      expect(findStandardFormatsForVersion('1.2.3-beta2', true), isNotEmpty);
      expect(findStandardFormatsForVersion('2.0.0-rc1', true), isNotEmpty);
      expect(findStandardFormatsForVersion('1.2.3-alpha', true), isNotEmpty);
      expect(findStandardFormatsForVersion('1.2.3+45', true), isNotEmpty);
    });

    test('non-version strings match nothing in strict mode', () {
      expect(findStandardFormatsForVersion('abcdef', true), isEmpty);
      expect(
        findStandardFormatsForVersion('c0ffee1234deadbeef', true),
        isEmpty,
      );
    });
  });
}
