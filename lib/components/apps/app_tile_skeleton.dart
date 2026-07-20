import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:provider/provider.dart';

class AppTileSkeleton extends StatelessWidget {
  final bool isGrid;

  const AppTileSkeleton({super.key, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<ViewSettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    final highlightColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
        : colorScheme.surface;

    if (isGrid) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isCompact = settingsProvider.appListDensity == AppListDensity.compact;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListTile(
        visualDensity: isCompact ? VisualDensity.compact : null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        title: Container(
          width: 150,
          height: 14,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: settingsProvider.displayShowAuthor
            ? Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )
            : null,
        trailing: Container(
          width: 60,
          height: 20,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
