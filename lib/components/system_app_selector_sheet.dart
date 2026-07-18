import 'package:flutter/material.dart';
import 'package:obtainium/pages/system_app_selector.dart';

/// Shows the system app selector (Import Installed Apps) as a draggable bottom sheet.
Future<T?> showSystemAppSelectorSheet<T>({required BuildContext context}) {
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
          return SystemAppSelector(
            isModal: true,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}
