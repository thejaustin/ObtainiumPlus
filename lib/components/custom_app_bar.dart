import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';

/// A Samsung OneUI inspired AppBar for [CustomScrollView].
///
/// When One-Handed Reachability mode is enabled (`plusEnableOneHandedMode`),
/// the header expands on pull-down / at the top of the screen to bring interactive
/// content into the lower thumb reach area, gracefully shifting and scaling the
/// title from the top-left into the center.
///
/// When collapsed, it pins as a sleek compact toolbar with the title docked
/// on the top-left.
class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.bottom,
    this.actions,
    this.leading,
    this.expandedHeight,
    this.forceOneHanded,
  });

  final String title;
  final String? subtitle;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final Widget? leading;
  final double? expandedHeight;
  final bool? forceOneHanded;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isOneHanded =
        widget.forceOneHanded ?? plusSettings.plusEnableOneHandedMode;
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomHeight = widget.bottom?.preferredSize.height ?? 0.0;

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final effectiveLeading =
        widget.leading ?? (canPop ? const BackButton() : null);

    // OneUI expanded viewing area height (typically ~240-270dp)
    final effectiveExpandedHeight = widget.expandedHeight ??
        (220.0 + bottomHeight + (widget.subtitle != null ? 24.0 : 0.0));

    if (!isOneHanded) {
      // Standard compact pinned AppBar when one-handed mode is off
      return SliverAppBar(
        pinned: true,
        automaticallyImplyLeading: false,
        leading: effectiveLeading,
        backgroundColor: colorScheme.surface.withValues(
          alpha: enableGlass ? AppConstants.glassSurfaceAlpha : 1.0,
        ),
        title: Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        bottom: widget.bottom,
        actions: widget.actions,
      );
    }

    // Authentic OneUI collapsible header
    return SliverAppBar(
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      leading: effectiveLeading,

      backgroundColor: colorScheme.surface,
      expandedHeight: effectiveExpandedHeight,
      collapsedHeight: kToolbarHeight + bottomHeight,
      actions: widget.actions,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

          double t = 1.0;
          if (settings != null) {
            final double delta = settings.maxExtent - settings.minExtent;
            if (delta > 0) {
              t = (1.0 - (settings.maxExtent - settings.currentExtent) / delta)
                  .clamp(0.0, 1.0);
            } else {
              t = 0.0;
            }
          }

          // Smooth OneUI cubic easing curve for organic motion
          final curvedT = Curves.easeInOutCubic.transform(t);

          // Title interpolation: shifts from top-left (curvedT = 0) to center (curvedT = 1)
          final titleAlignment = Alignment.lerp(
            Alignment.centerLeft,
            Alignment.center,
            curvedT,
          )!;

          final fontSize = lerpDouble(20.0, 32.0, curvedT)!;
          final hasLeading = effectiveLeading != null;
          final leftPadding = lerpDouble(
            hasLeading ? 56.0 : 20.0,
            24.0,
            curvedT,
          )!;
          final rightPadding = lerpDouble(
            widget.actions != null && widget.actions!.isNotEmpty ? 56.0 : 20.0,
            24.0,
            curvedT,
          )!;

          // Vertical alignment within viewing area
          final verticalCenterOffset = lerpDouble(
            (topPadding + kToolbarHeight / 2) - 10,
            topPadding + ((effectiveExpandedHeight - bottomHeight - topPadding) / 2) - 14,
            curvedT,
          )!;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Glassmorphic background blur when content is scrolled under
              if (enableGlass && curvedT < 0.8)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: AppConstants.glassBlurSigmaSoft,
                        sigmaY: AppConstants.glassBlurSigmaSoft,
                      ),
                      child: Container(
                        color: colorScheme.surface.withValues(
                          alpha: AppConstants.glassSurfaceAlpha,
                        ),
                      ),
                    ),
                  ),
                ),

              // Title and Subtitle Container
              Positioned(
                top: verticalCenterOffset,
                left: leftPadding,
                right: rightPadding,
                child: Align(
                  alignment: titleAlignment,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: curvedT > 0.5
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        textAlign: curvedT > 0.5
                            ? TextAlign.center
                            : TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: curvedT > 0.4
                              ? FontWeight.w700
                              : FontWeight.bold,
                          letterSpacing: lerpDouble(-0.2, -0.6, curvedT),
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (widget.subtitle != null && curvedT > 0.3) ...[
                        const SizedBox(height: 4),
                        Opacity(
                          opacity: ((curvedT - 0.3) / 0.7).clamp(0.0, 1.0),
                          child: Text(
                            widget.subtitle!,
                            textAlign: curvedT > 0.5
                                ? TextAlign.center
                                : TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom widget (e.g. SearchBar in Settings or Filter chips)
              if (widget.bottom != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: widget.bottom!,
                ),

              // Hairline bottom border when collapsed
              if (curvedT < 0.5)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: ((0.5 - curvedT) / 0.5).clamp(0.0, 1.0),
                    child: Divider(
                      height: 1,
                      thickness: 0.8,
                      color: colorScheme.outlineVariant.withValues(
                        alpha: enableGlass ? 0.35 : 0.2,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
