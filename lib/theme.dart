// Shared layout and motion constants. The app theme itself is built by
// ThemeBuilder in lib/utils/theme_builder.dart.

import 'package:flutter/material.dart';

/// Corner radius for the outer corners of a connected tile run.
const double connectedTileBigRadius = 24;

/// Corner radius for the inner (joined) corners of a connected tile run.
const double connectedTileSmallRadius = 6;

/// Corners for one tile in a connected run: [outer] on the run's ends,
/// [inner] (capped at [outer]) where tiles join. The defaults are the
/// classic 24/6 look; the segmented settings style passes its own radii.
BorderRadius positionalTileRadius({
  required bool isFirst,
  required bool isLast,
  double outer = connectedTileBigRadius,
  double inner = connectedTileSmallRadius,
}) {
  final o = outer < 0 ? 0.0 : outer;
  final i = inner.clamp(0.0, o);
  return BorderRadius.vertical(
    top: Radius.circular(isFirst ? o : i),
    bottom: Radius.circular(isLast ? o : i),
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
  static const EdgeInsets inputContent = EdgeInsets.all(16);
  static const EdgeInsets listOuter = EdgeInsets.fromLTRB(12, 4, 12, 4);
  static const EdgeInsets rowHorizontal = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets sectionHeader = EdgeInsets.fromLTRB(16, 24, 16, 8);
}

abstract final class AppSpacings {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double sectionGap = 20;
  static const double elementGap = 8;
  static const double connectedGap = 3;
  static const double listGap = xs;
}

abstract final class AppRadii {
  static const double inline = 4;
  static const double xs = 8;
  static const double small = 12;
  static const double medium = 16;
  static const double fab = 20;
  static const double large = 24;
  static const double xlarge = 28;
}

/// The type style used for section labels.
TextStyle? sectionHeaderTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
