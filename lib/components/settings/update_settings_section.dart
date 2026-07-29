import 'package:obtainium/utils/haptic_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'dart:async';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/services/background_update_service.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';

/// Update settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class UpdateSettingsSection extends StatelessWidget {
  final bool showIntervalLabel;
  final Function(bool) onIntervalLabelChange;
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const UpdateSettingsSection({
    super.key,
    required this.showIntervalLabel,
    required this.onIntervalLabelChange,
    required this.androidInfoFuture,
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

    List<Widget> children = [
      if (_matches(tr('runBgCheckNow')))
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _RunBgUpdateCheckNowButton(),
        ),
      if (_matches(tr('bgUpdateCheckInterval'))) ...[
        _buildIntervalLabel(context),
        _buildIntervalSlider(context),
      ],
      if (_matches(tr('bgUpdateRequiresWifi')))
        Consumer<UpdateSettingsProvider>(
          builder: (context, settings, _) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.wifi_outlined),
            title: Text(
              tr('bgUpdateRequiresWifi'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            value: settings.bgUpdateRequiresWifi,
            onChanged: (v) => settings.bgUpdateRequiresWifi = v,
          ),
        ),
      if (_matches(tr('bgUpdateRequiresCharging')))
        Consumer<UpdateSettingsProvider>(
          builder: (context, settings, _) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.battery_charging_full_outlined),
            title: Text(
              tr('bgUpdateRequiresCharging'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            value: settings.bgUpdateRequiresCharging,
            onChanged: (v) => settings.bgUpdateRequiresCharging = v,
          ),
        ),
      _buildForegroundServiceSection(context),
      if (_matches(tr('xiaomiBatteryTroubleshooting')))
        _buildXiaomiTroubleshooting(context),

      // Update check on start
      if (_matches(tr('checkOnStart')))
        Consumer<UpdateSettingsProvider>(
          builder: (context, settings, _) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.power_settings_new_outlined),
            title: Text(
              tr('checkOnStart'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(tr('checkOnStartDescription')),
            value: settings.checkOnStart,
            onChanged: (v) => settings.checkOnStart = v,
          ),
        ),

      // Only check installed or track only apps
      if (_matches(tr('onlyCheckInstalledOrTrackOnlyApps')))
        Consumer<UpdateSettingsProvider>(
          builder: (context, settings, _) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.check_circle_outline),
            title: Text(
              tr('onlyCheckInstalledOrTrackOnlyApps'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(tr('onlyCheckInstalledOrTrackOnlyAppsDescription')),
            value: settings.onlyCheckInstalledOrTrackOnlyApps,
            onChanged: (v) => settings.onlyCheckInstalledOrTrackOnlyApps = v,
          ),
        ),

      // Background updates on Wi-Fi only
      if (_matches(tr('bgUpdatesOnWiFiOnly')))
        Consumer<UpdateSettingsProvider>(
          builder: (context, settings, _) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.wifi_outlined),
            title: Text(
              tr('bgUpdatesOnWiFiOnly'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            value: settings.bgUpdatesOnWiFiOnly,
            onChanged: (v) => settings.bgUpdatesOnWiFiOnly = v,
          ),
        ),

      // Background updates while charging only
      if (_matches(tr('bgUpdatesWhileChargingOnly')))
        Consumer<UpdateSettingsProvider>(
          builder: (context, settings, _) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.battery_charging_full_outlined),
            title: Text(
              tr('bgUpdatesWhileChargingOnly'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            value: settings.bgUpdatesWhileChargingOnly,
            onChanged: (v) => settings.bgUpdatesWhileChargingOnly = v,
          ),
        ),

      // Parallel downloads
      if (_matches(tr('parallelDownloads'), isAdvanced: true))
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, _) => SwitchListTile.adaptive(
            secondary: const Icon(Icons.file_download_outlined),
            title: Text(
              tr('parallelDownloads'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(tr('parallelDownloadsDescription')),
            value: settings.parallelDownloads,
            onChanged: (v) => settings.parallelDownloads = v,
          ),
        ),

      // Concurrency Limit settings
      if (_matches(tr('parallelDownloads'), isAdvanced: true))
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: Text(tr('plusUpdateCheckConcurrency')),
            subtitle: Text(tr('plusUpdateCheckConcurrencyDescription')),
            trailing: DropdownButton<int>(
              value: settings.updateCheckConcurrencyLimit,
              onChanged: (val) {
                if (val != null) {
                  settings.updateCheckConcurrencyLimit = val;
                }
              },
              items: [1, 2, 3, 5, 10]
                  .map(
                    (limit) => DropdownMenuItem(
                      value: limit,
                      child: Text(limit.toString()),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

      if (_matches(tr('parallelDownloads'), isAdvanced: true))
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(tr('plusDownloadConcurrency')),
            subtitle: Text(tr('plusDownloadConcurrencyDescription')),
            trailing: DropdownButton<int>(
              value: settings.updateDownloadConcurrencyLimit,
              onChanged: (val) {
                if (val != null) {
                  settings.updateDownloadConcurrencyLimit = val;
                }
              },
              items: [1, 2, 3, 4, 5]
                  .map(
                    (limit) => DropdownMenuItem(
                      value: limit,
                      child: Text(limit.toString()),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

      _buildAdditionalUpdateSettings(context),
    ];

    if (children.every((w) => w is SizedBox && w.child == null))
      return const SizedBox.shrink();

    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('updates'),
      icon: Icons.update_rounded,
      isExpandable: !isSearching,
      initiallyExpanded: false,
      children: children,
    );
  }

  Widget _buildForegroundServiceSection(BuildContext context) {
    if (!_matches(tr('foregroundServiceExplanation')))
      return const SizedBox.shrink();
    return Consumer<UpdateSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.run_circle_outlined),
          title: Text(
            tr('foregroundServiceExplanation'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          value: settings.useFGService,
          onChanged: (value) => settings.useFGService = value,
        );
      },
    );
  }

  Widget _buildXiaomiTroubleshooting(BuildContext context) {
    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          var device = snapshot.data!;
          var isXiaomi =
              [
                'xiaomi',
                'poco',
                'redmi',
              ].contains(device.manufacturer.toLowerCase()) ||
              ['xiaomi', 'poco', 'redmi'].contains(device.brand.toLowerCase());

          if (isXiaomi) {
            return ListTile(
              leading: const Icon(
                Icons.battery_alert_outlined,
                color: Colors.orange,
              ),
              title: Text(
                tr('xiaomiBatteryTroubleshooting'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
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
    showDialog(
      context: context,
      builder: (ctx) => buildXiaomiTroubleshootingDialog(ctx),
    );
  }

  Widget buildXiaomiTroubleshootingDialog(BuildContext context) {
    return GlassDialog(
      title: tr('xiaomiTroubleshootingTitle'),
      icon: Icons.battery_alert_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('xiaomiTroubleshootingDescription')),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              AppHaptics.selectionClick();
              AppInstallService.openXiaomiAutostartSettings();
            },
            icon: const Icon(Icons.play_arrow_outlined),
            label: Text(tr('enableAutostart')),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              AppHaptics.selectionClick();
              AppInstallService.openXiaomiBatterySaverSettings();
            },
            icon: const Icon(Icons.battery_saver_outlined),
            label: Text(tr('disableBatterySaver')),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('ok')),
        ),
      ],
    );
  }

  Widget _buildIntervalLabel(BuildContext context) {
    return Consumer<UpdateSettingsProvider>(
      builder: (context, updateSettings, child) {
        return ListTile(
          leading: const Icon(Icons.history_toggle_off_outlined),
          title: Text(
            tr('bgUpdateCheckInterval'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(updateSettings.updateIntervalLabel),
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

  Widget _buildAdditionalUpdateSettings(BuildContext context) {
    return Consumer3<
      UpdateSettingsProvider,
      ViewSettingsProvider,
      PlusSettingsProvider
    >(
      builder: (context, updateSettings, viewSettings, plusSettings, child) {
        return Column(
          children: [
            if (_matches(tr('checkUpdateOnDetailPage')))
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.description_outlined),
                title: Text(
                  tr('checkUpdateOnDetailPage'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                value: updateSettings.checkUpdateOnDetailPage,
                onChanged: (value) =>
                    updateSettings.checkUpdateOnDetailPage = value,
              ),
            if (plusSettings.enableAllPlusFeatures &&
                _matches(tr('plusSystemUpdateScanner'), isAdvanced: true))
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.system_update_alt_rounded),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('plusSystemUpdateScanner'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(
                          plusSettings.plusGlobalCornerRadius.clamp(0.0, 12.0),
                        ),
                      ),
                      child: Text(
                        tr('beta'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(tr('plusSystemUpdateScannerDescription')),
                value: plusSettings.plusEnableSystemUpdateScanner,
                onChanged: (v) =>
                    plusSettings.plusEnableSystemUpdateScanner = v,
              ),
            if (plusSettings.enableAllPlusFeatures &&
                _matches(tr('plusEnableUpdateSchedule')))
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.schedule_outlined),
                title: Text(
                  tr('plusEnableUpdateSchedule'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(tr('plusEnableUpdateScheduleDescription')),
                value: plusSettings.plusEnableUpdateSchedule,
                onChanged: (v) => plusSettings.plusEnableUpdateSchedule = v,
              ),
            if (plusSettings.enableAllPlusFeatures &&
                _matches(tr('updateSchedule')) &&
                plusSettings.plusEnableUpdateSchedule)
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(
                  tr('updateSchedule'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(updateSettings.getScheduleDescription()),
                trailing: Switch(
                  value: updateSettings.useUpdateSchedule,
                  onChanged: (bool value) {
                    updateSettings.useUpdateSchedule = value;
                  },
                ),
                onTap: () => _showScheduleDialog(context, updateSettings),
              ),
            if (_matches(tr('releaseChannel'), isAdvanced: true))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: Text(
                      tr('releaseChannel'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(tr('obtainiumReleaseChannelDescription')),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'latest',
                            label: Text(tr('latest')),
                            icon: const Icon(Icons.new_releases_outlined),
                          ),
                          ButtonSegment(
                            value: 'dev',
                            label: Text(tr('dev')),
                            icon: const Icon(Icons.bug_report_outlined),
                          ),
                        ],
                        selected: {updateSettings.obtainiumReleaseChannel},
                        onSelectionChanged: (value) {
                          final newValue = value.first;
                          if (newValue == 'dev' &&
                              updateSettings.obtainiumReleaseChannel != 'dev') {
                            showDialog(
                              context: context,
                              builder: (ctx) => GlassDialog(
                                icon: Icons.warning_amber_rounded,
                                title: tr('devChannelWarningTitle'),
                                content: Text(tr('devChannelWarningMessage')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(tr('cancel')),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      updateSettings.obtainiumReleaseChannel =
                                          'dev';
                                      Navigator.pop(ctx);
                                    },
                                    child: Text(tr('enable')),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            updateSettings.obtainiumReleaseChannel = newValue;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            Consumer<BehaviorSettingsProvider>(
              builder: (context, behaviorSettings, _) => Column(
                children: [
                  if (_matches(tr('preferredUpdateSource')))
                    ListTile(
                      leading: const Icon(Icons.store_outlined),
                      title: Text(
                        tr('preferredUpdateSource'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        _getSourceDisplayName(
                          behaviorSettings.preferredUpdateSource,
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: behaviorSettings.preferredUpdateSource,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            behaviorSettings.preferredUpdateSource = newValue;
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'direct',
                            child: Text(tr('direct')),
                          ),
                          DropdownMenuItem(
                            value: 'play_store',
                            child: Text(tr('playStore')),
                          ),
                          DropdownMenuItem(
                            value: 'aurora',
                            child: Text(tr('auroraStore')),
                          ),
                          DropdownMenuItem(
                            value: 'github',
                            child: Text(tr('github')),
                          ),
                          DropdownMenuItem(
                            value: 'apkpure',
                            child: Text(tr('apkpure')),
                          ),
                        ],
                      ),
                    ),
                  if (_matches(tr('allowThirdPartySources'), isAdvanced: true))
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.cloud_download_outlined),
                      title: Text(
                        tr('allowThirdPartySources'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(tr('allowThirdPartySourcesDescription')),
                      value: behaviorSettings.allowThirdPartySources,
                      onChanged: (value) =>
                          behaviorSettings.allowThirdPartySources = value,
                    ),
                  if (plusSettings.enableAllPlusFeatures &&
                      _matches(tr('plusEnableAutoUpdateRules')))
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.rule_outlined),
                      title: Text(
                        tr('plusEnableAutoUpdateRules'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        tr('plusEnableAutoUpdateRulesDescription'),
                      ),
                      value: plusSettings.plusEnableAutoUpdateRules,
                      onChanged: (v) =>
                          plusSettings.plusEnableAutoUpdateRules = v,
                    ),
                  if (plusSettings.enableAllPlusFeatures &&
                      plusSettings.plusEnableAutoUpdateRules &&
                      _matches(tr('autoUpdateRules')))
                    ListTile(
                      leading: const Icon(Icons.rule_outlined),
                      title: Text(
                        tr('autoUpdateRules'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(tr('autoUpdateRulesDescription')),
                      onTap: () => _showAutoUpdateRulesDialog(
                        context,
                        updateSettings,
                        viewSettings,
                      ),
                    ),
                  if (_matches(tr('usePlayStoreAppLinks')))
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.android_outlined),
                      title: Text(
                        tr('usePlayStoreAppLinks'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(tr('usePlayStoreAppLinksDescription')),
                      value: behaviorSettings.usePlayStoreAppLinks,
                      onChanged: (value) =>
                          behaviorSettings.usePlayStoreAppLinks = value,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getSourceDisplayName(String source) {
    switch (source) {
      case 'direct':
        return tr('direct');
      case 'play_store':
        return tr('playStore');
      case 'aurora':
        return tr('auroraStore');
      case 'github':
        return tr('github');
      case 'apkpure':
        return tr('apkpure');
      default:
        return tr('direct');
    }
  }

  void _showScheduleDialog(
    BuildContext context,
    UpdateSettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return GlassDialog(
          title: tr('updateSchedule'),
          icon: Icons.schedule_outlined,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
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
                              items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('$i:00'),
                                ),
                              ),
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
                              items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('$i:00'),
                                ),
                              ),
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
                      final isSelected = settings.updateScheduleDays.contains(
                        day,
                      );
                      final dayNames = [
                        '',
                        tr('mon'),
                        tr('tue'),
                        tr('wed'),
                        tr('thu'),
                        tr('fri'),
                        tr('sat'),
                        tr('sun'),
                      ];
                      return FilterChip(
                        label: Text(dayNames[day]),
                        selected: isSelected,
                        onSelected: (selected) {
                          final current = List<int>.from(
                            settings.updateScheduleDays,
                          );
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
              );
            },
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('done')),
            ),
          ],
        );
      },
    );
  }

  void _showAutoUpdateRulesDialog(
    BuildContext context,
    UpdateSettingsProvider updateSettings,
    ViewSettingsProvider viewSettings,
  ) {
    final appsProvider = context.read<AppsProvider>();
    final categories = viewSettings.categories.keys.toList();
    final allTags = appsProvider
        .getAppValues()
        .expand((a) => a.app.tags)
        .toSet()
        .toList();
    allTags.sort();

    showDialog(
      context: context,
      builder: (context) {
        return GlassDialog(
          title: tr('autoUpdateRules'),
          icon: Icons.rule_outlined,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              final rules = updateSettings.autoUpdateRules;

              Widget buildRuleItem(String key, String title, bool isCategory) {
                final ruleKey = isCategory ? 'cat_$key' : 'tag_$key';
                final rule =
                    rules[ruleKey] ?? {'wifiOnly': false, 'disabled': false};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: Text(tr('wifiOnly')),
                      value: rule['wifiOnly'] == true,
                      onChanged: (val) {
                        setDialogState(() {
                          rules[ruleKey] = {...rule, 'wifiOnly': val ?? false};
                          updateSettings.autoUpdateRules = rules;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: Text(tr('disableBackgroundUpdates')),
                      value: rule['disabled'] == true,
                      onChanged: (val) {
                        setDialogState(() {
                          rules[ruleKey] = {...rule, 'disabled': val ?? false};
                          updateSettings.autoUpdateRules = rules;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                  ],
                );
              }

              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (categories.isNotEmpty) ...[
                        _sectionHeader(context, tr('perCategoryRules')),
                        const SizedBox(height: 8),
                        ...categories.map((c) => buildRuleItem(c, c, true)),
                      ],
                      if (allTags.isNotEmpty) ...[
                        _sectionHeader(context, tr('perTagRules')),
                        const SizedBox(height: 8),
                        ...allTags.map((t) => buildRuleItem(t, t, false)),
                      ],
                      if (categories.isEmpty && allTags.isEmpty)
                        Text(
                          tr('noCategoriesOrTags'),
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('done')),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _RunBgUpdateCheckNowButton extends StatefulWidget {
  const _RunBgUpdateCheckNowButton();

  @override
  State<_RunBgUpdateCheckNowButton> createState() =>
      _RunBgUpdateCheckNowButtonState();
}

class _RunBgUpdateCheckNowButtonState
    extends State<_RunBgUpdateCheckNowButton> {
  bool _isRunning = false;

  Future<void> _trigger() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    // Read the provider before the async gap so we don't touch context after.
    final LogsProvider logs = context.read<LogsProvider>();
    await logs.add(
      'Manual background update check triggered from settings',
      level: LogLevel.info,
    );
    try {
      final String taskId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
      await BackgroundUpdateService.bgUpdateCheck(taskId, null);
      await logs.add(
        'Manual background update check completed',
        level: LogLevel.info,
      );
    } catch (e) {
      unawaited(
        logs.add(
          'Manual background update check failed: $e',
          level: LogLevel.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: _isRunning ? null : _trigger,
        style: FilledButton.styleFrom(
          textStyle: Theme.of(context).textTheme.bodyLarge,
        ),
        child: _isRunning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('runBgCheckNow'.tr()),
      ),
    );
  }
}
