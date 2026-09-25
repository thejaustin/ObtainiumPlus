import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

enum _VisualThemeMode { system, light, dark, amoled }

/// Visual 4-column theme thumbnail picker for Material 3 Expressive settings
class VisualThemeSelector extends StatelessWidget {
  const VisualThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSettings = context.watch<ThemeSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    _VisualThemeMode currentMode;
    if (themeSettings.theme == ThemeSettings.system) {
      currentMode = _VisualThemeMode.system;
    } else if (themeSettings.theme == ThemeSettings.light) {
      currentMode = _VisualThemeMode.light;
    } else if (themeSettings.useBlackTheme) {
      currentMode = _VisualThemeMode.amoled;
    } else {
      currentMode = _VisualThemeMode.dark;
    }

    final options = [
      (
        mode: _VisualThemeMode.system,
        label: tr('followSystem'),
        icon: Icons.brightness_auto_rounded,
      ),
      (
        mode: _VisualThemeMode.light,
        label: tr('light'),
        icon: Icons.light_mode_rounded,
      ),
      (
        mode: _VisualThemeMode.dark,
        label: tr('dark'),
        icon: Icons.dark_mode_rounded,
      ),
      (
        mode: _VisualThemeMode.amoled,
        label: 'AMOLED',
        icon: Icons.nightlife_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  tr('theme'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
          Row(
            children: options.map((opt) {
              final isSelected = opt.mode == currentMode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _ThemeThumbnailCard(
                    mode: opt.mode,
                    label: opt.label,
                    isSelected: isSelected,
                    onTap: () {
                      AppHaptics.selectionClick();
                      switch (opt.mode) {
                        case _VisualThemeMode.system:
                          themeSettings.theme = ThemeSettings.system;
                          themeSettings.useBlackTheme = false;
                          break;
                        case _VisualThemeMode.light:
                          themeSettings.theme = ThemeSettings.light;
                          themeSettings.useBlackTheme = false;
                          break;
                        case _VisualThemeMode.dark:
                          themeSettings.theme = ThemeSettings.dark;
                          themeSettings.useBlackTheme = false;
                          break;
                        case _VisualThemeMode.amoled:
                          themeSettings.theme = ThemeSettings.dark;
                          themeSettings.useBlackTheme = true;
                          break;
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeThumbnailCard extends StatelessWidget {
  final _VisualThemeMode mode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeThumbnailCard({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mockup Window
              Container(
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildMockupPreview(context),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupPreview(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    switch (mode) {
      case _VisualThemeMode.system:
        return Row(
          children: [
            Expanded(
              child: _MockHalf(
                bgColor: const Color(0xFFF6F7F9),
                headerColor: primary.withValues(alpha: 0.35),
                itemColor: const Color(0xFFE2E4E9),
              ),
            ),
            Container(width: 0.8, color: Colors.grey.withValues(alpha: 0.3)),
            Expanded(
              child: _MockHalf(
                bgColor: const Color(0xFF16171B),
                headerColor: primary.withValues(alpha: 0.45),
                itemColor: const Color(0xFF2B2D35),
              ),
            ),
          ],
        );
      case _VisualThemeMode.light:
        return _MockHalf(
          bgColor: const Color(0xFFFAFAFD),
          headerColor: primary.withValues(alpha: 0.35),
          itemColor: const Color(0xFFE5E7EB),
        );
      case _VisualThemeMode.dark:
        return _MockHalf(
          bgColor: const Color(0xFF1E2026),
          headerColor: primary.withValues(alpha: 0.45),
          itemColor: const Color(0xFF2E323D),
        );
      case _VisualThemeMode.amoled:
        return _MockHalf(
          bgColor: const Color(0xFF000000),
          headerColor: primary.withValues(alpha: 0.6),
          itemColor: const Color(0xFF1A1A1A),
        );
    }
  }
}

class _MockHalf extends StatelessWidget {
  final Color bgColor;
  final Color headerColor;
  final Color itemColor;

  const _MockHalf({
    required this.bgColor,
    required this.headerColor,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 7,
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 5,
            width: 18,
            decoration: BoxDecoration(
              color: itemColor,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3.5),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3.5),
            ),
          ),
        ],
      ),
    );
  }
}
