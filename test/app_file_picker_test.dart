import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/app_detail_widgets.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

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

  testWidgets('shows per-APK ABIs and universal packages', (tester) async {
    final app = App(
      'com.example.app',
      'https://f-droid.org/packages/com.example.app',
      'Example',
      'Example',
      null,
      '1.0.0',
      const [
        MapEntry('arm64.apk', 'https://example.com/arm64.apk'),
        MapEntry('universal.apk', 'https://example.com/universal.apk'),
      ],
      0,
      const {},
      DateTime(2026),
      false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<PlusSettingsProvider>(
            create: (_) => PlusSettingsProvider(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppFilePicker(
              app: app,
              archs: const ['arm64-v8a'],
              apkAbis: const {
                'https://example.com/arm64.apk': ['arm64-v8a'],
                'https://example.com/universal.apk': [],
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ABI: arm64-v8a'), findsOneWidget);
    expect(find.text('Universal'), findsOneWidget);
  });
}
