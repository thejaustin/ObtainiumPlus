import 'package:flutter/material.dart';

/// Shows a modal bottom sheet that is draggable from its scrollable content.
Future<T?> showDraggableModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  double initialChildSize = 0.95,
  double minChildSize = 0.5,
  double maxChildSize = 1.0,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: builder,
    ),
  );
}
