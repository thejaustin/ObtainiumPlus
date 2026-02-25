import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
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
            padding: const EdgeInsets.only(left: 20.0, top: 24.0, bottom: 8.0),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
              sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                color: (isDark 
                    ? Theme.of(context).colorScheme.surfaceContainerHigh 
                    : Theme.of(context).colorScheme.surface)
                  .withValues(alpha: settings.plusEnableGlassmorphism ? 0.7 : 1.0),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(
                    alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.2
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
                          indent: 16,
                          endIndent: 16,
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
