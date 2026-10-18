// Shared layout and motion constants. The app theme itself is built by
// ThemeBuilder in lib/utils/theme_builder.dart.

import 'package:flutter/material.dart';

/// Corner radius for the outer corners of a connected tile run.
const double connectedTileBigRadius = 24;

/// Corner radius for the inner (joined) corners of a connected tile run.
const double connectedTileSmallRadius = 6;

BorderRadius positionalTileRadius({
  required bool isFirst,
  required bool isLast,
}) {
  return BorderRadius.vertical(
    top: Radius.circular(
      isFirst ? connectedTileBigRadius : connectedTileSmallRadius,
    ),
    bottom: Radius.circular(
      isLast ? connectedTileBigRadius : connectedTileSmallRadius,
    ),
  );
}

abstract final class ExpressiveMotion {
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  static const Duration short = Durations.short4;
  static const Duration medium = Durations.medium2;
}

abstract final class AppPaddings {
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets page = EdgeInsets.fromLTRB(16, 0, 16, 0);
  static const EdgeInsets cardInner = EdgeInsets.all(16);
}

abstract final class AppSpacings {
  static const double sectionGap = 20;
  static const double elementGap = 8;
}
