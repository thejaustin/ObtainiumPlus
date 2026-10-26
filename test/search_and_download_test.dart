import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/components/search/command_center.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}

AppInMemory _createTestApp(
  String id,
  String name, {
  String url = 'https://github.com/example/app',
}) {
  return AppInMemory(
    App(
      id,
      url,
      'Author',
      name,
      '1.0.0',
      '1.0.0',
      [],
      0,
      {},
      null,
      false,
    ),
    null,
    null,
    null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  testWidgets('Omnibar renders and displays active downloads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(sp);
    plus.plusEnableEnhancedAnimations = false;
    final view = ViewSettingsProvider();
    await view.initializeSettings(sp);
    final apps = AppsProvider();

    const locale = Locale('en');

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [locale],
        startLocale: locale,
        path: 'assets/translations',
        fallbackLocale: locale,
        assetLoader: _MemoryAssetLoader(translations),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: plus),
            ChangeNotifierProvider.value(value: view),
            ChangeNotifierProvider.value(value: apps),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: appLocalizationsDelegates(
                context.localizationDelegates,
              ),
              supportedLocales: const [locale],
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Omnibar(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(Omnibar), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Simulate an active download in apps
    final appInMemory = _createTestApp('org.example.app', 'Example App');
    appInMemory.downloadProgress = 42.0;
    apps.apps['org.example.app'] = appInMemory;
    apps.notify();

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Clean up
    appInMemory.downloadProgress = null;
    apps.notify();
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('CommandCenter builds and shows results', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(sp);
    plus.plusEnableEnhancedAnimations = false;
    final view = ViewSettingsProvider();
    await view.initializeSettings(sp);
    final apps = AppsProvider();

    final appInMemory = _createTestApp(
      'org.example.testapp',
      'Test Application',
    );
    apps.apps['org.example.testapp'] = appInMemory;

    const locale = Locale('en');

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [locale],
        startLocale: locale,
        path: 'assets/translations',
        fallbackLocale: locale,
        assetLoader: _MemoryAssetLoader(translations),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: plus),
            ChangeNotifierProvider.value(value: view),
            ChangeNotifierProvider.value(value: apps),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: appLocalizationsDelegates(
                context.localizationDelegates,
              ),
              supportedLocales: const [locale],
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => CommandCenter.show(context),
                    child: const Text('open_command_center'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('open_command_center'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(CommandCenter), findsOneWidget);
  });
}
