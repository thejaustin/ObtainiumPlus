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
