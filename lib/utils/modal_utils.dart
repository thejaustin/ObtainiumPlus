import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
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
  final plusSettings = context.read<PlusSettingsProvider>();
  final enableGlass = plusSettings.plusEnableGlassmorphism;
  final radius = plusSettings.plusOverrideIndividualCornerRadius
      ? plusSettings.plusHomeCornerRadius
      : plusSettings.plusGlobalCornerRadius;
  final sheetRadius = Radius.circular(radius.clamp(20.0, 36.0));

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: false, // Handled internally
    barrierColor: Theme.of(
      context,
    ).colorScheme.scrim.withValues(alpha: AppOpacity.medium),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: sheetRadius),
            child: ConditionalBlur(
              enabled: enableGlass,
              sigma: AppConstants.glassBlurSigmaSoft,
              child: Container(
                decoration: BoxDecoration(
                  color: enableGlass
                      ? Theme.of(context).colorScheme.surface.withValues(
                          alpha: AppConstants.glassSurfaceAlphaStrong,
                        )
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.vertical(top: sheetRadius),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant
                          .withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.35
                                : 0.65,
                          ),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  top: useSafeArea,
                  child: builder(context, scrollController),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
