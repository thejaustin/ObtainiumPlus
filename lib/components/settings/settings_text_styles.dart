import 'package:flutter/material.dart';

/// Title style shared by every settings row (toggles, links, choice rows),
/// so rows built from different widgets read as one list. Compact density
/// uses a smaller medium-weight title; otherwise the list tile theme's.
TextStyle? settingsRowTitleStyle(
  BuildContext context, {
  required bool compact,
}) {
  final theme = Theme.of(context);
  return compact
      ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
      : theme.listTileTheme.titleTextStyle;
}

/// Subtitle style matching [settingsRowTitleStyle].
TextStyle? settingsRowSubtitleStyle(
  BuildContext context, {
  required bool compact,
}) {
  final theme = Theme.of(context);
  return compact
      ? theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        )
      : theme.listTileTheme.subtitleTextStyle;
}
