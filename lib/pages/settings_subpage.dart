import 'package:flutter/material.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:provider/provider.dart';

/// A dedicated Material 3 Expressive subpage for settings sections
/// (replacing slide-up bottom sheets) with adaptive width centering,
/// one-handed mode integration, and native predictive back navigation.
class SettingsSubpage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final Widget child;

  const SettingsSubpage({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
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
    final double hPadding = screenWidth > 840
        ? ((screenWidth - 840) / 2) + 16.0
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
                  child,
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
