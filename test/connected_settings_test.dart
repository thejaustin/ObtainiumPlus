import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/connected_setting_container.dart';
import 'package:obtainium/components/settings/connected_settings_bar.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final translations =
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(
      const Locale('en'),
      translations: Translations(translations),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ConnectedSettingsBar renders related items and handles tap', (
    WidgetTester tester,
  ) async {
    final plusSettings = PlusSettingsProvider();
    bool tappedFirst = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlusSettingsProvider>.value(
            value: plusSettings,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ConnectedSettingsBar(
              title: 'Related Settings',
              description: 'Quick jump to connected settings',
              items: [
                ConnectedSettingItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle: 'Update alerts & quiet hours',
                  onTap: () => tappedFirst = true,
                ),
                ConnectedSettingItem(
                  icon: Icons.healing_outlined,
                  title: 'Update Health',
                  subtitle: 'Check rate limits',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Related Settings'), findsOneWidget);
    expect(find.text('Quick jump to connected settings'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Update alerts & quiet hours'), findsOneWidget);
    expect(find.text('Update Health'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    expect(tappedFirst, isTrue);
  });

  testWidgets(
    'ConnectedSettingContainer renders child with accent rail and label',
    (WidgetTester tester) async {
      final plusSettings = PlusSettingsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlusSettingsProvider>.value(
              value: plusSettings,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ConnectedSettingContainer(
                label: 'Dependent Options',
                child: Text('Nested Setting Content'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dependent Options'), findsOneWidget);
      expect(find.text('Nested Setting Content'), findsOneWidget);
      expect(find.byType(ConnectedSettingContainer), findsOneWidget);
    },
  );
}
