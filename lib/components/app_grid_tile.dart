import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'dart:ui';

class AppGridTile extends StatefulWidget {
  final AppInMemory appInMemory;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool hasUpdate;

  const AppGridTile({
    super.key,
    required this.appInMemory,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.hasUpdate = false,
  });

  @override
  State<AppGridTile> createState() => _AppGridTileState();
}

class _AppGridTileState extends State<AppGridTile> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.hasUpdate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AppGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasUpdate && !oldWidget.hasUpdate) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasUpdate && oldWidget.hasUpdate) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // --- ADAPTIVE LAYOUT DETECTION ---
        final bool isHorizontal = constraints.maxWidth / constraints.maxHeight > 1.5;
        
        // Calculate responsive sizes based on available width
        double availableWidth = constraints.maxWidth - 24; // Account for padding

        // Icon size: adaptive
        double iconSize = isHorizontal 
            ? (constraints.maxHeight * 0.7).clamp(40.0, 100.0)
            : (availableWidth * 0.65).clamp(40.0, 80.0);

        // ... (existing radius/padding logic)
        double iconBorderRadius = (iconSize * 0.18).clamp(8.0, 14.0);
        double cardBorderRadius = (iconSize * 0.21).clamp(10.0, 16.0);
        double padding = (availableWidth * 0.1).clamp(8.0, 12.0);
        double badgeSize = (iconSize * 0.25).clamp(12.0, 18.0);

        if (widget.appInMemory.icon == null) {
          context.read<AppsProvider>().updateAppIcon(widget.appInMemory.app.id);
        }

        final settingsProvider = context.watch<SettingsProvider>();
        final curve = settingsProvider.plusEnableEnhancedAnimations 
            ? (settingsProvider.plusEnableMaterialExpressive 
                ? AppConstants.expressiveStandard 
                : AppConstants.standardStandard)
            : Curves.easeInOut;

        return AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: curve,
          child: ConditionalBlur(
            enabled: settingsProvider.plusEnableGlassmorphism,
            sigma: 10,
            child: AnimatedContainer(
              duration: Duration(milliseconds: settingsProvider.plusEnableEnhancedAnimations ? AppConstants.shortAnimationMs : 200),
              curve: settingsProvider.plusEnableEnhancedAnimations ? Curves.easeOutCubic : Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardBorderRadius),
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7)
                    : widget.hasUpdate
                        ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.12)
                        : Theme.of(context).colorScheme.surface.withOpacity(settingsProvider.plusEnableGlassmorphism ? 0.45 : 1.0),
                border: Border.all(
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : widget.hasUpdate
                          ? Theme.of(context).colorScheme.error.withOpacity(AppOpacity.low)
                          : widget.appInMemory.app.pinned
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                              : Theme.of(context).colorScheme.outline.withOpacity(settingsProvider.plusEnableGlassmorphism ? 0.1 : 0),
                  width: widget.isSelected || widget.appInMemory.app.pinned || widget.hasUpdate ? 1.5 : 0.8,
                ),
                boxShadow: widget.isSelected
                    ? AppShadows.glow(color: Theme.of(context).colorScheme.primary, intensity: 0.6)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardBorderRadius),
                child: Stack(
                  children: [
                    // Glass sheen
                    if (settingsProvider.plusEnableGlassmorphism)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.transparent,
                                Colors.black.withOpacity(0.02),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                    
                    Semantics(
                      label: _buildSemanticLabel(),
                      button: true,
                      selected: widget.isSelected,
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) {
                          setState(() => _isPressed = false);
                          widget.onTap();
                        },
                        onTapCancel: () => setState(() => _isPressed = false),
                        onLongPressStart: (_) {
                          setState(() => _isPressed = true);
                          AppHaptics.mediumImpact();
                        },
                        onLongPressEnd: (_) {
                          setState(() => _isPressed = false);
                          widget.onLongPress();
                        },
                        child: InkWell(
                          onTap: null, // Handled by GestureDetector
                          onLongPress: null, // Handled by GestureDetector
                          borderRadius: BorderRadius.circular(cardBorderRadius),
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: isHorizontal ? _buildHorizontalContent(iconSize, iconBorderRadius, badgeSize, settingsProvider) : _buildVerticalContent(iconSize, iconBorderRadius, badgeSize, settingsProvider),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildVerticalContent(double iconSize, double iconBorderRadius, double badgeSize, SettingsProvider settingsProvider) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _buildIconStack(iconSize, iconBorderRadius, badgeSize),
      const SizedBox(height: 10),
      _buildAppInfo(settingsProvider, TextAlign.center),
    ],
  );
}

Widget _buildHorizontalContent(double iconSize, double iconBorderRadius, double badgeSize, SettingsProvider settingsProvider) {
  return Row(
    children: [
      _buildIconStack(iconSize, iconBorderRadius, badgeSize),
      const SizedBox(width: 20),
      Expanded(child: _buildAppInfo(settingsProvider, TextAlign.start)),
      const Icon(Icons.chevron_right_rounded, opacity: 0.5),
    ],
  );
}

Widget _buildIconStack(double iconSize, double iconBorderRadius, double badgeSize) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Hero(
        tag: 'app_icon_${widget.appInMemory.app.id}',
        child: Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(iconBorderRadius),
            boxShadow: widget.hasUpdate 
                ? AppShadows.smooth(color: Theme.of(context).colorScheme.error, opacity: 0.1)
                : null,
          ),
          child: widget.appInMemory.icon != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(iconBorderRadius),
                  child: Image.memory(
                    widget.appInMemory.icon!,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                )
              : AppIconShimmer(
                  size: iconSize,
                  borderRadius: iconBorderRadius,
                ),
        ),
      ),
      if (widget.hasUpdate)
        Positioned(
          right: -4,
          top: -4,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: AppShadows.glow(
                      color: Theme.of(context).colorScheme.primary,
                      intensity: (_pulseAnimation.value - 1.0) * 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}

Widget _buildAppInfo(SettingsProvider settingsProvider, TextAlign textAlign) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: textAlign == TextAlign.start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
    children: [
      Text(
        widget.appInMemory.name,
        maxLines: 2,
        textAlign: textAlign,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight:
              widget.appInMemory.app.pinned || widget.hasUpdate ? FontWeight.bold : FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      if (settingsProvider.plusShowTagsInList && widget.appInMemory.app.tags.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            alignment: textAlign == TextAlign.start ? WrapAlignment.start : WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: widget.appInMemory.app.tags.take(2).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
        ),
      // Checking / Progress logic...
      _buildProgressIndicator(),
    ],
  );
}

Widget _buildProgressIndicator() {
  return Builder(builder: (ctx) {
    final isChecking = ctx.select<AppsProvider, bool>(
      (p) => p.checkingUpdateIds.contains(widget.appInMemory.app.id),
    );
    if (widget.appInMemory.downloadProgress != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ExpressiveProgressIndicator(
          value: widget.appInMemory.downloadProgress! >= 0
              ? widget.appInMemory.downloadProgress! / 100
              : null,
          height: 4,
        ),
      );
    }
    if (isChecking) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ExpressiveProgressIndicator(value: null, height: 2),
      );
    }
    return const SizedBox.shrink();
  });
}
      },
    );
  }

  /// Builds a semantic label for screen readers
  String _buildSemanticLabel() {
    final StringBuffer label = StringBuffer(widget.appInMemory.name);

    if (widget.hasUpdate) {
      label.write(', ${tr('updateAvailable')}');
    }

    if (widget.appInMemory.installedInfo != null) {
      label.write(', ${tr('installed')}');
    } else {
      label.write(', ${tr('notInstalled')}');
    }

    if (widget.appInMemory.app.pinned) {
      label.write(', pinned');
    }

    if (widget.appInMemory.app.tags.isNotEmpty) {
      label.write(', tags: ${widget.appInMemory.app.tags.join(", ")}');
    }

    if (widget.isSelected) {
      label.write(', selected');
    }

    if (widget.appInMemory.downloadProgress != null) {
      final progress = widget.appInMemory.downloadProgress! >= 0
          ? tr('percentProgress', args: [widget.appInMemory.downloadProgress!.toInt().toString()])
          : tr('installing');
      label.write(', $progress');
    }

    return label.toString();
  }
}
