import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/system_app_selector_sheet.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:obtainium/installers/root_installer.dart';
import 'package:obtainium/providers/settings_provider.dart';
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

          // Install Unknown Apps (system settings shortcut)
          if (_matches(tr('installUnknownApps')))
            ListTile(
              leading: Icon(
                Icons.install_mobile_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                tr('installUnknownApps'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => AppInstallService.openInstallUnknownAppsSettings(
                AppConstants.obtainiumPlusId,
              ),
            ),

          // Battery Optimization (background reliability, system shortcut)
          if (_matches(tr('batteryOptimizationSettings')))
            ListTile(
              leading: Icon(
                Icons.battery_saver_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                tr('batteryOptimizationSettings'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: tr('batteryOptimizationSettingsPage'),
                onPressed: () {
                  AppHaptics.lightImpact();
                  AppInstallService.openBatteryOptimizationSettings();
                },
              ),
              onTap: () {
                AppHaptics.lightImpact();
                AppInstallService.requestBatteryOptimizationExemption();
              },
            ),

          // Import Installed Apps
          if (_matches(tr('importInstalledApps')))
            ListTile(
              leading: const Icon(Icons.install_mobile_rounded),
              title: Text(
                tr('importInstalledApps'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('importInstalledAppsDescription')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppHaptics.selectionClick();
                showSystemAppSelectorSheet(context: context);
              },
            ),

          // Smart Retries & Caching
          if (_matches(tr('plusSmartRetries'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.bolt_outlined,
              title: tr('plusSmartRetries'),
              subtitle: tr('plusSmartRetriesDescription'),
              value: (s) => s.plusEnableSmartRetries,
              onChanged: (s, v) => s.plusEnableSmartRetries = v,
            ),

          // MicroG Compat Hub
          if (_matches(tr('plusEnableMicroGHub'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.hub_outlined,
              title: tr('plusEnableMicroGHub'),
              subtitle: tr('plusEnableMicroGHubDescription'),
              value: (s) => s.plusEnableMicroGHub,
              onChanged: (s, v) => s.plusEnableMicroGHub = v,
            ),

          // Standalone Installer
          if (_matches(tr('plusEnableStandaloneInstaller')))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.install_mobile_outlined,
              title: tr('plusEnableStandaloneInstaller'),
              subtitle: tr('plusEnableStandaloneInstallerDescription'),
              value: (s) => s.plusEnableStandaloneInstaller,
              onChanged: (s, v) => s.plusEnableStandaloneInstaller = v,
            ),

          // Update Ownership (Android 14+)
          if (_matches(tr('plusUpdateOwnership'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.security_update_good_rounded,
              title: tr('plusUpdateOwnership'),
              subtitle: tr('plusUpdateOwnershipDescription'),
              value: (s) => s.plusEnableUpdateOwnership,
              onChanged: (s, v) => s.plusEnableUpdateOwnership = v,
            ),

          // User Pre-approval (Android 14+)
          if (_matches(tr('plusUserPreapproval'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.touch_app_outlined,
              title: tr('plusUserPreapproval'),
              subtitle: tr('plusUserPreapprovalDescription'),
              value: (s) => s.plusEnableUserPreapproval,
              onChanged: (s, v) => s.plusEnableUserPreapproval = v,
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

          // Root Installation
          if (_matches(tr('rootInstaller')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.security_rounded),
              title: Text(
                tr('rootInstaller'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('rootInstallerDescription')),
              value: behaviorSettings.installerMode == 'root',
              onChanged: (enable) async {
                if (!enable) {
                  behaviorSettings.installerMode = behaviorSettings.useShizuku
                      ? 'shizuku'
                      : 'system';
                  return;
                }
                final hasRoot = await RootInstaller(
                  SettingsProvider(behaviorSettings.prefs),
                ).checkPermission();
                if (!context.mounted) return;
                if (hasRoot) {
                  behaviorSettings.installerMode = 'root';
                } else {
                  _showError(context, ObtainiumError(tr('rootNotDetected')));
                }
              },
            ),
        ];

        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('installation'),
          persistKey: 'installation',
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
