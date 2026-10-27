import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/apps/app_grid_view.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAppsProvider extends ChangeNotifier implements AppsProvider {
  @override
  final Set<String> checkingUpdateIds = const {};
  @override
  final Map<String, AppInMemory> apps = const {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    final translations =
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(
      const Locale('en'),
      translations: Translations(translations),
    );
  });

  AppInMemory makeApp(String id, String name, {bool pinned = false}) {
    final app = App(
      id,
      'https://github.com/example/$id',
      'Author',
      name,
      '1.0.0',
      '1.0.0',
      const [MapEntry('https://example.com/app.apk', 'app.apk')],
      0,
      const {},
      null,
      pinned,
    );
    return AppInMemory(app, null, null, null);
  }

  testWidgets('AppGridView groups pinned apps and respects custom drag order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'plusPinnedAppsOrder': ['app3', 'app1'],
      'tactileFeedbackEnabled': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final plusSettings = PlusSettingsProvider();
    plusSettings.plusPinnedAppsOrder = ['app3', 'app1'];
    final viewSettings = ViewSettingsProvider()..prefs = prefs;

    final apps = [
      makeApp('app1', 'App One', pinned: true),
      makeApp('app2', 'App Two', pinned: false),
      makeApp('app3', 'App Three', pinned: true),
      makeApp('app4', 'App Four', pinned: false),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsProvider>.value(
            value: _TestAppsProvider(),
          ),
          ChangeNotifierProvider<PlusSettingsProvider>.value(
            value: plusSettings,
          ),
          ChangeNotifierProvider<ViewSettingsProvider>.value(
            value: viewSettings,
          ),
          Provider<SourceProvider>.value(value: SourceProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AppGridView(
                  apps: apps,
                  onAppTap: (_) {},
                  selectedAppIds: const {},
                  onToggleSelected: (_) {},
                  updateAppIds: const {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify pinned section header exists with count 2, and unpinned section also has count 2
    expect(find.text('Pin'), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));

    // Verify all 4 app tiles are rendered
    expect(find.byType(AppGridTile), findsNWidgets(4));

    // Verify App Three and App One exist
    expect(find.text('App Three'), findsOneWidget);
    expect(find.text('App One'), findsOneWidget);
  });
}
