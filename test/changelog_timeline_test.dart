import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/changelog/changelog_timeline.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> _release(String tag, String date, String body) => {
  'tag_name': tag,
  'published_at': date,
  'draft': false,
  'prerelease': false,
  'body': body,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ChangelogTimeline.debugResetCache();
  });

  tearDown(() => ChangelogTimeline.debugFetchPage = null);

  Future<void> pumpTimeline(
    WidgetTester tester, {
    required String installed,
    String? since,
    Brightness brightness = Brightness.dark,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(prefs);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        assetLoader: _MemoryAssetLoader(translations),
        child: ChangeNotifierProvider.value(
          value: plus,
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: appLocalizationsDelegates(
                context.localizationDelegates,
              ),
              supportedLocales: const [Locale('en')],
              locale: const Locale('en'),
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: brightness,
                ),
              ),
              home: Scaffold(
                body: ChangelogTimeline(
                  installedVersion: installed,
                  sinceVersion: since,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (tester.any(find.byType(CustomScrollView))) break;
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('renders releases newest first with badges and filters', (
    tester,
  ) async {
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            // API order is by creation, not publish date.
            _release(
              'v1.7.1-p28',
              '2026-10-21T11:12:48Z',
              '### 🐛 Bug Fixes\n- fix(ui): stop cold-start flash (4496f27c)',
            ),
            _release(
              'v1.7.1-p29',
              '2026-10-21T20:46:29Z',
              '### ✨ New Features\n- feat: Hebrew for Obtainium+ (#339)',
            ),
            _release(
              'v1.7.1-p27',
              '2026-10-21T06:28:10Z',
              '**Full Changelog**: https://example.invalid/compare',
            ),
          ]
        : [];
    await pumpTimeline(tester, installed: '1.7.1-p29', since: '1.7.1-p27');

    expect(tester.takeException(), isNull);
    expect(find.text('v1.7.1-p29'), findsWidgets);
    expect(find.text('v1.7.1-p28'), findsOneWidget);
    // A release with nothing user-facing is hidden.
    expect(find.text('v1.7.1-p27'), findsNothing);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('2 new releases since you last looked'), findsOneWidget);

    // Newest first, regardless of API order.
    final p29 = tester.getTopLeft(find.text('v1.7.1-p29').last).dy;
    final p28 = tester.getTopLeft(find.text('v1.7.1-p28')).dy;
    expect(p29, lessThan(p28));

    await tester.tap(find.widgetWithText(FilterChip, 'Fixes'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('v1.7.1-p28'), findsOneWidget);
    expect(find.text('Hebrew for Obtainium+ (#339)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pre-releases are hidden until the chip is switched on', (
    tester,
  ) async {
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            _release(
              'v2.0.0',
              '2026-10-21T20:00:00Z',
              '### 🐛 Bug Fixes\n- fix: stable fix (1)',
            ),
            {
              ..._release(
                'dev-901',
                '2026-10-21T10:00:00Z',
                '### ✨ New Features\n- feat: nightly only thing (2)',
              ),
              'prerelease': true,
            },
          ]
        : [];
    await pumpTimeline(tester, installed: '2.0.0');
    expect(find.text('v2.0.0'), findsWidgets);
    expect(find.text('dev-901'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Pre-releases'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('dev-901'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('older releases collapse to kind chips and expand on tap', (
    tester,
  ) async {
    final bullets = List.generate(
      9,
      (i) => '- fix: issue number $i',
    ).join('\n');
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            _release('v2', '2026-10-21T00:00:00Z', '- feat: newest thing'),
            // Old enough to take the locale date-format path.
            _release('v1', '2025-06-15T12:00:00Z', bullets),
          ]
        : [];
    await pumpTimeline(tester, installed: '2', brightness: Brightness.light);

    expect(find.textContaining('2025'), findsOneWidget);
    // Latest is expanded, the older one is only a summary chip.
    expect(find.text('Newest thing'), findsOneWidget);
    expect(find.text('Issue number 0'), findsNothing);
    expect(find.text('9'), findsWidgets);
    await tester.tap(find.text('v1'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Issue number 0'), findsOneWidget);
    expect(find.text('Issue number 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sections follow the fixed order; rows expand on tap at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const longDesc =
        'a very long description that cannot possibly fit on a single line '
        'of a phone screen so it must be ellipsized until the row is tapped '
        'to reveal the remaining words';
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            _release(
              'v3',
              '2026-10-21T00:00:00Z',
              '### Bug Fixes\n- fix: a crash on launch\n'
                  '### New Features\n- **Shiny thing** — $longDesc (#12)\n'
                  '- feat: Plain entry. Second sentence here',
            ),
          ]
        : [];
    await pumpTimeline(tester, installed: '3');

    final feat = tester.getTopLeft(find.text('Features').last).dy;
    final fixes = tester.getTopLeft(find.text('Fixes').last).dy;
    expect(feat, lessThan(fixes));
    expect(find.text('Shiny thing'), findsOneWidget);
    expect(find.text('#12'), findsWidgets);
    // No-headline entry: first sentence leads.
    expect(find.text('Plain entry.'), findsOneWidget);

    final desc = find.textContaining('a very long description');
    final collapsedH = tester.getSize(desc).height;
    await tester.tap(find.text('Shiny thing'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(desc).height, greaterThan(collapsedH));
    expect(tester.takeException(), isNull);
  });

  test('headlineAndBody uses the first sentence when no title', () {
    expect(changelogHeadlineAndBody('Fixed it. More detail here.'), (
      'Fixed it.',
      'More detail here.',
    ));
    expect(changelogHeadlineAndBody('One liner'), ('One liner', ''));
    expect(changelogHeadlineAndBody('**T** — body'), ('T', 'body'));
  });

  testWidgets('when behind, newer releases are marked available', (
    tester,
  ) async {
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            _release('v1.7.1-p29', '2026-10-21T20:46:29Z', '- feat: newest'),
            _release('v1.7.1-p28', '2026-10-21T11:12:48Z', '- fix: middle'),
            _release('v1.7.1-p27', '2026-10-20T06:28:10Z', '- fix: mine'),
          ]
        : [];
    await pumpTimeline(tester, installed: '1.7.1-p27', since: '1.7.1-p27');

    expect(find.text('2 releases newer than yours'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Installed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day labels: today, yesterday, weekday, then a date', (
    tester,
  ) async {
    ChangelogTimeline.debugFetchPage = (_) async => [];
    await pumpTimeline(tester, installed: '1');
    final now = DateTime(2026, 10, 23, 0, 30); // Friday, just after midnight
    String label(DateTime d) => changelogDayLabel(d, now, 'en');
    expect(label(DateTime(2026, 10, 23, 0, 5)), 'Today');
    expect(label(DateTime(2026, 10, 22, 23, 55)), 'Yesterday');
    expect(label(DateTime(2026, 10, 19, 12)), 'Monday');
    expect(label(DateTime(2026, 10, 2, 12)), 'October 2');
    expect(label(DateTime(2025, 6, 15, 12)), 'June 15, 2025');
  });

  testWidgets('marks the boundary with "You are here" when behind', (
    tester,
  ) async {
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            _release('v3', '2026-10-21T20:00:00Z', '- feat: newest'),
            _release('v2', '2026-10-21T11:00:00Z', '- fix: mine'),
          ]
        : [];
    await pumpTimeline(tester, installed: '2');
    expect(find.text('You are here'), findsOneWidget);
    final here = tester.getTopLeft(find.text('You are here')).dy;
    expect(tester.getTopLeft(find.text('v3').last).dy, lessThan(here));
    expect(here, lessThan(tester.getTopLeft(find.text('v2').last).dy));
  });

  testWidgets('no marker when up to date', (tester) async {
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [_release('v3', '2026-10-21T20:00:00Z', '- feat: newest')]
        : [];
    await pumpTimeline(tester, installed: '3');
    expect(find.text('You are here'), findsNothing);
  });

  testWidgets('filter chips show counts, are remembered, empty state clears', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            _release(
              'v3',
              '2026-10-21T20:00:00Z',
              '- fix: one\n- fix: two\n- feat: shiny',
            ),
          ]
        : [];
    await pumpTimeline(tester, installed: '3');
    expect(
      find.descendant(
        of: find.widgetWithText(FilterChip, 'Fixes'),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Fixes'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilterChip, 'Fixes'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Shiny'), findsNothing);

    // Reopen within the session: the choice is remembered.
    await tester.pumpWidget(const SizedBox());
    await pumpTimeline(tester, installed: '3');
    expect(find.text('Shiny'), findsNothing);
    expect(find.text('One'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a skeleton while loading and a saved copy on failure', (
    tester,
  ) async {
    final gate = Completer<List<Object?>>();
    ChangelogTimeline.debugFetchPage = (_) => gate.future;
    final prefs = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(prefs);
    Widget app() => EasyLocalization(
      supportedLocales: const [Locale('en')],
      startLocale: const Locale('en'),
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: _MemoryAssetLoader(translations),
      child: ChangeNotifierProvider.value(
        value: plus,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: appLocalizationsDelegates(
              context.localizationDelegates,
            ),
            locale: const Locale('en'),
            supportedLocales: const [Locale('en')],
            home: const Scaffold(
              body: ChangelogTimeline(installedVersion: '1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    gate.complete([]);
    await tester.pump();
  });

  testWidgets('shows retry when the first page fails', (tester) async {
    ChangelogTimeline.debugFetchPage = (_) async => throw Exception('403');
    await tester.runAsync(() async {});
    final prefs = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(prefs);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        assetLoader: _MemoryAssetLoader(translations),
        child: ChangeNotifierProvider.value(
          value: plus,
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: appLocalizationsDelegates(
                context.localizationDelegates,
              ),
              locale: const Locale('en'),
              supportedLocales: const [Locale('en')],
              home: const Scaffold(
                body: ChangelogTimeline(installedVersion: '1'),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (tester.any(find.byIcon(Icons.cloud_off_rounded))) break;
    }
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
