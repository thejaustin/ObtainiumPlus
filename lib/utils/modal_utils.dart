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
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.65,
                        ),
                    width: 1,
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

/// Width from which detail pages can open as a side sheet.
const double kSideSheetBreakpoint = 840;

/// Opens app details: a side sheet on wide screens when the responsive
/// layout setting is on, otherwise the usual draggable bottom sheet.
Future<T?> showAdaptiveDetailSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
}) {
  final plusSettings = context.read<PlusSettingsProvider>();
  final width = MediaQuery.sizeOf(context).width;
  if (!plusSettings.plusEnableResponsiveAppLayout ||
      width < kSideSheetBreakpoint) {
    return showDraggableModalBottomSheet<T>(context: context, builder: builder);
  }
  final radius = plusSettings.plusOverrideIndividualCornerRadius
      ? plusSettings.plusHomeCornerRadius
      : plusSettings.plusGlobalCornerRadius;
  final sheetRadius = Radius.circular(radius.clamp(20.0, 36.0));
  final sheetWidth = (width * 0.45).clamp(360.0, 560.0);
  final anims = plusSettings.plusEnableEnhancedAnimations;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel:
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.modalBarrierDismissLabel ??
        'Dismiss',
    barrierColor: Theme.of(
      context,
    ).colorScheme.scrim.withValues(alpha: AppOpacity.medium),
    transitionDuration: Duration(milliseconds: anims ? 320 : 0),
    pageBuilder: (context, _, _) => Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: sheetWidth,
        height: double.infinity,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.horizontal(
              start: sheetRadius,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            left: false,
            right: false,
            bottom: false,
            child: _OwnedScrollController(builder: builder),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Easing.emphasizedDecelerate,
        reverseCurve: Easing.emphasizedAccelerate,
      );
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return SlideTransition(
        position: Tween(
          begin: Offset(rtl ? -1 : 1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class _OwnedScrollController extends StatefulWidget {
  final Widget Function(BuildContext, ScrollController) builder;

  const _OwnedScrollController({required this.builder});

  @override
  State<_OwnedScrollController> createState() => _OwnedScrollControllerState();
}

class _OwnedScrollControllerState extends State<_OwnedScrollController> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
