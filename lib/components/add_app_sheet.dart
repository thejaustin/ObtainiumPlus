import 'package:flutter/material.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/utils/modal_utils.dart';

/// Shows the modern "Add App" bottom sheet with glassmorphism and full-fledged functionality.
/// This wraps AddAppPage in a draggable modal bottom sheet.
Future<T?> showAddAppSheet<T>({
  required BuildContext context,
  String? initialUrl,
  String? appId,
}) {
  return showDraggableModalBottomSheet<T>(
    context: context,
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (context, scrollController) {
      return AddAppPage(
        isModal: true,
        scrollController: scrollController,
        initialUrl: initialUrl,
        appId: appId,
      );
    },
  );
}
