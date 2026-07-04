import 'dart:math';

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

  /// Outer radius for cards whose size is driven by a measured extent
  /// (e.g. grid tiles sized by column count): the user's radius, kept
  /// proportional to the card so tight layouts stay card-shaped.
  static double cardFor(double base, double extent) =>
      min(card(base), extent * 0.25);
}
