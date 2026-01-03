import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    const height16 = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRemoveOnExternalUninstallToggle(context),
        height16,
        _buildAppVerifierToggle(context),
        height16,
        _buildUseShizukuToggle(context),
        height16,
        _buildShizukuPretendToBeGooglePlayToggle(context),
        height16,
        _buildHideTrackOnlyWarningToggle(context),
        height16,
        _buildHideAPKOriginWarningToggle(context),
      ],
    );
  }

  Widget _buildRemoveOnExternalUninstallToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(tr('removeOnExternalUninstall')),
            ),
            Switch(
              value: settings.removeOnExternalUninstall,
              onChanged: (value) {
                settings.removeOnExternalUninstall = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppVerifierToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('beforeNewInstallsShareToAppVerifier'),
                  ),
                  GestureDetector(
                    onTap: () {
                      launchUrlString(
                        'https://github.com/soupslurpr/AppVerifier',
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Text(
                      tr('about'),
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.beforeNewInstallsShareToAppVerifier,
              onChanged: (value) {
                settings.beforeNewInstallsShareToAppVerifier = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUseShizukuToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('useShizuku'))),
            Switch(
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildShizukuPretendToBeGooglePlayToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(tr('shizukuPretendToBeGooglePlay')),
            ),
            Switch(
              value: settings.shizukuPretendToBeGooglePlay,
              onChanged: (value) {
                settings.shizukuPretendToBeGooglePlay = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHideTrackOnlyWarningToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(tr('dontShowTrackOnlyWarnings')),
            ),
            Switch(
              value: settings.hideTrackOnlyWarning,
              onChanged: (value) {
                settings.hideTrackOnlyWarning = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHideAPKOriginWarningToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(tr('dontShowAPKOriginWarnings')),
            ),
            Switch(
              value: settings.hideAPKOriginWarning,
              onChanged: (value) {
                settings.hideAPKOriginWarning = value;
              },
            ),
          ],
        );
      },
    );
  }
}
