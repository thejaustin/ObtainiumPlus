import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/settings_provider.dart';
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.history_toggle_off_outlined),
          title: Text(tr('bgUpdateCheckInterval'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(settings.updateIntervalLabel),
          trailing: InfoTooltip(message: tr('backgroundUpdateCheckIntervalTooltip')),
        );
      },
    );
  }

  Widget _buildIntervalSlider(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: settings.updateIntervalSliderVal,
            max: settings.updateIntervalNodes.length.toDouble(),
            divisions: settings.updateIntervalNodes.length * 20,
            onChanged: (double value) {
              settings.updateIntervalSliderVal = value;
              settings.processIntervalSliderValue(value);
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
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            if (settings.updateInterval <= 0) return const SizedBox.shrink();

            bool canShowForeground = ((snapshot.data?.version.sdkInt ?? 0) >= 30) || settings.useShizuku;
            if (!canShowForeground) return const SizedBox.shrink();

            List<Widget> fgWidgets = [
              if (_matches(tr('foregroundService')))
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(tr('foregroundService'), style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text(tr('foregroundServiceExplanation')),
                  value: settings.useFGService,
                  onChanged: (value) => settings.useFGService = value,
                ),
              if (_matches(tr('enableBackgroundUpdates')))
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.sync_outlined),
                  title: Text(tr('enableBackgroundUpdates'), style: Theme.of(context).textTheme.bodyLarge),
                  value: settings.enableBackgroundUpdates,
                  onChanged: (value) => settings.enableBackgroundUpdates = value,
                ),
              if (settings.enableBackgroundUpdates) ...[
                if (_matches(tr('bgUpdatesOnWiFiOnly')))
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.wifi_outlined),
                    title: Text(tr('bgUpdatesOnWiFiOnly'), style: Theme.of(context).textTheme.bodyLarge),
                    value: settings.bgUpdatesOnWiFiOnly,
                    onChanged: (value) => settings.bgUpdatesOnWiFiOnly = value,
                  ),
                if (_matches(tr('bgUpdatesWhileChargingOnly')))
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.battery_charging_full_outlined),
                    title: Text(tr('bgUpdatesWhileChargingOnly'), style: Theme.of(context).textTheme.bodyLarge),
                    value: settings.bgUpdatesWhileChargingOnly,
                    onChanged: (value) => settings.bgUpdatesWhileChargingOnly = value,
                  ),
                // Only show Update Schedule section if Plus Feature is enabled
                if (_matches(tr('updateSchedule')) && settings.plusEnableUpdateSchedule)
                  _buildUpdateScheduleSection(context, settings),
              ]
            ];

            return Column(children: fgWidgets);
          },
        );
      },
    );
  }

  Widget _buildCheckOnStartToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.power_settings_new_outlined),
          title: Text(tr('checkOnStart'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.checkOnStart,
          onChanged: (value) => settings.checkOnStart = value,
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
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.file_download_outlined),
          title: Text(tr('parallelDownloads'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.parallelDownloads,
          onChanged: (value) => settings.parallelDownloads = value,
        );
      },
    );
  }

  Widget _buildUpdateScheduleSection(BuildContext context, SettingsProvider settings) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.schedule_outlined),
          title: Text(tr('updateSchedule'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: settings.useUpdateSchedule
              ? Text(settings.getScheduleDescription())
              : Text(tr('updateScheduleDescription')),
          value: settings.useUpdateSchedule,
          onChanged: (value) => settings.useUpdateSchedule = value,
        ),
        if (settings.useUpdateSchedule) ...[
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(tr('activeHours'), style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text('${settings.updateScheduleStartHour.toString().padLeft(2, '0')}:00 - ${settings.updateScheduleEndHour.toString().padLeft(2, '0')}:00'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimeRangePicker(context, settings),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(tr('activeDays'), style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text(_getDaysDescription(settings.updateScheduleDays)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDaysPicker(context, settings),
          ),
        ],
      ],
    );
  }

  String _getDaysDescription(List<int> days) {
    if (days.length == 7) return tr('everyDay');
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) return tr('weekdays');
    if (days.length == 2 && days.contains(6) && days.contains(7)) return tr('weekends');

    final dayNames = ['', tr('mon'), tr('tue'), tr('wed'), tr('thu'), tr('fri'), tr('sat'), tr('sun')];
    return days.map((d) => dayNames[d]).join(', ');
  }

  void _showTimeRangePicker(BuildContext context, SettingsProvider settings) {
    int startHour = settings.updateScheduleStartHour;
    int endHour = settings.updateScheduleEndHour;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tr('activeHours')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(tr('startTime')),
                trailing: DropdownButton<int>(
                  value: startHour,
                  items: List.generate(24, (i) => DropdownMenuItem(
                    value: i,
                    child: Text('${i.toString().padLeft(2, '0')}:00'),
                  )),
                  onChanged: (val) => setState(() => startHour = val ?? startHour),
                ),
              ),
              ListTile(
                title: Text(tr('endTime')),
                trailing: DropdownButton<int>(
                  value: endHour,
                  items: List.generate(24, (i) => DropdownMenuItem(
                    value: i,
                    child: Text('${i.toString().padLeft(2, '0')}:00'),
                  )),
                  onChanged: (val) => setState(() => endHour = val ?? endHour),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                settings.updateScheduleStartHour = startHour;
                settings.updateScheduleEndHour = endHour;
                Navigator.of(context).pop();
              },
              child: Text(tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDaysPicker(BuildContext context, SettingsProvider settings) {
    List<int> selectedDays = List.from(settings.updateScheduleDays);
    final dayNames = [tr('mon'), tr('tue'), tr('wed'), tr('thu'), tr('fri'), tr('sat'), tr('sun')];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tr('activeDays')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (index) {
              final day = index + 1; // 1=Mon, 7=Sun
              return CheckboxListTile(
                title: Text(dayNames[index]),
                value: selectedDays.contains(day),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      if (!selectedDays.contains(day)) selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                    selectedDays.sort();
                  });
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (selectedDays.isNotEmpty) {
                  settings.updateScheduleDays = selectedDays;
                }
                Navigator.of(context).pop();
              },
              child: Text(tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}
