import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/force_update_dialog.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/known_issues_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  const testIssue = KnownIssue(
    id: 'test_issue_1',
    title: 'Test Update Title',
    description: 'Test Update Description',
    severity: 'warning',
    affectedVersions: ['1.0.0'],
    githubIssueUrl: 'https://github.com/thejaustin/ObtainiumPlus/releases',
    fixedInVersion: '1.0.1',
    forceUpdate: true,
  );

  testWidgets('ForceUpdateDialog renders issue details and action buttons', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(sp);
    plus.plusEnableEnhancedAnimations = false;
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
            ChangeNotifierProvider.value(value: apps),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: appLocalizationsDelegates(
                context.localizationDelegates,
              ),
              supportedLocales: const [locale],
              home: const Scaffold(body: ForceUpdateDialog(issue: testIssue)),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Update Recommended'), findsOneWidget);
    expect(find.text('Fixed in 1.0.1'), findsOneWidget);
    expect(find.text('Test Update Title'), findsOneWidget);
    expect(find.text('Test Update Description'), findsOneWidget);
    expect(find.text("Don't show this again"), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);

    // Teardown
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('ForceUpdateDialog toggle dontShowAgain updates state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(sp);
    plus.plusEnableEnhancedAnimations = false;
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
            ChangeNotifierProvider.value(value: apps),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: appLocalizationsDelegates(
                context.localizationDelegates,
              ),
              supportedLocales: const [locale],
              home: const Scaffold(body: ForceUpdateDialog(issue: testIssue)),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

    await tester.tap(find.text("Don't show this again"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

    // Teardown
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 600));
  });
}
