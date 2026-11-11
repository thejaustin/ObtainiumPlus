import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/utils/haptic_utils.dart';

/// Opt-in haptic previews: intensity mapping, the native channel path and
/// follow-system gating.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const native = MethodChannel('dev.thejaustin.obtainiumplus/native');
  late List<String?> flutterCalls;
  late List<MethodCall> nativeCalls;
  Object? nativeReply;

  setUp(() {
    AppHaptics.enabled = true;
    AppHaptics.resetPreviewOptions();
    flutterCalls = [];
    nativeCalls = [];
    nativeReply = true;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        flutterCalls.add(call.arguments as String?);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(native, (call) async {
      nativeCalls.add(call);
      if (nativeReply is Exception) throw nativeReply!;
      return nativeReply;
    });
  });

  tearDown(() {
    AppHaptics.resetPreviewOptions();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(native, null);
  });

  Future<void> flush() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('subtle and strong toggle mapping', () async {
    AppHaptics.intensity = HapticIntensity.subtle;
    AppHaptics.toggleOn();
    AppHaptics.toggleOff();
    AppHaptics.intensity = HapticIntensity.strong;
    AppHaptics.toggleOn();
    AppHaptics.toggleOff();
    await flush();
    expect(flutterCalls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.heavyImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  test('subtle drops gesture start / end; standard keeps shipped', () async {
    AppHaptics.intensity = HapticIntensity.subtle;
    AppHaptics.gestureStart();
    AppHaptics.gestureEnd();
    await flush();
    expect(flutterCalls, isEmpty);
    AppHaptics.intensity = HapticIntensity.standard;
    AppHaptics.gestureEnd();
    await flush();
    expect(flutterCalls, ['HapticFeedbackType.lightImpact']);
  });

  test('error is heavy at standard, a notification at strong', () async {
    AppHaptics.error();
    AppHaptics.intensity = HapticIntensity.strong;
    AppHaptics.error();
    AppHaptics.success();
    await flush();
    expect(flutterCalls, [
      'HapticFeedbackType.heavyImpact',
      'HapticFeedbackType.errorNotification',
      'HapticFeedbackType.successNotification',
    ]);
  });

  test(
    'native path sends the Android constant and no Flutter haptic',
    () async {
      AppHaptics.useNative = true;
      AppHaptics.toggleOn();
      AppHaptics.toggleOff();
      AppHaptics.segmentTick();
      await flush();
      expect(nativeCalls.map((c) => c.method), everyElement('performHaptic'));
      expect(nativeCalls.map((c) => (c.arguments as Map)['constant']), [
        'TOGGLE_ON',
        'TOGGLE_OFF',
        'SEGMENT_TICK',
      ]);
      expect(flutterCalls, isEmpty);
    },
  );

  test('native failure falls back to the Flutter haptic', () async {
    AppHaptics.useNative = true;
    nativeReply = PlatformException(code: 'x');
    AppHaptics.toggleOn();
    await flush();
    expect(flutterCalls, ['HapticFeedbackType.mediumImpact']);

    flutterCalls.clear();
    nativeReply = false;
    AppHaptics.toggleOff();
    await flush();
    expect(flutterCalls, ['HapticFeedbackType.lightImpact']);
  });

  test('native off never touches the channel', () async {
    AppHaptics.toggleOn();
    AppHaptics.segmentTick();
    await flush();
    expect(nativeCalls, isEmpty);
  });

  test('follow system: off in Android silences haptics', () async {
    AppHaptics.followSystem = true;
    nativeReply = false;
    await AppHaptics.refreshSystemSetting();
    expect(nativeCalls.single.method, 'isSystemHapticsEnabled');
    AppHaptics.toggleOn();
    AppHaptics.lightImpact();
    await flush();
    expect(flutterCalls, isEmpty);

    // Turning follow-system off restores haptics regardless.
    AppHaptics.followSystem = false;
    AppHaptics.lightImpact();
    await flush();
    expect(flutterCalls, ['HapticFeedbackType.lightImpact']);
  });

  test('follow system: query failure assumes enabled', () async {
    AppHaptics.followSystem = true;
    nativeReply = PlatformException(code: 'x');
    await AppHaptics.refreshSystemSetting();
    AppHaptics.lightImpact();
    await flush();
    expect(flutterCalls, ['HapticFeedbackType.lightImpact']);
  });

  test('follow system re-reads the setting on app resume', () async {
    nativeReply = true;
    AppHaptics.followSystem = true;
    AppHaptics.watchSystemSetting(true);
    await flush();
    expect(nativeCalls.map((c) => c.method), ['isSystemHapticsEnabled']);

    // User turns touch feedback off in Android settings, then comes back.
    nativeReply = false;
    final binding = TestWidgetsFlutterBinding.instance;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush();
    expect(nativeCalls, hasLength(2));
    AppHaptics.lightImpact();
    await flush();
    expect(flutterCalls, isEmpty);

    AppHaptics.watchSystemSetting(false);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush();
    expect(nativeCalls, hasLength(2));
  });
}
