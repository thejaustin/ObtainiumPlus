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
import 'package:obtainium/components/settings/plus_features_section.dart';
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<ColorSwatch<Object>, String> colorsNameMap =
      <ColorSwatch<Object>, String>{
        ColorTools.createPrimarySwatch(obtainiumThemeColor): 'Obtainium',
      };

  // PERFORMANCE: Cache DeviceInfoPlugin result to avoid redundant async calls
  AndroidDeviceInfo? _cachedAndroidInfo;
  Future<AndroidDeviceInfo>? _androidInfoFuture;
  bool _isIgnoringBatteryOptimizations = false;

  @override
  void initState() {
    super.initState();
    // Cache the android info on init
    _androidInfoFuture = DeviceInfoPlugin().androidInfo.then((info) {
      _cachedAndroidInfo = info;
      return info;
    });
    _checkBatteryStatus();
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
    super.dispose();
  }

  bool _matches(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    SourceProvider sourceProvider = SourceProvider();
    if (settingsProvider.prefs == null) settingsProvider.initializeSettings();

    final bool isSearching = _searchQuery.isNotEmpty;

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

    var sourceSpecificFields = sourceProvider.sources.map((e) {
      if (e.sourceConfigSettingFormItems.isNotEmpty) {
        // We filter these based on source name if needed, but for now show them all
        // or filter by items inside. GeneratedForm is complex, so we just wrap it.
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

        const height16 = SizedBox(height: 16);
        const height24 = SizedBox(height: 24);
    
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
                                        elevation: MaterialStateProperty.all(0),
                                        backgroundColor: MaterialStateProperty.all(
                                          Theme.of(context).colorScheme.surfaceContainerHigh,
                                        ),
                                        shape: MaterialStateProperty.all(
                                          const StadiumBorder(),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                        trailing: [
                                          if (_searchQuery.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _searchQuery = '';
                                                  _searchController.clear();
                                                });
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
                            if (_matches(tr('backgroundUpdates')))
                              SwitchListTile.adaptive(
                                secondary: const Icon(Icons.sync_outlined),
                                title: Text(tr('backgroundUpdates'), style: Theme.of(context).textTheme.bodyLarge),
                                value: settingsProvider.updateInterval > 0,
                                onChanged: (value) {
                                  settingsProvider.updateInterval = value ? 60 : 0;
                                },
                              ),
                            if (_matches(tr('batteryOpt')))
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
                          searchQuery: _searchQuery,
                        ),
                        const SizedBox(height: 24),
                        UpdateSettingsSection(
                          showIntervalLabel: showIntervalLabel,
                          onIntervalLabelChange: (value) => setState(() => showIntervalLabel = value),
                          androidInfoFuture: _androidInfoFuture,
                          searchQuery: _searchQuery,
                        ),
                        if (sourceSpecificFields.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SettingsGroup(
                            title: tr('sourceSpecific'),
                            children: sourceSpecificFields.toList(),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppsViewSettingsSection(onSetState: setState, searchQuery: _searchQuery),
                        const SizedBox(height: 24),
                        BehaviorSettingsSection(
                          sortDropdown: sortDropdown,
                          orderDropdown: orderDropdown,
                          localeDropdown: localeDropdown,
                          searchQuery: _searchQuery,
                        ),
                        const SizedBox(height: 24),
                        PlusFeaturesSection(searchQuery: _searchQuery),
                        const SizedBox(height: 24),
                        AdvancedSettingsSection(searchQuery: _searchQuery),
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

                        // 2. Navigation Categories
                        SettingsGroup(
                          children: [
                            _buildSubMenuTile(
                              context,
                              icon: Icons.palette_outlined,
                              title: tr('appearance') ?? 'Appearance',
                              destination: _SubMenuPage(
                                title: tr('appearance') ?? 'Appearance',
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ThemeSettingsSection(
                                      androidInfoFuture: _androidInfoFuture,
                                      colorsNameMap: colorsNameMap,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.system_update_outlined,
                              title: tr('updates'),
                              destination: _SubMenuPage(
                                title: tr('updates'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: UpdateSettingsSection(
                                      showIntervalLabel: showIntervalLabel,
                                      onIntervalLabelChange: (value) => setState(() => showIntervalLabel = value),
                                      androidInfoFuture: _androidInfoFuture,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (sourceSpecificFields.isNotEmpty)
                              _buildSubMenuTile(
                                context,
                                icon: Icons.storage_outlined,
                                title: tr('sourceSpecific'),
                                destination: _SubMenuPage(
                                  title: tr('sourceSpecific'),
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SettingsGroup(
                                        title: tr('sourceSpecific'),
                                        children: sourceSpecificFields.toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.view_quilt_outlined,
                              title: tr('viewOptions'), // "Apps & View"
                              destination: _SubMenuPage(
                                title: tr('viewOptions'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: AppsViewSettingsSection(onSetState: setState),
                                  ),
                                ),
                              ),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.tune_outlined,
                              title: tr('general'), // Behavior
                              destination: _SubMenuPage(
                                title: tr('general'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: BehaviorSettingsSection(
                                      sortDropdown: sortDropdown,
                                      orderDropdown: orderDropdown,
                                      localeDropdown: localeDropdown,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildSubMenuTile(
                              context,
                              icon: Icons.build_outlined,
                              title: tr('advanced'),
                              destination: _SubMenuPage(
                                title: tr('advanced'),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: AdvancedSettingsSection(),
                                  ),
                                ),
                              ),
                            ),
                             _buildSubMenuTile(
                              context,
                              icon: Icons.help_outline,
                              title: tr('troubleshootingAndSystem') ?? 'Troubleshooting',
                              destination: _SubMenuPage(
                                title: tr('troubleshootingAndSystem') ?? 'Troubleshooting',
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SettingsGroup(children: [const TroubleshootingSection()]),
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
      }

      Widget _buildSubMenuTile(BuildContext context, {required IconData icon, required String title, required Widget destination}) {
        return ListTile(
          leading: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => destination),
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
            appBar: CustomAppBar(title: title),
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
    
              margin: const EdgeInsets.symmetric(vertical: 4.0),
    
              decoration: BoxDecoration(
    
                color: Theme.of(context).colorScheme.surfaceContainerHigh, // Changed to surfaceContainerHigh
    
                borderRadius: BorderRadius.circular(28.0),
    
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
    
                          indent: 64, // Standard M3 indent for icons
    
                          endIndent: 20,
    
                          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
    
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