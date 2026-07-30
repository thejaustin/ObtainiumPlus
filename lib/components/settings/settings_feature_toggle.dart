import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
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
  required dynamic Function(T) value,
  required void Function(T, bool) onChanged,
}) {
  return Consumer<T>(
    builder: (context, settings, child) {
      final plusGatedOff =
          settings is PlusSettingsProvider && !settings.enableAllPlusFeatures;
      if (plusGatedOff) {
        return const SizedBox.shrink();
      }
      return SwitchListTile.adaptive(
        secondary: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(subtitle),
        value: value(settings),
        onChanged: (v) => onChanged(settings, v),
      );
    },
  );
}
