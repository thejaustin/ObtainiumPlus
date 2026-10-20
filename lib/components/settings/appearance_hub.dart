import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
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
    final isCompact = plusSettings.plusUseCompactSettings;

    // Summaries
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    String themeSummary =
        '${isM3E ? 'M3E' : 'Obtainium+'} · ${themeSettings.theme == ThemeSettings.system ? tr('followSystem') : (themeSettings.useBlackTheme ? 'AMOLED' : (themeSettings.theme == ThemeSettings.light ? tr('light') : tr('dark')))}';
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
        '${viewSettings.globalViewMode.name.toUpperCase()} · ${viewSettings.appListDensity.name}${isCompact ? ' · Compact' : ''}';

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

    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);
    final badgeSize = isCompact ? 30.0 : 36.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: isCompact ? 6 : 10),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: plusSettings.plusEnableGlassmorphism
                  ? colorScheme.surfaceContainerLow.withValues(alpha: 0.7)
                  : colorScheme.surfaceContainerLow,
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
              child: Padding(
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
                            shape: CardMetrics.shape(
                              innerRadius,
                              expressive: isM3E,
                            ),
                          ),
                          child: Icon(
                            isM3E
                                ? Icons.brush_rounded
                                : Icons.auto_awesome_rounded,
                            size: isCompact ? 16 : 18,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('designSystemThemeStyle'),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                              if (!isCompact) ...[
                                const SizedBox(height: 2),
                                Text(
                                  isM3E
                                      ? tr('materialExpressiveThemeDescription')
                                      : tr('obtainiumPlusThemeDescription'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        style: SegmentedButton.styleFrom(
                          visualDensity: isCompact
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                        ),
                        segments: [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text(tr('obtainiumPlusTheme')),
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                            ),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text(tr('materialExpressiveTheme')),
                            icon: const Icon(Icons.brush_rounded, size: 16),
                          ),
                        ],
                        selected: {isM3E},
                        onSelectionChanged: (Set<bool> newSelection) {
                          final next = newSelection.first;
                          next ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                          plusSettings.plusEnableMaterialExpressive = next;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...hubCards.map((card) {
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
          }),
        ],
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
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final sheetRadius = Radius.circular(radius.clamp(20.0, 36.0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: sheetRadius),
              child: ConditionalBlur(
                sigma: 16,
                enabled: plusSettings.plusEnableGlassmorphism,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.88,
                  decoration: BoxDecoration(
                    color: plusSettings.plusEnableGlassmorphism
                        ? colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.9,
                          )
                        : (Theme.of(context).brightness == Brightness.dark
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surfaceContainerLow),
                    borderRadius: BorderRadius.vertical(top: sheetRadius),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.65,
                        ),
                        width: 1.0,
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
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: tr('close'),
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
                    color: accentColor.withValues(alpha: 0.14),
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
                        style:
                            (isCompact
                                    ? theme.textTheme.bodyMedium
                                    : theme.textTheme.bodyLarge)
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
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
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                          shape: CardMetrics.shape(
                            CardMetrics.pill(baseRadius),
                            expressive: isM3E,
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
