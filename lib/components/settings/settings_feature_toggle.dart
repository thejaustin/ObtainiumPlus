import 'package:flutter/material.dart';
import 'package:obtainium/components/common/morph_switch.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/settings_row.dart';
import 'package:obtainium/models/settings_enums.dart';
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
/// [hideWhenPlusOff] false keeps a non-Plus-branded row (stored in the Plus
/// provider for history) visible regardless.
Widget buildFeatureToggle<T extends ChangeNotifier>(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String? subtitle,
  required bool Function(T) value,
  required void Function(T, bool) onChanged,
  bool hideWhenPlusOff = true,
}) {
  return Consumer<T>(
    builder: (context, settings, child) {
      final isCompact = context.select<PlusSettingsProvider, bool>(
        (p) => p.plusUseCompactSettings,
      );
      final plusGatedOff =
          hideWhenPlusOff &&
          settings is PlusSettingsProvider &&
          !settings.enableAllPlusFeatures;
      if (plusGatedOff) {
        return const SizedBox.shrink();
      }
      final isEnabled = value(settings);
      final compactLines = context.select<PlusSettingsProvider, int>(
        (s) => s.plusLabCompactDescriptionLines,
      );
      final (switchStyle, iconMorph) = context
          .select<PlusSettingsProvider, (SettingsSwitchStyle, bool)>(
            (p) => (p.plusSwitchStyle, p.plusIconMorphOnToggle),
          );
      // Expressive-kit previews: only when one is switched on. The default
      // (classic switch, no icon morph) keeps the SwitchListTile below.
      if (switchStyle != SettingsSwitchStyle.classic || iconMorph) {
        return _KitToggleRow(
          icon: icon,
          title: title,
          subtitle: subtitle,
          value: isEnabled,
          switchStyle: switchStyle,
          iconMorph: iconMorph,
          isCompact: isCompact,
          compactLines: compactLines,
          onChanged: (v) => onChanged(settings, v),
        );
      }

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
                  maxLines: isCompact ? compactLines : 3,
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

/// Toggle row drawn with the expressive kit (SettingsRow + MorphSwitch +
/// ToggleIconBadge). The whole row toggles; one haptic per change.
class _KitToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final SettingsSwitchStyle switchStyle;
  final bool iconMorph;
  final bool isCompact;
  final int compactLines;
  final ValueChanged<bool> onChanged;

  const _KitToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.switchStyle,
    required this.iconMorph,
    required this.isCompact,
    required this.compactLines,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final (shape, morphStyle) = context
        .select<PlusSettingsProvider, (IconMorphShape, IconMorphStyle)>(
          (p) => (p.plusIconMorphShape, p.plusIconMorphStyle),
        );
    return SettingsRow(
      toggled: value,
      leading: ToggleIconBadge(
        icon: icon,
        active: value,
        morphOnToggle: iconMorph,
        fill: switchStyle == SettingsSwitchStyle.iconSwitch,
        shape: shape,
        style: morphStyle,
        size: isCompact ? 30 : 36,
      ),
      title: Text(title),
      summary: (subtitle != null && subtitle!.isNotEmpty)
          ? Text(
              subtitle!,
              maxLines: isCompact ? compactLines : 3,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () {
        AppHaptics.toggled(!value);
        onChanged(!value);
      },
      // The row carries the switch semantics.
      trailing: ExcludeSemantics(
        child: MorphSwitch(
          value: value,
          style: switchStyle,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
