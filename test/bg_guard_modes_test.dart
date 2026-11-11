import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/settings_provider.dart' show BgGuardMode;
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/utils/bg_update_guards.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UpdateSettingsProvider> _provider(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final p = UpdateSettingsProvider();
  p.prefs = await SharedPreferences.getInstance();
  return p;
}

void main() {
  test('old "only on Wi-Fi/charging" switches map to "nothing"', () async {
    final p = await _provider({
      'bgUpdateRequiresWifi': true,
      'bgUpdatesWhileChargingOnly': true,
    });
    expect(p.bgGuardOnWiFi, BgGuardMode.nothing);
    expect(p.bgGuardWhileCharging, BgGuardMode.nothing);
  });

  test('no stored settings allow checks and updates', () async {
    final p = await _provider({});
    expect(p.bgGuardOnWiFi, BgGuardMode.checksAndUpdates);
    expect(p.bgGuardWhileCharging, BgGuardMode.checksAndUpdates);
  });

  test(
    'a stored mode wins and keeps the scheduler constraint in sync',
    () async {
      final p = await _provider({'bgUpdateRequiresWifi': true});
      p.bgGuardOnWiFi = BgGuardMode.checksOnly;
      expect(p.bgGuardOnWiFi, BgGuardMode.checksOnly);
      expect(p.bgUpdateRequiresWifi, isFalse);
      p.bgGuardOnWiFi = BgGuardMode.nothing;
      expect(p.bgUpdateRequiresWifi, isTrue);
    },
  );

  test('checks only blocks installs but not checks', () {
    final d = evaluateBgGuards(
      wifiMode: BgGuardMode.checksOnly,
      chargingMode: BgGuardMode.checksAndUpdates,
      onUnmeteredNetwork: false,
      charging: false,
    );
    expect(d.skipChecks, isFalse);
    expect(d.allowInstalls, isFalse);
  });
}
