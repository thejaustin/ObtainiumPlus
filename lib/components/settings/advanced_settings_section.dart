import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Advanced settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class AdvancedSettingsSection extends StatelessWidget {
  const AdvancedSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRemoveOnExternalUninstallToggle(context),
        _buildAppVerifierToggle(context),
        _buildUseShizukuToggle(context),
        _buildShizukuPretendToBeGooglePlayToggle(context),
        _buildHideTrackOnlyWarningToggle(context),
        _buildHideAPKOriginWarningToggle(context),
        _buildDeepLoggingToggle(context),
      ],
    );
  }

  Widget _buildDeepLoggingToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          title: Text(tr('enableDeepLogging')),
          subtitle: Text(
            tr('deepLoggingExplanation'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          value: settings.enableDeepLogging,
          onChanged: (value) {
            settings.enableDeepLogging = value;
          },
        );
      },
    );
  }

  Widget _buildRemoveOnExternalUninstallToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          title: Text(tr('removeOnExternalUninstall')),
          secondary: InfoTooltip(message: tr('removeOnExternalUninstallTooltip')),
          value: settings.removeOnExternalUninstall,
          onChanged: (value) {
            settings.removeOnExternalUninstall = value;
          },
        );
      },
    );
  }

  Widget _buildAppVerifierToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          title: Text(tr('beforeNewInstallsShareToAppVerifier')),
          subtitle: GestureDetector(
            onTap: () {
              launchUrlString(
                'https://github.com/soupslurpr/AppVerifier',
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text(
              tr('about'),
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          secondary: InfoTooltip(message: tr('beforeNewInstallsShareToAppVerifierTooltip')),
          value: settings.beforeNewInstallsShareToAppVerifier,
          onChanged: (value) {
            settings.beforeNewInstallsShareToAppVerifier = value;
          },
        );
      },
    );
  }

  Widget _buildUseShizukuToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          title: Text(tr('useShizuku')),
          secondary: InfoTooltip(message: tr('useShizukuTooltip')),
          value: settings.useShizuku,
          onChanged: (useShizuku) {
            if (useShizuku) {
              ShizukuApkInstaller.checkPermission().then((resCode) {
                settings.useShizuku = resCode!.startsWith('granted');
                switch (resCode) {
                  case 'binder_not_found':
                    showError(
                      ObtainiumError(tr('shizukuBinderNotFound')),
                      context,
                    );
                  case 'old_shizuku':
                    showError(
                      ObtainiumError(tr('shizukuOld')),
                      context,
                    );
                  case 'old_android_with_adb':
                    showError(
                      ObtainiumError(
                        tr('shizukuOldAndroidWithADB'),
                      ),
                      context,
                    );
                  case 'denied':
                    showError(
                      ObtainiumError(tr('cancelled')),
                      context,
                    );
                }
              });
            } else {
              settings.useShizuku = false;
            }
          },
        );
      },
    );
  }

  Widget _buildShizukuPretendToBeGooglePlayToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.useShizuku) return const SizedBox.shrink();
        return SwitchListTile(
          title: Text(tr('shizukuPretendToBeGooglePlay')),
          secondary: InfoTooltip(message: tr('shizukuPretendToBeGooglePlayTooltip')),
          value: settings.shizukuPretendToBeGooglePlay,
          onChanged: (value) {
            settings.shizukuPretendToBeGooglePlay = value;
          },
        );
      },
    );
  }

  Widget _buildHideTrackOnlyWarningToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          title: Text(tr('dontShowTrackOnlyWarnings')),
          secondary: InfoTooltip(message: tr('hideTrackOnlyWarningTooltip')),
          value: settings.hideTrackOnlyWarning,
          onChanged: (value) {
            settings.hideTrackOnlyWarning = value;
          },
        );
      },
    );
  }

  Widget _buildHideAPKOriginWarningToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          title: Text(tr('dontShowAPKOriginWarnings')),
          secondary: InfoTooltip(message: tr('hideAPKOriginWarningTooltip')),
          value: settings.hideAPKOriginWarning,
          onChanged: (value) {
            settings.hideAPKOriginWarning = value;
          },
        );
      },
    );
  }
}
