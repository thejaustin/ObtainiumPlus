import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// App installation and update settings
class InstallationSection extends StatelessWidget {
  final String? searchQuery;

  const InstallationSection({
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
      // Parallel Downloads
      _buildFeatureToggle<BehaviorSettingsProvider>(
        context,
        icon: Icons.file_download_outlined,
        title: tr('parallelDownloads'),
        subtitle: tr('parallelDownloadsDescription'),
        value: (s) => s.parallelDownloads,
        onChanged: (s, v) => s.parallelDownloads = v,
        visible: (s) => _matches(tr('parallelDownloads')),
      ),
      
      // App Verifier
      _buildFeatureToggle<BehaviorSettingsProvider>(
        context,
        icon: Icons.verified_user_outlined,
        title: tr('beforeNewInstallsShareToAppVerifier'),
        subtitle: tr('beforeNewInstallsShareToAppVerifierDescription'),
        value: (s) => s.beforeNewInstallsShareToAppVerifier,
        onChanged: (s, v) => s.beforeNewInstallsShareToAppVerifier = v,
        visible: (s) => _matches(tr('beforeNewInstallsShareToAppVerifier')),
      ),
      
      // Remove on External Uninstall
      _buildFeatureToggle<BehaviorSettingsProvider>(
        context,
        icon: Icons.delete_sweep_outlined,
        title: tr('removeOnExternalUninstall'),
        subtitle: tr('removeOnExternalUninstallDescription'),
        value: (s) => s.removeOnExternalUninstall,
        onChanged: (s, v) => s.removeOnExternalUninstall = v,
        visible: (s) => _matches(tr('removeOnExternalUninstall')),
      ),
      
      // Shizuku
      _buildFeatureToggle<BehaviorSettingsProvider>(
        context,
        icon: Icons.android_outlined,
        title: tr('useShizuku'),
        subtitle: tr('useShizukuDescription'),
        value: (s) => s.useShizuku,
        onChanged: (s, v) => s.useShizuku = v,
        visible: (s) => _matches(tr('useShizuku')),
      ),
      
      // Shizuku Pretend to be Google Play
      _buildFeatureToggle<BehaviorSettingsProvider>(
        context,
        icon: Icons.shop_outlined,
        title: tr('shizukuPretendToBeGooglePlay'),
        subtitle: tr('shizukuPretendToBeGooglePlayDescription'),
        value: (s) => s.shizukuPretendToBeGooglePlay,
        onChanged: (s, v) => s.shizukuPretendToBeGooglePlay = v,
        visible: (s) => _matches(tr('shizukuPretendToBeGooglePlay')),
      ),
    ];

    return SettingsGroup(
      title: isSearching ? null : tr('installation'),
      children: children,
    );
  }

  Widget _buildFeatureToggle<T>(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool Function(T) value,
    required void Function(T, bool) onChanged,
    required bool Function(T) visible,
  }) {
    return Consumer<T>(
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
