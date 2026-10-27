import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/installers/install_landed.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hasInstallLanded', () {
    test('new install: waits for the target code', () {
      expect(
        hasInstallLanded(wasInstalled: false, targetCode: 5, currentCode: 4),
        isFalse,
      );
      expect(
        hasInstallLanded(wasInstalled: false, targetCode: 5, currentCode: 5),
        isTrue,
      );
    });

    test('update: the old version is not success', () {
      expect(
        hasInstallLanded(
          wasInstalled: true,
          existingCode: 10,
          targetCode: 11,
          currentCode: 10,
        ),
        isFalse,
      );
      expect(
        hasInstallLanded(
          wasInstalled: true,
          existingCode: 10,
          targetCode: 11,
          currentCode: 11,
        ),
        isTrue,
      );
    });

    test('update with null codes (Android 15 long codes) is not an '
        'instant success', () {
      // Before: a null existing code counted as a fresh install, so the
      // first poll — still the old version — reported success.
      expect(
        hasInstallLanded(
          wasInstalled: true,
          existingName: '1.0',
          targetName: '1.1',
          currentName: '1.0',
        ),
        isFalse,
      );
      expect(
        hasInstallLanded(
          wasInstalled: true,
          existingName: '1.0',
          targetName: '1.1',
          currentName: '1.1',
        ),
        isTrue,
      );
    });

    test('same-version reinstall lands when the update time moves', () {
      const base = (
        existingCode: 7,
        existingName: '2.0',
        targetCode: 7,
        targetName: '2.0',
      );
      expect(
        hasInstallLanded(
          wasInstalled: true,
          existingCode: base.existingCode,
          existingName: base.existingName,
          targetCode: base.targetCode,
          targetName: base.targetName,
          existingUpdateTime: 100,
          currentCode: 7,
          currentName: '2.0',
          currentUpdateTime: 100,
        ),
        isFalse,
      );
      expect(
        hasInstallLanded(
          wasInstalled: true,
          existingCode: base.existingCode,
          existingName: base.existingName,
          targetCode: base.targetCode,
          targetName: base.targetName,
          existingUpdateTime: 100,
          currentCode: 7,
          currentName: '2.0',
          currentUpdateTime: 200,
        ),
        isTrue,
      );
    });
  });

  group('BehaviorSettingsProvider installer mode', () {
    Future<BehaviorSettingsProvider> provider(
      Map<String, Object> values,
    ) async {
      SharedPreferences.setMockInitialValues(values);
      final p = BehaviorSettingsProvider();
      await p.initializeSettings(await SharedPreferences.getInstance());
      return p;
    }

    test(
      'migrated prefs (installMethod only) still count as Shizuku',
      () async {
        final p = await provider({'installMethod': 'shizuku'});
        expect(p.useShizuku, isTrue);
      },
    );

    test('the old bool alone still selects Shizuku', () async {
      final p = await provider({'useShizuku': true});
      expect(p.installerMode, InstallerMode.shizuku.name);
      expect(p.useShizuku, isTrue);
    });

    test('turning Shizuku off leaves root alone', () async {
      final p = await provider({'installMethod': 'root'});
      p.useShizuku = false;
      expect(p.installerMode, 'root');
    });

    test('turning Shizuku off from Shizuku goes back to the system '
        'installer', () async {
      final p = await provider({'installMethod': 'shizuku'});
      p.useShizuku = false;
      expect(p.installerMode, InstallerMode.system.name);
      p.useShizuku = true;
      expect(p.installerMode, InstallerMode.shizuku.name);
    });
  });

  test('moveStrToEnd moves both matches in order', () {
    expect(
      AppDownloadService.moveStrToEnd(['a', 'x', 'b', 'y'], 'a', strB: 'b'),
      ['x', 'y', 'a', 'b'],
    );
    expect(AppDownloadService.moveStrToEnd(['a', 'b'], 'z'), ['a', 'b']);
  });
}
