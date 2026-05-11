import 'package:obtainium/utils/haptic_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
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

      // Parallel downloads
      if (_matches(tr('parallelDownloads')))
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

      _buildAdditionalUpdateSettings(context),
    ];

    if (children.every((w) => w is SizedBox && w.child == null))
      return const SizedBox.shrink();

    return SettingsGroup(
      title: isSearching ? null : tr('updates'),
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

  Widget _buildFeatureToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required dynamic Function(dynamic) value,
    required void Function(dynamic, bool) onChanged,
    required bool Function(dynamic) visible,
    required Type providerType,
  }) {
    if (providerType == SettingsProvider) {
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
    } else if (providerType == UpdateSettingsProvider) {
      return Consumer<UpdateSettingsProvider>(
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
    return const SizedBox.shrink();
  }

  Widget _buildAdditionalUpdateSettings(BuildContext context) {
    return Consumer3<
      UpdateSettingsProvider,
      SettingsProvider,
      PlusSettingsProvider
    >(
      builder: (context, updateSettings, settings, plusSettings, child) {
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
            if (_matches(tr('updateSchedule')) &&
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
            if (_matches(tr('releaseChannel')))
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: Text(
                  tr('releaseChannel'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(tr('obtainiumReleaseChannelDescription')),
                trailing: DropdownButton<String>(
                  value: updateSettings.obtainiumReleaseChannel,
                  onChanged: (String? newValue) {
                    if (newValue == null) return;
                    if (newValue == 'dev' &&
                        updateSettings.obtainiumReleaseChannel != 'dev') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          title: Text(tr('devChannelWarningTitle')),
                          content: Text(tr('devChannelWarningMessage')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(tr('cancel')),
                            ),
                            FilledButton(
                              onPressed: () {
                                updateSettings.obtainiumReleaseChannel = 'dev';
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
                  items: [
                    DropdownMenuItem(
                      value: 'latest',
                      child: Text(tr('latest')),
                    ),
                    DropdownMenuItem(value: 'dev', child: Text(tr('dev'))),
                  ],
                ),
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
                  if (_matches(tr('allowThirdPartySources')))
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
                  if (plusSettings.plusEnableAutoUpdateRules &&
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
                        settings,
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
    SettingsProvider settings,
  ) {
    final appsProvider = context.read<AppsProvider>();
    final categories = settings.categories.keys.toList();
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
