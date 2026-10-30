import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// One-line intro under the settings tab bar.
///
/// The selected tab chip (or bottom-bar destination) already names the tab
/// and shows its icon, so repeating both in a card here only pushed the
/// actual settings down. [icon], [title] and [accentColor] are kept for the
/// screen reader label and existing call sites.
class SettingsTabMasthead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? accentColor;

  const SettingsTabMasthead({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = context
        .watch<PlusSettingsProvider>()
        .plusUseCompactSettings;
    if (isCompact) return const SizedBox(height: 4);

    return Semantics(
      header: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
        child: Text(description, style: theme.listTileTheme.subtitleTextStyle),
      ),
    );
  }
}
