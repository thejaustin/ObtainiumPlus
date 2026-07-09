import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/utils/version_utils.dart';

App makeApp(String? installed, String latest) => App(
  'com.example.app',
  'https://github.com/example/app',
  'example',
  'Example',
  installed,
  latest,
  [],
  0,
  <String, dynamic>{},
  null,
  false,
);

void main() {
  group('compareVersionStrings', () {
    test('orders ObtainiumPlus patch scheme numerically', () {
      expect(compareVersionStrings('1.4.3-p36', '1.4.3-p41'), lessThan(0));
      expect(compareVersionStrings('1.4.3-p42', '1.4.3-p41'), greaterThan(0));
      expect(compareVersionStrings('1.4.3-p41', '1.4.3-p41'), 0);
    });

    test('compares numeric segments piecewise, not lexically', () {
      expect(compareVersionStrings('1.4.3', '1.4.10'), lessThan(0));
      expect(compareVersionStrings('1.10.0', '1.9.5'), greaterThan(0));
    });

    test('treats trailing zero segments and v-prefix as insignificant', () {
      expect(compareVersionStrings('1.4', '1.4.0'), 0);
      expect(compareVersionStrings('v1.4.3', '1.4.4'), lessThan(0));
    });

    test('returns null for structurally incomparable strings', () {
      // Date-like vs semver
      expect(compareVersionStrings('2024-01-05', '1.2.3'), isNull);
      // Hash-like strings
      expect(compareVersionStrings('abc123', '1.2.3'), isNull);
      expect(compareVersionStrings('abc123', 'def456'), isNull);
      // No digits at all
      expect(compareVersionStrings('latest', 'stable'), isNull);
      // Extra non-zero segment
      expect(compareVersionStrings('1.4.3-p36', '1.4.3'), isNull);
      // Differing non-numeric suffix structure
      expect(compareVersionStrings('1.4.3-beta2', '1.4.3-alpha3'), isNull);
    });
  });

  group('areVersionsDifferent downgrade guard', () {
    test('does not offer a confidently older latestVersion as an update', () {
      // The v1.4.3-p41 -> v1.4.3-p36 DowngradeError scenario: installed got
      // reconciled from the OS but latestVersion is stale.
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('1.4.3-p41', '1.4.3-p36'),
          '1.4.3-p41',
          '1.4.3-p36',
        ),
        isFalse,
      );
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('1.4.10', '1.4.3'),
          '1.4.10',
          '1.4.3',
        ),
        isFalse,
      );
    });

    test('still offers newer versions as updates', () {
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('1.4.3-p41', '1.4.3-p42'),
          '1.4.3-p41',
          '1.4.3-p42',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('1.4.3', '1.4.10'),
          '1.4.3',
          '1.4.10',
        ),
        isTrue,
      );
    });

    test('equal or reconciled-equal versions are not updates', () {
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('1.4.3-p41', '1.4.3-p41'),
          '1.4.3-p41',
          '1.4.3-p41',
        ),
        isFalse,
      );
    });

    test('unorderable but different versions still count as updates', () {
      // Ordering is unknown here, so behavior must fall back to
      // "different = update available" — never suppress genuine updates
      // for apps with unusual versioning.
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('2024-01-05', '1.2.3'),
          '2024-01-05',
          '1.2.3',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('abc123', 'def456'),
          'abc123',
          'def456',
        ),
        isTrue,
      );
    });

    test('ignoreOrdering restores plain mismatch detection', () {
      // Used by version-format reconciliation call sites that need to know
      // whether the strings differ at all, not whether an update exists.
      expect(
        AppUpdateService.areVersionsDifferent(
          makeApp('1.4.3-p41', '1.4.3-p36'),
          '1.4.3-p41',
          '1.4.3-p36',
          ignoreOrdering: true,
        ),
        isTrue,
      );
    });

    test('isAmbiguousUpdate flag behavior is preserved', () {
      // Likely-identical strings that fail reconciliation set the flag
      var ambiguous = makeApp('1.2.3', '1.2.3-fork');
      expect(
        AppUpdateService.areVersionsDifferent(ambiguous, '1.2.3', '1.2.3-fork'),
        isTrue,
      );
      expect(ambiguous.additionalSettings['isAmbiguousUpdate'], isTrue);

      // A clearly distinct newer version removes a stale flag
      var distinct = makeApp('1.4.3-p41', '1.4.3-p42');
      distinct.additionalSettings['isAmbiguousUpdate'] = true;
      expect(
        AppUpdateService.areVersionsDifferent(
          distinct,
          '1.4.3-p41',
          '1.4.3-p42',
        ),
        isTrue,
      );
      expect(
        distinct.additionalSettings.containsKey('isAmbiguousUpdate'),
        isFalse,
      );
    });
  });
}
