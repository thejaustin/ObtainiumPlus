import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/utils/app_constants.dart';

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
        // Calculate responsive sizes based on available width
        double availableWidth = constraints.maxWidth - 24; // Account for padding

        // Icon size: 60-70% of available width (min 40, max 80)
        double iconSize = (availableWidth * 0.65).clamp(40.0, 80.0);

        // Border radius: proportional to icon size for consistent appearance
        double iconBorderRadius = (iconSize * 0.18).clamp(8.0, 14.0);

        // Card border radius: slightly larger for card container
        double cardBorderRadius = (iconSize * 0.21).clamp(10.0, 16.0);

        // Padding: scale with grid size (min 8, max 12)
        double padding = (availableWidth * 0.1).clamp(8.0, 12.0);

        // Badge size: proportional to icon size (min 12, max 18)
        double badgeSize = (iconSize * 0.25).clamp(12.0, 18.0);

        // Placeholder icon size: proportional to icon size
        double placeholderIconSize = (iconSize * 0.57).clamp(24.0, 48.0);

        return AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: AppConstants.expressiveStandard,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: AppConstants.shortAnimationMs),
            curve: Curves.easeOutCubic,
            child: Card(
              elevation: widget.isSelected ? 8 : 1,
              shadowColor: widget.isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : null,
              surfaceTintColor: widget.isSelected ? Theme.of(context).colorScheme.primary : null,
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardBorderRadius),
                side: widget.appInMemory.app.pinned
                    ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: Semantics(
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
                  HapticFeedback.mediumImpact();
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: 'app_icon_${widget.appInMemory.app.id}',
                        child: SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: widget.appInMemory.icon != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(iconBorderRadius),
                                  child: Image.memory(
                                    widget.appInMemory.icon!,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    opacity: AlwaysStoppedAnimation(
                                      widget.appInMemory.installedInfo == null ? 0.6 : 1,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(iconBorderRadius),
                                  ),
                                  child: Icon(
                                    Icons.apps,
                                    size: placeholderIconSize,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      // Update indicator badge with pulsing animation
                      if (widget.hasUpdate)
                        Positioned(
                          right: 0,
                          top: 0,
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                        blurRadius: 4 * _pulseAnimation.value,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // App Name
                  Text(
                    widget.appInMemory.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          widget.appInMemory.app.pinned ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  // Download progress
                  if (widget.appInMemory.downloadProgress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(
                          value: widget.appInMemory.downloadProgress! >= 0
                              ? widget.appInMemory.downloadProgress! / 100
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a semantic label for screen readers
  String _buildSemanticLabel() {
    final StringBuffer label = StringBuffer(widget.appInMemory.name);

    if (widget.hasUpdate) {
      label.write(', update available');
    }

    if (widget.appInMemory.installedInfo != null) {
      label.write(', installed');
    } else {
      label.write(', not installed');
    }

    if (widget.appInMemory.app.pinned) {
      label.write(', pinned');
    }

    if (widget.isSelected) {
      label.write(', selected');
    }

    if (widget.appInMemory.downloadProgress != null) {
      final progress = widget.appInMemory.downloadProgress! >= 0
          ? '${widget.appInMemory.downloadProgress}%'
          : 'in progress';
      label.write(', downloading $progress');
    }

    return label.toString();
  }
}
