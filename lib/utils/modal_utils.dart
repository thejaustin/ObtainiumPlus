import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/components/common/conditional_blur.dart';

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
    elevation: 0,
    barrierColor: Theme.of(context).colorScheme.scrim.withOpacity(0.3),
    builder: (context) {
      final settings = context.watch<SettingsProvider>();
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: ConditionalBlur(
          enabled: settings.plusEnableGlassmorphism,
          sigma: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(
                settings.plusEnableGlassmorphism ? 0.85 : 1.0,
              ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: initialChildSize,
            minChildSize: minChildSize,
            maxChildSize: maxChildSize,
            expand: false,
            builder: builder,
          ),
        ),
      );
    },
  );
}
