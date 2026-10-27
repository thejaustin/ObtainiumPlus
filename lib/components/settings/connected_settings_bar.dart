import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Representation of a related or connected setting link.
class ConnectedSettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback onTap;

  const ConnectedSettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor,
    required this.onTap,
  });
}

/// Material 3 Expressive connected settings jump hub.
///
/// Discovers and presents logically connected settings, tools, and subpages
/// across ObtainiumPlus so users can fluidly jump between related preferences.
class ConnectedSettingsBar extends StatelessWidget {
  final String? title;
  final String? description;
  final List<ConnectedSettingItem> items;
  final bool isCompact;

  const ConnectedSettingsBar({
    super.key,
    this.title,
    this.description,
    required this.items,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final isGlass = plusSettings.plusEnableGlassmorphism;

    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);
    final badgeSize = isCompact ? 32.0 : 38.0;

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 8.0 : 12.0),
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12.0 : 16.0,
            isCompact ? 10.0 : 14.0,
            isCompact ? 12.0 : 16.0,
            isCompact ? 12.0 : 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: ShapeDecoration(
                      color: colorScheme.secondary.withValues(
                        alpha: isM3E ? 0.18 : 0.12,
                      ),
                      shape: CardMetrics.shape(innerRadius, expressive: isM3E),
                    ),
                    child: Icon(
                      Icons.alt_route_rounded,
                      size: isCompact ? 17 : 20,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? tr('relatedSettings'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          description ?? tr('relatedSettingsDesc'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 10 : 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool useTwoColumns = constraints.maxWidth >= 540;
                  final spacing = isCompact ? 6.0 : 8.0;

                  if (useTwoColumns) {
                    final itemWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: items.map((item) {
                        return SizedBox(
                          width: itemWidth,
                          child: _ConnectedChip(
                            item: item,
                            innerRadius: innerRadius,
                            isCompact: isCompact,
                            isM3E: isM3E,
                          ),
                        );
                      }).toList(),
                    );
                  }

                  return Column(
                    children: items.map((item) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: _ConnectedChip(
                          item: item,
                          innerRadius: innerRadius,
                          isCompact: isCompact,
                          isM3E: isM3E,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedChip extends StatelessWidget {
  final ConnectedSettingItem item;
  final double innerRadius;
  final bool isCompact;
  final bool isM3E;

  const _ConnectedChip({
    required this.item,
    required this.innerRadius,
    required this.isCompact,
    required this.isM3E,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedAccent = item.accentColor ?? colorScheme.primary;
    final itemShape = CardMetrics.shape(
      innerRadius,
      expressive: isM3E,
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.28 : 0.50,
        ),
        width: 0.8,
      ),
    );

    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      scaleDownFactor: 0.96,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: isM3E ? 0.38 : 0.22,
        ),
        shape: itemShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppHaptics.selectionClick();
            item.onTap();
          },
          customBorder: itemShape,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10.0 : 12.0,
              vertical: isCompact ? 8.0 : 10.0,
            ),
            child: Row(
              children: [
                Container(
                  width: isCompact ? 28 : 32,
                  height: isCompact ? 28 : 32,
                  decoration: ShapeDecoration(
                    color: resolvedAccent.withValues(alpha: 0.14),
                    shape: CardMetrics.shape(
                      innerRadius * 0.7,
                      expressive: isM3E,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: isCompact ? 15 : 17,
                    color: resolvedAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 12.5 : 13.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (item.subtitle != null &&
                          item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: isCompact ? 10.5 : 11.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: isCompact ? 14 : 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
