import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:provider/provider.dart';

/// Shared M3E / Obtainium+ icon badge for settings rows (`SwitchListTile` and `ListTile`).
/// Adapts automatically to `plusUseCompactSettings` (`30×30` vs `36×36`) and
/// `plusEnableMaterialExpressive` (squircle vs circular-arc rounded rect) so
/// every setting row across the app shares a single vertical alignment axis.
Widget buildSettingsIconBadge(
  BuildContext context,
  IconData icon, {
  bool active = false,
  Color? accentColor,
}) {
  final (isM3E, isCompact, baseRadius) = context
      .select<PlusSettingsProvider, (bool, bool, double)>(
        (p) => (
          p.plusEnableMaterialExpressive,
          p.plusUseCompactSettings,
          p.plusOverrideIndividualCornerRadius
              ? p.plusSettingsCornerRadius
              : p.plusGlobalCornerRadius,
        ),
      );
  final animDuration = AppMotion.duration(
    context,
    const Duration(milliseconds: 200),
  );
  final colorScheme = Theme.of(context).colorScheme;
  final innerRadius = CardMetrics.inner(CardMetrics.card(baseRadius));
  final badgeSize = isCompact ? 30.0 : 36.0;
  final resolvedAccent = accentColor ?? colorScheme.primary;

  return AnimatedScale(
    scale: active ? 1.05 : 1.0,
    duration: animDuration,
    curve: Curves.easeOutCubic,
    child: AnimatedContainer(
      duration: animDuration,
      curve: Curves.easeOutCubic,
      width: badgeSize,
      height: badgeSize,
      decoration: ShapeDecoration(
        color: active
            ? resolvedAccent.withValues(alpha: isM3E ? 0.16 : 0.12)
            : colorScheme.surfaceContainerHighest.withValues(
                alpha: isM3E ? 0.50 : 0.32,
              ),
        shape: CardMetrics.shape(innerRadius, expressive: isM3E),
      ),
      child: Icon(
        icon,
        size: isCompact ? 16 : 19,
        color: active ? resolvedAccent : colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Shared toggle-row builder for settings sections: wraps a single boolean
/// preference in a Consumer<T> and renders a SwitchListTile.adaptive.
///
/// Search/advanced-settings matching is the caller's responsibility (wrap
/// the call in `if (_matches(...))` so hidden toggles are actually absent
/// from the children list, not just internally hidden — group widgets like
/// ExpressiveSettingsGroup can't detect an empty group through a Consumer
/// that renders SizedBox.shrink() internally).
///
/// Any T that is a PlusSettingsProvider is still automatically hidden when
/// `enableAllPlusFeatures` is off, since that's runtime provider state the
/// caller can't cheaply check without watching the provider itself.
Widget buildFeatureToggle<T extends ChangeNotifier>(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String? subtitle,
  required bool Function(T) value,
  required void Function(T, bool) onChanged,
}) {
  return Consumer<T>(
    builder: (context, settings, child) {
      final isCompact = context.select<PlusSettingsProvider, bool>(
        (p) => p.plusUseCompactSettings,
      );
      final plusGatedOff =
          settings is PlusSettingsProvider && !settings.enableAllPlusFeatures;
      if (plusGatedOff) {
        return const SizedBox.shrink();
      }
      final isEnabled = value(settings);

      // The switch's onChanged fires toggleOn/toggleOff; a press-down haptic
      // here as well would buzz twice for one change.
      return ScaleTouchWrapper(
        scaleDownFactor: 0.985,
        hapticOnPressDown: false,
        child: SwitchListTile.adaptive(
          secondary: buildSettingsIconBadge(context, icon, active: isEnabled),
          title: Text(
            title,
            style: isCompact
                ? Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
                : Theme.of(context).listTileTheme.titleTextStyle,
          ),
          subtitle: (subtitle != null && subtitle.isNotEmpty)
              ? Text(
                  subtitle,
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: isCompact
                      ? Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                )
              : null,
          value: isEnabled,
          onChanged: (v) {
            v ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
            onChanged(settings, v);
          },
        ),
      );
    },
  );
}
