import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/app_behavior_section.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/troubleshooting_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/components/settings/plus_features_section.dart';
import 'package:obtainium/components/settings/installation_section.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/utils/locale_constants.dart' show supportedLocales;
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/pages/developer_settings.dart';
import 'package:obtainium/pages/statistics.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
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
              Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final int initialTab;
  const SettingsPage({super.key, this.initialTab = 0});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool showIntervalLabel = false;
  int _aboutTapCount = 0;
  Timer? _aboutTapTimer;
  bool _useGridView = true;
  int _lastNonZeroUpdateInterval = 360;

  late Future<AndroidDeviceInfo> _androidInfoFuture;
  bool _isIgnoringBatteryOptimizations = false;

  final Map<ColorSwatch<Object>, String> colorsNameMap = {};

  @override
  void initState() {
    super.initState();
    _androidInfoFuture = DeviceInfoPlugin().androidInfo;
    _checkBatteryStatus();
    final settings = context.read<SettingsProvider>();
    _useGridView = settings.plusEnableGridView;
  }

  Future<void> _checkBatteryStatus() async {
    bool isIgnoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!mounted) return;
    setState(() {
      _isIgnoringBatteryOptimizations = isIgnoring;
    });
  }

  bool _matches(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  void _cycleTheme(SettingsProvider sp) {
    final values = ThemeSettings.values;
    final next = values[(sp.theme.index + 1) % values.length];
    sp.theme = next;
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isSearching = _searchQuery.isNotEmpty;

    // --- HUB PAGE BUILDERS ---
    Widget Function(BuildContext) _hubBuilderPlus = (_) => const _SettingsSubMenuPage(
      title: 'Obtainium+ Features',
      child: PlusFeaturesSection(),
    );

    Widget Function(BuildContext) _hubBuilderUpdates = (_) => _SettingsSubMenuPage(
      title: 'Updates & Automation',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: UpdateSettingsSection(
            showIntervalLabel: showIntervalLabel,
            onIntervalLabelChange: (value) => setState(() => showIntervalLabel = value),
            androidInfoFuture: _androidInfoFuture,
          ),
        ),
      ),
    );

    Widget Function(BuildContext) _hubBuilderTheming = (_) => _SettingsSubMenuPage(
      title: 'Theming',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ThemeSettingsSection(
            androidInfoFuture: _androidInfoFuture,
            colorsNameMap: colorsNameMap,
          ),
        ),
      ),
    );

    Widget Function(BuildContext) _hubBuilderLayout = (_) => _SettingsSubMenuPage(
      title: 'Layout',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppsViewSettingsSection(onSetState: setState),
        ),
      ),
    );

    Widget Function(BuildContext) _hubBuilderInstallation = (_) => _SettingsSubMenuPage(
      title: tr('installation'),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: InstallationSection(),
        ),
      ),
    );

    Widget Function(BuildContext) _hubBuilderStats = (_) => StatisticsPage();
    Widget Function(BuildContext) _hubBuilderAdvanced = (_) => _SettingsSubMenuPage(
      title: tr('advanced'),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            AppBehaviorSection(searchQuery: _searchQuery),
            const SizedBox(height: 24),
            AdvancedSettingsSection(searchQuery: _searchQuery),
            const SizedBox(height: 24),
            TroubleshootingSection(searchQuery: _searchQuery),
          ]),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: isSearching 
                ? const SizedBox.shrink()
                : Text(tr('settings'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            actions: isSearching ? null : [
              IconButton(
                icon: Icon(_useGridView ? Icons.view_list_outlined : Icons.grid_view_outlined),
                onPressed: () => setState(() => _useGridView = !_useGridView),
              ),
            ],
          ),

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
                    backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHigh),
                    shape: WidgetStateProperty.all(const StadiumBorder()),
                    onChanged: (v) => setState(() => _searchQuery = v),
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
                          label: tr('updates'),
                          value: settingsProvider.updateInterval > 0,
                          onChanged: (val) {
                            if (!val) {
                              if (settingsProvider.updateInterval > 0) _lastNonZeroUpdateInterval = settingsProvider.updateInterval;
                              settingsProvider.updateInterval = 0;
                            } else {
                              settingsProvider.updateInterval = _lastNonZeroUpdateInterval;
                            }
                          },
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
                          shape: StadiumBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickToggle(
                          context,
                          icon: Icons.check_circle_outline,
                          label: tr('installed'),
                          value: settingsProvider.onlyCheckInstalledOrTrackOnlyApps,
                          onChanged: (val) => settingsProvider.onlyCheckInstalledOrTrackOnlyApps = val,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickToggle(
                          context,
                          icon: Icons.bolt_outlined,
                          label: 'Shizuku / Sui',
                          value: settingsProvider.useShizuku,
                          onChanged: (val) {
                            if (!val) {
                              settingsProvider.useShizuku = false;
                              return;
                            }
                            ShizukuApkInstaller.checkPermission().then((resCode) {
                              if (resCode == null || !resCode.startsWith('granted')) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(resCode == 'binder_not_found' || resCode == null
                                      ? tr('shizukuBinderNotFound')
                                      : resCode == 'old_shizuku'
                                          ? tr('shizukuOld')
                                          : tr('shizukuBinderNotFound')),
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }
                              settingsProvider.useShizuku = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: _useGridView 
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildHubCard(context, icon: Icons.auto_awesome_outlined, title: tr('obtainiumPlusFeatures'), subtitle: tr('plusFeaturesDescription'), builder: _hubBuilderPlus),
                    _buildHubCard(context, icon: Icons.sync_outlined, title: tr('updatesAndAutomation'), subtitle: tr('updatesDescription'), builder: _hubBuilderUpdates),
                    _buildHubCard(context, icon: Icons.palette_outlined, title: tr('theming'), subtitle: tr('themingDescription'), builder: _hubBuilderTheming),
                    _buildHubCard(context, icon: Icons.grid_view_outlined, title: tr('layout'), subtitle: tr('layoutDescription'), builder: _hubBuilderLayout),
                    _buildHubCard(context, icon: Icons.install_mobile_outlined, title: tr('installation'), subtitle: tr('installationDescription'), builder: _hubBuilderInstallation),
                    _buildHubCard(context, icon: Icons.bar_chart_outlined, title: tr('statistics'), subtitle: tr('statisticsDescription'), builder: _hubBuilderStats),
                    if (settingsProvider.plusDeveloperMode)
                      _buildHubCard(context, icon: Icons.code_rounded, title: tr('devAndLogs'), subtitle: tr('devAndLogsDescription'), builder: (ctx) => const DeveloperSettingsPage()),
                    _buildHubCard(context, icon: Icons.bug_report_outlined, title: tr('advanced'), subtitle: tr('advancedDescription'), builder: _hubBuilderAdvanced),
                  ]),
                )
              : SliverList(
                  delegate: SliverChildListDelegate([
                    _buildExpressiveGroup(
                      context,
                      title: tr('settingsFeatures'),
                      children: [
                        _buildSubMenuTile(context, icon: Icons.auto_awesome_outlined, title: tr('obtainiumPlusFeatures'), builder: _hubBuilderPlus, subtitle: tr('plusFeaturesDescription')),
                        _buildSubMenuTile(context, icon: Icons.sync_outlined, title: tr('updatesAndAutomation'), builder: _hubBuilderUpdates, subtitle: tr('updatesDescription')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildExpressiveGroup(
                      context,
                      title: tr('settingsPersonalization'),
                      children: [
                        _buildSubMenuTile(context, icon: Icons.palette_outlined, title: tr('theming'), builder: _hubBuilderTheming, subtitle: tr('themingDescription')),
                        _buildSubMenuTile(context, icon: Icons.grid_view_outlined, title: tr('layout'), builder: _hubBuilderLayout, subtitle: tr('layoutDescription')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildExpressiveGroup(
                      context,
                      title: tr('settingsMaintenance'),
                      children: [
                        _buildSubMenuTile(context, icon: Icons.bar_chart_outlined, title: tr('statistics'), builder: _hubBuilderStats, subtitle: tr('statisticsDescription')),
                        _buildSubMenuTile(context, icon: Icons.install_mobile_outlined, title: tr('installation'), builder: _hubBuilderInstallation, subtitle: tr('installationDescription')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildExpandableExpressiveGroup(
                      context,
                      title: tr('settingsSystemAndAdvanced'),
                      icon: Icons.settings_suggest_outlined,
                      children: [
                        _buildSubMenuTile(context, icon: Icons.bug_report_outlined, title: tr('advanced'), builder: _hubBuilderAdvanced, subtitle: tr('advancedDescription')),
                        if (settingsProvider.plusDeveloperMode)
                          _buildSubMenuTile(context, icon: Icons.code_rounded, title: tr('devAndLogs'), builder: (ctx) => const DeveloperSettingsPage(), subtitle: tr('devAndLogsDescription')),
                      ],
                    ),
                  ]),
                ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 4,
                    runSpacing: 8,
                    children: [
                      _buildAboutIcon(context, icon: Icons.article_outlined, label: tr('viewChangelog'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangelogPage()))),
                      _buildAboutIcon(context, icon: Icons.code_outlined, label: tr('appSource'), onTap: () => launchUrlString(settingsProvider.sourceUrl, mode: LaunchMode.externalApplication)),
                      _buildAboutIcon(context, icon: Icons.help_outline_rounded, label: tr('wiki'), onTap: () => launchUrlString('https://wiki.obtainium.imranr.dev/', mode: LaunchMode.externalApplication)),
                      _buildAboutIcon(
                        context,
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
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showMessage(dynamic message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message is ObtainiumError ? message.message : message.toString()), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildQuickToggle(BuildContext context, {required IconData icon, required String label, required bool value, required Function(bool) onChanged}) {
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
      shape: StadiumBorder(side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
    );
  }

  Widget _buildHubCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Widget Function(BuildContext) builder}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: builder,
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpressiveGroup(BuildContext context, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3))),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final idx = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  child,
                  if (idx < children.length - 1)
                    Divider(height: 1, indent: 56, endIndent: 16, color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableExpressiveGroup(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3))),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary)),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        children: [
          const Divider(height: 1, indent: 56, endIndent: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubMenuTile(BuildContext context, {required IconData icon, required String title, String? subtitle, required Widget Function(BuildContext) builder}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary)),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: builder);
      },
    );
  }

  Widget _buildAboutIcon(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, VoidCallback? onLongPress}) {
    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
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
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: child,
    );
  }
}
