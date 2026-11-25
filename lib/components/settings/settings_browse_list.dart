import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// The "list" way of browsing Settings: one plain list of categories, each
/// with a title and a one-line summary. Tapping a row opens that category.
class SettingsBrowseList extends StatelessWidget {
  final ValueChanged<int> onOpen;

  const SettingsBrowseList({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = context.select<PlusSettingsProvider, double>(
      (p) => p.plusGlobalCornerRadius,
    );
    return Material(
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        children: [
          for (var i = 0; i < kSettingsSections.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 72,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Icon(kSettingsSections[i].icon, color: cs.primary),
              title: Text(tr(kSettingsSections[i].labelKey)),
              subtitle: Text(
                tr(kSettingsSections[i].descKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
              onTap: () => onOpen(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header shown above an opened category in the list style: a back arrow
/// and the category name.
class SettingsBrowseBack extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsBrowseBack({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(tr('settingsBrowseAll')),
      ),
    );
  }
}
