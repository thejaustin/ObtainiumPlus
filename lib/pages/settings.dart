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
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _showIntervalLabel = true;
  late Future<AndroidDeviceInfo> _androidInfoFuture;
  int _selectedSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex = (widget.initialTab ?? 0).clamp(0, 8);
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          CustomAppBar(
            title: tr('settings'),
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
          if (_searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // Plain labels, not tr(): 'apps' is a plural (nested) key in
                  // the translation JSON, and tr() on a nested key throws a
                  // TypeError that blanks the whole page in release (#217)
                  children: const [
                    'Obtainium+',
                    'Visuals',
                    'Apps View',
                    'Updates',
                    'Installation',
                    'Notifications',
                    'Behavior',
                    'Advanced',
                    'Troubleshooting',
                  ].asMap().entries.map((entry) {
                    final isSelected = _selectedSectionIndex == entry.key;
                    final displayTitle = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(displayTitle),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSectionIndex = entry.key);
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(plusSettings.plusGlobalCornerRadius),
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 0)
                    PlusFeaturesSection(searchQuery: _searchQuery),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 1)
                    ThemeSettingsSection(
                      searchQuery: _searchQuery,
                      androidInfoFuture: _androidInfoFuture,
                      colorsNameMap: const <ColorSwatch<Object>, String>{},
                    ),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 2)
                    AppsViewSettingsSection(
                      searchQuery: _searchQuery,
                      onSetState: (fn) => setState(fn),
                    ),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 3)
                    UpdateSettingsSection(
                      searchQuery: _searchQuery,
                      showIntervalLabel: _showIntervalLabel,
                      onIntervalLabelChange: (val) => setState(() => _showIntervalLabel = val),
                      androidInfoFuture: _androidInfoFuture,
                    ),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 4)
                    InstallationSection(searchQuery: _searchQuery),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 5)
                    NotificationSettingsSection(searchQuery: _searchQuery),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 6)
                    AppBehaviorSection(searchQuery: _searchQuery),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 7)
                    AdvancedSettingsSection(searchQuery: _searchQuery),
                  if (_searchQuery.isNotEmpty || _selectedSectionIndex == 8)
                    TroubleshootingSection(searchQuery: _searchQuery),
                  const SizedBox(height: 48),
                  _buildFooter(context),
                  const SizedBox(height: 32),
                ].asMap().entries.map((e) => TweenAnimationBuilder<double>(
                  key: ValueKey('${e.key}_${_selectedSectionIndex}'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (e.key * 75).clamp(0, 600)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: e.value,
                )).toList(),
              ),
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
