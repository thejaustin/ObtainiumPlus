import 'package:android_package_manager/android_package_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApplicationInfo extends ApplicationInfo {
  _FakeApplicationInfo({required super.enabled})
    : super(
        compatibleWidthLimitDp: 0,
        dataDir: '',
        descriptionRes: 0,
        flags: 0,
        largestWidthLimitDp: 0,
        processName: '',
        publicSourceDir: '',
        requiresSmallestWidthDp: 0,
        sourceDir: '',
        theme: 0,
        uiOptions: 0,
        uid: 0,
        targetSdkVersion: 35,
      );
}

class _FakePackageInfo extends PackageInfo {
  const _FakePackageInfo({super.packageName, super.applicationInfo})
    : super(installLocation: AndroidInstallLocation.auto);
}

App _app(String id) => App(
  id,
  'https://github.com/example/$id',
  'Author',
  id,
  '1.0',
  '2.0',
  const [],
  0,
  const {},
  null,
  false,
);

PackageInfo _pkg(String id, {bool? enabled}) => _FakePackageInfo(
  packageName: id,
  applicationInfo: enabled == null
      ? null
      : _FakeApplicationInfo(enabled: enabled),
);

AppInMemory _aim(String id, {PackageInfo? info}) =>
    AppInMemory(_app(id), null, info, null);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('checkSystemDisabledApps defaults to true and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = UpdateSettingsProvider();
    provider.prefs = await SharedPreferences.getInstance();
    expect(provider.checkSystemDisabledApps, isTrue);
    provider.checkSystemDisabledApps = false;
    final reloaded = UpdateSettingsProvider();
    reloaded.prefs = await SharedPreferences.getInstance();
    expect(reloaded.checkSystemDisabledApps, isFalse);
  });

  test('AppInMemory.isSystemDisabled reflects applicationInfo.enabled', () {
    expect(_aim('a').isSystemDisabled, isFalse);
    expect(_aim('b', info: _pkg('b')).isSystemDisabled, isFalse);
    expect(_aim('c', info: _pkg('c', enabled: true)).isSystemDisabled, isFalse);
    expect(_aim('d', info: _pkg('d', enabled: false)).isSystemDisabled, isTrue);
  });

  test('static candidate list skips system-disabled apps only when off', () {
    final apps = {
      'on': _aim('on', info: _pkg('on', enabled: true)),
      'off': _aim('off', info: _pkg('off', enabled: false)),
    };
    expect(
      AppUpdateService.getAppsSortedByUpdateCheckTime(apps).toSet(),
      {'on', 'off'},
    );
    expect(
      AppUpdateService.getAppsSortedByUpdateCheckTime(
        apps,
        checkSystemDisabledApps: false,
      ),
      ['on'],
    );
  });

  test('AppsProvider candidates and installed-info refresh', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final provider = AppsProvider(isBg: true, settingsProvider: settings);
    addTearDown(provider.dispose);
    provider.apps['x'] = _aim('x', info: _pkg('x', enabled: true));
    provider.apps['y'] = _aim('y', info: _pkg('y', enabled: true));

    await provider.refreshInstalledInfoForChecks(
      fetchInstalledInfo: () async => [_pkg('x', enabled: false)],
    );
    expect(provider.apps['x']!.isSystemDisabled, isTrue);
    expect(provider.apps['y']!.isSystemDisabled, isFalse);

    expect(provider.getAppsSortedByUpdateCheckTime().toSet(), {'x', 'y'});
    expect(
      provider.getAppsSortedByUpdateCheckTime(checkSystemDisabledApps: false),
      ['y'],
    );

    await provider.refreshInstalledInfoForChecks(
      fetchInstalledInfo: () async => throw Exception('boom'),
    );
    expect(provider.apps['x']!.isSystemDisabled, isTrue);
  });
}
