import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/app_constants.dart';

class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final String? helpText;
  final VoidCallback? onReset;

  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
    this.helpText,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    // Use listen: false to avoid type mismatch issues when nested in specialized Consumers
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Robustly filter out hidden/empty widgets
    final visibleChildren = children.where((child) {
      if (child is SizedBox && child.child == null) return false;
      if (child is Visibility && !child.visible) return false;
      return true;
    }).toList();

    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              top: 24.0,
              bottom: 8.0,
              right: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (helpText != null)
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    onPressed: () => _showHelp(context),
                    visualDensity: VisualDensity.compact,
                    tooltip: tr('help'),
                  ),
                if (onReset != null)
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    onPressed: onReset,
                    visualDensity: VisualDensity.compact,
                    tooltip: tr('resetToDefault'),
                  ),
              ],
            ),
          ),
        Consumer<PlusSettingsProvider>(
          builder: (context, settings, _) {
            final radius = settings.plusOverrideIndividualCornerRadius
                ? settings.plusSettingsCornerRadius
                : settings.plusGlobalCornerRadius;

            final container = Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? Theme.of(context).colorScheme.surfaceContainerLow
                            : Theme.of(context).colorScheme.surface)
                        .withValues(
                          alpha: settings.plusEnableGlassmorphism ? 0.7 : 1.0,
                        ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(
                        alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.2,
                      ),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(visibleChildren.length, (index) {
                  return Column(
                    children: [
                      visibleChildren[index],
                      if (index < visibleChildren.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                          color: Theme.of(context).colorScheme.outlineVariant
                              .withValues(alpha: AppOpacity.low),
                        ),
                    ],
                  );
                }),
              ),
            );
            if (!settings.plusEnableGlassmorphism) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: container,
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: container,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        title: tr('help'),
        icon: Icons.help_outline_rounded,
        content: Text(helpText!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('ok')),
          ),
        ],
      ),
    );
  }
}
