import 'dart:async';
import 'dart:io';
import 'dart:ui';

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
import 'package:obtainium/utils/locale_constants.dart' show supportedLocales;
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
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/pages/developer_settings.dart';
import 'package:obtainium/models/settings_enums.dart';

import 'package:obtainium/components/logs_dialog.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/legacy_settings.dart';
import 'package:obtainium/pages/statistics.dart';
import 'package:obtainium/components/settings/app_behavior_section.dart';
import 'package:obtainium/components/settings/app_display_section.dart';
import 'package:obtainium/components/settings/installation_section.dart';


class SetupAssistantSection extends StatefulWidget {
  const SetupAssistantSection({super.key});

  @override
  State<SetupAssistantSection> createState() => _SetupAssistantSectionState();
}

class _SetupAssistantSectionState extends State<SetupAssistantSection> {
  bool _isIgnoringBattery = true;
  bool _hasNotificationPermission = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final battery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    final notifs = await Permission.notification.isGranted;
    if (mounted) {
      setState(() {
        _isIgnoringBattery = battery;
        _hasNotificationPermission = notifs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isIgnoringBattery && _hasNotificationPermission) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_fix_high, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Quick Setup Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isIgnoringBattery)
                _buildActionRow(
                  context,
                  label: 'Allow background updates',
                  onTap: () async {
                    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
                    _checkStatus();
                  },
                ),
              if (!_hasNotificationPermission)
                _buildActionRow(
                  context,
                  label: 'Enable update notifications',
                  onTap: () async {
                    await Permission.notification.request();
                    _checkStatus();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, {required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
              Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final int initialTab; // Kept for backward compatibility, though tabs are removed
  const SettingsPage({super.key, this.initialTab = 0});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  bool showIntervalLabel = true;
  bool _useGridView = true;
  int _aboutTapCount = 0;
  Timer? _aboutTapTimer;
  String _searchQuery = '';
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

  List<Widget>? _sourceSpecificFields;

  @override
  void initState() {
    super.initState();
    // Cache the android info on init
    _androidInfoFuture = DeviceInfoPlugin().androidInfo.then((info) {
      _cachedAndroidInfo = info;
      return info;
    });
    _checkBatteryStatus();

    // Initialize settings if not already done (must NOT be called in build())
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<SettingsProvider>();
      if (sp.prefs == null) {
        sp.initializeSettings();
      }
      // Defer source fields to prevent navigation freeze
      if (_sourceSpecificFields == null) {
        _initSourceSpecificFields();
        if (mounted) setState(() {});
      }
    });
  }

  void _initSourceSpecificFields() {
    if (_sourceSpecificFields != null) return;
    final sp = context.read<SettingsProvider>();
    if (sp.prefs == null) return;

    _sourceSpecificFields = _sourceProvider.sources
        .where((e) => e.sourceConfigSettingFormItems.isNotEmpty)
        .map((e) {
          return GeneratedForm(
            items: e.sourceConfigSettingFormItems.map((item) {
              if (item is GeneratedFormSwitch) {
                item.defaultValue = sp.getSettingBool(item.key);
              } else {
                item.defaultValue = sp.getSettingString(item.key);
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
    _aboutTapTimer?.cancel();
    super.dispose();
  }

  bool _matches(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    if (!settingsProvider.plusEnableModernSettings) {
      return const LegacySettingsPage();
    }
    
    if (settingsProvider.prefs == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

    final sourceSpecificFields = _sourceSpecificFields ?? [];

    // Hub item builders — defined once, shared by grid and list rendering
    Widget Function(BuildContext) _hubBuilderPlus = (_) => _SettingsSubMenuPage(
      title: tr('obtainiumPlusFeatures'),
      child: const SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16), child: PlusFeaturesSection())),
    );
    Widget Function(BuildContext) _hubBuilderUpdates = (_) => _SettingsSubMenuPage(
      title: tr('updatesAndAutomation'),
      child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: UpdateSettingsSection(showIntervalLabel: showIntervalLabel, onIntervalLabelChange: (v) => setState(() => showIntervalLabel = v), androidInfoFuture: _androidInfoFuture))),
    );
    Widget Function(BuildContext) _hubBuilderTheming = (_) => _SettingsSubMenuPage(
      title: tr('theming'),
      child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: ThemeSettingsSection(androidInfoFuture: _androidInfoFuture, colorsNameMap: colorsNameMap))),
    );
    Widget Function(BuildContext) _hubBuilderLayout = (_) => _SettingsSubMenuPage(
      title: tr('layout'),
      child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: AppsViewSettingsSection(onSetState: setState))),
    );
    Widget Function(BuildContext) _hubBuilderBackup = (_) => ImportExportPage();
    Widget Function(BuildContext) _hubBuilderStats = (_) => StatisticsPage();
    Widget Function(BuildContext) _hubBuilderDeveloper = (_) => const DeveloperSettingsPage();
    Widget Function(BuildContext) _hubBuilderAdvanced = (_) => _SettingsSubMenuPage(
      title: tr('advancedAndTroubleshooting'),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (sourceSpecificFields.isNotEmpty) ...[
              SettingsGroup(title: tr('sourceSpecific'), children: sourceSpecificFields.toList()),
              const SizedBox(height: 24),
            ],
            // App Behavior Section
            AppBehaviorSection(searchQuery: _searchQuery),
            const SizedBox(height: 24),
            // App Display Section
            AppDisplaySection(searchQuery: _searchQuery),
            const SizedBox(height: 24),
            // Installation Section
            InstallationSection(searchQuery: _searchQuery),
            const SizedBox(height: 24),
            // General Settings (sort, order, locale)
            BehaviorSettingsSection(sortDropdown: sortDropdown, orderDropdown: orderDropdown, localeDropdown: localeDropdown, searchQuery: _searchQuery),
            const SizedBox(height: 24),
            // Advanced Settings
            AdvancedSettingsSection(searchQuery: _searchQuery),
            const SizedBox(height: 24),
            // Troubleshooting
            const TroubleshootingSection(),
          ]),
        ),
      ),
    );

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
                                    actions: isSearching ? null : [
                                      IconButton(
                                        icon: Icon(_useGridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
                                        tooltip: _useGridView ? 'List view' : 'Grid view',
                                        onPressed: () => setState(() => _useGridView = !_useGridView),
                                      ),
                                    ],
                                  ),
                        
                                  // 2. Search Pill (Persistent below title)
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                                              setState(() {
                                                _searchQuery = value;
                                              });
                                            },
                                            trailing: [
                                              if (isSearching)
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
                                        if (!isSearching) const SetupAssistantSection(),
                                        if (!isSearching)
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              children: [
                                                _buildQuickToggle(
                                                  context,
                                                  icon: Icons.sync_outlined,
                                                  label: 'Updates',
                                                  value: settingsProvider.updateInterval > 0,
                                                  onChanged: (val) => settingsProvider.updateInterval = val ? 360 : 0,
                                                ),
                                                const SizedBox(width: 8),
                                                ActionChip(
                                                  avatar: Icon(
                                                    settingsProvider.theme == ThemeSettings.system ? Icons.brightness_auto : 
                                                    settingsProvider.theme == ThemeSettings.light ? Icons.light_mode : Icons.dark_mode,
                                                    size: 16,
                                                  ),
                                                  label: Text(
                                                    settingsProvider.theme == ThemeSettings.system ? 'System' : 
                                                    settingsProvider.theme == ThemeSettings.light ? 'Light' : 'Dark',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                  onPressed: () => _cycleTheme(settingsProvider),
                                                  shape: StadiumBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5))),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildQuickToggle(
                                                  context,
                                                  icon: Icons.check_circle_outline,
                                                  label: 'Installed',
                                                  value: settingsProvider.onlyCheckInstalledOrTrackOnlyApps,
                                                  onChanged: (val) => settingsProvider.onlyCheckInstalledOrTrackOnlyApps = val,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildQuickToggle(
                                                  context,
                                                  icon: Icons.category_outlined,
                                                  label: 'Categories',
                                                  value: settingsProvider.groupByCategory,
                                                  onChanged: (val) => settingsProvider.groupByCategory = val,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildQuickToggle(
                                                  context,
                                                  icon: Icons.bolt_outlined,
                                                  label: 'Shizuku',
                                                  value: settingsProvider.useShizuku,
                                                  onChanged: (val) => settingsProvider.useShizuku = val,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                        
                                  // 3. Settings Content (Material 3 Expressive Grouped Layout)
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    sliver: SliverList(
                                      delegate: SliverChildListDelegate([
                                        if (isSearching) ...[
                                          // Searching view remains flattened for scanability
                                          _buildExpressiveGroup(
                                            context,
                                            title: tr('suggested'),
                                            children: [
                                              if (_matches(tr('enableBackgroundUpdates')))
                                                SwitchListTile.adaptive(
                                                  secondary: const Icon(Icons.sync_outlined),
                                                  title: Text(tr('enableBackgroundUpdates'), style: Theme.of(context).textTheme.bodyLarge),
                                                  subtitle: Text(tr('backgroundUpdatesDescription')),
                                                  value: settingsProvider.updateInterval > 0,
                                                  onChanged: (value) {
                                                    settingsProvider.updateInterval = value ? 60 : 0;
                                                  },
                                                ),
                                              if (_matches(tr('batteryOpt')))
                                                SwitchListTile.adaptive(
                                                  secondary: const Icon(Icons.battery_saver_outlined),
                                                  title: Text(tr('batteryOpt'), style: Theme.of(context).textTheme.bodyLarge),
                                                  subtitle: Text("${tr('batteryOptDescription')} (${_isIgnoringBatteryOptimizations ? tr('enabled') : tr('disabled')})"),
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
                                          const SizedBox(height: 16),
                                          _buildExpressiveGroup(context, title: tr('theme'), children: [ThemeSettingsSection(androidInfoFuture: _androidInfoFuture, colorsNameMap: colorsNameMap, searchQuery: _searchQuery)]),
                                          const SizedBox(height: 16),
                                          _buildExpressiveGroup(context, title: tr('updatesAndAutomation'), children: [UpdateSettingsSection(showIntervalLabel: showIntervalLabel, onIntervalLabelChange: (value) => setState(() => showIntervalLabel = value), androidInfoFuture: _androidInfoFuture, searchQuery: _searchQuery)]),
                                          const SizedBox(height: 16),
                                          _buildExpressiveGroup(context, title: tr('layout'), children: [AppsViewSettingsSection(onSetState: setState, searchQuery: _searchQuery)]),
                                          const SizedBox(height: 16),
                                          _buildExpressiveGroup(context, title: tr('appBehavior'), children: [BehaviorSettingsSection(sortDropdown: sortDropdown, orderDropdown: orderDropdown, localeDropdown: localeDropdown, searchQuery: _searchQuery)]),
                                          const SizedBox(height: 16),
                                          _buildExpressiveGroup(context, title: tr('advancedAndTroubleshooting'), children: [AdvancedSettingsSection(searchQuery: _searchQuery), const Divider(height: 1, indent: 56, endIndent: 16), TroubleshootingSection(searchQuery: _searchQuery)]),
                                        ] else ...[
                                          // --- GROUPED MENU MODE ---
                                          
                                          // 1. Feature Group
                                          _buildExpressiveGroup(
                                            context,
                                            title: 'Features',
                                            children: [
                                              _buildSubMenuTile(context, icon: Icons.auto_awesome_outlined, title: tr('obtainiumPlusFeatures'), builder: _hubBuilderPlus, subtitle: tr('plusFeaturesDescription')),
                                              _buildSubMenuTile(context, icon: Icons.sync_outlined, title: tr('updatesAndAutomation'), builder: _hubBuilderUpdates, subtitle: tr('updatesDescription')),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // 2. Personalization Group
                                          _buildExpressiveGroup(
                                            context,
                                            title: 'Personalization',
                                            children: [
                                              _buildSubMenuTile(context, icon: Icons.palette_outlined, title: tr('theming'), builder: _hubBuilderTheming, subtitle: tr('themingDescription')),
                                              _buildSubMenuTile(context, icon: Icons.grid_view_outlined, title: tr('layout'), builder: _hubBuilderLayout, subtitle: tr('layoutDescription')),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // 3. Maintenance Group
                                          _buildExpressiveGroup(
                                            context,
                                            title: 'Maintenance',
                                            children: [
                                              _buildSubMenuTile(context, icon: Icons.bar_chart_outlined, title: tr('statistics'), builder: _hubBuilderStats, subtitle: tr('statisticsDescription')),
                                              _buildSubMenuTile(context, icon: Icons.backup_outlined, title: tr('backupAndSync'), builder: _hubBuilderBackup, subtitle: tr('backupAndSyncDescription')),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // 4. Expandable System Settings (To shorten the scroll)
                                          _buildExpandableExpressiveGroup(
                                            context,
                                            title: 'System & Advanced',
                                            icon: Icons.settings_suggest_outlined,
                                            children: [
                                              _buildSubMenuTile(context, icon: Icons.bug_report_outlined, title: tr('advanced'), builder: _hubBuilderAdvanced, subtitle: tr('advancedDescription')),
                                              if (settingsProvider.plusDeveloperMode)
                                                _buildSubMenuTile(context, icon: Icons.code_rounded, title: 'Dev & Logs', builder: (ctx) => const DeveloperSettingsPage(), subtitle: 'Diagnostics and debugging'),
                                            ],
                                          ),
                                        ],
                                      ]),
                                    ),
                                  ),
                    const SizedBox(height: 24),
                    SettingsGroup(
                      title: null,
                      children: [
                        // Tappable title: double-tap=stable update, triple-tap=dev update, long-press=menu
                        GestureDetector(
                          onTap: _onAboutHeaderTap,
                          onLongPress: _showUpdateMenu,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Text(
                              isSearching ? '' : tr('about'),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 4,
                            runSpacing: 8,
                            children: [
                              _buildAboutIcon(context,
                                icon: Icons.history_outlined,
                                label: tr('releaseChannel'),
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
                                    title: Text(tr('releaseChannel')),
                                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                                      RadioListTile<String>(
                                        title: Text(tr('latest')),
                                        value: 'latest',
                                        groupValue: context.read<SettingsProvider>().obtainiumReleaseChannel,
                                        onChanged: (v) { if (v != null) { context.read<SettingsProvider>().obtainiumReleaseChannel = v; setS(() {}); } },
                                      ),
                                      RadioListTile<String>(
                                        title: Text(tr('dev')),
                                        value: 'dev',
                                        groupValue: context.read<SettingsProvider>().obtainiumReleaseChannel,
                                        onChanged: (v) { if (v != null) { context.read<SettingsProvider>().obtainiumReleaseChannel = v; setS(() {}); } },
                                      ),
                                    ]),
                                    actions: [TextButton(onPressed: () => Navigator.maybeOf(ctx)?.pop(), child: Text(tr('close')))],
                                  )),
                                ),
                              ),
                              _buildAboutIcon(context,
                                icon: Icons.article_outlined,
                                label: tr('viewChangelog'),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangelogPage())),
                              ),
                              _buildAboutIcon(context,
                                icon: Icons.code_outlined,
                                label: tr('appSource'),
                                onTap: () => launchUrlString(settingsProvider.sourceUrl, mode: LaunchMode.externalApplication),
                              ),
                              _buildAboutIcon(context,
                                icon: Icons.help_outline_rounded,
                                label: tr('wiki'),
                                onTap: () => launchUrlString('https://wiki.obtainium.imranr.dev/', mode: LaunchMode.externalApplication),
                              ),
                              _buildAboutIcon(context,
                                icon: Icons.apps_rounded,
                                label: tr('crowdsourcedConfigsShort'),
                                onTap: () => launchUrlString('https://apps.obtainium.imranr.dev/', mode: LaunchMode.externalApplication),
                              ),
                              _buildAboutIcon(context,
                                icon: Icons.info_outline_rounded,
                                label: 'App Info',
                                onTap: () async {
                                  final info = await DeviceInfoPlugin().androidInfo;
                                  if (!mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Obtainium+ Info'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Version: ${tr('version')}'), // Assuming there's a version tr
                                          const SizedBox(height: 8),
                                          Text('Device: ${info.model}'),
                                          Text('Android: ${info.version.release} (API ${info.version.sdkInt})'),
                                          const SizedBox(height: 8),
                                          const Text('A modernized source-first app updater.'),
                                        ],
                                      ),
                                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('close')))],
                                    ),
                                  );
                                },
                                onLongPress: () {
                                  settingsProvider.plusDeveloperMode = !settingsProvider.plusDeveloperMode;
                                  HapticFeedback.heavyImpact();
                                  showMessage(settingsProvider.plusDeveloperMode ? 'Developer Mode Enabled' : 'Developer Mode Disabled', context);
                                },
                              ),
                            ],
                          ),
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

  void showMessage(dynamic message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message is ObtainiumError ? message.message : message.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
void _cycleTheme(SettingsProvider sp) {
  final next = ThemeSettings.values[(sp.theme.index + 1) % ThemeSettings.values.length];
  sp.theme = next;
  HapticFeedback.mediumImpact();
}

Widget _buildQuickToggle(BuildContext context, {required IconData icon, required String label, required bool value, required Function(bool) onChanged}) {
...

    return FilterChip(
      avatar: Icon(icon, size: 16, color: value ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant),
      label: Text(label, style: TextStyle(fontSize: 12, color: value ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface)),
      selected: value,
      onSelected: (val) {
        HapticFeedback.selectionClick();
        onChanged(val);
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: StadiumBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5))),
    );
  }

  void _onAboutHeaderTap() {
    _aboutTapCount++;
    _aboutTapTimer?.cancel();
    _aboutTapTimer = Timer(const Duration(milliseconds: 400), () {
      final n = _aboutTapCount;
      _aboutTapCount = 0;
      if (n == 2) _triggerUpdateCheck(channel: 'latest');
      else if (n >= 3) _triggerUpdateCheck(channel: 'dev');
    });
  }

  void _showUpdateMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 32, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('Check for update (stable)'),
            onTap: () { Navigator.maybeOf(ctx)?.pop(); _triggerUpdateCheck(channel: 'latest'); },
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Check for update (dev/beta)'),
            onTap: () { Navigator.maybeOf(ctx)?.pop(); _triggerUpdateCheck(channel: 'dev'); },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _triggerUpdateCheck({required String channel}) async {
    final sp = context.read<SettingsProvider>();
    final orig = sp.obtainiumReleaseChannel;
    if (sp.obtainiumReleaseChannel != channel) sp.obtainiumReleaseChannel = channel;
    final appsProvider = context.read<AppsProvider>();
    App? update = await appsProvider.checkObtainiumUpdate(ignoreCache: true);
    if (!mounted) return;
    if (sp.obtainiumReleaseChannel != orig) sp.obtainiumReleaseChannel = orig;
    if (update != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('xHasAnUpdate', args: ['Obtainium+'])),
          content: Text('${tr('latestVersion')}: ${update.latestVersion}'),
          actions: [
            TextButton(onPressed: () => Navigator.maybeOf(ctx)?.pop(), child: Text(tr('cancel'))),
            TextButton(
              onPressed: () {
                Navigator.maybeOf(ctx)?.pop();
                appsProvider.downloadAndInstallLatestApps([update.id], context);
              },
              child: Text(tr('update')),
            ),
          ],
        ),
      );
    } else {
      showMessage(tr('noNewUpdates'), context);
    }
  }

  Widget _buildAboutIcon(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, VoidCallback? onLongPress}) {
    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Widget Function(BuildContext) builder}) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
          sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: (isDark 
              ? Theme.of(context).colorScheme.surfaceContainerLow 
              : Theme.of(context).colorScheme.surface)
            .withValues(alpha: settings.plusEnableGlassmorphism ? 0.6 : 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: settings.plusEnableGlassmorphism ? 0.4 : 0.3,
              ),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              HapticFeedback.selectionClick();
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        InfoTooltip(message: subtitle, size: 14, padding: const EdgeInsets.only(left: 4)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                  ...

                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableExpressiveGroup(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Tap to expand', style: Theme.of(context).textTheme.bodySmall),
            children: children.asMap().entries.map((entry) {
              final idx = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  if (idx == 0)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  child,
                  if (idx < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpressiveGroup(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: children.asMap().entries.map((entry) {
                final idx = entry.key;
                final child = entry.value;
                return Column(
                  children: [
                    child,
                    if (idx < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubMenuTile(BuildContext context, {required IconData icon, required String title, String? subtitle, required Widget Function(BuildContext) builder}) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall) : null,
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {
            HapticFeedback.selectionClick();
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

class _SettingsSubMenuPage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSubMenuPage({required this.title, required this.child});

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

