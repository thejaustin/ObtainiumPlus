import 'package:flutter/material.dart';
import 'package:obtainium/pages/add_app.dart';

/// Shows the modern "Add App" bottom sheet with glassmorphism and full-fledged functionality.
/// This wraps AddAppPage in a draggable modal bottom sheet.
Future<T?> showAddAppSheet<T>({
  required BuildContext context,
  String? initialUrl,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    elevation: 0,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return AddAppPage(
            isModal: true,
            scrollController: scrollController,
            initialUrl: initialUrl,
          );
        },
      );
    },
  );
}
