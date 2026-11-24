import 'dart:typed_data';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/apps/app_grid_view.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAppsProvider extends ChangeNotifier implements AppsProvider {
  _TestAppsProvider({this.liveByApp = const {}});

  /// What the per-tile icon notifiers hold, by app id.
  final Map<String, AppInMemory?> liveByApp;

  @override
  final Set<String> checkingUpdateIds = const {};
  @override
  final Map<String, AppInMemory> apps = const {};
  @override
  ValueListenable<AppInMemory?> iconListenable(String appId) =>
      ValueNotifier<AppInMemory?>(liveByApp[appId] ?? apps[appId]);
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

    // Verify Reorder button exists for pinned section with > 1 pinned apps
    expect(find.text('Reorder'), findsOneWidget);

    // Tap Reorder button to enter reorder mode
    await tester.tap(find.text('Reorder'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify button switches to "Done"
    expect(find.text('Done'), findsOneWidget);

    // Tap Done to exit reorder mode
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify button switches back to "Reorder"
    expect(find.text('Reorder'), findsOneWidget);

    // Verify author display when enabled
    viewSettings.displayShowAuthor = true;
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
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Author'), findsWidgets);
  });

  // 1x1 transparent PNG
  final png = Uint8List.fromList(const [
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1f,
    0x15,
    0xc4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0d,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9c,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0d,
    0x0a,
    0x2d,
    0xb4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4e,
    0x44,
    0xae,
    0x42,
    0x60,
    0x82,
  ]);

  Future<void> pumpTile(
    WidgetTester tester,
    AppInMemory shown,
    AppInMemory? live,
  ) async {
    SharedPreferences.setMockInitialValues({'tactileFeedbackEnabled': false});
    final prefs = await SharedPreferences.getInstance();
    final viewSettings = ViewSettingsProvider()..prefs = prefs;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsProvider>.value(
            value: _TestAppsProvider(liveByApp: {shown.app.id: live}),
          ),
          ChangeNotifierProvider<PlusSettingsProvider>.value(
            value: PlusSettingsProvider(),
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
                  apps: [shown],
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
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('tile shows an icon that only the notifier has', (tester) async {
    final shown = makeApp('a', 'App A');
    await pumpTile(tester, shown, shown.copyWith(icon: png));
    expect(
      find.descendant(
        of: find.byType(AppGridTile),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tile keeps its own icon when the notifier snapshot is stale', (
    tester,
  ) async {
    final stale = makeApp('a', 'App A');
    await pumpTile(tester, stale.copyWith(icon: png), stale);
    expect(
      find.descendant(
        of: find.byType(AppGridTile),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });
}
