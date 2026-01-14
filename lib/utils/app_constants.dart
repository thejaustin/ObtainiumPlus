import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Foreground Service Configuration
  /// Unique identifier for the foreground service
  static const int foregroundServiceId = 666;

  /// Default interval for background update checks (in milliseconds)
  /// 900000ms = 15 minutes
  static const int defaultUpdateIntervalMs = 900000;

  // Animation Durations (Material 3 Motion Tokens)
  /// Short duration for quick transitions (Material 3)
  static const int shortAnimationMs = 200;

  /// Medium duration for standard transitions (Material 3)
  static const int mediumAnimationMs = 300;

  /// Long duration for complex transitions (Material 3)
  static const int longAnimationMs = 400;

  /// Expressive duration for Material You animations
  static const int expressiveAnimationMs = 500;

  // Material You Expressive Curves
  /// Standard expressive easing curve (Material 3)
  static const Curve expressiveStandard = Curves.easeOutCubic;

  /// Decelerate curve for enter animations (Material 3)
  static const Curve expressiveDecelerate = Curves.easeOutQuint;

  /// Accelerate curve for exit animations (Material 3)
  static const Curve expressiveAccelerate = Curves.easeInQuint;

  /// Emphasized curve for important transitions (Material 3)
  static const Curve expressiveEmphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Smooth curve for micro-interactions
  static const Curve expressiveSmooth = Curves.easeInOutCubicEmphasized;

  // Spring Physics for Micro-interactions
  /// Spring physics for press animations
  static const SpringDescription pressSpring = SpringDescription(
    mass: 1.0,
    stiffness: 150.0,
    damping: 12.0,
  );

  /// Spring physics for bounce effects
  static const SpringDescription bounceSpring = SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 10.0,
  );

  /// Spring physics for gentle rebounds
  static const SpringDescription gentleSpring = SpringDescription(
    mass: 1.0,
    stiffness: 120.0,
    damping: 15.0,
  );

  // UI Layout Constants
  /// Default border radius for cards and containers
  static const double defaultBorderRadius = 12.0;

  /// Border width for focused input fields
  static const double focusedBorderWidth = 2.5;

  /// Border width for enabled input fields
  static const double enabledBorderWidth = 2.0;

  /// Horizontal padding for input fields
  static const double inputHorizontalPadding = 16.0;

  /// Vertical padding for input fields
  static const double inputVerticalPadding = 16.0;
}
