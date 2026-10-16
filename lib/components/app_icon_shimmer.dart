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
        ? colorScheme.primaryContainer.withValues(alpha: 0.20)
        : colorScheme.primaryContainer.withValues(alpha: 0.35);
    final highlightColor = isDark
        ? colorScheme.primaryContainer.withValues(alpha: 0.55)
        : colorScheme.primaryContainer.withValues(alpha: 0.80);

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
