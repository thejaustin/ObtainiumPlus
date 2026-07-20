import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppIconShimmer extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AppIconShimmer({super.key, this.size = 48.0, this.borderRadius = 12.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    final highlightColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
        : colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
