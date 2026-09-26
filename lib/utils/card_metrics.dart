import 'dart:math';
import 'package:flutter/widgets.dart';

/// One radius system for the cards that compartmentalize apps —
/// dashboard sub-cards, app grid tiles, Discover results, app icons.
///
/// Everything derives from the user's corner-radius setting so the whole
/// app scales together; previously each card picked its own factor and
/// clamp (0.5/0.7/0.75, clamps of 8–20, 10–24, 12–24…) and the grid tile
/// ignored the setting entirely.
class CardMetrics {
  /// Outer radius for compact cards (grid tiles, discover results,
  /// dashboard sub-cards). Caps the user value so small cards don't
  /// turn into pills at high settings.
  static double card(double base) => base.clamp(12.0, 24.0);

  /// Radius for elements nested one level inside a card (app icons,
  /// thumbnails, inner buttons) — reads as concentric with [card].
  static double inner(double base) => (base * 0.5).clamp(8.0, 16.0);

  /// Radius for pill-shaped elements (segmented filter bars, capsule chips, badges)
  /// adhering to Material 3 Expressive guidelines.
  static double pill([double base = 28.0]) => max(24.0, base).clamp(24.0, 32.0);

  /// Outer radius for cards whose size is driven by a measured extent
  /// (e.g. grid tiles sized by column count): the user's radius, kept
  /// proportional to the card so tight layouts stay card-shaped.
  static double cardFor(double base, double extent) =>
      min(card(base), extent * 0.25);
}

/// Standardized Material 3 Expressive layout calculations for app grids.
class GridMetrics {
  /// Calculates responsive column counts adapting to screen width breakpoints.
  static int adaptiveColumns(BuildContext context, {int preferred = 0}) {
    if (preferred > 0) return preferred;
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    if (width >= 400) return 3;
    return 2;
  }

  /// Calculates adaptive child aspect ratio guaranteeing zero vertical overflow
  /// and optimal typography across phone and tablet screens.
  static double childAspectRatio({
    required int columnCount,
    required bool hasExtraDetails,
  }) {
    if (columnCount <= 1) return 2.2;
    if (columnCount == 2) return hasExtraDetails ? 0.88 : 0.98;
    if (columnCount == 3) return hasExtraDetails ? 0.82 : 0.90;
    if (columnCount == 4) return hasExtraDetails ? 0.78 : 0.86;
    return hasExtraDetails ? 0.74 : 0.82;
  }
}
