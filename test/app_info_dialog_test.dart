import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/app_detail_widgets.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _url = 'https://github.com/ImranR98/Obtainium';

class _UnusedAppsProvider extends ChangeNotifier implements AppsProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    Localization.load(
      const Locale('en'),
      translations: Translations(
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>,
      ),
    );
  });

  testWidgets(
    'the source URL in the app info dialog is a link and copies on long press',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsProvider()..prefs = prefs;
      final plus = PlusSettingsProvider();
      await plus.initializeSettings(prefs);
      final app = App(
        'dev.imranr.obtainium',
        _url,
        'ImranR98',
        'Obtainium',
        null,
        '1.0.0',
        const [],
        0,
        {},
        null,
        false,
      );
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<PlusSettingsProvider>.value(value: plus),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppInfoDialog(
                app: AppInMemory(app, null, null, null),
                appsProvider: _UnusedAppsProvider(),
              ),
            ),
          ),
        ),
      );

      final link = tester.widget<LinkText>(find.byType(LinkText));
      expect(link.url, _url);
      expect(link.text, _url);

      await tester.longPress(find.text(_url));
      await tester.pump();
      expect(copied, _url);
    },
  );
}
