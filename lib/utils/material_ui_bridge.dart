import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// Some dependencies (animations 3.x, flex_color_picker, cupertino_ui) are
/// built on the decoupled `material_ui` package and read *its* `Theme`, a
/// different InheritedWidget from Flutter's. Without one above them they fall
/// back to the stock light theme — e.g. page transitions filled the System
/// updates tab with a white canvas in dark mode. This mirrors the app's
/// active Flutter theme into a `material_ui` Theme.
class MaterialUiThemeBridge extends StatelessWidget {
  final Widget child;

  const MaterialUiThemeBridge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return mui.Theme(data: materialUiThemeFrom(theme), child: child);
  }
}

mui.ThemeData materialUiThemeFrom(ThemeData theme) {
  final c = theme.colorScheme;
  return mui.ThemeData(
    useMaterial3: true,
    colorScheme: mui.ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      primaryFixed: c.primaryFixed,
      primaryFixedDim: c.primaryFixedDim,
      onPrimaryFixed: c.onPrimaryFixed,
      onPrimaryFixedVariant: c.onPrimaryFixedVariant,
      secondary: c.secondary,
      onSecondary: c.onSecondary,
      secondaryContainer: c.secondaryContainer,
      onSecondaryContainer: c.onSecondaryContainer,
      secondaryFixed: c.secondaryFixed,
      secondaryFixedDim: c.secondaryFixedDim,
      onSecondaryFixed: c.onSecondaryFixed,
      onSecondaryFixedVariant: c.onSecondaryFixedVariant,
      tertiary: c.tertiary,
      onTertiary: c.onTertiary,
      tertiaryContainer: c.tertiaryContainer,
      onTertiaryContainer: c.onTertiaryContainer,
      tertiaryFixed: c.tertiaryFixed,
      tertiaryFixedDim: c.tertiaryFixedDim,
      onTertiaryFixed: c.onTertiaryFixed,
      onTertiaryFixedVariant: c.onTertiaryFixedVariant,
      error: c.error,
      onError: c.onError,
      errorContainer: c.errorContainer,
      onErrorContainer: c.onErrorContainer,
      surface: c.surface,
      onSurface: c.onSurface,
      surfaceDim: c.surfaceDim,
      surfaceBright: c.surfaceBright,
      surfaceContainerLowest: c.surfaceContainerLowest,
      surfaceContainerLow: c.surfaceContainerLow,
      surfaceContainer: c.surfaceContainer,
      surfaceContainerHigh: c.surfaceContainerHigh,
      surfaceContainerHighest: c.surfaceContainerHighest,
      onSurfaceVariant: c.onSurfaceVariant,
      outline: c.outline,
      outlineVariant: c.outlineVariant,
      shadow: c.shadow,
      scrim: c.scrim,
      inverseSurface: c.inverseSurface,
      onInverseSurface: c.onInverseSurface,
      inversePrimary: c.inversePrimary,
      surfaceTint: c.surfaceTint,
    ),
    canvasColor: theme.canvasColor,
    scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
    fontFamily: theme.textTheme.bodyMedium?.fontFamily,
  );
}
