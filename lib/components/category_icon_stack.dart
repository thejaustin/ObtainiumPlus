import 'package:flutter/material.dart';
import 'dart:typed_data';

class CategoryIconStack extends StatelessWidget {
  final List<Uint8List?> icons;
  final int maxIcons;
  final double iconSize;
  final double overlapPercentage;

  const CategoryIconStack({
    super.key,
    required this.icons,
    this.maxIcons = 6,
    this.iconSize = 32,
    this.overlapPercentage = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out null icons and limit to maxIcons
    final validIcons =
        icons.where((icon) => icon != null).take(maxIcons).toList();

    if (validIcons.isEmpty) {
      return const SizedBox.shrink();
    }

    final overlapOffset = iconSize * (1 - overlapPercentage);
    final totalWidth = validIcons.length == 1
        ? iconSize
        : iconSize + (overlapOffset * (validIcons.length - 1));

    return SizedBox(
      width: totalWidth,
      height: iconSize,
      child: Stack(
        children: validIcons.asMap().entries.map((entry) {
          final index = entry.key;
          final icon = entry.value;

          return Positioned(
            left: index * overlapOffset,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.memory(
                  icon!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
