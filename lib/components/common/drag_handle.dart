import 'package:flutter/material.dart';

/// Standardized drag handle for bottom sheets and panels.
class DragHandle extends StatelessWidget {
  final double width;
  final Color? color;
  final EdgeInsets margin;

  const DragHandle({
    super.key,
    this.width = 32,
    this.color,
    this.margin = const EdgeInsets.only(top: 12, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
