import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Advanced / warnings settings section
class AdvancedSettingsSection extends StatelessWidget {
  final String? searchQuery;

  const AdvancedSettingsSection({
      super.key,
      this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    List<Widget> children = [
      _buildSettingsToggle(
        context,
        icon: Icons.report_off_outlined,
        title: tr('dontShowTrackOnlyWarnings'),
        subtitle: tr('dontShowTrackOnlyWarningsDescription'),
        value: (s) => s.hideTrackOnlyWarning,
        onChanged: (s, v) => s.hideTrackOnlyWarning = v,
        visible: (s) => _matches(tr('dontShowTrackOnlyWarnings')),
      ),
      _buildSettingsToggle(
        context,
        icon: Icons.security_outlined,
        title: tr('dontShowAPKOriginWarnings'),
        subtitle: tr('dontShowAPKOriginWarningsDescription'),
        value: (s) => s.hideAPKOriginWarning,
        onChanged: (s, v) => s.hideAPKOriginWarning = v,
        visible: (s) => _matches(tr('dontShowAPKOriginWarnings')),
      ),
      _buildSettingsToggle(
        context,
        icon: Icons.bug_report_outlined,
        title: tr('enableDeepLogging'),
        subtitle: tr('enableDeepLoggingDescription'),
        value: (s) => s.enableDeepLogging,
        onChanged: (s, v) => s.enableDeepLogging = v,
        visible: (s) => _matches(tr('enableDeepLogging')),
      ),
      _buildSettingsToggle(
        context,
        icon: Icons.lightbulb_outline,
        title: tr('enableContextualTips'),
        subtitle: tr('enableContextualTipsDescription'),
        value: (s) => s.enableContextualTips,
        onChanged: (s, v) => s.enableContextualTips = v,
        visible: (s) => _matches(tr('enableContextualTips')),
      ),
    ];

    if (children.every((w) => w is SizedBox && w.child == null)) return const SizedBox.shrink();

    return SettingsGroup(
      title: isSearching ? null : tr('advanced'),
      children: children,
    );
  }

  Widget _buildSettingsToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool Function(SettingsProvider) value,
    required void Function(SettingsProvider, bool) onChanged,
    required bool Function(SettingsProvider) visible,
  }) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!visible(settings)) return const SizedBox.shrink();
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
}
