import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/behavior_settings_section.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/troubleshooting_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/models/settings_enums.dart';

import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/legacy_settings.dart';
import 'package:obtainium/pages/statistics.dart';

// Global variable for cached device info
AndroidDeviceInfo? _cachedDeviceInfo;

class SettingsPage extends StatefulWidget {
  final int initialTab; // Kept for backward compatibility, though tabs are removed
  const SettingsPage({super.key, this.initialTab = 0});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  bool showIntervalLabel = true;
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  final TextEditingController _searchController = TextEditingController();

  final Map<ColorSwatch<Object>, String> colorsNameMap =
      <ColorSwatch<Object>, String>{
        ColorTools.createPrimarySwatch(obtainiumThemeColor): 'Obtainium',
      };

  // PERFORMANCE: Cache SourceProvider to avoid recreating 24 source objects on every build
  late final SourceProvider _sourceProvider = SourceProvider();

  // PERFORMANCE: Cache DeviceInfoPlugin result to avoid redundant async calls
  AndroidDeviceInfo? _cachedAndroidInfo;
  Future<AndroidDeviceInfo>? _androidInfoFuture;
  bool _isIgnoringBatteryOptimizations = false;

  late List<Widget> _sourceSpecificFields;

  @override
  void initState() {
    super.initState();
    // Cache the android info on init
    _androidInfoFuture = DeviceInfoPlugin().androidInfo.then((info) {
      _cachedAndroidInfo = info;
      return info;
    });
    _checkBatteryStatus();

    // PERFORMANCE: Cache source specific fields once
    _sourceSpecificFields = _sourceProvider.sources
        .where((e) => e.sourceConfigSettingFormItems.isNotEmpty)
        .map((e) {
          return GeneratedForm(
            items: e.sourceConfigSettingFormItems.map((item) {
              if (item is GeneratedFormSwitch) {
                item.defaultValue = context.read<SettingsProvider>().getSettingBool(item.key);
              } else {
                item.defaultValue = context.read<SettingsProvider>().getSettingString(item.key);
              }
              return [item];
            }).toList(),
            onValueChanges: (values, valid, isBuilding) {
              if (valid && !isBuilding) {
                final settingsProvider = context.read<SettingsProvider>();
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
    }).toList();

    // Initialize settings if not already done (must NOT be called in build())
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<SettingsProvider>();
      if (sp.prefs == null) {
        sp.initializeSettings();
      }
    });
  }

  Future<void> _checkBatteryStatus() async {
    final isIgnoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (mounted) {
      setState(() {
        _isIgnoringBatteryOptimizations = isIgnoring;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  bool _matches(String text, String query) {
    if (query.isEmpty) return true;
    return text.toLowerCase().contains(query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsProvider, (bool, bool)>(
      selector: (_, sp) => (sp.plusEnableModernSettings, sp.prefs == null),
      builder: (context, data, _) {
        final (plusEnableModernSettings, prefsIsNull) = data;
        if (!plusEnableModernSettings) {
          return const LegacySettingsPage();
        }
        if (prefsIsNull) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return ValueListenableBuilder<String>(
          valueListenable: _searchQueryNotifier,
          builder: (context, searchQuery, _) {
            final bool isSearching = searchQuery.isNotEmpty;
            final settingsProvider = context.read<SettingsProvider>();

            // --- Dropdowns for Behavior Settings ---
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
      items:
          [
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
      items:
          [
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
      items:
          [
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
    // ----------------------------------------

    final sourceSpecificFields = _sourceSpecificFields;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
                                  // 1. Header with Title (Chrome Style)
                                  SliverAppBar.large(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    surfaceTintColor: Colors.transparent,
                                    title: isSearching 
                                      ? null 
                                      : Text(
                                          tr('settings'),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                  ),
                        
                                  // 2. Search Pill (Persistent below title)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: SearchBar(
                                        controller: _searchController,
                                        hintText: tr('searchSettings'),
                                        leading: const Icon(Icons.search),
                                        elevation: WidgetStateProperty.all(0),
                                        backgroundColor: WidgetStateProperty.all(
                                          Theme.of(context).colorScheme.surfaceContainerHigh,
                                        ),
                                        shape: WidgetStateProperty.all(
                                          const StadiumBorder(),
                                        ),
                                        onChanged: (value) {
                                          _searchQueryNotifier.value = value;
                                        },
                                        trailing: [
                                          if (searchQuery.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchQueryNotifier.value = '';
                                                _searchController.clear();
                                              },
                                            )
                                        ],
                                      ),
                                    ),
                                  ),
                        
                                  // 3. Settings Content
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    sliver: SliverList(
                                          delegate: SliverChildListDelegate([
                    // --- SEARCH RESULTS (FLATTENED) ---
                    if (isSearching) ...[
                        SettingsGroup(
                          title: tr('basics'),
                          children: [
                            if (_matches(tr('backgroundUpdates'), searchQuery))
                              SwitchListTile.adaptive(
                                secondary: const Icon(Icons.sync_outlined),
                                title: Text(tr('backgroundUpdates'), style: Theme.of(context).textTheme.bodyLarge),
                                value: settingsProvider.updateInterval > 0,
                                onChanged: (value) {
                                  settingsProvider.updateInterval = value ? 60 : 0;
                                },
                              ),
                            if (_matches(tr('batteryOpt'), searchQuery))
                              SwitchListTile.adaptive(
                                secondary: const Icon(Icons.battery_saver_outlined),
                                title: Text(tr('batteryOpt'), style: Theme.of(context).textTheme.bodyLarge),
                                subtitle: Text(_isIgnoringBatteryOptimizations ? tr('enabled') : tr('disabled')),
                                value: _isIgnoringBatteryOptimizations,
                                onChanged: (value) async {
                                  if (!_isIgnoringBatteryOptimizations) {
                                    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
                                    _checkBatteryStatus();
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ThemeSettingsSection(
                          androidInfoFuture: _androidInfoFuture,
                          colorsNameMap: colorsNameMap,
                          searchQuery: searchQuery,
                        ),
                        const SizedBox(height: 24),
                        UpdateSettingsSection(
                          showIntervalLabel: showIntervalLabel,
                          onIntervalLabelChange: (value) => setState(() => showIntervalLabel = value),
                          androidInfoFuture: _androidInfoFuture,
                          searchQuery: searchQuery,
                        ),
                        if (sourceSpecificFields.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SettingsGroup(
                            title: tr('sourceSpecific'),
                            children: sourceSpecificFields.toList(),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppsViewSettingsSection(onSetState: setState, searchQuery: searchQuery),
                        const SizedBox(height: 24),
                        BehaviorSettingsSection(
                          sortDropdown: sortDropdown,
                          orderDropdown: orderDropdown,
                          localeDropdown: localeDropdown,
                          searchQuery: searchQuery,
                        ),
                        const SizedBox(height: 24),
                        AdvancedSettingsSection(searchQuery: searchQuery),
                        const SizedBox(height: 24),
                        SettingsGroup(
                          title: tr('troubleshootingAndSystem'),
                          children: [const TroubleshootingSection()],
                        ),
                    ] else ...[
                        // --- MENU MODE (CATEGORIES) ---
                        
                        // 1. Basics (Quick Toggles)
                        SettingsGroup(
                          title: tr('basics'),
                          children: [
                             SwitchListTile.adaptive(
                                secondary: const Icon(Icons.sync_outlined),
                                title: Text(tr('backgroundUpdates'), style: Theme.of(context).textTheme.bodyLarge),
                                value: settingsProvider.updateInterval > 0,
                                onChanged: (value) {
                                  settingsProvider.updateInterval = value ? 60 : 0;
                                },
                              ),
                             SwitchListTile.adaptive(
                                secondary: const Icon(Icons.battery_saver_outlined),
                                title: Text(tr('batteryOpt'), style: Theme.of(context).textTheme.bodyLarge),
                                subtitle: Text(_isIgnoringBatteryOptimizations ? tr('enabled') : tr('disabled')),
                                value: _isIgnoringBatteryOptimizations,
                                onChanged: (value) async {
                                  if (!_isIgnoringBatteryOptimizations) {
                                    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
                                    _checkBatteryStatus();
                                  } else if (_cachedAndroidInfo != null) {
                                     // Xiaomi Check
                                     var isXiaomi = ['xiaomi', 'poco', 'redmi'].contains(_cachedAndroidInfo!.manufacturer.toLowerCase()) ||
                                                    ['xiaomi', 'poco', 'redmi'].contains(_cachedAndroidInfo!.brand.toLowerCase());
                                     if (isXiaomi) {
                                       if (mounted) {
                                         showDialog(
                                           context: context,
                                           builder: (context) => UpdateSettingsSection(
                                             showIntervalLabel: true, 
                                             onIntervalLabelChange: (_) {}, 
                                             androidInfoFuture: Future.value(_cachedAndroidInfo)
                                           ).buildXiaomiTroubleshootingDialog(context),
                                         );
                                       }
                                     }
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 2. Navigation Categories (Refactored for ObtainiumPlus Spec)
                        SettingsGroup(
                          children: [
                            _buildSubMenuTile(
                              context,
                              icon: Icons.sync_outlined,
                              title: tr('updatesAndAutomation'),
                              builder: (context) => _SubMenuPage(
                                title: tr('updatesAndAutomation'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: UpdateSettingsSection(
                                      showIntervalLabel: showIntervalLabel,
                                      onIntervalLabelChange: (val) => setState(() => showIntervalLabel = val),
                                      androidInfoFuture: _androidInfoFuture,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.notifications_active_outlined,
                              title: tr('notifications'),
                              builder: (context) => _SubMenuPage(
                                title: tr('notifications'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SettingsGroup(
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.settings_suggest_outlined),
                                          title: Text(tr('notificationSettings'), style: Theme.of(context).textTheme.bodyLarge),
                                          subtitle: Text(tr('notificationSettingsDescription')),
                                          onTap: () => AppInstallService.openNotificationSettings(obtainiumId),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.palette_outlined,
                              title: tr('appearance'),
                              builder: (context) => _SubMenuPage(
                                title: tr('appearance'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        ThemeSettingsSection(
                                          androidInfoFuture: _androidInfoFuture,
                                          colorsNameMap: colorsNameMap,
                                        ),
                                        const SizedBox(height: 24),
                                        AppsViewSettingsSection(onSetState: setState),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.import_export_outlined,
                              title: tr('backupAndImportExport'),
                              builder: (context) => ImportExportPage(),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.bar_chart_outlined,
                              title: tr('statistics'),
                              builder: (context) => StatisticsPage(),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.bug_report_outlined,
                              title: tr('advancedAndTroubleshooting'),
                              builder: (context) => _SubMenuPage(
                                title: tr('advancedAndTroubleshooting'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        if (sourceSpecificFields.isNotEmpty) ...[
                                          SettingsGroup(
                                            title: tr('sourceSpecific'),
                                            children: sourceSpecificFields.toList(),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        BehaviorSettingsSection(
                                          sortDropdown: sortDropdown,
                                          orderDropdown: orderDropdown,
                                          localeDropdown: localeDropdown,
                                        ),
                                        const SizedBox(height: 24),
                                        AdvancedSettingsSection(),
                                        const SizedBox(height: 24),
                                        const TroubleshootingSection(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
    
                    // --- SECTION: ABOUT (Always Visible) ---
                    const SizedBox(height: 24),
                    SettingsGroup(
                      title: isSearching ? null : tr('about'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.code_outlined),
                          title: Text(tr('appSource'), style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () => launchUrlString(settingsProvider.sourceUrl, mode: LaunchMode.externalApplication),
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline_rounded),
                          title: Text(tr('wiki'), style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () => launchUrlString('https://wiki.obtainium.imranr.dev/', mode: LaunchMode.externalApplication),
                        ),
                        ListTile(
                          leading: const Icon(Icons.apps_rounded),
                          title: Text(tr('crowdsourcedConfigsLabel'), style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () => launchUrlString('https://apps.obtainium.imranr.dev/', mode: LaunchMode.externalApplication),
                        ),
                        ListTile(
                          leading: const Icon(Icons.bug_report_outlined),
                          title: Text(tr('appLogs'), style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () {
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
                        ),
                      ],
                    ),
    
                    const SizedBox(height: 64),
                  ]),
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildSubMenuTile(BuildContext context, {required IconData icon, required String title, required Widget Function(BuildContext) builder}) {
        return ListTile(
          leading: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: builder,
            );
          },
        );
      }
    }

    class _SubMenuPage extends StatelessWidget {
      final String title;
      final Widget child;

      const _SubMenuPage({required this.title, required this.child});

        @override
        Widget build(BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 12),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(title),
                ],
              ),
              centerTitle: true,
              toolbarHeight: 80,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: child,
          );
        }
      }    
    class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    // Robustly filter out hidden/empty widgets
    final visibleChildren = children.where((child) {
      if (child is SizedBox && child.child == null) return false;
      if (child is Visibility && !child.visible) return false;
      return true;
    }).toList();

    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 24.0, bottom: 8.0),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(32.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(visibleChildren.length, (index) {
              return Column(
                children: [
                  visibleChildren[index],
                  if (index < visibleChildren.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
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
  final Future<AndroidDeviceInfo> _androidInfoFuture = DeviceInfoPlugin().androidInfo;

  Future<void> _reportIssue() async {
    var logs = logString ?? '';
    if (logs.length > 2000) {
      logs = logs.substring(logs.length - 2000);
    }

    var appInfo = await AppInstallService.getInstalledInfo(obtainiumId);
    var deviceInfo = _cachedDeviceInfo;
    var androidInfo = await _androidInfoFuture;

    var body = '''${tr('reportIssue')}
    
App: $appInfo
Device: $deviceInfo
Android: $androidInfo

$logs''';

    var url = Uri.parse(
      'https://github.com/thejaustin/ObtainiumPlus/issues/new?body=${Uri.encodeComponent(body)}',
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
            : FutureBuilder<List<Log>>(
                future: context.read<LogsProvider>().get(after: DateTime.now().subtract(const Duration(days: 7))),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final logs = snapshot.data!;
                    logString = logs.map((log) => '[${log.level.name}] ${log.timestamp}: ${log.message}').join('\n');
                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(logString ?? ''),
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