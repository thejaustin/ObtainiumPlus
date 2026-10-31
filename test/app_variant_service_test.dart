import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/services/app_variant_service.dart';
import 'package:obtainium/utils/app_constants.dart';

void main() {
  const shizuku = InstalledVariant(
    packageName: AppConstants.shizukuStockId,
    label: 'Shizuku',
    versionName: '13.6.0',
  );

  VariantAction decide({
    bool exact = false,
    List<InstalledVariant> variants = const [shizuku],
    String? remembered,
    bool askEnabled = true,
    bool hasContext = true,
  }) => AppVariantService.decide(
    apkPackageInstalled: exact,
    installedVariants: variants,
    rememberedChoice: remembered,
    askEnabled: askEnabled,
    hasContext: hasContext,
  );

  group('decide', () {
    test('the exact package installed is a normal update', () {
      expect(decide(exact: true), VariantAction.install);
    });

    test('nothing else installed is a normal install', () {
      expect(decide(variants: const []), VariantAction.install);
    });

    test('only another build installed asks', () {
      expect(decide(), VariantAction.ask);
    });

    test('remembered "keep both" installs without asking', () {
      expect(
        decide(remembered: AppVariantService.keepBothValue),
        VariantAction.install,
      );
    });

    test('turning the setting off installs without asking', () {
      expect(decide(askEnabled: false), VariantAction.install);
    });

    test('no one to ask holds instead of adding a second app', () {
      expect(decide(hasContext: false), VariantAction.hold);
    });

    test('a remembered choice still applies in the background', () {
      expect(
        decide(hasContext: false, remembered: AppVariantService.keepBothValue),
        VariantAction.install,
      );
    });
  });

  group('candidateVariants', () {
    test('Shizuku+ and its drop-in build are variants of each other', () {
      expect(
        AppVariantService.candidateVariants(AppConstants.shizukuPlusId),
        contains(AppConstants.shizukuStockId),
      );
      expect(
        AppVariantService.candidateVariants(AppConstants.shizukuStockId),
        contains(AppConstants.shizukuPlusId),
      );
    });

    test('Dhizuku is a separate app, not a Shizuku build', () {
      expect(
        AppVariantService.candidateVariants(AppConstants.shizukuPlusId),
        isNot(contains(AppConstants.dhizukuId)),
      );
      expect(
        AppVariantService.candidateVariants(AppConstants.dhizukuId),
        isEmpty,
      );
    });

    test('suffix builds both ways, never the package itself', () {
      final v = AppVariantService.candidateVariants('org.example.app.fdroid');
      expect(v, contains('org.example.app'));
      expect(v, contains('org.example.app.fdroid.debug'));
      expect(v, isNot(contains('org.example.app.fdroid')));
    });
  });
}
