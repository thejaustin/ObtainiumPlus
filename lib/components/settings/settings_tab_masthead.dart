import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:provider/provider.dart';

class SettingsTabMasthead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? accentColor;

  const SettingsTabMasthead({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isCompact = plusSettings.plusUseCompactSettings;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final isGlass = plusSettings.plusEnableGlassmorphism;
    final resolvedAccent = accentColor ?? colorScheme.primary;

    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);
    final badgeSize = isCompact ? 36.0 : 44.0;
    final iconSize = isCompact ? 18.0 : 22.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 8.0 : 12.0),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isGlass
            ? colorScheme.surfaceContainerLow.withValues(alpha: 0.72)
            : colorScheme.surfaceContainerLow,
        shape: CardMetrics.shape(
          cardRadius,
          expressive: isM3E,
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.35 : 0.65,
            ),
          ),
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(
            shape: CardMetrics.shape(cardRadius, expressive: isM3E),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -18,
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
                        color: resolvedAccent.withValues(alpha: 0.14),
                        shape: CardMetrics.shape(
                          innerRadius,
                          expressive: isM3E,
                        ),
                      ),
                      child: Icon(icon, size: iconSize, color: resolvedAccent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
