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

  /// Two successive impulses — for warnings or "double confirm" feel.
  /// Medium immediately, then light 60ms later so both beats are felt.
  static Future<void> warning() async {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Double-beat confirm — light then medium, 60ms apart.
  /// Communicates completion of a significant action (e.g. batch update done).
  static Future<void> doubleImpact() async {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Install / update success: light tap → 80ms → medium confirm.
  /// More satisfying than a single light tap for a successful install.
  static Future<void> installSuccess() async {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Switch toggled ON — slightly heavier than off to feel more decisive.
  static void toggleOn() => mediumImpact();

  /// Switch toggled OFF — lighter, less assertive than on.
  static void toggleOff() => lightImpact();
}
