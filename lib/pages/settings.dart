import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/components/settings/app_behavior_section.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/installation_section.dart';
import 'package:obtainium/components/settings/notification_settings_section.dart';
import 'package:obtainium/components/settings/plus_features_section.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/troubleshooting_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  final int? initialTab;
  const SettingsPage({super.key, this.initialTab});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showIntervalLabel = true;
  late Future<AndroidDeviceInfo> _androidInfoFuture;

  @override
  void initState() {
    super.initState();
    _androidInfoFuture = DeviceInfoPlugin().androidInfo;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  final plusSettings = context.watch<PlusSettingsProvider>();
  final screenWidth = MediaQuery.of(context).size.width;
  final isLargeScreen = screenWidth > 900;

  if (isLargeScreen) {
    return _buildLargeScreenLayout(context, plusSettings);
  }

  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: CustomScrollView(
      slivers: [
        CustomAppBar(
          title: tr('settings'),
...
Widget _buildLargeScreenLayout(BuildContext context, PlusSettingsProvider plusSettings) {
  return Scaffold(
    body: Row(
      children: [
        // Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Column(
            children: [
              CustomAppBar(
                title: tr('settings'),
                automaticallyImplyLeading: true,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: tr('searchSettings'),
                  leading: const Icon(Icons.search),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSidebarItem(context, tr('plusFeatures'), Icons.auto_awesome_rounded),
                    _buildSidebarItem(context, tr('appearance'), Icons.palette_rounded),
                    _buildSidebarItem(context, tr('appsString'), Icons.grid_view_rounded),
                    _buildSidebarItem(context, tr('updates'), Icons.update_rounded),
                    _buildSidebarItem(context, tr('installation'), Icons.install_mobile_rounded),
                    _buildSidebarItem(context, tr('notifications'), Icons.notifications_active_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Density / Advanced toggles
                    ExpressiveSettingsGroup(
                      children: [
                        SwitchListTile.adaptive(
                          secondary: const Icon(Icons.density_medium_rounded),
                          title: Text(tr('useCompactSettings')),
                          value: plusSettings.plusUseCompactSettings,
                          onChanged: (v) => plusSettings.plusUseCompactSettings = v,
                        ),
                        SwitchListTile.adaptive(
                          secondary: const Icon(Icons.tune_rounded),
                          title: Text(tr('showAdvancedSettings')),
                          value: plusSettings.plusShowAdvancedSettings,
                          onChanged: (v) => plusSettings.plusShowAdvancedSettings = v,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Load all sections, they will self-filter based on search
                    PlusFeaturesSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),
                    ThemeSettingsSection(
                      searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
                      androidInfoFuture: _androidInfoFuture,
                      colorsNameMap: const <ColorSwatch<Object>, String>{},
                    ),
                    AppsViewSettingsSection(
                      searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
                      onSetState: (fn) => setState(fn),
                    ),
                    UpdateSettingsSection(
                      searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
                      showIntervalLabel: _showIntervalLabel,
                      onIntervalLabelChange: (val) => setState(() => _showIntervalLabel = val),
                      androidInfoFuture: _androidInfoFuture,
                    ),
                    InstallationSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),
                    NotificationSettingsSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),
                    AppBehaviorSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),
                    AdvancedSettingsSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),
                    TroubleshootingSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSidebarItem(BuildContext context, String title, IconData icon) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onTap: () {
      // For now, just a visual placeholder or scrolling logic
      // Ideally this would jump to the section
    },
  );
}

            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SearchBar(
                  controller: _searchController,
                  hintText: tr('searchSettings'),
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // UI Density & Advanced Toggle
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ExpressiveSettingsGroup(
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.density_medium_rounded),
                        title: Text(
                          tr('useCompactSettings'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(tr('useCompactSettingsDescription')),
                        value: plusSettings.plusUseCompactSettings,
                        onChanged: (value) {
                          AppHaptics.lightImpact();
                          plusSettings.plusUseCompactSettings = value;
                        },
                      ),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.tune_rounded),
                        title: Text(
                          tr('showAdvancedSettings'),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(tr('showAdvancedSettingsDescription')),
                        value: plusSettings.plusShowAdvancedSettings,
                        onChanged: (value) {
                          AppHaptics.lightImpact();
                          plusSettings.plusShowAdvancedSettings = value;
                        },
                      ),
                    ],
                  ),
                ),

                // 1. Obtainium+ Features (if master toggle is on or if searching)
                PlusFeaturesSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),

                // 2. Appearance & Theme
                ThemeSettingsSection(
                  searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
                  androidInfoFuture: _androidInfoFuture,
                  colorsNameMap: const <ColorSwatch<Object>, String>{},
                ),

                // 3. App List, Categories & Display
                AppsViewSettingsSection(
                  searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
                  onSetState: (fn) => setState(fn),
                ),

                // 4. Updates
                UpdateSettingsSection(
                  searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
                  showIntervalLabel: _showIntervalLabel,
                  onIntervalLabelChange: (val) => setState(() => _showIntervalLabel = val),
                  androidInfoFuture: _androidInfoFuture,
                ),

                // 5. Installation
                InstallationSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),

                // 6. Notifications (Enhancements)
                NotificationSettingsSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),

                // 7. App Behavior (Generic)
                AppBehaviorSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),

                // 8. Advanced
                AdvancedSettingsSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),

                // 9. Troubleshooting & Logs
                TroubleshootingSection(searchQuery: _searchQuery, showAdvancedSettings: plusSettings.plusShowAdvancedSettings),

                const SizedBox(height: 48),
                _buildFooter(context),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (_searchQuery.isNotEmpty) return const SizedBox.shrink();
    
    final settingsProvider = context.read<SettingsProvider>();
    return Column(
      children: [
        const Divider(indent: 32, endIndent: 32),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FooterIcon(
              icon: Icons.code,
              label: tr('appSource'),
              url: settingsProvider.sourceUrl,
            ),
            _FooterIcon(
              icon: Icons.help_outline_rounded,
              label: tr('wiki'),
              url: 'https://wiki.obtainium.imranr.dev/',
            ),
            _FooterIcon(
              icon: Icons.apps_rounded,
              label: tr('crowdsourcedConfigsLabel'),
              url: 'https://apps.obtainium.imranr.dev/',
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _FooterIcon({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => launchUrlString(url, mode: LaunchMode.externalApplication),
          icon: Icon(icon),
          tooltip: label,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
