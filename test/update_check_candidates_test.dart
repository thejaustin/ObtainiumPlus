import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

App _app(
  String id, {
  bool disabled = false,
  List<String> categories = const [],
  DateTime? lastUpdateCheck,
}) => App(
  id,
  'https://github.com/example/$id',
  'Author',
  id,
  '1.0',
  '1.0',
  const [],
  0,
  const {},
  lastUpdateCheck,
  false,
  disabled: disabled,
  categories: categories,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('batch check candidates skip disabled apps and excluded categories, '
      'oldest check first', () async {
    SharedPreferences.setMockInitialValues({
      'categoriesExcludedFromChecks': jsonEncode(['Ignored']),
    });
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final provider = AppsProvider(isBg: true, settingsProvider: settings);
    addTearDown(provider.dispose);

    final now = DateTime(2026, 10, 29);
    for (final app in [
      _app('recent', lastUpdateCheck: now),
      _app('never'),
      _app('old', lastUpdateCheck: now.subtract(const Duration(days: 2))),
      _app('off', disabled: true),
      _app('excluded', categories: ['Ignored', 'Other']),
      _app('otherCategory', categories: ['Other'], lastUpdateCheck: now),
    ]) {
      provider.apps[app.id] = AppInMemory(app, null, null, null);
    }

    final ids = provider.getAppsSortedByUpdateCheckTime();
    expect(ids.toSet(), {'recent', 'never', 'old', 'otherCategory'});
    expect(ids.take(2), ['never', 'old']);
  });
}
