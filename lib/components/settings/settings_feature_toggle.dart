import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

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
  required String subtitle,
  required bool Function(T) value,
  required void Function(T, bool) onChanged,
}) {
  return Consumer<T>(
    builder: (context, settings, child) {
      final plusSettings = context.watch<PlusSettingsProvider>();
      final plusGatedOff =
          settings is PlusSettingsProvider && !settings.enableAllPlusFeatures;
      if (plusGatedOff) {
        return const SizedBox.shrink();
      }
      final isEnabled = value(settings);
      final colorScheme = Theme.of(context).colorScheme;
      final isM3E = plusSettings.plusEnableMaterialExpressive;
      final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
          ? plusSettings.plusSettingsCornerRadius
          : plusSettings.plusGlobalCornerRadius;
      final innerRadius = CardMetrics.inner(CardMetrics.card(baseRadius));

      return SwitchListTile.adaptive(
        secondary: AnimatedContainer(
          duration: Duration(
            milliseconds: plusSettings.plusEnableEnhancedAnimations ? 220 : 0,
          ),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          decoration: ShapeDecoration(
            color: isEnabled
                ? colorScheme.primary.withValues(alpha: isM3E ? 0.16 : 0.10)
                : colorScheme.surfaceContainerHighest.withValues(
                    alpha: isM3E ? 0.50 : 0.30,
                  ),
            shape: CardMetrics.shape(innerRadius, expressive: isM3E),
          ),
          child: Icon(
            icon,
            size: 19,
            color: isEnabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(subtitle),
        value: isEnabled,
        onChanged: (v) {
          v ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
          onChanged(settings, v);
        },
      );
    },
  );
}
