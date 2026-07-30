import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:obtainium/utils/logger.dart';

/// App installation and update settings
class InstallationSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const InstallationSection({
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

    return Consumer<BehaviorSettingsProvider>(
      builder: (context, behaviorSettings, child) {
        List<Widget> children = [
          // Parallel Downloads
          if (_matches(tr('parallelDownloads'), isAdvanced: true))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.file_download_outlined),
              title: Text(
                tr('parallelDownloads'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('parallelDownloadsDescription')),
              value: behaviorSettings.parallelDownloads,
              onChanged: (v) => behaviorSettings.parallelDownloads = v,
            ),

          // App Verifier
          if (_matches(tr('beforeNewInstallsShareToAppVerifier')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.verified_user_outlined),
              title: Text(
                tr('beforeNewInstallsShareToAppVerifier'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(
                tr('beforeNewInstallsShareToAppVerifierDescription'),
              ),
              value: behaviorSettings.beforeNewInstallsShareToAppVerifier,
              onChanged: (v) =>
                  behaviorSettings.beforeNewInstallsShareToAppVerifier = v,
            ),

          // Use Play Store App Links
          if (_matches(tr('usePlayStoreAppLinks')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.storefront_outlined),
              title: Text(
                tr('usePlayStoreAppLinks'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('usePlayStoreAppLinksDescription')),
              value: behaviorSettings.usePlayStoreAppLinks,
              onChanged: (v) => behaviorSettings.usePlayStoreAppLinks = v,
            ),

          // Allow Third-Party Sources
          if (_matches(tr('allowThirdPartySources')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.source_outlined),
              title: Text(
                tr('allowThirdPartySources'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('allowThirdPartySourcesDescription')),
              value: behaviorSettings.allowThirdPartySources,
              onChanged: (v) => behaviorSettings.allowThirdPartySources = v,
            ),

          // Smart Retries & Caching
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            showAdvancedSettings: showAdvancedSettings,
            icon: Icons.bolt_outlined,
            title: tr('plusSmartRetries'),
            subtitle: tr('plusSmartRetriesDescription'),
            value: (s) => s.plusEnableSmartRetries,
            onChanged: (s, v) => s.plusEnableSmartRetries = v,
            visible: (s) => _matches(tr('plusSmartRetries'), isAdvanced: true),
          ),

          // MicroG Compat Hub
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            showAdvancedSettings: showAdvancedSettings,
            icon: Icons.hub_outlined,
            title: tr('plusEnableMicroGHub'),
            subtitle: tr('plusEnableMicroGHubDescription'),
            value: (s) => s.plusEnableMicroGHub,
            onChanged: (s, v) => s.plusEnableMicroGHub = v,
            visible: (s) =>
                _matches(tr('plusEnableMicroGHub'), isAdvanced: true),
          ),

          // Standalone Installer
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            showAdvancedSettings: showAdvancedSettings,
            icon: Icons.install_mobile_outlined,
            title: tr('plusEnableStandaloneInstaller'),
            subtitle: tr('plusEnableStandaloneInstallerDescription'),
            value: (s) => s.plusEnableStandaloneInstaller,
            onChanged: (s, v) => s.plusEnableStandaloneInstaller = v,
            visible: (s) => _matches(tr('plusEnableStandaloneInstaller')),
          ),

          // Update Ownership (Android 14+)
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            showAdvancedSettings: showAdvancedSettings,
            icon: Icons.security_update_good_rounded,
            title: tr('plusUpdateOwnership'),
            subtitle: tr('plusUpdateOwnershipDescription'),
            value: (s) => s.plusEnableUpdateOwnership,
            onChanged: (s, v) => s.plusEnableUpdateOwnership = v,
            visible: (s) =>
                _matches(tr('plusUpdateOwnership'), isAdvanced: true),
          ),

          // User Pre-approval (Android 14+)
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            showAdvancedSettings: showAdvancedSettings,
            icon: Icons.touch_app_outlined,
            title: tr('plusUserPreapproval'),
            subtitle: tr('plusUserPreapprovalDescription'),
            value: (s) => s.plusEnableUserPreapproval,
            onChanged: (s, v) => s.plusEnableUserPreapproval = v,
            visible: (s) =>
                _matches(tr('plusUserPreapproval'), isAdvanced: true),
          ),

          // Remove on External Uninstall
          if (_matches(tr('removeOnExternalUninstall')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.delete_sweep_outlined),
              title: Text(
                tr('removeOnExternalUninstall'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('removeOnExternalUninstallDescription')),
              value: behaviorSettings.removeOnExternalUninstall,
              onChanged: (v) => behaviorSettings.removeOnExternalUninstall = v,
            ),

          // Shizuku / Sui
          if (_matches(tr('useShizuku')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.terminal_outlined),
              title: Text(
                tr('useShizuku'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('useShizukuDescription')),
              value: behaviorSettings.useShizuku,
              onChanged: (enable) {
                if (!enable) {
                  behaviorSettings.useShizuku = false;
                  return;
                }
                ShizukuApkInstaller().checkPermission().then(
                  (resCode) {
                    if (resCode == null) {
                      if (context.mounted) {
                        _showError(
                          context,
                          ObtainiumError(tr('shizukuBinderNotFound')),
                        );
                      }
                      return;
                    }
                    behaviorSettings.useShizuku =
                        resCode.startsWith('authorized') ||
                        resCode.startsWith('granted');
                    if (!context.mounted) return;
                    switch (resCode) {
                      case 'binder_not_found':
                        _showError(
                          context,
                          ObtainiumError(tr('shizukuBinderNotFound')),
                        );
                      case 'old_shizuku':
                        _showError(context, ObtainiumError(tr('shizukuOld')));
                      case 'old_android_with_adb':
                        _showError(
                          context,
                          ObtainiumError(tr('shizukuOldAndroidWithADB')),
                        );
                      case 'denied':
                        _showError(context, ObtainiumError(tr('cancelled')));
                    }
                  },
                  onError: (e) {
                    talker.warning('Shizuku checkPermission error: $e');
                  },
                );
              },
            ),

          // Shizuku Pretend to be Google Play
          if (_matches(tr('shizukuPretendToBeGooglePlay')) &&
              behaviorSettings.useShizuku)
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.shop_outlined),
              title: Text(
                tr('shizukuPretendToBeGooglePlay'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('shizukuPretendToBeGooglePlayDescription')),
              value: behaviorSettings.shizukuPretendToBeGooglePlay,
              onChanged: (v) =>
                  behaviorSettings.shizukuPretendToBeGooglePlay = v,
            ),
        ];

        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('installation'),
          icon: Icons.install_mobile_rounded,
          isExpandable: !isSearching,
          initiallyExpanded: false,
          children: children,
        );
      },
    );
  }

  void _showError(BuildContext context, ObtainiumError error) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(error.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
