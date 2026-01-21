import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:provider/provider.dart';

/// Update settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class UpdateSettingsSection extends StatelessWidget {
  final bool showIntervalLabel;
  final Function(bool) onIntervalLabelChange;
  final Future<AndroidDeviceInfo>? androidInfoFuture;

  const UpdateSettingsSection({
    super.key,
    required this.showIntervalLabel,
    required this.onIntervalLabelChange,
    required this.androidInfoFuture,
  });

  @override
  Widget build(BuildContext context) {
    const height16 = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntervalLabel(context),
        _buildIntervalSlider(context),
        _buildForegroundServiceSection(context),
        _buildXiaomiTroubleshooting(context),
        height16,
        _buildCheckOnStartToggle(context),
        _buildOnlyCheckInstalledToggle(context),
        _buildParallelDownloadsToggle(context),
      ],
    );
  }

  Widget _buildXiaomiTroubleshooting(BuildContext context) {
    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          var device = snapshot.data!;
          var isXiaomi = [
            'xiaomi',
            'poco',
            'redmi'
          ].contains(device.manufacturer.toLowerCase()) ||
              [
                'xiaomi',
                'poco',
                'redmi'
              ].contains(device.brand.toLowerCase());

          if (isXiaomi) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.battery_alert_outlined,
                      color: Colors.orange),
                  title: Text(tr('xiaomiBatteryTroubleshooting')),
                  subtitle:
                      Text(tr('xiaomiBatteryTroubleshootingDescription')),
                  onTap: () {
                    showXiaomiTroubleshootingDialog(context);
                  },
                ),
              ],
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  void showXiaomiTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return buildXiaomiTroubleshootingDialog(ctx);
      },
    );
  }

  Widget buildXiaomiTroubleshootingDialog(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.battery_alert_outlined, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(tr('xiaomiTroubleshootingTitle'))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('xiaomiTroubleshootingDescription')),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                AppInstallService.openXiaomiAutostartSettings();
              },
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(tr('enableAutostart')),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                AppInstallService.openXiaomiBatterySaverSettings();
              },
              icon: const Icon(Icons.battery_saver_outlined),
              label: Text(tr('disableBatterySaver')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                AppInstallService.openAppSettings(obtainiumId);
              },
              icon: const Icon(Icons.settings_outlined),
              label: Text(tr('openAppInfo')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('ok')),
        ),
      ],
    );
  }

  Widget _buildIntervalLabel(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (showIntervalLabel) {
          return SizedBox(
            child: Row(
              children: [
                const Icon(Icons.history_toggle_off_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "${tr('bgUpdateCheckInterval')}: ${settings.updateIntervalLabel}",
                  ),
                ),
                InfoTooltip(message: tr('backgroundUpdateCheckIntervalTooltip')),
              ],
            ),
          );
        } else {
          return const SizedBox(height: 16);
        }
      },
    );
  }

  Widget _buildIntervalSlider(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: Slider(
            value: settings.updateIntervalSliderVal,
            max: settings.updateIntervalNodes.length.toDouble(),
            divisions: settings.updateIntervalNodes.length * 20,
            label: settings.updateIntervalLabel,
            onChanged: (double value) {
              settings.updateIntervalSliderVal = value;
              settings.processIntervalSliderValue(value);
              // Trigger callback for parent state change
              onIntervalLabelChange(false);
            },
            onChangeStart: (double value) {
              onIntervalLabelChange(false);
            },
            onChangeEnd: (double value) {
              onIntervalLabelChange(true);
            },
          ),
        );
      },
    );
  }

  Widget _buildForegroundServiceSection(BuildContext context) {
    const height8 = SizedBox(height: 8);

    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            if (settings.updateInterval <= 0) {
              return const SizedBox.shrink();
            }

            bool canShowForeground = ((snapshot.data?.version.sdkInt ?? 0) >= 30) ||
                settings.useShizuku;

            if (!canShowForeground) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Row(
                    children: [
                      Expanded(child: Text(tr('foregroundService'))),
                      InfoTooltip(message: tr('foregroundServiceTooltip')),
                    ],
                  ),
                  subtitle: Text(tr('foregroundServiceExplanation')),
                  value: settings.useFGService,
                  onChanged: (value) {
                    settings.useFGService = value;
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.sync_outlined),
                  title: Text(tr('enableBackgroundUpdates')),
                  value: settings.enableBackgroundUpdates,
                  onChanged: (value) {
                    settings.enableBackgroundUpdates = value;
                  },
                ),
                if (settings.enableBackgroundUpdates)
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('backgroundUpdateReqsExplanation'),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          tr('backgroundUpdateLimitsExplanation'),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        height8,
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.wifi_outlined),
                          title: Text(tr('bgUpdatesOnWiFiOnly')),
                          value: settings.bgUpdatesOnWiFiOnly,
                          onChanged: (value) {
                            settings.bgUpdatesOnWiFiOnly = value;
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.battery_charging_full_outlined),
                          title: Text(tr('bgUpdatesWhileChargingOnly')),
                          value: settings.bgUpdatesWhileChargingOnly,
                          onChanged: (value) {
                            settings.bgUpdatesWhileChargingOnly = value;
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCheckOnStartToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.power_settings_new_outlined),
          title: Text(tr('checkOnStart')),
          value: settings.checkOnStart,
          onChanged: (value) {
            settings.checkOnStart = value;
          },
        );
      },
    );
  }

  Widget _buildOnlyCheckInstalledToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.check_circle_outline),
          title: Text(tr('onlyCheckInstalledOrTrackOnlyApps')),
          value: settings.onlyCheckInstalledOrTrackOnlyApps,
          onChanged: (value) {
            settings.onlyCheckInstalledOrTrackOnlyApps = value;
          },
        );
      },
    );
  }

  Widget _buildParallelDownloadsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          secondary: const Icon(Icons.file_download_outlined),
          title: Row(
            children: [
              Expanded(child: Text(tr('parallelDownloads'))),
              InfoTooltip(message: tr('parallelDownloadsTooltip')),
            ],
          ),
          value: settings.parallelDownloads,
          onChanged: (value) {
            settings.parallelDownloads = value;
          },
        );
      },
    );
  }
}
