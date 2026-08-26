import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Master switch for all Obtainium+ features.
///
/// Individual Plus toggles live in their thematically-relevant settings
/// section (Appearance, Updates & Install, Notifications, Behavior,
/// Advanced & Debug) rather than here, so this is a single compact row
/// pinned above the section tabs — not a full collapsible group, since it
/// only ever holds one control.
class PlusFeaturesSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const PlusFeaturesSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    if (isSearching &&
        !tr(
          'enableAllPlusFeatures',
        ).toLowerCase().contains(searchQuery!.toLowerCase())) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: colorScheme.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: SwitchListTile.adaptive(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            secondary: Icon(
              Icons.auto_awesome_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            title: Text(
              tr('enableAllPlusFeatures'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              tr('enableAllPlusFeaturesDescription'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: settings.enableAllPlusFeatures,
            onChanged: (value) => settings.enableAllPlusFeatures = value,
          ),
        );
      },
    );
  }
}
