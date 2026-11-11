import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/models/settings_enums.dart';

/// Central haptic feedback utility. All haptic calls in the app go through
/// here so that the user's "Enable Haptic Feedback" setting is respected.
///
/// [AppHaptics.enabled] is a static flag kept in sync by [BehaviorSettingsProvider]
/// whenever the preference changes, and initialized at app start.
///
/// [intensity], [useNative] and [followSystem] are opt-in previews kept in
/// sync by `PlusSettingsProvider`. At their defaults (standard, off, off)
/// every method sends exactly the shipped haptic (pinned by
/// `test/haptics_equivalence_test.dart`).
class AppHaptics {
  AppHaptics._();

  static bool enabled = true;

  /// Haptic strength preview. [HapticIntensity.standard] = shipped haptics.
  static HapticIntensity intensity = HapticIntensity.standard;

  /// Route semantic haptics (toggle, segment tick, confirm/reject, gesture)
  /// through Android's `View.performHapticFeedback` constants.
  static bool useNative = false;

  /// Also respect Android's system "touch feedback" setting.
  static bool followSystem = false;

  /// Last known value of the system touch-feedback setting (assume on until
  /// [refreshSystemSetting] says otherwise, or when the query fails).
  static bool _systemEnabled = true;

  static const MethodChannel _native = MethodChannel(
    'dev.thejaustin.obtainiumplus/native',
  );

  /// Restores every preview option to its default. For tests.
  @visibleForTesting
  static void resetPreviewOptions() {
    intensity = HapticIntensity.standard;
    useNative = false;
    followSystem = false;
    _systemEnabled = true;
  }

  /// Re-reads Android's touch-feedback setting into a cache, so the hot path
  /// never awaits a platform call. Failures (tests, older APKs) keep the last
  /// value, initially "enabled".
  static Future<void> refreshSystemSetting() async {
    try {
      final v = await _native.invokeMethod<bool>('isSystemHapticsEnabled');
      if (v != null) _systemEnabled = v;
    } catch (_) {
      // keep the cached value
    }
  }

  @visibleForTesting
  static set systemEnabledForTesting(bool v) => _systemEnabled = v;

  static bool get _on => enabled && (!followSystem || _systemEnabled);

  /// Timestamp (microseconds) of the most recent [tapDown] event.
  /// Used to suppress duplicate [selectionClick] calls when a widget wrapped in
  /// [ScaleTouchWrapper] (`hapticOnPressDown: true`) also calls
  /// `AppHaptics.selectionClick()` in its `onTap`/`onPressed` callback.
  static int _lastTapDownUs = 0;
  static const int _tapDownDedupeWindowUs = 220 * 1000;

  /// Sends the Android constant [name] when [useNative] is on; otherwise, or
  /// when the native call fails / reports no haptic, runs [fallback].
  static void _nativeOr(String name, void Function() fallback) {
    if (!useNative) {
      fallback();
      return;
    }
    _native
        .invokeMethod<bool>('performHaptic', {'constant': name})
        .then((done) {
          if (done != true && _on) fallback();
        })
        .catchError((Object _) {
          if (_on) fallback();
        });
  }

  static void selectionClick() {
    if (!_on) return;
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    if (nowUs - _lastTapDownUs < _tapDownDedupeWindowUs) {
      return;
    }
    HapticFeedback.selectionClick();
  }

  /// Crisp discrete tick for slider divisions, segmented buttons, and scrubbers.
  /// Bypasses tap-down deduplication so rapid scrubbing always ticks cleanly.
  static void segmentTick() {
    if (_on) _nativeOr('SEGMENT_TICK', HapticFeedback.selectionClick);
  }

  static void lightImpact() {
    if (_on) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (_on) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (_on) HapticFeedback.heavyImpact();
  }

  static void vibrate() {
    if (_on) HapticFeedback.vibrate();
  }

  // ── Semantic outcome haptics ─────────────────────────────────────────────
  // Prefer these over raw impact methods when signalling operation outcomes.

  /// Positive outcome (e.g. successful install or update).
  /// Standard: light (shipped). Subtle: selection. Strong: success pattern.
  static void success() {
    if (!_on) return;
    switch (intensity) {
      case HapticIntensity.standard:
        _nativeOr('CONFIRM', HapticFeedback.lightImpact);
      case HapticIntensity.subtle:
        HapticFeedback.selectionClick();
      case HapticIntensity.strong:
        _nativeOr('CONFIRM', _successPattern);
    }
  }

  /// Negative outcome (e.g. failed install, downgrade error).
  static void failure() => error();

  /// Error (bad token, failed import). Heavy at every intensity except
  /// Strong, which uses the error notification pattern.
  static void error() {
    if (!_on) return;
    if (intensity == HapticIntensity.strong) {
      _nativeOr('REJECT', _errorPattern);
    } else {
      _nativeOr('REJECT', HapticFeedback.heavyImpact);
    }
  }

  static void _successPattern() => unawaited(
    HapticFeedback.successNotification().catchError(
      (Object _) => HapticFeedback.mediumImpact(),
    ),
  );

  static void _errorPattern() => unawaited(
    HapticFeedback.errorNotification().catchError(
      (Object _) => HapticFeedback.heavyImpact(),
    ),
  );

  // ── Gesture haptics (sliders, drags, swipes) ─────────────────────────────

  /// Finger lands on a slider / drag handle. Standard: the shipped
  /// press-down tick. Subtle: nothing.
  static void gestureStart() {
    if (!_on) return;
    switch (intensity) {
      case HapticIntensity.standard:
        tapDown();
      case HapticIntensity.subtle:
        break;
      case HapticIntensity.strong:
        _nativeOr('GESTURE_START', HapticFeedback.lightImpact);
    }
  }

  /// Finger lifts. Standard: the shipped light release. Subtle: nothing.
  static void gestureEnd() {
    if (!_on) return;
    switch (intensity) {
      case HapticIntensity.standard:
        HapticFeedback.lightImpact();
      case HapticIntensity.subtle:
        break;
      case HapticIntensity.strong:
        _nativeOr('GESTURE_END', HapticFeedback.lightImpact);
    }
  }

  /// A drag crosses an action threshold ([activate]) or returns ([!activate]).
  static void gestureThreshold({bool activate = true}) {
    if (!_on) return;
    if (activate) {
      _nativeOr(
        'GESTURE_THRESHOLD_ACTIVATE',
        intensity == HapticIntensity.strong
            ? HapticFeedback.heavyImpact
            : HapticFeedback.mediumImpact,
      );
    } else if (intensity != HapticIntensity.subtle) {
      _nativeOr('GESTURE_THRESHOLD_DEACTIVATE', HapticFeedback.lightImpact);
    }
  }

  /// A slider hit its min or max. Only at Strong (none shipped).
  static void gestureLimit() {
    if (_on && intensity == HapticIntensity.strong) {
      HapticFeedback.mediumImpact();
    }
  }

  /// A settings group expanded or collapsed.
  static void expandChanged(bool expanded) {
    if (!_on) return;
    switch (intensity) {
      case HapticIntensity.standard:
        selectionClick();
      case HapticIntensity.subtle:
        break;
      case HapticIntensity.strong:
        expanded ? toggleOn() : toggleOff();
    }
  }

  // ── M3E interaction haptics ──────────────────────────────────────────────
  // Used for shape morphs, press-down events, and multi-beat patterns.

  /// Fires on pointer contact — more physical than waiting for pointer-up.
  /// Use with [ScaleTouchWrapper]'s hapticOnPressDown for responsive feel.
  static void tapDown() {
    if (!_on) return;
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    if (nowUs - _lastTapDownUs < 40 * 1000) {
      return;
    }
    _lastTapDownUs = nowUs;
    HapticFeedback.selectionClick();
  }

  /// Subtle cue fired when a UI element begins a shape morph transition.
  static void morphCue() => segmentTick();

  /// Two successive impulses — for warnings or "double confirm" feel.
  /// Medium immediately, then light 60ms later so both beats are felt.
  static Future<void> warning() async {
    if (!_on) return;
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (_on) HapticFeedback.lightImpact();
  }

  /// Double-beat confirm — light then medium, 60ms apart.
  /// Communicates completion of a significant action (e.g. batch update done).
  static Future<void> doubleImpact() async {
    if (!_on) return;
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (_on) HapticFeedback.mediumImpact();
  }

  /// Install / update success: light tap → 80ms → medium confirm.
  /// More satisfying than a single light tap for a successful install.
  static Future<void> installSuccess() async {
    if (!_on) return;
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (_on) HapticFeedback.mediumImpact();
  }

  /// Switch toggled ON — slightly heavier than off to feel more decisive.
  /// Subtle: selection. Strong: heavy.
  static void toggleOn() {
    if (!_on) return;
    _nativeOr('TOGGLE_ON', switch (intensity) {
      HapticIntensity.standard => HapticFeedback.mediumImpact,
      HapticIntensity.subtle => HapticFeedback.selectionClick,
      HapticIntensity.strong => HapticFeedback.heavyImpact,
    });
  }

  /// Switch toggled OFF — lighter, less assertive than on.
  /// Subtle: selection. Strong: medium.
  static void toggleOff() {
    if (!_on) return;
    _nativeOr('TOGGLE_OFF', switch (intensity) {
      HapticIntensity.standard => HapticFeedback.lightImpact,
      HapticIntensity.subtle => HapticFeedback.selectionClick,
      HapticIntensity.strong => HapticFeedback.mediumImpact,
    });
  }

  /// Fires the toggle haptic for a switch that just changed to [value].
  static void toggled(bool value) => value ? toggleOn() : toggleOff();
}
