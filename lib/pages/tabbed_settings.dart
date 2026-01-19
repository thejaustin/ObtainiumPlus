import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/behavior_settings_section.dart';
import 'package:obtainium/components/settings/boolean_control_grid.dart';
import 'package:obtainium/components/settings/quick_toggles_dashboard.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/services/app_install_service.dart';
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

// Global variable for cached device info
AndroidDeviceInfo? _cachedDeviceInfo;

class TabbedSettingsPage extends StatefulWidget {
  const TabbedSettingsPage({super.key});

  @override
  State<TabbedSettingsPage> createState() => _TabbedSettingsPageState();
}

class _TabbedSettingsPageState extends State<TabbedSettingsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  
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
    _tabController = TabController(length: 3, vsync: this);
    // Cache the android info on init
    _androidInfoFuture = DeviceInfoPlugin().androidInfo.then((info) {
      _cachedAndroidInfo = info;
      return info;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: Text(tr('settings')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('appearance')),
            Tab(text: tr('updatesSources')),
            Tab(text: tr('appManagement')),
            Tab(text: tr('advanced')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Appearance
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const QuickTogglesDashboard(),
                      ThemeSettingsSection(
                        androidInfoFuture: _androidInfoFuture,
                        colorsNameMap: colorsNameMap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tab 2: Updates & Sources
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UpdateSettingsSection(
                        showIntervalLabel: showIntervalLabel,
                        onIntervalLabelChange: (value) {
                          setState(() {
                            showIntervalLabel = value;
                          });
                        },
                        androidInfoFuture: _androidInfoFuture,
                      ),
                      height16,
                      ...sourceSpecificFields,
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tab 3: App Management
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppsViewSettingsSection(
                        onSetState: setState,
                      ),
                      height16,
                      BehaviorSettingsSection(
                        sortDropdown: sortDropdown,
                        orderDropdown: orderDropdown,
                        localeDropdown: localeDropdown,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tab 4: Advanced
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdvancedSettingsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
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

  Future<void> _reportIssue() async {
    var logs = logString ?? '';
    if (logs.length > 2000) {
      logs = logs.substring(logs.length - 2000);
    }

    var appInfo = await AppInstallService.getInstalledInfo(obtainiumId);
    var deviceInfo = await _cachedDeviceInfo;
    var androidInfo = await _androidInfoFuture;

    var body = '''${tr('reportIssue')}
    
App: $appInfo
Device: $deviceInfo
Android: $androidInfo

$logs''';

    var url = Uri.parse(
      'https://github.com/ImranR98/Obtainium/issues/new?body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      Clipboard.setData(ClipboardData(text: url.toString()));
      showMessage(tr('copiedToClipboard'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('appLogs')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
        child: logString != null
            ? Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Text(logString!),
                ),
              )
            : FutureBuilder(
                future: context.read<LogsProvider>().get(after: DateTime.now().subtract(const Duration(days: 7))),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    logString = snapshot.data;
                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(snapshot.data ?? ''),
                      ),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(tr('close')),
        ),
        TextButton(
          onPressed: () {
            context.read<LogsProvider>().clear();
            Navigator.of(context).pop();
          },
          child: Text(tr('clearCache')),
        ),
        TextButton(
          onPressed: () {
            _reportIssue();
            Navigator.of(context).pop();
          },
          child: Text(tr('reportIssue')),
        ),
      ],
    );
  }
}