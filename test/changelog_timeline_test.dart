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

  testWidgets('long releases start collapsed and expand on tap', (
    tester,
  ) async {
    final bullets = List.generate(
      9,
      (i) => '- fix: issue number $i',
    ).join('\n');
    ChangelogTimeline.debugFetchPage = (page) async => page == 1
        ? [
            _release('v2', '2026-10-21T00:00:00Z', '- feat: newest thing'),
            _release('v1', '2026-10-20T00:00:00Z', bullets),
          ]
        : [];
    await pumpTimeline(tester, installed: '2', brightness: Brightness.light);

    expect(find.text('Issue number 0'), findsOneWidget);
    expect(find.text('Issue number 8'), findsNothing);
    await tester.tap(find.text('Show 6 more'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Issue number 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
