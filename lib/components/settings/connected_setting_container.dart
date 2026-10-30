import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:provider/provider.dart';

/// Visually connected container for dependent/nested settings rows.
///
/// Provides an M3E tonal surface, indented spacing, and an accent connector
/// indicator along the leading edge to clearly communicate hierarchy and
/// logical relationships between parent toggles and their sub-settings.
class ConnectedSettingContainer extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final String? label;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ConnectedSettingContainer({
    super.key,
    required this.child,
    this.accentColor,
    this.label,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final isCompact = plusSettings.plusUseCompactSettings;
    final isGlass = plusSettings.plusEnableGlassmorphism;

    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.inner(CardMetrics.card(baseRadius));
    final resolvedAccent = accentColor ?? colorScheme.primary;
    final containerColor = isGlass
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
        : colorScheme.surfaceContainerHighest.withValues(
            alpha: isM3E ? 0.45 : 0.30,
          );
    final containerShape = CardMetrics.shape(
      cardRadius,
      expressive: isM3E,
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.25 : 0.45,
        ),
        width: 0.8,
      ),
    );

    return Padding(
      padding:
          margin ??
          EdgeInsets.fromLTRB(
            isCompact ? 16.0 : 20.0,
            2.0,
            isCompact ? 12.0 : 16.0,
            isCompact ? 6.0 : 8.0,
          ),
      child: Material(
        color: containerColor,
        shape: containerShape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Leading accent connector rail clipped by parent Material
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 3.5,
              child: ColoredBox(
                color: resolvedAccent.withValues(alpha: isM3E ? 0.80 : 0.60),
              ),
            ),
            // Foreground content
            Padding(
              padding: const EdgeInsets.only(left: 3.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 12.0 : 14.0,
                        isCompact ? 6.0 : 8.0,
                        isCompact ? 12.0 : 14.0,
                        2.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 14,
                            color: resolvedAccent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: resolvedAccent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(padding: padding ?? EdgeInsets.zero, child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
