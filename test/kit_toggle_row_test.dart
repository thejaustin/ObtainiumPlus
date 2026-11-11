import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/common/morph_switch.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/settings/settings_row.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Flag extends ChangeNotifier {
  bool value = false;
  void set(bool v) {
    value = v;
    notifyListeners();
  }
}

/// buildFeatureToggle with an opt-in switch style / icon morph renders the
/// kit row; one haptic per change whether the row or the switch is tapped.
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<_Flag> pump(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(await SharedPreferences.getInstance());
    final flag = _Flag();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlusSettingsProvider>.value(value: plus),
          ChangeNotifierProvider<_Flag>.value(value: flag),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => buildFeatureToggle<_Flag>(
                context,
                icon: Icons.vibration,
                title: 'Toggle row',
                subtitle: 'subtitle',
                value: (f) => f.value,
                onChanged: (f, v) => f.set(v),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return flag;
  }

  for (final style in SettingsSwitchStyle.values) {
    testWidgets('${style.name}: row tap and switch tap, one haptic each', (
      tester,
    ) async {
      final flag = await pump(tester, {
        'plusSwitchStyle': style.index,
        // Classic only reaches the kit row through the icon morph.
        'plusIconMorphOnToggle': style == SettingsSwitchStyle.classic,
      });
      expect(find.byType(SettingsRow), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);

      await tester.tap(find.text('Toggle row'));
      await tester.pumpAndSettle();
      expect(flag.value, isTrue);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);

      await tester.tap(find.byType(MorphSwitch));
      await tester.pumpAndSettle();
      expect(flag.value, isFalse);
      expect(haptics, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.lightImpact',
      ]);
    });
  }

  testWidgets('row semantics carry the toggle state', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, {
      'plusSwitchStyle': SettingsSwitchStyle.expressive.index,
    });
    expect(
      tester.getSemantics(find.text('Toggle row')),
      containsSemantics(
        hasToggledState: true,
        isToggled: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('defaults keep the SwitchListTile', (tester) async {
    await pump(tester, {});
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(SettingsRow), findsNothing);
  });
}
