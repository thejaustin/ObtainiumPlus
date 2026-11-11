import 'package:flutter/material.dart';
import 'package:obtainium/theme.dart';

/// Layout tokens for the expressive settings kit (segmented groups, rows,
/// choice groups). Built on the [AppSpacings] scale; only the opt-in
/// segmented style reads them, the classic card style keeps its own values.
abstract final class SettingsTokens {
  /// Horizontal page gutter.
  static const double pageGutter = 16;

  /// Gap between two groups (the group label adds its own top padding).
  static const double groupGap = AppSpacings.elementGap * 2;

  /// Gap between the rows of a segmented group.
  static const double segmentGap = 2;

  /// Padding around an open group label.
  static const EdgeInsets labelPadding = EdgeInsets.fromLTRB(20, 12, 20, 6);

  /// M3E list spec corners: outer (group ends) and inner (joints).
  static const double outerRadius = 16;
  static const double innerRadius = 4;
  static const double maxOuterRadius = 28;

  /// Row geometry.
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(16, 10, 16, 10);
  static const double rowSlotGap = 12;
  static const double rowMinHeight = 56;
  static const double rowMinHeightCompact = 48;
  static const double trailingSlotWidth = 52;
  static const double leadingIconSize = 24;
  static const double leadingIconSizeCompact = 20;

  /// Scale of a pressed row.
  static const double pressedScale = 0.985;

  /// Opacity of a disabled (dependent) row.
  static const double disabledOpacity = 0.38;

  /// Connected choice group geometry.
  static const double choiceHeight = 40;
  static const double choiceInnerRadius = 8;
  static const double choicePressedRadius = 4;

  /// Slider tile padding in the segmented style.
  static const EdgeInsets sliderPadding = EdgeInsets.fromLTRB(16, 8, 16, 8);

  /// Row colour for a segmented group: `surfaceContainer` on a normal page,
  /// one step up when the page itself is pure black (AMOLED theme).
  static Color rowColor(ColorScheme cs) => cs.surface == Colors.black
      ? cs.surfaceContainerHigh
      : cs.surfaceContainer;

  /// Open group label style (never uppercase).
  static TextStyle? labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      );
}
