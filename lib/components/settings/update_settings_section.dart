import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:provider/provider.dart';

/// Update settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class UpdateSettingsSection extends StatelessWidget {
  final bool showIntervalLabel;
  final Function(bool) onIntervalLabelChange;
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final String? searchQuery;

  const UpdateSettingsSection({
    super.key,
    required this.showIntervalLabel,
    required this.onIntervalLabelChange,
    required this.androidInfoFuture,
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
      if (_matches(tr('bgUpdateCheckInterval'))) ...[
        _buildIntervalLabel(context),
        _buildIntervalSlider(context),
      ],
      _buildForegroundServiceSection(context),
      if (_matches(tr('xiaomiBatteryTroubleshooting'))) _buildXiaomiTroubleshooting(context),
      if (_matches(tr('checkOnStart'))) _buildCheckOnStartToggle(context),
      if (_matches(tr('onlyCheckInstalledOrTrackOnlyApps'))) _buildOnlyCheckInstalledToggle(context),
      if (_matches(tr('parallelDownloads'))) _buildParallelDownloadsToggle(context),
      _buildAdditionalUpdateSettings(context),
    ];

    if (children.every((w) => w is SizedBox && w.child == null)) return const SizedBox.shrink();

    return SettingsGroup(
      title: isSearching ? null : tr('updates'),
      children: children,
    );
  }

  Widget _buildXiaomiTroubleshooting(BuildContext context) {
    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          var device = snapshot.data!;
          var isXiaomi = ['xiaomi', 'poco', 'redmi'].contains(device.manufacturer.toLowerCase()) ||
              ['xiaomi', 'poco', 'redmi'].contains(device.brand.toLowerCase());

          if (isXiaomi) {
            return ListTile(
              leading: const Icon(Icons.battery_alert_outlined, color: Colors.orange),
              title: Text(tr('xiaomiBatteryTroubleshooting'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(tr('xiaomiBatteryTroubleshootingDescription')),
              onTap: () => showXiaomiTroubleshootingDialog(context),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  void showXiaomiTroubleshootingDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => buildXiaomiTroubleshootingDialog(ctx));
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
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('ok')))],
    );
  }

  Widget _buildIntervalLabel(BuildContext context) {
    return Consumer<UpdateSettingsProvider>(
      builder: (context, updateSettings, child) {
        return ListTile(
          leading: const Icon(Icons.history_toggle_off_outlined),
          title: Text(tr('bgUpdateCheckInterval'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(updateSettings.updateIntervalLabel),
          trailing: InfoTooltip(message: tr('backgroundUpdateCheckIntervalTooltip')),
        );
      },
    );
  }

  Widget _buildIntervalSlider(BuildContext context) {
    return Consumer<UpdateSettingsProvider>(
      builder: (context, updateSettings, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: updateSettings.updateIntervalSliderVal,
            max: updateSettings.updateIntervalNodes.length.toDouble(),
            divisions: updateSettings.updateIntervalNodes.length * 20,
            onChanged: (double value) {
              updateSettings.updateIntervalSliderVal = value;
              updateSettings.processIntervalSliderValue(value);
              onIntervalLabelChange(false);
            },
            onChangeEnd: (double value) => onIntervalLabelChange(true),
          ),
        );
      },
    );
  }

  Widget _buildForegroundServiceSection(BuildContext context) {
    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        return Consumer2<SettingsProvider, UpdateSettingsProvider>(
          builder: (context, settings, updateSettings, child) {
            if (updateSettings.updateInterval <= 0) return const SizedBox.shrink();

            bool canShowForeground = ((snapshot.data?.version.sdkInt ?? 0) >= 30) || settings.behaviorSettings.useShizuku;
            if (!canShowForeground) return const SizedBox.shrink();

            List<Widget> fgWidgets = [
              if (_matches(tr('foregroundService')))
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(tr('foregroundService'), style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text(tr('foregroundServiceExplanation')),
                  value: updateSettings.useFGService,
                  onChanged: (value) => updateSettings.useFGService = value,
                ),
              if (_matches(tr('enableBackgroundUpdates')))
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.sync_outlined),
                  title: Text(tr('enableBackgroundUpdates'), style: Theme.of(context).textTheme.bodyLarge),
                  value: updateSettings.enableBackgroundUpdates,
                  onChanged: (value) => updateSettings.enableBackgroundUpdates = value,
                ),
              if (updateSettings.enableBackgroundUpdates) ...[
                if (_matches(tr('bgUpdatesOnWiFiOnly')))
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.wifi_outlined),
                    title: Text(tr('bgUpdatesOnWiFiOnly'), style: Theme.of(context).textTheme.bodyLarge),
                    value: updateSettings.bgUpdatesOnWiFiOnly,
                    onChanged: (value) => updateSettings.bgUpdatesOnWiFiOnly = value,
                  ),
                if (_matches(tr('bgUpdatesWhileChargingOnly')))
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.battery_charging_full_outlined),
                    title: Text(tr('bgUpdatesWhileChargingOnly'), style: Theme.of(context).textTheme.bodyLarge),
                    value: updateSettings.bgUpdatesWhileChargingOnly,
                    onChanged: (value) => updateSettings.bgUpdatesWhileChargingOnly = value,
                  ),
              ]
            ];

            return Column(children: fgWidgets);
          },
        );
      },
    );
  }

  Widget _buildCheckOnStartToggle(BuildContext context) {
    return Consumer<UpdateSettingsProvider>(
      builder: (context, updateSettings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.power_settings_new_outlined),
          title: Text(tr('checkOnStart'), style: Theme.of(context).textTheme.bodyLarge),
          value: updateSettings.checkOnStart,
          onChanged: (value) => updateSettings.checkOnStart = value,
        );
      },
    );
  }

  Widget _buildOnlyCheckInstalledToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.check_circle_outline),
          title: Text(tr('onlyCheckInstalledOrTrackOnlyApps'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.onlyCheckInstalledOrTrackOnlyApps,
          onChanged: (value) => settings.onlyCheckInstalledOrTrackOnlyApps = value,
        );
      },
    );
  }

  Widget _buildParallelDownloadsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.file_download_outlined),
          title: Text(tr('parallelDownloads'), style: Theme.of(context).textTheme.bodyLarge),
          value: settingsProvider.parallelDownloads,
          onChanged: (value) => settingsProvider.parallelDownloads = value,
        );
      },
    );
  }

  Widget _buildAdditionalUpdateSettings(BuildContext context) {
    return Consumer<UpdateSettingsProvider>(
      builder: (context, updateSettings, child) {
        return Column(
          children: [
            if (_matches(tr('checkUpdateOnDetailPage')))
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.description_outlined),
                title: Text(tr('checkUpdateOnDetailPage'), style: Theme.of(context).textTheme.bodyLarge),
                value: updateSettings.checkUpdateOnDetailPage,
                onChanged: (value) => updateSettings.checkUpdateOnDetailPage = value,
              ),
            if (_matches(tr('updateSchedule')))
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(tr('updateSchedule'), style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(updateSettings.getScheduleDescription()),
                trailing: Switch(
                  value: updateSettings.useUpdateSchedule,
                  onChanged: (bool value) {
                    updateSettings.useUpdateSchedule = value;
                  },
                ),
                onTap: () => _showScheduleDialog(context, updateSettings),
              ),
            if (_matches(tr('releaseChannel')))
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: Text(tr('releaseChannel'), style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(tr('obtainiumReleaseChannelDescription')),
                trailing: DropdownButton<String>(
                  value: updateSettings.obtainiumReleaseChannel,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      updateSettings.obtainiumReleaseChannel = newValue;
                    }
                  },
                  items: [
                    DropdownMenuItem(value: 'latest', child: Text(tr('latest'))),
                    DropdownMenuItem(value: 'dev', child: Text(tr('dev'))),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showScheduleDialog(BuildContext context, UpdateSettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(tr('updateSchedule')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(tr('start')),
                            DropdownButton<int>(
                              value: settings.updateScheduleStartHour,
                              onChanged: (val) {
                                if (val != null) {
                                  settings.updateScheduleStartHour = val;
                                  setDialogState(() {});
                                }
                              },
                              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(tr('end')),
                            DropdownButton<int>(
                              value: settings.updateScheduleEndHour,
                              onChanged: (val) {
                                if (val != null) {
                                  settings.updateScheduleEndHour = val;
                                  setDialogState(() {});
                                }
                              },
                              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(tr('days')),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final isSelected = settings.updateScheduleDays.contains(day);
                      final dayNames = ['', tr('mon'), tr('tue'), tr('wed'), tr('thu'), tr('fri'), tr('sat'), tr('sun')];
                      return FilterChip(
                        label: Text(dayNames[day]),
                        selected: isSelected,
                        onSelected: (selected) {
                          final current = List<int>.from(settings.updateScheduleDays);
                          if (selected) {
                            current.add(day);
                          } else if (current.length > 1) {
                            current.remove(day);
                          }
                          settings.updateScheduleDays = current;
                          setDialogState(() {});
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('done')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
