import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
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

/// One toggle change must produce exactly one haptic: the switch's
/// toggleOn/toggleOff, not an extra press-down tick from ScaleTouchWrapper.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String?> hapticCalls;

  setUp(() {
    AppHaptics.enabled = true;
    hapticCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          // Feedback.forTap also sends SystemSound.play on this channel.
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call.arguments as String?);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<_Flag> pumpToggle(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(prefs);
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

  testWidgets('switch tap on a feature toggle fires exactly one haptic', (
    tester,
  ) async {
    final flag = await pumpToggle(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(flag.value, isTrue);
    expect(hapticCalls, hasLength(1));
    // toggleOn → mediumImpact.
    expect(hapticCalls.single, 'HapticFeedbackType.mediumImpact');
  });

  testWidgets('tapping the row title also fires exactly one haptic', (
    tester,
  ) async {
    final flag = await pumpToggle(tester);

    await tester.tap(find.text('Toggle row'));
    await tester.pumpAndSettle();

    expect(flag.value, isTrue);
    expect(hapticCalls, hasLength(1));

    hapticCalls.clear();
    await tester.tap(find.text('Toggle row'));
    await tester.pumpAndSettle();
    expect(flag.value, isFalse);
    // toggleOff → lightImpact.
    expect(hapticCalls, ['HapticFeedbackType.lightImpact']);
  });
}
