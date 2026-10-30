import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppsProvider> providerWithApp() async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final provider = AppsProvider(isBg: true, settingsProvider: settings);
    final app = App(
      'com.example.app',
      'https://git.example.com/me/app',
      'Author',
      'App',
      null,
      '1.0',
      const [],
      0,
      {'github-creds': 'secret-token', 'includePrereleases': true},
      null,
      false,
    );
    provider.apps[app.id] = AppInMemory(app, null, null, null);
    return provider;
  }

  Map<String, dynamic> exportedSettings(Map<String, dynamic> export) {
    final app = (export['apps'] as List).single as Map<String, dynamic>;
    return jsonDecode(app['additionalSettings'] as String)
        as Map<String, dynamic>;
  }

  test('exports without credentials strip per-app tokens', () async {
    final provider = await providerWithApp();
    addTearDown(provider.dispose);
    for (final level in [0, 1]) {
      final settings = exportedSettings(
        provider.generateExportJSON(overrideExportSettings: level),
      );
      expect(settings.containsKey('github-creds'), isFalse);
      expect(settings['includePrereleases'], isTrue);
    }
    // The app in memory keeps its token.
    expect(
      provider.apps['com.example.app']!.app.additionalSettings['github-creds'],
      'secret-token',
    );
  });

  test('exports with credentials keep per-app tokens', () async {
    final provider = await providerWithApp();
    addTearDown(provider.dispose);
    final settings = exportedSettings(
      provider.generateExportJSON(overrideExportSettings: 2),
    );
    expect(settings['github-creds'], 'secret-token');
  });
}
