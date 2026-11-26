import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/selection_modal.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<List<String>?> openModal(
    WidgetTester tester, {
    required bool pickSources,
    required Future<void> Function() act,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(await SharedPreferences.getInstance());
    List<String>? result;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        assetLoader: _MemoryAssetLoader(translations),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: plus),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: appLocalizationsDelegates(
                context.localizationDelegates,
              ),
              locale: const Locale('en'),
              supportedLocales: const [Locale('en')],
              home: Builder(
                builder: (ctx) => Scaffold(
                  body: TextButton(
                    onPressed: () async => result = await showDialog(
                      context: ctx,
                      builder: (_) => SelectionModal(
                        entries: {
                          'https://a.example': ['A'],
                        },
                        selectedByDefault: false,
                        onlyOneSelectionAllowed: true,
                        showPickDifferentSources: pickSources,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await act();
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('Pick different sources returns the sentinel', (tester) async {
    final result = await openModal(
      tester,
      pickSources: true,
      act: () async => tester.tap(find.text('Pick different sources')),
    );
    expect(result, [SelectionModal.pickSourcesSentinel]);
  });

  testWidgets('the button is hidden unless asked for', (tester) async {
    await openModal(tester, pickSources: false, act: () async {});
    expect(find.text('Pick different sources'), findsNothing);
  });
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
