import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/common/contextual_tip.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tips = [
  TipSpec(id: 'a', title: 'First tip', message: 'one'),
  TipSpec(id: 'b', title: 'Second tip', message: 'two'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<SettingsProvider> pump(
    WidgetTester tester,
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    late SettingsProvider settings;
    late PlusSettingsProvider plus;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      settings = SettingsProvider();
      settings.prefs = prefs;
      plus = PlusSettingsProvider();
      await plus.initializeSettings(prefs);
    });
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        assetLoader: _MemoryAssetLoader(translations),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: plus),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ContextualTip(tips: _tips)),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    return settings;
  }

  testWidgets('hidden while tips are off', (tester) async {
    await pump(tester, {});
    expect(find.text('First tip'), findsNothing);
  });

  testWidgets('shows one tip at a time and remembers dismissals', (
    tester,
  ) async {
    final settings = await pump(tester, {'enableContextualTips': true});
    expect(find.text('First tip'), findsOneWidget);
    expect(find.text('Second tip'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('First tip'), findsNothing);
    expect(find.text('Second tip'), findsOneWidget);
    expect(settings.dismissedTips, ['a']);

    settings.resetTips();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('First tip'), findsOneWidget);
  });
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
