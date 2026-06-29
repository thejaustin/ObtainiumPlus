import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/app_constants.dart';

class ExpressiveSettingsGroup extends StatelessWidget {
  final String? title;
  final String? description;
  final String? helpText;
  final List<Widget> children;
  final bool isExpandable;
  final bool initiallyExpanded;
  final IconData? icon;
  final VoidCallback? onReset;

  const ExpressiveSettingsGroup({
    super.key,
    this.title,
    this.description,
    this.helpText,
    required this.children,
    this.isExpandable = false,
    this.initiallyExpanded = true,
    this.icon,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final plusSettings = Provider.of<PlusSettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = plusSettings.plusUseCompactSettings;

    final visibleChildren = children.where((child) {
      if (child is SizedBox && child.child == null) return false;
      if (child is Visibility && !child.visible) return false;
      return true;
    }).toList();

    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    Widget content = Column(
      children: List.generate(visibleChildren.length, (index) {
        return Column(
          children: [
            if (isCompact)
              Theme(
                data: Theme.of(context).copyWith(
                  visualDensity: VisualDensity.compact,
                ),
                child: visibleChildren[index],
              )
            else
              visibleChildren[index],
            if (index < visibleChildren.length - 1)
              Divider(
                height: 1,
                indent: isCompact ? 16 : 56,
                endIndent: 16,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(AppOpacity.low),
              ),
          ],
        );
      }),
    );

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusSettingsCornerRadius
        : settings.plusGlobalCornerRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expandable groups show their title inside the ExpansionTile header —
        // suppress the outer label to prevent it rendering twice.
        if (title != null && !isExpandable)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (description != null || helpText != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description ?? helpText!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onReset != null)
                  IconButton(
                    icon: const Icon(Icons.restore_rounded, size: 20),
                    onPressed: onReset,
                    tooltip: 'Reset to default',
                  ),
              ],
            ),
          ),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color:
              (isDark
                      ? Theme.of(context).colorScheme.surfaceContainerLow
                      : Theme.of(context).colorScheme.surface)
                  .withOpacity(settings.plusEnableGlassmorphism ? 0.7 : 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(
                settings.plusEnableGlassmorphism ? 0.4 : 0.2,
              ),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: settings.plusEnableGlassmorphism
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: isExpandable
                        ? ExpansionTile(
                            shape: const RoundedRectangleBorder(
                              side: BorderSide.none,
                            ),
                            collapsedShape: const RoundedRectangleBorder(
                              side: BorderSide.none,
                            ),
                            initiallyExpanded: initiallyExpanded,
                            leading: icon != null
                                ? Icon(
                                    icon,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: isCompact ? 20 : 24,
                                  )
                                : null,
                            title: Text(
                              title ?? 'Settings',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [content],
                          )
                        : content,
                  )
                : isExpandable
                ? ExpansionTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    collapsedShape: const RoundedRectangleBorder(
                      side: BorderSide.none,
                    ),
                    initiallyExpanded: initiallyExpanded,
                    leading: icon != null
                        ? Icon(
                            icon,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    title: Text(
                      title ?? 'Settings',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [content],
                  )
                : content,
          ),
        ),
      ],
    );
  }
}
