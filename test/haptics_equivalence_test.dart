import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/haptic_utils.dart';

/// Pins the platform-channel calls of every pre-existing [AppHaptics]
/// method at the default settings, so new intensity / native / follow-system
/// options can never change the shipped feel while they are off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String?> calls;

  setUp(() {
    AppHaptics.enabled = true;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String?);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  const selection = 'HapticFeedbackType.selectionClick';
  const light = 'HapticFeedbackType.lightImpact';
  const medium = 'HapticFeedbackType.mediumImpact';
  const heavy = 'HapticFeedbackType.heavyImpact';

  final cases = <String, (void Function(), List<String?>)>{
    'segmentTick': (AppHaptics.segmentTick, [selection]),
    'lightImpact': (AppHaptics.lightImpact, [light]),
    'mediumImpact': (AppHaptics.mediumImpact, [medium]),
    'heavyImpact': (AppHaptics.heavyImpact, [heavy]),
    'vibrate': (AppHaptics.vibrate, [null]),
    'success': (AppHaptics.success, [light]),
    'failure': (AppHaptics.failure, [heavy]),
    'morphCue': (AppHaptics.morphCue, [selection]),
    'toggleOn': (AppHaptics.toggleOn, [medium]),
    'toggleOff': (AppHaptics.toggleOff, [light]),
  };

  for (final entry in cases.entries) {
    test('${entry.key} sends the shipped haptic', () async {
      entry.value.$1();
      await Future<void>.delayed(Duration.zero);
      expect(calls, entry.value.$2);
    });
  }

  test(
    'tapDown then selectionClick inside the dedupe window: one tick',
    () async {
      AppHaptics.tapDown();
      AppHaptics.selectionClick();
      await Future<void>.delayed(Duration.zero);
      expect(calls, [selection]);
    },
  );

  test('disabled haptics send nothing', () async {
    AppHaptics.enabled = false;
    for (final c in cases.values) {
      c.$1();
    }
    AppHaptics.tapDown();
    AppHaptics.selectionClick();
    await AppHaptics.warning();
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
    AppHaptics.enabled = true;
  });

  test('two-beat patterns keep their order', () async {
    await AppHaptics.warning();
    await AppHaptics.doubleImpact();
    await AppHaptics.installSuccess();
    expect(calls, [medium, light, light, medium, light, medium]);
  });
}
