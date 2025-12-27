import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/apps_provider.dart';

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Card(
        elevation: widget.isSelected ? 8 : 1,
        shadowColor: widget.isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : null,
        surfaceTintColor: widget.isSelected ? Theme.of(context).colorScheme.primary : null,
        color: widget.isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: widget.appInMemory.app.pinned
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: InkWell(
        onTap: widget.onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Stack(
                children: [
                  Hero(
                    tag: 'app_icon_${widget.appInMemory.app.id}',
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: widget.appInMemory.icon != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.apps,
                                size: 32,
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
                      right: -4,
                      top: -4,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 16,
                              height: 16,
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
    );
  }
}
