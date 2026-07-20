import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the full settings page for every section tab (issue #217): any
/// exception thrown while building a section would blank the whole page in
/// a release build, so this catches that class of regression in CI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Serve translations from memory: the rootBundle load is real async that
  // completes for the first test but hangs for later ones (static state in
  // EasyLocalization), so tabs 1+ never mounted with the default loader
  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<Widget> buildSettingsApp(int tab) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final plusSettings = PlusSettingsProvider();
    await plusSettings.initializeSettings(prefs);
    final themeSettings = ThemeSettingsProvider();
    await themeSettings.initializeSettings(prefs);
    final behaviorSettings = BehaviorSettingsProvider();
    await behaviorSettings.initializeSettings(prefs);
    final viewSettings = ViewSettingsProvider();
    await viewSettings.initializeSettings(prefs);
    final updateSettings = UpdateSettingsProvider();
    await updateSettings.initializeSettings(prefs);

    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: _MemoryAssetLoader(translations),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: plusSettings),
          ChangeNotifierProvider.value(value: themeSettings),
          ChangeNotifierProvider.value(value: behaviorSettings),
          ChangeNotifierProvider.value(value: viewSettings),
          ChangeNotifierProvider.value(value: updateSettings),
          // Lazy: only read on user actions, never during build — the real
          // constructor touches platform channels unavailable in tests
          ChangeNotifierProvider<AppsProvider>(
            create: (_) => AppsProvider(),
            lazy: true,
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: SettingsPage(initialTab: tab),
          ),
        ),
      ),
    );
  }

  /// EasyLocalization renders empty until its translation asset loads via
  /// real async, so alternate real-async waits with frames until the page
  /// mounts, then let the section entry animations play out.
  Future<void> pumpUntilMounted(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byType(SettingsPage))) break;
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // takeException only keeps the bare exception object; capture the full
  // details (error-causing widget + source location) so CI failures are
  // actionable. Must be installed inside the test body — the binding
  // replaces FlutterError.onError after setUp — and restored before the
  // binding's post-test check.
  Future<void> pumpCapturingErrors(WidgetTester tester, Widget app) async {
    final errorDetails = <FlutterErrorDetails>[];
    final baseHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errorDetails.add(details);
      baseHandler?.call(details);
    };
    try {
      await tester.pumpWidget(app);
      await pumpUntilMounted(tester);
    } finally {
      FlutterError.onError = baseHandler;
    }
    final exception = tester.takeException();
    if (exception != null) {
      for (final d in errorDetails) {
        // ignore: avoid_print
        print('──── captured error detail ────\n$d');
      }
    }
    expect(exception, isNull);
  }

  for (var tab = 0; tab <= 8; tab++) {
    testWidgets(
      'settings section $tab builds without throwing',
      (tester) async {
        late Widget app;
        // Provider setup does real async work (platform channels, prefs) that
        // never completes inside the widget test's fake-async zone
        await tester.runAsync(() async {
          await EasyLocalization.ensureInitialized();
          app = await buildSettingsApp(tab);
        });
        await pumpCapturingErrors(tester, app);
        expect(find.byType(SettingsPage), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  }

  testWidgets(
    'settings page survives corrupted preference types',
    (tester) async {
      // The issue #217 corruption class: keys stored with the wrong type
      // (JSON import) or stale enum indexes must not blank the page
      SharedPreferences.setMockInitialValues({
        'plusSettingsCornerRadius': 16, // int where double expected
        'plusGlobalCornerRadius': 'oops', // string where double expected
        'theme': 99, // out-of-range enum index
        'themeVariant': -1, // negative enum index
        'plusEnableGlassmorphism': 'true', // string where bool expected
        'updateIntervalSliderVal': 9999.0, // beyond slider max
      });
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(0);
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
