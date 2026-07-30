import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Shared toggle-row builder for settings sections: wraps a single boolean
/// preference in a Consumer<T>, applies visibility/advanced-settings/
/// Plus-master-switch gating, and renders a SwitchListTile.adaptive.
///
/// Any T that is a PlusSettingsProvider is automatically hidden when
/// `enableAllPlusFeatures` is off, regardless of `visible`/`isAdvanced`.
Widget buildFeatureToggle<T extends ChangeNotifier>(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required dynamic Function(T) value,
  required void Function(T, bool) onChanged,
  required bool Function(T) visible,
  bool isAdvanced = false,
  bool? showAdvancedSettings,
}) {
  return Consumer<T>(
    builder: (context, settings, child) {
      final plusGatedOff =
          settings is PlusSettingsProvider && !settings.enableAllPlusFeatures;
      if (!visible(settings) ||
          plusGatedOff ||
          (isAdvanced && !(showAdvancedSettings ?? false))) {
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
