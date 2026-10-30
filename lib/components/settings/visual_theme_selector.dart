import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

enum _VisualThemeMode { system, light, dark, amoled }

/// Visual 4-column theme thumbnail picker for Material 3 Expressive settings
class VisualThemeSelector extends StatelessWidget {
  final bool embedded;
  const VisualThemeSelector({super.key, this.embedded = false});

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
        // Tiles are ~80dp wide on phones; "Follow system" truncated there.
        label: tr('system'),
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

    final plusSettings = context.watch<PlusSettingsProvider>();
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final isCompact = plusSettings.plusUseCompactSettings;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);
    final badgeSize = isCompact ? 30.0 : 36.0;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 16,
        isCompact ? 10 : 14,
        isCompact ? 14 : 16,
        isCompact ? 10 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: ShapeDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  shape: CardMetrics.shape(innerRadius, expressive: isM3E),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  size: isCompact ? 16 : 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tr('theme'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 12),
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
                    isCompact: isCompact,
                    onTap: () {
                      AppHaptics.segmentTick();
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

    if (embedded) return body;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 3 : 6),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: CardMetrics.shape(
          cardRadius,
          expressive: isM3E,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.35
                  : 0.65,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

class _ThemeThumbnailCard extends StatelessWidget {
  final _VisualThemeMode mode;
  final String label;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _ThemeThumbnailCard({
    required this.mode,
    required this.label,
    required this.isSelected,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final animsEnabled = plusSettings.plusEnableEnhancedAnimations;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.inner(CardMetrics.card(baseRadius));
    final innerRadius = CardMetrics.inner(cardRadius);

    return ScaleTouchWrapper(
      hapticOnPressDown: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: CardMetrics.shape(cardRadius, expressive: isM3E),
          child: AnimatedContainer(
            duration: Duration(milliseconds: animsEnabled ? 220 : 0),
            curve: AppConstants.expressiveDecelerate,
            padding: EdgeInsets.all(isCompact ? 4 : 6),
            decoration: ShapeDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              shape: CardMetrics.shape(
                cardRadius,
                expressive: isM3E,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.35
                              : 0.65,
                        ),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mockup Window
                Container(
                  height: isCompact ? 42 : 58,
                  decoration: ShapeDecoration(
                    shape: CardMetrics.shape(
                      innerRadius,
                      expressive: isM3E,
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.5)
                            : colorScheme.outlineVariant.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildMockupPreview(context),
                ),
                SizedBox(height: isCompact ? 4 : 6),
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
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
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
            Container(
              width: 0.8,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
