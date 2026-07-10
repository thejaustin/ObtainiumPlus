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

  // Semantic outcome haptics — app-wide convention:
  // success = light impact, failure/error = heavy impact.
  // Prefer these over the raw impact methods when signalling the outcome
  // of an operation (e.g. install completed vs install failed).

  /// Positive outcome (e.g. successful install or update).
  static void success() {
    lightImpact();
  }

  /// Negative outcome (e.g. failed install, downgrade error).
  static void failure() {
    heavyImpact();
  }
}
