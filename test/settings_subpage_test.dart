import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/connected_settings_bar.dart';
import 'package:obtainium/pages/settings_subpage.dart';
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

  testWidgets(
    'SettingsSubpage renders masthead, siblings switcher, and switches siblings',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final plusSettings = PlusSettingsProvider();

      final siblings = [
        const SettingsSubpageSibling(
          title: 'Themes & Colors',
          subtitle: 'M3E themes and palettes',
          icon: Icons.palette_rounded,
          accentColor: Colors.blue,
          child: Text('Themes Body Content'),
        ),
        const SettingsSubpageSibling(
          title: 'App Tile Styling',
          subtitle: 'Tile decoration and borders',
          icon: Icons.style_rounded,
          accentColor: Colors.deepPurple,
          child: Text('Tile Styling Body Content'),
        ),
        const SettingsSubpageSibling(
          title: 'Layout & Nav',
          subtitle: 'Grid columns and density',
          icon: Icons.dashboard_customize_outlined,
          accentColor: Colors.teal,
          child: Text('Layout Body Content'),
        ),
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlusSettingsProvider>.value(
              value: plusSettings,
            ),
          ],
          child: MaterialApp(
            home: SettingsSubpage(
              title: siblings[0].title,
              subtitle: siblings[0].subtitle,
              icon: siblings[0].icon,
              accentColor: siblings[0].accentColor,
              siblings: siblings,
              currentSiblingIndex: 0,
              child: siblings[0].child,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // CustomAppBar + Masthead + sibling chip = 3 widgets
      expect(find.text('Themes & Colors'), findsNWidgets(3));
      expect(find.text('Themes Body Content'), findsOneWidget);

      // Sibling chips are rendered
      expect(find.text('App Tile Styling'), findsOneWidget);
      expect(find.text('Layout & Nav'), findsOneWidget);

      // Tap on second sibling: "App Tile Styling"
      await tester.tap(find.text('App Tile Styling'));
      await tester.pumpAndSettle();

      // Should now show App Tile Styling content and title in CustomAppBar, Masthead, & Chip
      expect(find.text('Tile Styling Body Content'), findsOneWidget);
      expect(find.text('App Tile Styling'), findsNWidgets(3));
      expect(find.text('Themes Body Content'), findsNothing);
    },
  );

  testWidgets(
    'SettingsSubpage renders connectedItems and respects wide display padding',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900); // Wide screen (> 1040dp)
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final plusSettings = PlusSettingsProvider();
      bool tappedConnected = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlusSettingsProvider>.value(
              value: plusSettings,
            ),
          ],
          child: MaterialApp(
            home: SettingsSubpage(
              title: 'Motion & Physics',
              subtitle: 'Animations and haptics',
              icon: Icons.auto_awesome_motion_rounded,
              connectedItems: [
                ConnectedSettingItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle: 'Jump to notifications',
                  onTap: () => tappedConnected = true,
                ),
              ],
              child: const Text('Motion Content'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // CustomAppBar + Masthead = 2 widgets
      expect(find.text('Motion & Physics'), findsNWidgets(2));
      expect(find.text('Motion Content'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Jump to notifications'), findsOneWidget);

      await tester.tap(find.text('Notifications'));
      expect(tappedConnected, isTrue);

      // Verify wide screen padding clamp
      final sliverPaddingFinder = find.byType(SliverPadding);
      expect(sliverPaddingFinder, findsOneWidget);
      final sliverPadding = tester.widget<SliverPadding>(sliverPaddingFinder);
      final padding = sliverPadding.padding as EdgeInsets;
      // (1400 - 1040) / 2 = 180.0
      expect(padding.left, equals(180.0));
      expect(padding.right, equals(180.0));
    },
  );

  testWidgets(
    'SettingsSubpage renders actions and triggers onReset',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final plusSettings = PlusSettingsProvider();
      bool resetCalled = false;
      bool actionCalled = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlusSettingsProvider>.value(
              value: plusSettings,
            ),
          ],
          child: MaterialApp(
            home: SettingsSubpage(
              title: 'App Tile Styling',
              subtitle: 'Custom tile geometry',
              icon: Icons.style_rounded,
              onReset: () => resetCalled = true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => actionCalled = true,
                ),
              ],
              child: const Text('Tile Settings Body'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restore_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.restore_rounded));
      expect(resetCalled, isTrue);

      await tester.tap(find.byIcon(Icons.info_outline));
      expect(actionCalled, isTrue);
    },
  );
}
