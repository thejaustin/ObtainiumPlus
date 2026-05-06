import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:obtainium/utils/logger.dart';

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
      _buildToggle(
        context,
        icon: Icons.file_download_outlined,
        title: tr('parallelDownloads'),
        subtitle: tr('parallelDownloadsDescription'),
        value: (s) => s.parallelDownloads,
        onChanged: (s, v) => s.parallelDownloads = v,
        visible: (s) => _matches(tr('parallelDownloads')),
      ),

      // App Verifier
      _buildToggle(
        context,
        icon: Icons.verified_user_outlined,
        title: tr('beforeNewInstallsShareToAppVerifier'),
        subtitle: tr('beforeNewInstallsShareToAppVerifierDescription'),
        value: (s) => s.beforeNewInstallsShareToAppVerifier,
        onChanged: (s, v) => s.beforeNewInstallsShareToAppVerifier = v,
        visible: (s) => _matches(tr('beforeNewInstallsShareToAppVerifier')),
      ),

      // Smart Retries & Caching
      _buildToggle(
        context,
        icon: Icons.bolt_outlined,
        title: tr('plusSmartRetries'),
        subtitle: tr('plusSmartRetriesDescription'),
        value: (s) => s.plusEnableSmartRetries,
        onChanged: (s, v) => s.plusEnableSmartRetries = v,
        visible: (s) => _matches(tr('plusSmartRetries')),
      ),

      // Update Ownership (Android 14+)
      _buildToggle(
        context,
        icon: Icons.security_update_good_rounded,
        title: tr('plusUpdateOwnership'),
        subtitle: tr('plusUpdateOwnershipDescription'),
        value: (s) => s.plusEnableUpdateOwnership,
        onChanged: (s, v) => s.plusEnableUpdateOwnership = v,
        visible: (s) => _matches(tr('plusUpdateOwnership')),
      ),

      // User Pre-approval (Android 14+)
      _buildToggle(
        context,
        icon: Icons.touch_app_outlined,
        title: tr('plusUserPreapproval'),
        subtitle: tr('plusUserPreapprovalDescription'),
        value: (s) => s.plusEnableUserPreapproval,
        onChanged: (s, v) => s.plusEnableUserPreapproval = v,
        visible: (s) => _matches(tr('plusUserPreapproval')),
      ),

      // Remove on External Uninstall
      _buildToggle(
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
        Consumer<SettingsProvider>(
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
                settings.useShizuku = resCode.startsWith('authorized') || resCode.startsWith('granted');
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
              }).catchError((e) {
                talker.warning('Shizuku checkPermission error: $e');
              });
            },
          ),
        ),

      // Shizuku Pretend to be Google Play (only visible when Shizuku is on)
      if (_matches(tr('shizukuPretendToBeGooglePlay')))
        Consumer<SettingsProvider>(
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
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(error.message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildToggle(
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
