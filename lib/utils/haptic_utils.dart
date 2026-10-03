import 'package:flutter/services.dart';

/// Central haptic feedback utility. All haptic calls in the app go through
/// here so that the user's "Enable Haptic Feedback" setting is respected.
///
/// [AppHaptics.enabled] is a static flag kept in sync by [BehaviorSettingsProvider]
/// whenever the preference changes, and initialized at app start.
class AppHaptics {
  AppHaptics._();

  static bool enabled = true;

  static void selectionClick() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void lightImpact() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  static void vibrate() {
    if (enabled) HapticFeedback.vibrate();
  }

  // ── Semantic outcome haptics ─────────────────────────────────────────────
  // Prefer these over raw impact methods when signalling operation outcomes.

  /// Positive outcome (e.g. successful install or update).
  static void success() => lightImpact();

  /// Negative outcome (e.g. failed install, downgrade error).
  static void failure() => heavyImpact();

  // ── M3E interaction haptics ──────────────────────────────────────────────
  // Used for shape morphs, press-down events, and multi-beat patterns.

  /// Fires on pointer contact — more physical than waiting for pointer-up.
  /// Use with [ScaleTouchWrapper]'s hapticOnPressDown for responsive feel.
  static void tapDown() => selectionClick();

  /// Subtle cue fired when a UI element begins a shape morph transition.
  static void morphCue() => selectionClick();

  /// Two successive impulses — for warnings or a "double confirm" feel.
  /// Fires medium then light immediately (OS sequences them on Android).
  static void warning() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    HapticFeedback.lightImpact();
  }

  /// Double-beat confirm — light then medium.
  /// Communicates successful completion of a significant action.
  static void doubleImpact() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    HapticFeedback.mediumImpact();
  }
}
