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

  // Animation Durations (Snappy & Responsive)
  /// Short duration for quick transitions (Reduced for snappiness)
  static const int shortAnimationMs = 150;

  /// Medium duration for standard transitions (Reduced for responsiveness)
  static const int mediumAnimationMs = 200;

  /// Long duration for complex transitions (Reduced for better feel)
  static const int longAnimationMs = 250;

  /// Expressive duration for Material You animations (Reduced for tactile feel)
  static const int expressiveAnimationMs = 200;

  // Material 3 Motion Curves
  /// Standard M3 curves (for regular mode)
  static const Curve standardStandard = Curves.easeInOutCubic;
  static const Curve standardDecelerate = Curves.easeOutCubic;
  static const Curve standardAccelerate = Curves.easeInCubic;
  static const Curve standardEmphasized = Curves.easeInOutQuart;
  static const Curve standardSmooth = Curves.easeInOut;

  /// Expressive M3E curves — cubic bezier values from Material 3 motion spec
  static const Curve expressiveStandard = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve expressiveDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve expressiveAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve expressiveEmphasized = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve expressiveSmooth = Cubic(0.4, 0.0, 0.2, 1.0);

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
  static const double defaultBorderRadius = 24.0;

  /// Border width for focused input fields
  static const double focusedBorderWidth = 2.5;

  /// Border width for enabled input fields
  static const double enabledBorderWidth = 2.0;

  /// Horizontal padding for input fields
  static const double inputHorizontalPadding = 16.0;

  /// Vertical padding for input fields
  static const double inputVerticalPadding = 16.0;

  // Package IDs for thejaustin's "Plus" apps
  /// ObtainiumPlus Package ID
  static const String obtainiumPlusId = 'app.obtainiumplus';

  /// ShizukuPlus Package ID
  static const String shizukuPlusId = 'af.shizuku.plus.api';

  /// AppManager (thejaustin fork) Package ID
  static const String appManagerId = 'io.github.muntashirakon.AppManager';

  /// ContactsPlus Package ID
  static const String contactsPlusId = 'com.contactsplus.app';

  /// TermuxPlus Package ID
  static const String termuxPlusId = 'com.termux.plus';

  /// SimWeather Package ID
  static const String simWeatherId = 'com.thejaustin.simweather';

  /// ShareMove Package ID
  static const String shareMoveId = 'com.thejaustin.sharemove';

  /// Pearity Package ID
  static const String pearityId = 'com.thejaustin.pearity';

  /// List of all thejaustin's apps that require special version reconciliation
  static const Set<String> plusAppIds = {
    obtainiumPlusId,
    shizukuPlusId,
    appManagerId,
    contactsPlusId,
    termuxPlusId,
    simWeatherId,
    shareMoveId,
    pearityId,
  };

  /// Supported app package file extensions
  static const List<String> supportedPackageExtensions = ['.apk', '.xapk'];
}

/// Centralised opacity values used across the app.
/// Always prefer these over inline literals.
class AppOpacity {
  AppOpacity._();

  /// Very subtle tint — overlays, shadows (0.1)
  static const double subtle = 0.1;

  /// Low-key fill or tint (0.2)
  static const double low = 0.2;

  /// Medium fill for containers (0.3)
  static const double medium = 0.3;

  /// Moderate fill — selected states (0.4)
  static const double moderate = 0.4;

  /// Half opacity — pulsing badges, placeholders (0.5)
  static const double half = 0.5;

  /// Material ripple / state-layer (0.12)
  static const double hint = 0.12;

  /// Muted secondary text (0.65)
  static const double muted = 0.65;
}

/// Centralised shadow configurations.
/// Uses layered shadows for a "smoother" look.
class AppShadows {
  AppShadows._();

  /// A smooth, multi-layered shadow for glassmorphic elements or "glowing" cards.
  static List<BoxShadow> smooth({
    required Color color,
    double opacity = 0.15,
    double blurFactor = 1.0,
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity * 0.4),
        blurRadius: 24 * blurFactor,
        spreadRadius: -2,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: color.withOpacity(opacity * 0.6),
        blurRadius: 12 * blurFactor,
        spreadRadius: -1,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: 4 * blurFactor,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// A diffuse glow effect for selected or highlighted items.
  static List<BoxShadow> glow({required Color color, double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.2 * intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withOpacity(0.1 * intensity),
        blurRadius: 40,
        spreadRadius: 4,
      ),
    ];
  }
}
