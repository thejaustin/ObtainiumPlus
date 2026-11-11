import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/pages/settings_subpage.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// With motion off (in-app "enhanced animations" toggle or the OS "remove
/// animations" setting), settings navigation and group expansion must land
/// in their end state on the very next frame, with nothing left ticking.
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

  final homeKey = GlobalKey();

  Future<void> pumpHarness(
    WidgetTester tester, {
    required bool inAppMotion,
    bool osDisableAnimations = false,
    Widget? body,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'plusEnableEnhancedAnimations': inAppMotion,
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsProvider(prefs);
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<PlusSettingsProvider>.value(value: plus),
        ],
        child: MaterialApp(
          // Ink splashes/highlights animate regardless of the motion gate.
          theme: ThemeData(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: osDisableAnimations),
            child: child!,
          ),
          home: Scaffold(key: homeKey, body: body ?? const SizedBox.shrink()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SettingsSubpage buildSubpage() {
    const siblings = [
      SettingsSubpageSibling(
        title: 'First',
        icon: Icons.palette_rounded,
        child: Text('first body'),
      ),
      SettingsSubpageSibling(
        title: 'Second',
        icon: Icons.style_rounded,
        child: Text('second body'),
      ),
      SettingsSubpageSibling(
        title: 'Third',
        icon: Icons.dashboard_customize_outlined,
        child: Text('third body'),
      ),
    ];
    return const SettingsSubpage(
      title: 'Third',
      icon: Icons.dashboard_customize_outlined,
      siblings: siblings,
      currentSiblingIndex: 2,
      child: Text('third body'),
    );
  }

  group('settings subpage push', () {
    for (final (label, inApp, os) in [
      ('in-app toggle off', false, false),
      ('OS remove-animations on', true, true),
    ]) {
      testWidgets('lands in one frame with motion off ($label)', (
        tester,
      ) async {
        await pumpHarness(tester, inAppMotion: inApp, osDisableAnimations: os);
        unawaited(pushRoute<void>(homeKey.currentContext!, buildSubpage()));
        await tester.pump();

        expect(find.byType(SettingsSubpage), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
        // Post-frame sibling scroll must jump, not animate.
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
      });
    }

    testWidgets('still animates with motion on', (tester) async {
      await pumpHarness(tester, inAppMotion: true);
      unawaited(pushRoute<void>(homeKey.currentContext!, buildSubpage()));
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsSubpage), findsOneWidget);
    });
  });

  group('expressive settings group expand', () {
    Widget groupBody() => const SingleChildScrollView(
      child: ExpressiveSettingsGroup(
        title: 'Group title',
        isExpandable: true,
        initiallyExpanded: false,
        children: [Text('group child')],
      ),
    );

    RotationTransition arrow(WidgetTester tester) => tester.widget(
      find.descendant(
        of: find.byType(ExpressiveSettingsGroup),
        matching: find.byType(RotationTransition),
      ),
    );

    for (final (label, inApp, os) in [
      ('in-app toggle off', false, false),
      ('OS remove-animations on', true, true),
    ]) {
      testWidgets('expands in one frame with motion off ($label)', (
        tester,
      ) async {
        await pumpHarness(
          tester,
          inAppMotion: inApp,
          osDisableAnimations: os,
          body: groupBody(),
        );
        expect(arrow(tester).turns.value, 0);

        await tester.tap(find.text('Group title'));
        await tester.pump();

        expect(tester.hasRunningAnimations, isFalse);
        expect(arrow(tester).turns.value, closeTo(0.5, 0.001));
        expect(find.text('group child'), findsOneWidget);
      });
    }

    testWidgets('still animates with motion on', (tester) async {
      await pumpHarness(tester, inAppMotion: true, body: groupBody());

      await tester.tap(find.text('Group title'));
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(arrow(tester).turns.value, closeTo(0.5, 0.001));
    });
  });
}
