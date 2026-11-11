import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/pages/settings_subpage.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Look & motion hub: Theme & colour, Shapes, Motion & haptics and
/// Settings page, each opening its own subpage.
class AppearanceHub extends StatelessWidget {
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final Widget themeContent;
  final Widget shapesContent;
  final Widget motionContent;
  final Widget settingsPageContent;

  const AppearanceHub({
    super.key,
    required this.androidInfoFuture,
    required this.themeContent,
    required this.shapesContent,
    required this.motionContent,
    required this.settingsPageContent,
  });

  /// Every subpage body, in card order (the settings tree test mounts them).
  List<Widget> get contents => [
    themeContent,
    shapesContent,
    motionContent,
    settingsPageContent,
  ];

  @override
  Widget build(BuildContext context) {
    final themeSettings = context.watch<ThemeSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = plusSettings.plusUseCompactSettings;

    // Summaries
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    String themeSummary =
        '${isM3E ? 'M3E' : 'Obtainium+'} · ${themeSettings.theme == ThemeSettings.system ? tr('followSystem') : (themeSettings.useBlackTheme ? 'AMOLED' : (themeSettings.theme == ThemeSettings.light ? tr('light') : tr('dark')))}';
    if (themeSettings.useMaterialYou) {
      themeSummary += ' · Monet';
    }

    final radiusDp = plusSettings.plusGlobalCornerRadius.round();
    final shapesSummary = tr('hubSummaryCornerDp', args: ['$radiusDp']);

    final List<String> motionDecor = [];
    if (plusSettings.plusEnableEnhancedAnimations) {
      motionDecor.add(tr('hubSummarySmooth'));
    }
    if (plusSettings.plusEnableBouncyPhysics) {
      motionDecor.add(tr('hubSummaryBouncy'));
    }
    final motionSummary = motionDecor.isEmpty
        ? tr('settingsAppearanceMotionHaptics')
        : motionDecor.join(' · ');

    final placement = switch (plusSettings.plusSettingsNavPlacement) {
      SettingsNavPlacement.bottom => tr('visualLabBottom'),
      SettingsNavPlacement.top => tr('visualLabTop'),
      SettingsNavPlacement.merged => tr('visualLabMerged'),
    };
    final settingsPageSummary = isCompact
        ? '$placement · ${tr('hubSummaryCompact')}'
        : placement;

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
        icon: Icons.rounded_corner_rounded,
        title: tr('settingsAppearanceShapes'),
        desc: tr('settingsAppearanceShapesDesc'),
        summary: shapesSummary,
        color: colorScheme.primary,
        content: shapesContent,
      ),
      (
        icon: Icons.auto_awesome_motion_rounded,
        title: tr('settingsAppearanceMotionHaptics'),
        desc: tr('settingsAppearanceMotionHapticsDesc'),
        summary: motionSummary,
        color: colorScheme.primary,
        content: motionContent,
      ),
      (
        icon: Icons.dashboard_customize_outlined,
        title: tr('settingsAppearanceSettingsPage'),
        desc: tr('settingsAppearanceSettingsPageDesc'),
        summary: settingsPageSummary,
        color: colorScheme.primary,
        content: settingsPageContent,
      ),
    ];

    final appearanceSiblings = hubCards.map((card) {
      return SettingsSubpageSibling(
        title: card.title,
        subtitle: card.desc,
        icon: card.icon,
        accentColor: card.color,
        child: card.content,
      );
    }).toList();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool useTwoColumns = constraints.maxWidth >= 560;
              final spacing = isCompact ? 8.0 : 12.0;

              if (useTwoColumns) {
                final cardWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: isCompact ? 6 : 10,
                  children: hubCards.asMap().entries.map((entry) {
                    final index = entry.key;
                    final card = entry.value;
                    return SizedBox(
                      width: cardWidth,
                      child: _HubCard(
                        icon: card.icon,
                        title: card.title,
                        desc: card.desc,
                        summary: card.summary,
                        accentColor: card.color,
                        isCompact: isCompact,
                        onTap: () {
                          AppHaptics.selectionClick();
                          pushRoute(
                            context,
                            SettingsSubpage(
                              title: card.title,
                              subtitle: card.desc,
                              icon: card.icon,
                              accentColor: card.color,
                              siblings: appearanceSiblings,
                              currentSiblingIndex: index,
                              child: card.content,
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: hubCards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isCompact ? 6 : 10),
                    child: _HubCard(
                      icon: card.icon,
                      title: card.title,
                      desc: card.desc,
                      summary: card.summary,
                      accentColor: card.color,
                      isCompact: isCompact,
                      onTap: () {
                        AppHaptics.selectionClick();
                        pushRoute(
                          context,
                          SettingsSubpage(
                            title: card.title,
                            subtitle: card.desc,
                            icon: card.icon,
                            accentColor: card.color,
                            siblings: appearanceSiblings,
                            currentSiblingIndex: index,
                            child: card.content,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String summary;
  final Color accentColor;
  final bool isCompact;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.summary,
    required this.accentColor,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);
    final badgeSize = isCompact ? 30.0 : 36.0;

    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final cardShape = CardMetrics.shape(
      cardRadius,
      expressive: isM3E,
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.35 : 0.65,
        ),
        width: 1.0,
      ),
    );

    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: cardShape,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 14 : 16,
              vertical: isCompact ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: ShapeDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: CardMetrics.shape(innerRadius, expressive: isM3E),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: isCompact ? 16 : 19,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // Same level as the other settings group headers.
                        style:
                            (isCompact
                                    ? theme.textTheme.titleSmall
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                  color: colorScheme.onSurface,
                                ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: theme.listTileTheme.subtitleTextStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: isCompact ? 4 : 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: isCompact ? 2 : 3,
                        ),
                        decoration: ShapeDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          shape: CardMetrics.shape(
                            CardMetrics.pill(baseRadius),
                            expressive: isM3E,
                            side: BorderSide(
                              color: accentColor.withValues(alpha: 0.24),
                              width: 0.8,
                            ),
                          ),
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
                  size: isCompact ? 18 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
