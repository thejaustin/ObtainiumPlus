import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('useRefreshButton is off by default and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = UpdateSettingsProvider();
    provider.prefs = await SharedPreferences.getInstance();
    expect(provider.useRefreshButton, isFalse);
    provider.useRefreshButton = true;
    final reloaded = UpdateSettingsProvider();
    reloaded.prefs = await SharedPreferences.getInstance();
    expect(reloaded.useRefreshButton, isTrue);
  });

  test('cancelUpdateCheck cancels the running check token only', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final provider = AppsProvider(isBg: true, settingsProvider: settings);
    addTearDown(provider.dispose);

    // No check running: nothing to cancel, and it must not throw.
    provider.cancelUpdateCheck();

    final token = CancellationToken();
    provider.updateCheckCancellation = token;
    expect(token.isCancelled, isFalse);
    provider.cancelUpdateCheck();
    expect(token.isCancelled, isTrue);
  });
}
