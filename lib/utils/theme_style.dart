import 'package:flutter/material.dart';
import 'package:obtainium/models/settings_enums.dart';

/// Seed shared with upstream Obtainium.
const Color obtainiumSeedColor = Color(0xFF6438B5);

/// Seed for the gold accent used by the Plus styles. Only its tonal palette is
/// used (see [applyPlusAccent]); no gold hex ends up in the UI directly, so
/// the on-colors keep the contrast guarantees of the M3 tone math.
const Color plusAccentSeed = Color(0xFFE0A526);

/// Variant used when the user has not picked one explicitly.
DynamicSchemeVariant defaultVariantFor(AppThemeStyle style) =>
    style.isExpressive
    ? DynamicSchemeVariant.expressive
    : DynamicSchemeVariant.tonalSpot;

/// Re-points the tertiary roles of [base] at a gold tonal palette for the Plus
/// styles; any other style returns [base] unchanged. Primary stays on the
/// user's colour (purple by default), gold becomes the highlight.
ColorScheme applyPlusAccent(ColorScheme base, AppThemeStyle style) {
  if (!style.isPlus) return base;
  final gold = ColorScheme.fromSeed(
    seedColor: plusAccentSeed,
    brightness: base.brightness,
  );
  return base.copyWith(
    tertiary: gold.primary,
    onTertiary: gold.onPrimary,
    tertiaryContainer: gold.primaryContainer,
    onTertiaryContainer: gold.onPrimaryContainer,
  );
}
