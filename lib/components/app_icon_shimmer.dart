import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppIconShimmer extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AppIconShimmer({super.key, this.size = 48.0, this.borderRadius = 12.0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainer,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
