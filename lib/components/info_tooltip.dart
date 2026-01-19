import 'package:flutter/material.dart';

class InfoTooltip extends StatelessWidget {
  final String message;
  final double size;
  final EdgeInsets padding;

  const InfoTooltip({
    super.key,
    required this.message,
    this.size = 20.0,
    this.padding = const EdgeInsets.only(left: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Tooltip(
        message: message,
        triggerMode: TooltipTriggerMode.tap,
        child: Icon(Icons.info_outline, size: size, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
