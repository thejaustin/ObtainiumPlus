import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/settings/visual_theme_selector.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Compartmentalized Appearance Hub for Material 3 Expressive settings
class AppearanceHub extends StatelessWidget {
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final Widget themeContent;
  final Widget appTileContent;
  final Widget layoutNavContent;
  final Widget motionPhysicsContent;

  const AppearanceHub({
    super.key,
    required this.androidInfoFuture,
    required this.themeContent,
    required this.appTileContent,
    required this.layoutNavContent,
    required this.motionPhysicsContent,
  });

  @override
  Widget build(BuildContext context) {
    final themeSettings = context.watch<ThemeSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final viewSettings = context.watch<ViewSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Summaries
    String themeSummary = themeSettings.theme == ThemeSettings.system
        ? tr('followSystem')
        : (themeSettings.useBlackTheme
            ? 'AMOLED'
            : (themeSettings.theme == ThemeSettings.light
                ? tr('light')
                : tr('dark')));
    if (themeSettings.useMaterialYou) {
      themeSummary += ' · Monet';
    }

    final List<String> tileDecor = [];
    if (plusSettings.plusPinnedBorderAccent) tileDecor.add('Pinned border');
    if (plusSettings.plusCategoryAccentRibbon) tileDecor.add('Category ribbon');
    if (plusSettings.plusUpdateExpressiveBadge) tileDecor.add('Update pill');
    if (plusSettings.plusIconRimBorder) tileDecor.add('Icon rim');
    final tileSummary = tileDecor.isEmpty
        ? tr('plusAppTileStyling')
        : tileDecor.take(2).join(' · ');

    final layoutSummary =
        '${viewSettings.viewMode.name.toUpperCase()} · ${viewSettings.appListDensity.name}';

    final List<String> motionDecor = [];
    if (plusSettings.plusEnableGlassmorphism) motionDecor.add('Glass');
    if (plusSettings.plusEnableBouncyPhysics) motionDecor.add('Bouncy');
    if (plusSettings.plusEnableEnhancedAnimations) motionDecor.add('Smooth');
    final motionSummary = motionDecor.isEmpty
        ? 'Corner: ${plusSettings.plusGlobalCornerRadius.round()}dp'
        : '${motionDecor.join(" · ")} · ${plusSettings.plusGlobalCornerRadius.round()}dp';

    final hubCards = [
      (
        icon: Icons.palette_rounded,
        title: tr('settingsAppearanceThemesAndColors'),
        desc: tr('settingsAppearanceThemesAndColorsDesc'),
        summary: themeSummary,
        color: colorScheme.primary,
        content: themeContent,
      ),
      (
        icon: Icons.style_rounded,
        title: tr('settingsAppearanceAppTileStyling'),
        desc: tr('settingsAppearanceAppTileStylingDesc'),
        summary: tileSummary,
        color: colorScheme.secondary,
        content: appTileContent,
      ),
      (
        icon: Icons.dashboard_customize_outlined,
        title: tr('settingsAppearanceLayoutNav'),
        desc: tr('settingsAppearanceLayoutNavDesc'),
        summary: layoutSummary,
        color: colorScheme.tertiary,
        content: layoutNavContent,
      ),
      (
        icon: Icons.auto_awesome_motion_rounded,
        title: tr('settingsAppearanceMotionPhysics'),
        desc: tr('settingsAppearanceMotionPhysicsDesc'),
        summary: motionSummary,
        color: colorScheme.primary,
        content: motionPhysicsContent,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: hubCards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HubCard(
              icon: card.icon,
              title: card.title,
              desc: card.desc,
              summary: card.summary,
              accentColor: card.color,
              onTap: () {
                AppHaptics.selectionClick();
                _showAppearanceSubmenuSheet(
                  context,
                  title: card.title,
                  icon: card.icon,
                  accentColor: card.color,
                  child: card.content,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAppearanceSubmenuSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    final plusSettings = context.read<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ConditionalBlur(
            sigma: 16,
            enabled: plusSettings.plusEnableGlassmorphism,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.surface)
                    .withValues(
                      alpha: plusSettings.plusEnableGlassmorphism ? 0.9 : 1.0,
                    ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accentColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String summary;
  final Color accentColor;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.summary,
    required this.accentColor,
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        summary,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
