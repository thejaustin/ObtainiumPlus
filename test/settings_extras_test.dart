import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/appearance_hub.dart';
import 'package:obtainium/components/settings/settings_page_section.dart';
import 'package:obtainium/components/settings/settings_search_jump.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/pages/settings_subpage.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/settings_route.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings page extras (all preview, all off by default): predictive back
/// routes, search jump and live hub summaries.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<PlusSettingsProvider> loadPlus() async {
    final prefs = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(prefs);
    return plus;
  }

  Future<Widget> buildApp(Widget home, {NavigatorObserver? observer}) async {
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
            navigatorObservers: [?observer],
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

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    NavigatorObserver? observer,
  }) async {
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildApp(home, observer: observer);
    });
    await tester.pumpWidget(app);
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byType(Scaffold))) break;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('keys', () {
    test('default off, and a type-flipped value falls back to off', () async {
      SharedPreferences.setMockInitialValues({});
      var p = await loadPlus();
      expect(p.plusSettingsPredictiveBack, isFalse);
      expect(p.plusSettingsSearchJump, isFalse);
      expect(p.plusSettingsLiveSummaries, isFalse);

      SharedPreferences.setMockInitialValues({
        'plusSettingsPredictiveBack': 'yes',
        'plusSettingsSearchJump': 3,
        'plusSettingsLiveSummaries': 1.5,
      });
      p = await loadPlus();
      expect(p.plusSettingsPredictiveBack, isFalse);
      expect(p.plusSettingsSearchJump, isFalse);
      expect(p.plusSettingsLiveSummaries, isFalse);
    });

    test('resetExpressiveKit turns them back off', () async {
      SharedPreferences.setMockInitialValues({
        'plusSettingsPredictiveBack': true,
        'plusSettingsSearchJump': true,
        'plusSettingsLiveSummaries': true,
      });
      final p = await loadPlus();
      expect(p.plusSettingsSearchJump, isTrue);
      p.resetExpressiveKit();
      expect(p.plusSettingsPredictiveBack, isFalse);
      expect(p.plusSettingsSearchJump, isFalse);
      expect(p.plusSettingsLiveSummaries, isFalse);
    });
  });

  group('predictive back route', () {
    Future<Route<dynamic>> pushSubpage(
      WidgetTester tester,
      Map<String, Object> prefs,
    ) async {
      SharedPreferences.setMockInitialValues(prefs);
      final observer = _RouteSpy();
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => pushRoute(
                context,
                const SettingsSubpage(title: 'Sub', child: Text('body')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        observer: observer,
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('body'), findsOneWidget);
      return observer.pushed.last;
    }

    testWidgets('off: subpages use the usual route', (tester) async {
      final route = await pushSubpage(tester, {});
      expect(route, isNot(isA<SettingsPageRoute>()));
    });

    testWidgets('on: subpages use the predictive-back route', (tester) async {
      final route = await pushSubpage(tester, {
        'plusSettingsPredictiveBack': true,
      });
      expect(route, isA<SettingsPageRoute>());
      // The button pop still works (shared axis).
      Navigator.of(tester.element(find.text('body'))).pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('body'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on: other pages keep the usual route', (tester) async {
      SharedPreferences.setMockInitialValues({
        'plusSettingsPredictiveBack': true,
      });
      final observer = _RouteSpy();
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => pushRoute(context, const Text('plain')),
              child: const Text('open'),
            ),
          ),
        ),
        observer: observer,
      );
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(seconds: 1));
      expect(observer.pushed.last, isNot(isA<SettingsPageRoute>()));
    });
  });

  group('live summaries', () {
    Future<void> pumpHub(WidgetTester tester, Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      await pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            child: AppearanceHub(
              androidInfoFuture: null,
              themeContent: SizedBox.shrink(),
              shapesContent: SizedBox.shrink(),
              motionContent: SizedBox.shrink(),
              settingsPageContent: SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    testWidgets('off: the short summaries stay', (tester) async {
      await pumpHub(tester, {});
      expect(find.textContaining('Haptics:'), findsNothing);
      expect(find.textContaining('Speed'), findsNothing);
      expect(find.textContaining('Corner:'), findsOneWidget);
    });

    testWidgets('on: cards show current values and follow changes', (
      tester,
    ) async {
      await pumpHub(tester, {'plusSettingsLiveSummaries': true});
      expect(find.textContaining('Haptics: standard'), findsOneWidget);
      expect(find.textContaining('Speed 1x'), findsOneWidget);
      expect(find.textContaining('Cards'), findsOneWidget);
      final plus = tester
          .element(find.byType(AppearanceHub))
          .read<PlusSettingsProvider>();
      plus.plusHapticIntensity = HapticIntensity.strong;
      plus.plusSettingsGroupStyle = SettingsGroupStyle.segmented;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Haptics: strong'), findsOneWidget);
      expect(find.textContaining('Segmented 16/4 dp'), findsOneWidget);
      plus.plusEnableEnhancedAnimations = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Animations off'), findsOneWidget);
    });
  });

  group('search jump', () {
    Widget list({required bool enabled, void Function(int, String)? onJump}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsSearchJumpLayer(
              enabled: enabled,
              onJump: onJump ?? (_, _) {},
              child: Column(
                children: [
                  for (var i = 0; i < 40; i++)
                    SettingsJumpSection(
                      index: i < 20 ? 1 : 3,
                      child: SwitchListTile(
                        title: Text('Row $i'),
                        subtitle: Text('About row $i'),
                        value: false,
                        onChanged: (_) => _taps.add('Row $i'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    setUp(_taps.clear);

    testWidgets('gated off: taps reach the rows', (tester) async {
      var jumps = 0;
      await tester.pumpWidget(list(enabled: false, onJump: (_, _) => jumps++));
      await tester.tap(find.text('Row 2'));
      expect(_taps, ['Row 2']);
      expect(jumps, 0);
    });

    testWidgets('on: a tap reports the row title and section', (tester) async {
      final jumps = <String>[];
      await tester.pumpWidget(
        list(enabled: true, onJump: (s, t) => jumps.add('$s:$t')),
      );
      await tester.tap(find.text('Row 2'));
      await tester.tap(find.text('About row 3'));
      expect(jumps, ['1:Row 2', '1:Row 3']);
      expect(_taps, isEmpty);
    });

    testWidgets('on: the list still scrolls', (tester) async {
      await tester.pumpWidget(list(enabled: true));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.pixels, greaterThan(0));
    });

    testWidgets('reveal scrolls the row into view and pulses a highlight', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final plus = await tester.runAsync(loadPlus) as PlusSettingsProvider;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(value: plus, child: list(enabled: false)),
      );
      final ctx = tester.element(find.byType(SingleChildScrollView));
      final row = findRowByTitle(ctx, 'Row 35')!;
      expect(row.widget, isA<ListTile>());
      unawaited(revealAndHighlightRow(ctx, row));
      bool pulse() => tester.any(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_RowPulse'),
      );
      // The highlight plays after the scroll.
      var seen = false;
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        seen = seen || pulse();
      }
      expect(seen, isTrue);
      final rect = tester.getRect(find.text('Row 35'));
      expect(rect.top, greaterThan(0));
      expect(rect.bottom, lessThan(600));
      await tester.pump(const Duration(seconds: 5));
      expect(pulse(), isFalse);
    });

    testWidgets(
      'settings page: tapping a result opens its section and pulses',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
          'plusSettingsSearchJump': true,
        });
        await pump(tester, const SettingsPage(initialTab: 0));
        await tester.enterText(find.byType(SearchBar), 'parallel downloads');
        await tester.pump(const Duration(milliseconds: 700));
        final title = translations['parallelDownloads'] as String;
        expect(find.text(title), findsOneWidget);
        await tester.tap(find.text(title), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        final field = tester.widget<SearchBar>(find.byType(SearchBar));
        expect(field.controller!.text, isEmpty);
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 4));
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets('settings page, gated off: a result still toggles', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
      });
      await pump(tester, const SettingsPage(initialTab: 0));
      await tester.enterText(find.byType(SearchBar), 'parallel downloads');
      await tester.pump(const Duration(milliseconds: 700));
      final title = translations['parallelDownloads'] as String;
      final ctx = tester.element(find.byType(SettingsPage));
      final before = ctx.read<BehaviorSettingsProvider>().parallelDownloads;
      await tester.tap(find.text(title));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        ctx.read<BehaviorSettingsProvider>().parallelDownloads,
        isNot(before),
      );
      // Still searching: the query was not cleared.
      expect(
        tester.widget<SearchBar>(find.byType(SearchBar)).controller!.text,
        'parallel downloads',
      );
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  testWidgets('Settings page lists the three previews, off', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pump(
      tester,
      const Scaffold(body: SingleChildScrollView(child: SettingsPageSection())),
    );
    for (final k in [
      'settingsPredictiveBack',
      'settingsSearchJump',
      'settingsLiveSummaries',
    ]) {
      final title = tr('previewSuffix', args: [tr(k)]);
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget, reason: k);
    }
  });
}

final List<String> _taps = [];

class _RouteSpy extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
