import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/behavior_settings_section.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool showIntervalLabel = true;
  final Map<ColorSwatch<Object>, String> colorsNameMap =
      <ColorSwatch<Object>, String>{
        ColorTools.createPrimarySwatch(obtainiumThemeColor): 'Obtainium',
      };

  // PERFORMANCE: Cache DeviceInfoPlugin result to avoid redundant async calls
  AndroidDeviceInfo? _cachedAndroidInfo;
  Future<AndroidDeviceInfo>? _androidInfoFuture;

  @override
  void initState() {
    super.initState();
    // Cache the android info on init
    _androidInfoFuture = DeviceInfoPlugin().androidInfo.then((info) {
      _cachedAndroidInfo = info;
      return info;
    });
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children, {bool initiallyExpanded = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: initiallyExpanded ? 2 : 0,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        ),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            HapticFeedback.lightImpact();
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 0.15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          initiallyExpanded: initiallyExpanded,
          childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.centerLeft,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    SourceProvider sourceProvider = SourceProvider();
    if (settingsProvider.prefs == null) settingsProvider.initializeSettings();

    var sortDropdown = DropdownButtonFormField(
      isExpanded: true,
      decoration: InputDecoration(labelText: tr('appSortBy')),
      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
      value: settingsProvider.sortColumn,
      items: [
        DropdownMenuItem(
          value: SortColumnSettings.authorName,
          child: Text(tr('authorName')),
        ),
        DropdownMenuItem(
          value: SortColumnSettings.nameAuthor,
          child: Text(tr('nameAuthor')),
        ),
        DropdownMenuItem(
          value: SortColumnSettings.added,
          child: Text(tr('asAdded')),
        ),
        DropdownMenuItem(
          value: SortColumnSettings.releaseDate,
          child: Text(tr('releaseDate')),
        ),
        DropdownMenuItem(
          value: SortColumnSettings.lastUpdated,
          child: Text(tr('lastUpdated')),
        ),
        DropdownMenuItem(
          value: SortColumnSettings.source,
          child: Text(tr('appSource')),
        ),
        DropdownMenuItem(
          value: SortColumnSettings.installDate,
          child: Text(tr('installDate')),
        ),
        DropdownMenuItem(
          value: SortColumnSettings.lastCheckDate,
          child: Text(tr('lastCheckDate')),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          settingsProvider.sortColumn = value;
        }
      },
    );

    var orderDropdown = DropdownButtonFormField(
      isExpanded: true,
      decoration: InputDecoration(labelText: tr('appSortOrder')),
      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
      value: settingsProvider.sortOrder,
      items: [
        DropdownMenuItem(
          value: SortOrderSettings.ascending,
          child: Text(tr('ascending')),
        ),
        DropdownMenuItem(
          value: SortOrderSettings.descending,
          child: Text(tr('descending')),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          settingsProvider.sortOrder = value;
        }
      },
    );

    var localeDropdown = DropdownButtonFormField(
      decoration: InputDecoration(labelText: tr('language')),
      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
      value: settingsProvider.forcedLocale,
      items: [
        DropdownMenuItem(value: null, child: Text(tr('followSystem'))),
        ...supportedLocales.map(
          (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
        ),
      ],
      onChanged: (value) {
        settingsProvider.forcedLocale = value;
        if (value != null) {
          context.setLocale(value);
        } else {
          settingsProvider.resetLocaleSafe(context);
        }
      },
    );

    var sourceSpecificFields = sourceProvider.sources.map((e) {
      if (e.sourceConfigSettingFormItems.isNotEmpty) {
        return GeneratedForm(
          items: e.sourceConfigSettingFormItems.map((e) {
            if (e is GeneratedFormSwitch) {
              e.defaultValue = settingsProvider.getSettingBool(e.key);
            } else {
              e.defaultValue = settingsProvider.getSettingString(e.key);
            }
            return [e];
          }).toList(),
          onValueChanges: (values, valid, isBuilding) {
            if (valid && !isBuilding) {
              values.forEach((key, value) {
                var formItem = e.sourceConfigSettingFormItems
                    .where((i) => i.key == key)
                    .firstOrNull;
                if (formItem is GeneratedFormSwitch) {
                  settingsProvider.setSettingBool(key, value == true);
                } else {
                  settingsProvider.setSettingString(key, value ?? '');
                }
              });
            }
          },
        );
      } else {
        return Container();
      }
    });

    const height8 = SizedBox(height: 8);
    const height16 = SizedBox(height: 16);
    const height32 = SizedBox(height: 32);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        cacheExtent: 300.0,
        slivers: <Widget>[
          CustomAppBar(title: tr('settings')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: settingsProvider.prefs == null
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(context, tr('appearance'), [
                          ThemeSettingsSection(
                            androidInfoFuture: _androidInfoFuture,
                            colorsNameMap: colorsNameMap,
                          ),
                        ]),

                        _buildSection(context, tr('updates'), [
                          UpdateSettingsSection(
                            showIntervalLabel: showIntervalLabel,
                            onIntervalLabelChange: (value) {
                              setState(() {
                                showIntervalLabel = value;
                              });
                            },
                            androidInfoFuture: _androidInfoFuture,
                          ),
                        ]),

                        _buildSection(context, tr('sourceSpecific'), [
                          ...sourceSpecificFields,
                        ]),
                        
                        _buildSection(context, tr('categories'), [
                          AppsViewSettingsSection(
                            onSetState: setState,
                          ),
                        ]),

                        _buildSection(context, tr('general'), [
                          BehaviorSettingsSection(
                            sortDropdown: sortDropdown,
                            orderDropdown: orderDropdown,
                            localeDropdown: localeDropdown,
                          ),
                        ]),

                        _buildSection(context, tr('advanced'), [
                          const AdvancedSettingsSection(),
                        ]),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        launchUrlString(
                          settingsProvider.sourceUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.code),
                      tooltip: tr('appSource'),
                    ),
                    IconButton(
                      onPressed: () {
                        launchUrlString(
                          'https://wiki.obtainium.imranr.dev/',
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.help_outline_rounded),
                      tooltip: tr('wiki'),
                    ),
                    IconButton(
                      onPressed: () {
                        launchUrlString(
                          'https://apps.obtainium.imranr.dev/',
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.apps_rounded),
                      tooltip: tr('crowdsourcedConfigsLabel'),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<LogsProvider>().get().then((logs) {
                          if (logs.isEmpty) {
                            showMessage(ObtainiumError(tr('noLogs')), context);
                          } else {
                            showDialog(
                              context: context,
                              builder: (BuildContext ctx) {
                                return const LogsDialog();
                              },
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.bug_report_outlined),
                      tooltip: tr('appLogs'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LogsDialog extends StatefulWidget {
  const LogsDialog({super.key});

  @override
  State<LogsDialog> createState() => _LogsDialogState();
}

class _LogsDialogState extends State<LogsDialog> {
  String? logString;
  List<int> days = [7, 5, 4, 3, 2, 1];

  @override
  Widget build(BuildContext context) {
    var logsProvider = context.read<LogsProvider>();
    void filterLogs(int days) {
      logsProvider
          .get(after: DateTime.now().subtract(Duration(days: days)))
          .then((value) {
            setState(() {
              String l = value.map((e) => e.toString()).join('\n\n');
              logString = l.isNotEmpty ? l : tr('noLogs');
            });
          });
    }

    if (logString == null) {
      filterLogs(days.first);
    }

    return AlertDialog(
      scrollable: true,
      title: Text(tr('appLogs')),
      content: Column(
        children: [
          DropdownButtonFormField(
            dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
            iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
            value: days.first,
            items: days
                .map(
                  (e) =>
                      DropdownMenuItem(value: e, child: Text(plural('day', e))),
                )
                .toList(),
            onChanged: (d) {
              filterLogs(d ?? 7);
            },
          ),
          const SizedBox(height: 32),
          Text(logString ?? ''),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            var cont =
                (await showDialog<Map<String, dynamic>?>(context: context, builder: (BuildContext ctx) { return GeneratedFormModal(title: tr('appLogs'), items: const [], initValid: true, message: tr('removeFromObtainium')); })) != null;
            if (cont) {
              logsProvider.clear();
              Navigator.of(context).pop();
            }
          },
          child: Text(tr('remove')),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(tr('close')),
        ),
        TextButton(
          onPressed: () {
            Share.share(logString ?? '', subject: tr('appLogs'));
            Navigator.of(context).pop();
          },
          child: Text(tr('share')),
        ),
      ],
    );
  }
}

