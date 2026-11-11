import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/connected_settings_bar.dart';
import 'package:obtainium/components/settings/settings_category_bar_host.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/pages/visual_lab_page.dart';
import 'package:obtainium/services/settings_section_controller.dart';
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
    Map<String, dynamic>? translationsOverride,
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
      assetLoader: _MemoryAssetLoader(translationsOverride ?? translations),
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
    // The category bar defaults to the bottom placement, which renders a
    // NavigationBar; tests focus on settings-section stability, so pin the
    // top chips (the tab-switch test taps them).
    SharedPreferences.setMockInitialValues({
      'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
    });
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

  // Phone width with enlarged text: the default 800x600 view hid overflowing
  // app-bar actions and tile rows that real devices show as clipped text.
  for (var tab = 0; tab <= 8; tab++) {
    testWidgets('settings section $tab fits a 360dp phone at 1.3x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(tab);
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 1)));
  }

  // Red error cards on device (1.7.3-p15): after scrolling one tab, switching
  // tabs threw "type 'double' is not a subtype of type 'bool?'" in
  // Expansible.initState — expansion tiles keyed with plain ValueKeys shared
  // the settings scroll view's PageStorage slot and read its scroll offset.
  testWidgets('switching tabs after scrolling keeps expansion state intact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(0);
    });
    final errors = <FlutterErrorDetails>[];
    final baseHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await tester.pumpWidget(app);
      await pumpUntilMounted(tester);
      for (final tabKey in [
        'settingsTabUpdatesInstall',
        'settingsTabNotifications',
        'settingsTabBehavior',
        'settingsTabAdvancedDebug',
      ]) {
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -400),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final chip = find.widgetWithText(
          ChoiceChip,
          translations[tabKey] as String,
        );
        await tester.ensureVisible(chip);
        await tester.tap(chip, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }
    } finally {
      FlutterError.onError = baseHandler;
    }
    final typeErrors = errors
        .where((d) => d.exception.toString().contains("'bool?'"))
        .toList();
    for (final d in typeErrors) {
      // ignore: avoid_print
      print('──── captured error detail ────\n$d');
    }
    expect(typeErrors, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 1)));

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
  // (the bottom placement is the default); users got a black screen.
  // Seeds only the pre-Visual-Lab bool, so this also covers its migration.
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
      // keep the top chips (see setUp comment)
      'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
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
        'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
      });
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(0);
      });
      await pumpCapturingErrors(tester, app);
      expect(find.byType(SettingsPage), findsOneWidget);

      // Obtainium+ features entry in the app bar (an icon button since the
      // labelled chips overflowed phone widths)
      expect(find.byTooltip('Obtainium+'), findsOneWidget);

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
        'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
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

  // ── Visual Lab ──────────────────────────────────────────────────────────

  test(
    'nav placement migrates from the old bool and survives type flips',
    () async {
      for (final c in <(Map<String, Object>, SettingsNavPlacement)>[
        (<String, Object>{}, SettingsNavPlacement.bottom),
        ({'plusSettingsBottomNavBar': true}, SettingsNavPlacement.bottom),
        ({'plusSettingsBottomNavBar': false}, SettingsNavPlacement.top),
        // New key wins over the old one
        (
          {
            'plusSettingsBottomNavBar': false,
            'plusSettingsNavPlacement': SettingsNavPlacement.merged.index,
          },
          SettingsNavPlacement.merged,
        ),
        // Out-of-range / type-flipped new key falls back to migration
        (
          {'plusSettingsBottomNavBar': false, 'plusSettingsNavPlacement': 9},
          SettingsNavPlacement.top,
        ),
        ({'plusSettingsNavPlacement': 'merged'}, SettingsNavPlacement.bottom),
      ]) {
        SharedPreferences.setMockInitialValues(c.$1);
        final prefs = await SharedPreferences.getInstance();
        final plus = PlusSettingsProvider();
        await plus.initializeSettings(prefs);
        expect(plus.plusSettingsNavPlacement, c.$2, reason: '${c.$1}');
      }
      // Reset writes explicit defaults (not removal, which would re-migrate)
      SharedPreferences.setMockInitialValues({
        'plusSettingsBottomNavBar': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final plus = PlusSettingsProvider();
      await plus.initializeSettings(prefs);
      plus.plusLabCompactDescriptionLines = 3;
      plus.resetVisualLab();
      expect(plus.plusSettingsNavPlacement, SettingsNavPlacement.bottom);
      expect(plus.plusLabCompactDescriptionLines, 2);
      expect(prefs.getInt('plusSettingsNavPlacement'), 0);
    },
  );

  // Every non-default Visual Lab value on a 360dp phone at 1.3x text
  // (the labelled-chip actions overflowed here by 146px before p15).
  for (final variant in <(String, Map<String, Object>)>[
    (
      'placement bottom',
      {'plusSettingsNavPlacement': SettingsNavPlacement.bottom.index},
    ),
    (
      'placement merged (standalone falls back)',
      {'plusSettingsNavPlacement': SettingsNavPlacement.merged.index},
    ),
    (
      'placement merged without main bar',
      {
        'plusSettingsNavPlacement': SettingsNavPlacement.merged.index,
        'plusEnableBottomNavBar': false,
      },
    ),
    (
      'labelled chip actions',
      {
        'plusLabSettingsAppBarActions':
            SettingsAppBarActionsStyle.labelledChips.index,
      },
    ),
    ('hero hidden', {'plusLabShowSettingsHero': false}),
    ('hero topic chips hidden', {'plusLabShowHeroTopicChips': false}),
    (
      'compact header',
      {'plusLabSettingsHeaderSize': SettingsHeaderSize.compact.index},
    ),
    (
      'compact header without one-handed mode',
      {
        'plusLabSettingsHeaderSize': SettingsHeaderSize.compact.index,
        'plusEnableOneHandedMode': false,
      },
    ),
    (
      'description lines 1 (compact)',
      {'plusLabCompactDescriptionLines': 1, 'plusUseCompactSettings': true},
    ),
    (
      'description lines 3 (compact)',
      {'plusLabCompactDescriptionLines': 3, 'plusUseCompactSettings': true},
    ),
    ('blur off', {'plusLabNavBarBlur': NavBarBlurStrength.off.index}),
    ('blur soft', {'plusLabNavBarBlur': NavBarBlurStrength.soft.index}),
    (
      'plus entry jump',
      {'plusLabPlusFeaturesEntry': PlusFeaturesEntry.jumpToSection.index},
    ),
  ]) {
    for (final tab in [0, 6]) {
      testWidgets('visual lab "${variant.$1}" fits 360dp (tab $tab)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({
          'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
          ...variant.$2,
        });
        late Widget app;
        await tester.runAsync(() async {
          await EasyLocalization.ensureInitialized();
          app = await buildSettingsApp(tab);
        });
        await pumpCapturingErrors(tester, app);
        expect(find.byType(SettingsPage), findsOneWidget);
      }, timeout: const Timeout(Duration(minutes: 1)));
    }
  }

  // Device run: searching "dev" showed no Developer & Diagnostics link, and
  // typing then clearing the search threw (TextStyle lerp / dependents).
  testWidgets('searching settings finds page links without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(0);
    });
    final errors = <FlutterErrorDetails>[];
    final baseHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      await tester.pumpWidget(app);
      await pumpUntilMounted(tester);
      await tester.tap(find.byType(SearchBar));
      await tester.pump();
      for (final text in ['d', 'de', 'dev']) {
        await tester.enterText(find.byType(SearchBar), text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 600));
      final link = find.descendant(
        of: find.byType(ConnectedSettingsBar),
        matching: find.text(translations['developerAndDiagnostics'] as String),
      );
      expect(link, findsOneWidget);
      // Visible without scrolling (it used to sit below every result).
      expect(tester.getRect(link).top, lessThan(860));
      await tester.enterText(find.byType(SearchBar), '');
      await tester.pump(const Duration(milliseconds: 600));
    } finally {
      FlutterError.onError = baseHandler;
    }
    for (final d in errors) {
      // ignore: avoid_print
      print('──── captured error detail ────\n${d.exceptionAsString()}');
    }
    expect(errors, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('Obtainium+ jump entry opens the Advanced tab', (tester) async {
    SharedPreferences.setMockInitialValues({
      'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
      'plusLabPlusFeaturesEntry': PlusFeaturesEntry.jumpToSection.index,
    });
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(0);
    });
    await pumpCapturingErrors(tester, app);
    await tester.tap(find.byTooltip('Obtainium+'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(
      find.text(translations['settingsTabAdvancedDebugDesc'] as String),
      findsWidgets,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('Visual Lab page builds, switches and resets at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(0, home: const VisualLabPage());
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
        if (tester.any(find.byType(VisualLabPage))) break;
      }
      await tester.pump(const Duration(milliseconds: 500));
      final merged = find.widgetWithText(
        ChoiceChip,
        translations['visualLabMerged'] as String,
      );
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -250),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(merged);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        Provider.of<PlusSettingsProvider>(
          tester.element(find.byType(VisualLabPage)),
          listen: false,
        ).plusSettingsNavPlacement,
        SettingsNavPlacement.merged,
      );
      final reset = find.byTooltip(translations['visualLabResetAll'] as String);
      await tester.tap(reset);
      await tester.pump(const Duration(milliseconds: 300));
    } finally {
      FlutterError.onError = base;
    }
    for (final d in errors) {
      // ignore: avoid_print
      print('──── visual lab error ────\n$d');
    }
    expect(tester.takeException(), isNull);
    expect(errors, isEmpty);
    final ctx = tester.element(find.byType(VisualLabPage));
    expect(
      Provider.of<PlusSettingsProvider>(
        ctx,
        listen: false,
      ).plusSettingsNavPlacement,
      SettingsNavPlacement.bottom,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  // Merged / hosted-bottom placements: a minimal stand-in for the home
  // scaffold (extendBody + bottom bar hosting the category row above a
  // NavigationBar) around the home-tab SettingsPage.
  for (final separate in [false, true]) {
    final mode = separate ? 'bottom (hosted)' : 'merged';
    testWidgets('$mode category bar drives the settings tab at 360dp', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'plusSettingsNavPlacement': separate
            ? SettingsNavPlacement.bottom.index
            : SettingsNavPlacement.merged.index,
        'plusEnableBottomNavBar': true,
      });
      final controller = SettingsSectionController();
      addTearDown(controller.dispose);
      late Widget app;
      await tester.runAsync(() async {
        await EasyLocalization.ensureInitialized();
        app = await buildSettingsApp(
          0,
          home: Scaffold(
            extendBody: true,
            body: SettingsPage(sectionController: controller),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (separate)
                      SettingsCategoryBarHost(
                        controller: controller,
                        show: true,
                        separate: true,
                      ),
                    Material(
                      key: const ValueKey('main_bar_surface'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!separate)
                            SettingsCategoryBarHost(
                              controller: controller,
                              show: true,
                              separate: false,
                            ),
                          NavigationBar(
                            selectedIndex: 1,
                            destinations: const [
                              NavigationDestination(
                                icon: Icon(Icons.apps),
                                label: 'Apps',
                              ),
                              NavigationDestination(
                                icon: Icon(Icons.settings),
                                label: 'Settings',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
      await pumpCapturingErrors(tester, app);
      // Only the hosted bar: the page hides its own dock/chips/NavigationBar
      expect(find.byType(SettingsSectionDock), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);

      final dockRect = tester.getRect(find.byType(SettingsSectionDock));
      final barRect = tester.getRect(find.byType(NavigationBar));
      expect(dockRect.bottom, lessThanOrEqualTo(barRect.top + 0.5));
      if (separate) {
        expect(barRect.top - dockRect.bottom, closeTo(kSettingsDockGap, 0.5));
      }

      // Switch category from the hosted bar
      final errors = <FlutterErrorDetails>[];
      final base = FlutterError.onError;
      FlutterError.onError = (d) {
        errors.add(d);
        base?.call(d);
      };
      try {
        await tester.tap(
          find.descendant(
            of: find.byType(SettingsSectionDock),
            matching: find.byTooltip(translations['notifications'] as String),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(controller.section.value, 2);
        expect(
          find.text(translations['settingsTabNotificationsDesc'] as String),
          findsWidgets,
        );

        // Content clears both bars: the page's bottom inset (which its
        // trailing spacer adds) spans the hosted row and the main bar.
        final pageInset = MediaQuery.paddingOf(
          tester.element(find.byType(CustomScrollView).first),
        ).bottom;
        expect(pageInset, greaterThanOrEqualTo(780 - dockRect.top - 0.5));
      } finally {
        FlutterError.onError = base;
      }
      for (final d in errors) {
        // ignore: avoid_print
        print('──── merged bar error ────\n$d');
      }
      expect(tester.takeException(), isNull);
      expect(errors, isEmpty);
    }, timeout: const Timeout(Duration(minutes: 1)));
  }
  // Search must work in the user's language: the German title below is
  // translated in de.json, and the English description only exists as the
  // row's subtitle.
  Map<String, dynamic> localeWithFallback(String name) => {
    ...translations,
    ...(jsonDecode(File('assets/translations/$name.json').readAsStringSync())
        as Map<String, dynamic>),
  };

  // The full page crossfades tab -> results with a shared GlobalKey, which
  // trips a duplicate-key assertion in tests, so search is exercised on the
  // section widget directly (this is the code path the page delegates to).
  Future<void> searchFor(
    WidgetTester tester,
    String query, {
    Locale locale = const Locale('en'),
    Map<String, dynamic>? translationsOverride,
  }) async {
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildSettingsApp(
        0,
        locale: locale,
        translationsOverride: translationsOverride,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppsViewSettingsSection(
              onSetState: (fn) => fn(),
              searchQuery: query,
            ),
          ),
        ),
      );
    });
    await tester.pumpWidget(app);
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byType(AppsViewSettingsSection))) break;
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  }

  testWidgets('search finds a row by its translated title in German', (
    tester,
  ) async {
    final de = localeWithFallback('de');
    final title = de['groupByCategory'] as String;
    expect(title, isNot(translations['groupByCategory']));
    await searchFor(
      tester,
      title,
      locale: const Locale('de'),
      translationsOverride: de,
    );
    expect(find.text(title), findsWidgets);
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('search matches a row by its description text', (tester) async {
    final description = translations['buryNonInstalledDescription'] as String;
    final title = translations['buryNonInstalled'] as String;
    final needle = description.substring(1, description.length - 1);
    expect(title.toLowerCase(), isNot(contains(needle.toLowerCase())));
    await searchFor(tester, needle);
    expect(find.text(title), findsWidgets);
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('search matches translated keyword needles', (tester) async {
    final de = {
      ...localeWithFallback('de'),
      'searchKeywordDefaultAppDetailsTab': 'standardreiter',
    };
    await searchFor(
      tester,
      'standardreiter',
      locale: const Locale('de'),
      translationsOverride: de,
    );
    expect(find.byType(SegmentedButton<AppDescriptionStyle>), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 1)));
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
