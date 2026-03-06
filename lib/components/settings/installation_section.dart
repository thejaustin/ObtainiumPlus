import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

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
      _buildBehaviorToggle(
        context,
        icon: Icons.file_download_outlined,
        title: tr('parallelDownloads'),
        subtitle: tr('parallelDownloadsDescription'),
        value: (s) => s.parallelDownloads,
        onChanged: (s, v) => s.parallelDownloads = v,
        visible: (s) => _matches(tr('parallelDownloads')),
      ),

      // App Verifier
      _buildBehaviorToggle(
        context,
        icon: Icons.verified_user_outlined,
        title: tr('beforeNewInstallsShareToAppVerifier'),
        subtitle: tr('beforeNewInstallsShareToAppVerifierDescription'),
        value: (s) => s.beforeNewInstallsShareToAppVerifier,
        onChanged: (s, v) => s.beforeNewInstallsShareToAppVerifier = v,
        visible: (s) => _matches(tr('beforeNewInstallsShareToAppVerifier')),
      ),

      // Remove on External Uninstall
      _buildBehaviorToggle(
        context,
        icon: Icons.delete_sweep_outlined,
        title: tr('removeOnExternalUninstall'),
        subtitle: tr('removeOnExternalUninstallDescription'),
        value: (s) => s.removeOnExternalUninstall,
        onChanged: (s, v) => s.removeOnExternalUninstall = v,
        visible: (s) => _matches(tr('removeOnExternalUninstall')),
      ),

      // Shizuku / Sui (with full permission check and error feedback)
      if (_matches(tr('useShizuku')))
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, child) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.terminal_outlined),
            title: Text(tr('useShizuku'), style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text(tr('useShizukuDescription')),
            value: settings.useShizuku,
            onChanged: (enable) {
              if (!enable) {
                settings.useShizuku = false;
                return;
              }
              ShizukuApkInstaller.checkPermission().then((resCode) {
                if (resCode == null) {
                  _showError(context, ObtainiumError(tr('shizukuBinderNotFound')));
                  return;
                }
                settings.useShizuku = resCode.startsWith('granted');
                switch (resCode) {
                  case 'binder_not_found':
                    _showError(context, ObtainiumError(tr('shizukuBinderNotFound')));
                  case 'old_shizuku':
                    _showError(context, ObtainiumError(tr('shizukuOld')));
                  case 'old_android_with_adb':
                    _showError(context, ObtainiumError(tr('shizukuOldAndroidWithADB')));
                  case 'denied':
                    _showError(context, ObtainiumError(tr('cancelled')));
                }
              });
            },
          ),
        ),

      // Shizuku Pretend to be Google Play (only visible when Shizuku is on)
      if (_matches(tr('shizukuPretendToBeGooglePlay')))
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, child) {
            if (!settings.useShizuku) return const SizedBox.shrink();
            return SwitchListTile.adaptive(
              secondary: const Icon(Icons.shop_outlined),
              title: Text(tr('shizukuPretendToBeGooglePlay'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(tr('shizukuPretendToBeGooglePlayDescription')),
              value: settings.shizukuPretendToBeGooglePlay,
              onChanged: (v) => settings.shizukuPretendToBeGooglePlay = v,
            );
          },
        ),
    ];

    return SettingsGroup(
      title: isSearching ? null : tr('installation'),
      children: children,
    );
  }

  void _showError(BuildContext context, ObtainiumError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildBehaviorToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool Function(BehaviorSettingsProvider) value,
    required void Function(BehaviorSettingsProvider, bool) onChanged,
    required bool Function(BehaviorSettingsProvider) visible,
  }) {
    return Consumer<BehaviorSettingsProvider>(
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
