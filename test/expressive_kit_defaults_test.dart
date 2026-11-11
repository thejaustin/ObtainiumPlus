import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/common/morph_switch.dart';
import 'package:obtainium/components/settings/connected_choice_group.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/motion_controls_card.dart';
import 'package:obtainium/components/settings/motion_haptics_section.dart';
import 'package:obtainium/components/settings/settings_page_section.dart';
import 'package:obtainium/components/settings/settings_row.dart';
import 'package:obtainium/components/settings/settings_section.dart';
import 'package:obtainium/components/settings/spring_expandable.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// With default prefs the settings page must render exactly the widget
/// types it did before the expressive kit (no kit widgets; SDK Switch,
/// SwitchListTile and ExpansionTile still used). With every kit option on,
/// every tab must still build.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<Widget> buildApp(Widget home) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(prefs);
    final theme = ThemeSettingsProvider();
    await theme.initializeSettings(prefs);
    final behavior = BehaviorSettingsProvider();
    await behavior.initializeSettings(prefs);
    final view = ViewSettingsProvider();
    await view.initializeSettings(prefs);
    final update = UpdateSettingsProvider();
    await update.initializeSettings(prefs);
    const locale = Locale('en');
    return EasyLocalization(
      supportedLocales: const [locale],
      startLocale: locale,
      path: 'assets/translations',
      fallbackLocale: locale,
      assetLoader: _MemoryAssetLoader(translations),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: plus),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: behavior),
          ChangeNotifierProvider.value(value: view),
          ChangeNotifierProvider.value(value: update),
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
            supportedLocales: const [locale],
            locale: locale,
            theme: ThemeBuilder.buildTheme(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useSystemFont: false,
              cornerRadius: plus.plusGlobalCornerRadius,
            ),
            home: home,
          ),
        ),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester, Widget home, Type mounted) async {
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildApp(home);
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
        if (tester.any(find.byType(mounted))) break;
      }
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    } finally {
      FlutterError.onError = base;
    }
    final exception = tester.takeException();
    if (exception != null) {
      for (final d in errors) {
        // ignore: avoid_print
        print('──── captured error detail ────\n$d');
      }
    }
    expect(exception, isNull);
    expect(find.byType(mounted), findsOneWidget);
  }

  // The kit options' home: Look & motion → Motion & haptics and Settings
  // page (both subpages, so not on the tab bodies checked below).
  const kitPages = Scaffold(
    body: SingleChildScrollView(
      child: Column(children: [MotionHapticsSection(), SettingsPageSection()]),
    ),
  );

  const kitTypes = <Type>[
    MorphSwitch,
    ToggleIconBadge,
    SettingsRow,
    PressMorphSurface,
    SettingsSection,
    SegmentedSettingsGroup,
    SpringExpandable,
    ConnectedChoiceGroup,
    MotionControlsCard,
  ];

  final seenDefault = <Type>{};
  final seenKit = <Type>{};

  tearDown(AppHaptics.resetPreviewOptions);

  group('default prefs', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
      });
    });

    for (var tab = 0; tab <= 8; tab++) {
      testWidgets('tab $tab renders no kit widgets', (tester) async {
        await pumpPage(tester, SettingsPage(initialTab: tab), SettingsPage);
        for (final t in kitTypes) {
          expect(find.byType(t), findsNothing, reason: '$t on tab $tab');
        }
        for (final t in const [Switch, SwitchListTile, ExpansionTile, Card]) {
          if (tester.any(find.byType(t))) seenDefault.add(t);
        }
      }, timeout: const Timeout(Duration(minutes: 1)));
    }

    test('SDK Switch, SwitchListTile, ExpansionTile and Card still used', () {
      expect(
        seenDefault,
        containsAll(const [Switch, SwitchListTile, ExpansionTile, Card]),
      );
    });
  });

  group('every kit option on', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
        'plusSettingsGroupStyle': SettingsGroupStyle.segmented.index,
        'plusSwitchStyle': SettingsSwitchStyle.shapeThumb.index,
        'plusIconMorphOnToggle': true,
        'plusIconMorphShape': IconMorphShape.cookie.index,
        'plusIconMorphStyle': IconMorphStyle.spin.index,
        'plusHapticIntensity': HapticIntensity.strong.index,
      });
    });

    for (var tab = 0; tab <= 8; tab++) {
      testWidgets('tab $tab builds', (tester) async {
        await pumpPage(tester, SettingsPage(initialTab: tab), SettingsPage);
        // Every card group switched to the segmented style.
        expect(
          find.byType(SegmentedSettingsGroup).evaluate().length,
          find.byType(ExpressiveSettingsGroup).evaluate().length,
        );
        for (final t in const [SegmentedSettingsGroup, MorphSwitch]) {
          if (tester.any(find.byType(t))) seenKit.add(t);
        }
      }, timeout: const Timeout(Duration(minutes: 1)));
    }

    test('the kit actually rendered on the settings tabs', () {
      expect(seenKit, containsAll(const [SegmentedSettingsGroup, MorphSwitch]));
    });

    testWidgets('Motion & haptics shows the kit options', (tester) async {
      await pumpPage(tester, kitPages, MotionHapticsSection);
      expect(find.byType(MotionControlsCard), findsOneWidget);
      expect(find.byType(MorphSwitch), findsWidgets);
    });
  });

  testWidgets('Motion & haptics at defaults builds with the kit entries', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester, kitPages, MotionHapticsSection);
    expect(find.byType(MotionControlsCard), findsOneWidget);
  });

  testWidgets('kit options switched at runtime, then reset to today\'s look', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester, kitPages, MotionHapticsSection);
    final plus = tester
        .element(find.byType(MotionHapticsSection))
        .read<PlusSettingsProvider>();
    expect(find.byType(SegmentedSettingsGroup), findsNothing);

    final base = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = (d) {
      errors.add(d);
      base?.call(d);
    };
    try {
      plus.plusSettingsGroupStyle = SettingsGroupStyle.segmented;
      plus.plusSwitchStyle = SettingsSwitchStyle.shapeThumb;
      plus.plusIconMorphOnToggle = true;
      plus.plusHapticIntensity = HapticIntensity.strong;
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SegmentedSettingsGroup), findsWidgets);
      expect(find.byType(MorphSwitch), findsWidgets);

      plus.plusSwitchStyle = SettingsSwitchStyle.iconSwitch;
      plus.plusSettingsGroupOuterRadius = 4;
      await tester.pump(const Duration(milliseconds: 600));

      plus.resetExpressiveKit();
      await tester.pump(const Duration(milliseconds: 600));
    } finally {
      FlutterError.onError = base;
    }
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    // Back to today's look; only the Motion card's own preview remains.
    expect(find.byType(SegmentedSettingsGroup), findsNothing);
    expect(find.byType(Card), findsWidgets);
    expect(
      find
          .descendant(
            of: find.byType(ExpressiveSettingsGroup),
            matching: find.byType(MorphSwitch),
          )
          .evaluate()
          .length,
      find
          .descendant(
            of: find.byType(MotionControlsCard),
            matching: find.byType(MorphSwitch),
          )
          .evaluate()
          .length,
    );
    expect(find.byType(SwitchListTile), findsWidgets);
  });
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
