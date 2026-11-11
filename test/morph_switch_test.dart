import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/common/morph_switch.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String?> haptics;

  setUp(() {
    AppHaptics.enabled = true;
    AppHaptics.resetPreviewOptions();
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String?);
          }
          return null;
        });
  });

  tearDown(() {
    AppHaptics.resetPreviewOptions();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Pumps a controlled MorphSwitch; returns a getter for the live value.
  Future<bool Function()> pump(
    WidgetTester tester,
    SettingsSwitchStyle? style, {
    bool initial = false,
    bool enabled = true,
    bool motion = true,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      'plusEnableEnhancedAnimations': motion,
      ...prefs,
    });
    final p = PlusSettingsProvider();
    await p.initializeSettings(await SharedPreferences.getInstance());
    var value = initial;
    await tester.pumpWidget(
      ChangeNotifierProvider<PlusSettingsProvider>.value(
        value: p,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => MorphSwitch(
                  value: value,
                  style: style,
                  onChanged: enabled ? (v) => setState(() => value = v) : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => value;
  }

  for (final style in SettingsSwitchStyle.values) {
    group(style.name, () {
      testWidgets('semantics report toggled and enabled', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, style, initial: true);
        expect(
          tester.getSemantics(find.byType(MorphSwitch)),
          containsSemantics(
            hasToggledState: true,
            isToggled: true,
            hasEnabledState: true,
            isEnabled: true,
          ),
        );
        handle.dispose();
      });

      testWidgets('disabled: semantics not enabled, tap ignored', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final value = await pump(tester, style, enabled: false);
        expect(
          tester.getSemantics(find.byType(MorphSwitch)),
          containsSemantics(
            hasToggledState: true,
            isToggled: false,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
        await tester.tap(find.byType(MorphSwitch), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(value(), isFalse);
        expect(haptics, isEmpty);
        handle.dispose();
      });

      testWidgets('tap toggles with exactly one haptic each way', (
        tester,
      ) async {
        final value = await pump(tester, style);
        await tester.tap(find.byType(MorphSwitch));
        await tester.pumpAndSettle();
        expect(value(), isTrue);
        expect(haptics, ['HapticFeedbackType.mediumImpact']);
        await tester.tap(find.byType(MorphSwitch));
        await tester.pumpAndSettle();
        expect(value(), isFalse);
        expect(haptics, [
          'HapticFeedbackType.mediumImpact',
          'HapticFeedbackType.lightImpact',
        ]);
      });

      if (style != SettingsSwitchStyle.iconSwitch) {
        testWidgets('drag on and back off', (tester) async {
          final value = await pump(tester, style);
          await tester.drag(find.byType(MorphSwitch), const Offset(60, 0));
          await tester.pumpAndSettle();
          expect(value(), isTrue);
          await tester.drag(find.byType(MorphSwitch), const Offset(-60, 0));
          await tester.pumpAndSettle();
          expect(value(), isFalse);
        });
      }

      if (style != SettingsSwitchStyle.classic) {
        testWidgets('motion off settles in one frame', (tester) async {
          final value = await pump(tester, style, motion: false);
          await tester.tap(find.byType(MorphSwitch));
          await tester.pump();
          expect(value(), isTrue);
          expect(tester.hasRunningAnimations, isFalse);
        });
      }
    });
  }

  testWidgets('default style is the SDK Switch', (tester) async {
    await pump(tester, null);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('style follows plusSwitchStyle', (tester) async {
    await pump(
      tester,
      null,
      prefs: {'plusSwitchStyle': SettingsSwitchStyle.expressive.index},
    );
    expect(find.byType(Switch), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MorphSwitch),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
  });

  testWidgets('shape thumb uses one static Morph; reduce-morphs still works', (
    tester,
  ) async {
    final first = MorphSwitch.thumbMorph;
    final value = await pump(
      tester,
      SettingsSwitchStyle.shapeThumb,
      prefs: {'plusReduceShapeMorphs': true},
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(MorphSwitch));
      await tester.pumpAndSettle();
    }
    expect(value(), isTrue);
    expect(identical(first, MorphSwitch.thumbMorph), isTrue);
  });

  testWidgets('icon badge morphs are cached per shape, not per build', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final p = PlusSettingsProvider();
    await p.initializeSettings(await SharedPreferences.getInstance());
    var active = false;
    final before = ToggleIconBadge.morphsBuilt;
    await tester.pumpWidget(
      ChangeNotifierProvider<PlusSettingsProvider>.value(
        value: p,
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => GestureDetector(
              onTap: () => setState(() => active = !active),
              child: ToggleIconBadge(
                icon: Icons.star,
                active: active,
                morphOnToggle: true,
                shape: IconMorphShape.clover,
                style: IconMorphStyle.spin,
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(ToggleIconBadge));
      await tester.pumpAndSettle();
    }
    expect(ToggleIconBadge.morphsBuilt - before, lessThanOrEqualTo(1));
    expect(
      identical(
        ToggleIconBadge.morphFor(IconMorphShape.clover),
        ToggleIconBadge.morphFor(IconMorphShape.clover),
      ),
      isTrue,
    );
  });
}
