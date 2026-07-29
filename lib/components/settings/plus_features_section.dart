import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Master switch for all Obtainium+ features.
///
/// Individual Plus toggles live in their thematically-relevant settings
/// section (Appearance, Updates & Install, Notifications, Behavior,
/// Advanced & Debug) rather than here, so this only hosts the switch that
/// gates all of them at once.
class PlusFeaturesSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const PlusFeaturesSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('plusFeatures'),
          icon: Icons.auto_awesome_rounded,
          isExpandable: !isSearching,
          initiallyExpanded: true,
          helpText: tr('plusFeaturesHelp'),
          onReset: () {
            AppHaptics.heavyImpact();
            settings.enableAllPlusFeatures = true;
          },
          children: [
            if (_matches(tr('enableAllPlusFeatures')))
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.auto_awesome),
                title: Text(
                  tr('enableAllPlusFeatures'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(tr('enableAllPlusFeaturesDescription')),
                value: settings.enableAllPlusFeatures,
                onChanged: (value) => settings.enableAllPlusFeatures = value,
              ),
          ],
        );
      },
    );
  }
}
