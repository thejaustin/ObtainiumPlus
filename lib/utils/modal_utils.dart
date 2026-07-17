import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Shows a modal bottom sheet that is draggable from its scrollable content.
Future<T?> showDraggableModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  double initialChildSize = 0.95,
  double minChildSize = 0.5,
  double maxChildSize = 1.0,
  bool useSafeArea = true,
}) {
  final plusSettings = context.read<PlusSettingsProvider>();
  final enableGlass = plusSettings.plusEnableGlassmorphism;
  final scrollController = ScrollController();

  return Navigator.of(context).push<T>(
    ModalSheetRoute<T>(
      swipeDismissible: true,
      barrierColor: Theme.of(
        context,
      ).colorScheme.scrim.withValues(alpha: AppOpacity.medium),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ConditionalBlur(
            enabled: enableGlass,
            sigma: AppConstants.glassBlurSigmaSoft,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(
                  alpha: enableGlass
                      ? AppConstants.glassSurfaceAlphaStrong
                      : 1.0,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                top: useSafeArea,
                child: Sheet(
                  physics: const BouncingSheetPhysics(),
                  scrollConfiguration: const SheetScrollConfiguration(),
                  child: builder(context, scrollController),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
