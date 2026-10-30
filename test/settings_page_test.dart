import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/pages/settings_subpage.dart';
import 'package:obtainium/pages/onboarding.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Builds the full settings page for every section tab (issue #217): any
/// exception thrown while building a section would blank the whole page in
/// a release build, so this catches that class of regression in CI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  // Serve translations from memory: the rootBundle load is real async that
  // completes for the first test but hangs for later ones (static state in
  // EasyLocalization), so tabs 1+ never mounted with the default loader
  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<Widget> buildSettingsApp(
    int tab, {
    Locale locale = const Locale('en'),
    bool isTV = false,
    bool matchSystemMaterialStyle = false,
    Brightness brightness = Brightness.light,
    Widget? home,
  }) async {
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
      supportedLocales: [locale],
      startLocale: locale,
      path: 'assets/translations',
      fallbackLocale: locale,
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
            localizationsDelegates: appLocalizationsDelegates(
              context.localizationDelegates,
            ),
            supportedLocales: [locale],
            // Hardcode the locale so the test never picks up the CI machine's
            // platform locale, which may be 'C' (POSIX) and unsupported.
            locale: locale,
            // The production theme, so theme-level changes (M3E slider,
            // squircle shapes, TV focus) are exercised by these builds.
            theme: ThemeBuilder.buildTheme(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: brightness,
              ),
              useSystemFont: false,
              cornerRadius: plusSettings.plusGlobalCornerRadius,
              isTV: isTV,
              matchSystemMaterialStyle: matchSystemMaterialStyle,
            ),
            home: home ?? SettingsPage(initialTab: tab),
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
    // plusSettingsBottomNavBar defaults to true, which renders a NavigationBar
    // that requires MaterialLocalizations via _NavigationBarDestinationSemantics.
    // Tests focus on settings-section stability, not nav-bar behaviour, so
    // disable it here to keep the test harness simple.
    SharedPreferences.setMockInitialValues({'plusSettingsBottomNavBar': false});
    FlutterSecureStorage.setMockInitialValues({});
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
    testWidgets('settings section $tab builds without throwing', (
      tester,
    ) async {
      late Widget app;
      // Provider setup does real async work (platform channels, prefs) that
      // never completes inside the widget test's fake-async zone
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(tab);
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 1)));
  }

  // #336/#337: flex_color_picker's colour-code field (Appearance tab) is a
  // material_ui TextField, which needs material_ui's own MaterialLocalizations.
  // Only the en-only Default delegate was registered, so every other locale
  // crashed with a null check on opening settings.
  testWidgets('settings page builds in a non-English locale', (tester) async {
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(0, locale: const Locale('zh'));
    });
    await pumpCapturingErrors(tester, app);
    expect(find.byType(SettingsPage), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 1)));

  for (final variant in const [
    ('TV focus theme', true, false, Brightness.light),
    ('match-system theme', false, true, Brightness.light),
    ('dark theme', false, false, Brightness.dark),
  ]) {
    testWidgets('settings page builds with the ${variant.$1}', (tester) async {
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(
          1,
          isTV: variant.$2,
          matchSystemMaterialStyle: variant.$3,
          brightness: variant.$4,
        );
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 1)));
  }

  // #340: with the main bottom bar off, settings shows its own bottom bar
  // (plusSettingsBottomNavBar defaults to true); users got a black screen.
  for (final mainBar in [false, true]) {
    testWidgets('settings bottom bar builds (main bottom bar $mainBar)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'plusSettingsBottomNavBar': true,
        'plusEnableBottomNavBar': mainBar,
      });
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(0);
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 1)));
  }

  // First screen of every fresh install; restored after being unreachable
  // from May to October.
  // #330: three-button navigation covered Skip / dots / next.
  testWidgets('onboarding controls clear the system nav bar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48 * 2.75);
    tester.view.padding = const FakeViewPadding(bottom: 48 * 2.75);
    addTearDown(tester.view.reset);
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(0, home: OnboardingPage(onDone: () {}));
    });
    await tester.pumpWidget(app);
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.text('Skip'))) break;
    }
    await tester.pump(const Duration(seconds: 1));
    const screenHeight = 2340 / 2.75;
    expect(
      tester.getRect(find.text('Skip')).bottom,
      lessThanOrEqualTo(screenHeight - 48),
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('onboarding page builds', (tester) async {
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(0, home: OnboardingPage(onDone: () {}));
    });
    final errors = <FlutterErrorDetails>[];
    final base = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d);
      base?.call(d);
    };
    try {
      await tester.pumpWidget(app);
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (tester.any(find.byType(OnboardingPage))) break;
      }
      await tester.pump(const Duration(seconds: 1));
    } finally {
      FlutterError.onError = base;
    }
    for (final d in errors) {
      // ignore: avoid_print
      print('──── onboarding error ────\n$d');
    }
    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingPage), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('settings page survives corrupted preference types', (
    tester,
  ) async {
    // The issue #217 corruption class: keys stored with the wrong type
    // (JSON import) or stale enum indexes must not blank the page
    SharedPreferences.setMockInitialValues({
      'plusSettingsBottomNavBar':
          false, // keep nav bar hidden (see setUp comment)
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
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets(
    'settings page displays organized layout and Obtainium+ chip without banner clutter',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'plusSettingsBottomNavBar': false,
      });
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(0);
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);

      // Verify Obtainium+ action chip in app bar (the design-style
      // segmented button also reads "Obtainium+", so match the chip itself)
      expect(find.widgetWithText(ActionChip, 'Obtainium+'), findsOneWidget);

      // Verify no redundant uppercase or banner duplication
      expect(find.text('APPEARANCE'), findsNothing);
      expect(find.text('UPDATES & INSTALL'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  testWidgets(
    'tapping appearance submenu card opens SettingsSubpage with back navigation',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'plusSettingsBottomNavBar': false,
      });
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(0);
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);

      final cardFinder = find.text(
        translations['settingsAppearanceThemesAndColors'] as String,
      );
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsSubpage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsSubpage), findsNothing);
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
