import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/dcl_warning_dialog.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/http_client_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Localization.load(
      const Locale('en'),
      translations: Translations(
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>,
      ),
    );
  });

  group('settings', () {
    test('default to the certificate store on and an unseen warning', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();
      provider.prefs = await SharedPreferences.getInstance();
      expect(provider.useAndroidCertStore, isTrue);
      expect(provider.dclWarningShown, isFalse);
    });

    test('persist the preference and warning state', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = SettingsProvider();
      provider.prefs = await SharedPreferences.getInstance();
      provider.useAndroidCertStore = false;
      provider.dclWarningShown = true;
      final reloaded = SettingsProvider();
      reloaded.prefs = await SharedPreferences.getInstance();
      expect(reloaded.useAndroidCertStore, isFalse);
      expect(reloaded.dclWarningShown, isTrue);
      HttpClientFactory.setAndroidCertStoreEnabled(true);
    });

    test('a type-flipped stored value falls back to the default', () async {
      SharedPreferences.setMockInitialValues({'useAndroidCertStore': 'yes'});
      final provider = SettingsProvider();
      provider.prefs = await SharedPreferences.getInstance();
      expect(provider.useAndroidCertStore, isTrue);
    });
  });

  group('HttpClientFactory.shouldUseCronet', () {
    bool use({
      bool android = true,
      bool store = true,
      bool restricted = false,
      bool unavailable = false,
    }) => HttpClientFactory.shouldUseCronet(
      isAndroid: android,
      androidCertStoreEnabled: store,
      execmemRestricted: restricted,
      cronetUnavailable: unavailable,
    );

    test('is on by default on Android', () => expect(use(), isTrue));
    test(
      'is off when the setting is off',
      () => expect(use(store: false), isFalse),
    );
    test(
      'is off when DCL is restricted',
      () => expect(use(restricted: true), isFalse),
    );
    test(
      'is off after Cronet failed to start',
      () => expect(use(unavailable: true), isFalse),
    );
    test(
      'is off away from Android',
      () => expect(use(android: false), isFalse),
    );
  });

  group('DclWarningDialog', () {
    Future<void> show(WidgetTester tester, VoidCallback onOpenSettings) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => unawaited(
                  showDialog<void>(
                    context: context,
                    builder: (_) =>
                        DclWarningDialog(onOpenSettings: onOpenSettings),
                  ),
                ),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens app settings and dismisses', (tester) async {
      var opened = false;
      await show(tester, () => opened = true);
      expect(
        find.text('Android certificate store unavailable'),
        findsOneWidget,
      );
      await tester.tap(find.text('Open app settings'));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('OK dismisses without opening settings', (tester) async {
      var opened = false;
      await show(tester, () => opened = true);
      await tester.tap(find.text('Okay'));
      await tester.pumpAndSettle();
      expect(opened, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
