import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_constants.dart';

class EmptyStateWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: onActionPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            if (onSecondaryActionPressed != null && secondaryActionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onSecondaryActionPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded),
                label: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
