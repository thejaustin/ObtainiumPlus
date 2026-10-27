import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/appearance_hub.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSettingsProvider extends ChangeNotifier {
  bool flag1 = false;
  bool flag2 = true;
}

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

  testWidgets(
    'AppearanceHub adapts between single-column and responsive grid',
    (WidgetTester tester) async {
      final plusSettings = PlusSettingsProvider();
      final themeSettings = ThemeSettingsProvider();
      final viewSettings = ViewSettingsProvider();

      Widget buildTestHarness(double width) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<PlusSettingsProvider>.value(
              value: plusSettings,
            ),
            ChangeNotifierProvider<ThemeSettingsProvider>.value(
              value: themeSettings,
            ),
            ChangeNotifierProvider<ViewSettingsProvider>.value(
              value: viewSettings,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: const SingleChildScrollView(
                    child: AppearanceHub(
                      androidInfoFuture: null,
                      themeContent: SizedBox.shrink(),
                      appTileContent: SizedBox.shrink(),
                      layoutNavContent: SizedBox.shrink(),
                      motionPhysicsContent: SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // 1. Narrow width (< 560): single column list
      await tester.pumpWidget(buildTestHarness(400));
      await tester.pumpAndSettle();
      expect(find.byType(AppearanceHub), findsOneWidget);
      expect(find.text('Theme & Dynamic Color'), findsOneWidget);

      // 2. Wide width (>= 560): adaptive 2-column Wrap
      await tester.pumpWidget(buildTestHarness(720));
      await tester.pumpAndSettle();
      expect(find.byType(Wrap), findsWidgets);
      expect(find.text('Theme & Dynamic Color'), findsOneWidget);
      expect(find.text('Layout & Navigation'), findsOneWidget);
    },
  );

  testWidgets(
    'GenericBooleanControlGrid adapts columns based on container width',
    (WidgetTester tester) async {
      final plusSettings = PlusSettingsProvider();
      plusSettings.plusSettingsUseGridToggles = true;
      final fakeProvider = _FakeSettingsProvider();

      Widget buildGridHarness(double width) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<PlusSettingsProvider>.value(
              value: plusSettings,
            ),
            ChangeNotifierProvider<_FakeSettingsProvider>.value(
              value: fakeProvider,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: GenericBooleanControlGrid<_FakeSettingsProvider>(
                    title: 'Test Controls',
                    settings: [
                      (
                        icon: Icons.check,
                        label: 'Option 1',
                        description: 'Desc 1',
                        getValue: (s) => s.flag1,
                        setValue: (s, v) => s.flag1 = v,
                      ),
                      (
                        icon: Icons.star,
                        label: 'Option 2',
                        description: 'Desc 2',
                        getValue: (s) => s.flag2,
                        setValue: (s, v) => s.flag2 = v,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildGridHarness(360));
      await tester.pumpAndSettle();
      expect(find.text('Test Controls'), findsOneWidget);
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
    },
  );
}
