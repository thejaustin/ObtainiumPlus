import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/settings/connected_settings_bar.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Representation of a sibling subpage in a group (e.g. Appearance hub sections).
class SettingsSubpageSibling {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final Widget child;

  const SettingsSubpageSibling({
    required this.title,
    this.subtitle,
    required this.icon,
    this.accentColor,
    required this.child,
  });
}

/// A dedicated Material 3 Expressive subpage for settings sections
/// (replacing slide-up bottom sheets) with adaptive width centering,
/// one-handed mode integration, lateral sibling navigation, and native predictive back navigation.
class SettingsSubpage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final List<SettingsSubpageSibling>? siblings;
  final int? currentSiblingIndex;
  final List<ConnectedSettingItem>? connectedItems;
  final Widget child;

  const SettingsSubpage({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.siblings,
    this.currentSiblingIndex,
    this.connectedItems,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final isCompact = plusSettings.plusUseCompactSettings;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);
    final resolvedAccent = accentColor ?? colorScheme.primary;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double hPadding = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;

    return Scaffold(
      body: CustomScrollView(
        physics: plusSettings.scrollPhysics,
        slivers: [
          CustomAppBar(title: title, subtitle: subtitle),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // M3 Expressive Masthead Card
                  if (icon != null) ...[
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
                      color: plusSettings.plusEnableGlassmorphism
                          ? colorScheme.surfaceContainerLow.withValues(
                              alpha: 0.75,
                            )
                          : colorScheme.surfaceContainerLow,
                      shape: CardMetrics.shape(
                        cardRadius,
                        expressive: isM3E,
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.35
                                : 0.65,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -16,
                            right: -16,
                            child: IgnorePointer(
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      resolvedAccent.withValues(alpha: 0.18),
                                      resolvedAccent.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(isCompact ? 12 : 16),
                            child: Row(
                              children: [
                                Container(
                                  width: isCompact ? 38 : 46,
                                  height: isCompact ? 38 : 46,
                                  decoration: ShapeDecoration(
                                    color: resolvedAccent.withValues(
                                      alpha: 0.16,
                                    ),
                                    shape: CardMetrics.shape(
                                      innerRadius,
                                      expressive: isM3E,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: isCompact ? 20 : 24,
                                    color: resolvedAccent,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      if (subtitle != null &&
                                          subtitle!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                height: 1.25,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Lateral Sibling Navigation Bar
                  if (siblings != null && siblings!.length > 1) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: isCompact ? 8 : 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: List.generate(siblings!.length, (index) {
                            final sibling = siblings![index];
                            final isCurrent = index == currentSiblingIndex;
                            final siblingAccent =
                                sibling.accentColor ?? resolvedAccent;
                            final chipRadius = CardMetrics.inner(cardRadius);

                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < siblings!.length - 1 ? 8.0 : 0.0,
                              ),
                              child: ScaleTouchWrapper(
                                hapticOnPressDown: true,
                                scaleDownFactor: 0.94,
                                child: Material(
                                  color: isCurrent
                                      ? siblingAccent.withValues(
                                          alpha: isM3E ? 0.22 : 0.16,
                                        )
                                      : (plusSettings.plusEnableGlassmorphism
                                          ? colorScheme.surfaceContainerLow
                                              .withValues(alpha: 0.72)
                                          : colorScheme.surfaceContainerLow),
                                  shape: CardMetrics.shape(
                                    chipRadius,
                                    expressive: isM3E,
                                    side: BorderSide(
                                      color: isCurrent
                                          ? siblingAccent.withValues(alpha: 0.6)
                                          : colorScheme.outlineVariant
                                              .withValues(
                                                alpha: theme.brightness ==
                                                        Brightness.dark
                                                    ? 0.35
                                                    : 0.65,
                                              ),
                                      width: isCurrent ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: InkWell(
                                    customBorder: CardMetrics.shape(
                                      chipRadius,
                                      expressive: isM3E,
                                    ),
                                    onTap: isCurrent
                                        ? null
                                        : () {
                                            AppHaptics.selectionClick();
                                            Navigator.of(context).pushReplacement(
                                              PageRouteBuilder(
                                                pageBuilder:
                                                    (context, animation, _) =>
                                                        SettingsSubpage(
                                                  title: sibling.title,
                                                  subtitle: sibling.subtitle,
                                                  icon: sibling.icon,
                                                  accentColor:
                                                      sibling.accentColor,
                                                  siblings: siblings,
                                                  currentSiblingIndex: index,
                                                  connectedItems: connectedItems,
                                                  child: sibling.child,
                                                ),
                                                transitionDuration:
                                                    const Duration(
                                                  milliseconds: 240,
                                                ),
                                                reverseTransitionDuration:
                                                    const Duration(
                                                  milliseconds: 200,
                                                ),
                                                transitionsBuilder: (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: CurvedAnimation(
                                                      parent: animation,
                                                      curve:
                                                          Curves.easeOutCubic,
                                                    ),
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompact ? 12.0 : 14.0,
                                        vertical: isCompact ? 8.0 : 9.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            sibling.icon,
                                            size: isCompact ? 16 : 18,
                                            color: isCurrent
                                                ? siblingAccent
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            sibling.title,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: isCurrent
                                                      ? (theme.brightness ==
                                                              Brightness.dark
                                                          ? siblingAccent
                                                          : colorScheme
                                                              .onSurface)
                                                      : colorScheme
                                                          .onSurfaceVariant,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                  child,
                  // Connected Settings Strip at subpage bottom
                  if (connectedItems != null && connectedItems!.isNotEmpty) ...[
                    SizedBox(height: isCompact ? 8 : 12),
                    ConnectedSettingsBar(
                      items: connectedItems!,
                      isCompact: isCompact,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 36),
          ),
        ],
      ),
    );
  }
}
