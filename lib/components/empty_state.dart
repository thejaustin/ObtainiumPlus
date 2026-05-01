import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';

class EmptyStateWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final VoidCallback? onSecondaryActionPressed;
  final String? secondaryActionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onActionPressed,
    this.actionLabel,
    this.onSecondaryActionPressed,
    this.secondaryActionLabel,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: ConditionalBlur(
                    sigma: 10,
                    enabled: settings.plusEnableGlassmorphism,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(
                          settings.plusEnableGlassmorphism ? AppOpacity.moderate : AppOpacity.low,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(
                            settings.plusEnableGlassmorphism ? AppOpacity.low : 0.0,
                          ),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.onActionPressed != null && widget.actionLabel != null) ...[
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: widget.onActionPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      widget.actionLabel!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                if (widget.onSecondaryActionPressed != null && widget.secondaryActionLabel != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: widget.onSecondaryActionPressed,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                    ),
                    icon: const Icon(Icons.explore_rounded),
                    label: Text(widget.secondaryActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
