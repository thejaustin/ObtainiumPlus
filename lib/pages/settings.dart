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
    int initTab = widget.initialTab ?? 0;
    if (initTab == 2) {
      initTab = 1;
    } else if (initTab == 3 || initTab == 4) {
      initTab = 2;
    } else if (initTab == 5) {
      initTab = 3;
    } else if (initTab == 6) {
      initTab = 4;
    } else if (initTab == 7 || initTab == 8) {
      initTab = 5;
    }
    _selectedSectionIndex = initTab.clamp(0, 5);
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
                    Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          if (_searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      [
                        (label: 'Obtainium+', icon: Icons.auto_awesome_rounded),
                        (label: 'Appearance', icon: Icons.palette_outlined),
                        (
                          label: 'Updates & Install',
                          icon: Icons.system_update_rounded,
                        ),
                        (
                          label: 'Notifications',
                          icon: Icons.notifications_outlined,
                        ),
                        (label: 'Behavior', icon: Icons.tune_rounded),
                        (label: 'Advanced & Debug', icon: Icons.code_rounded),
                      ].asMap().entries.map((entry) {
                        final isSelected = _selectedSectionIndex == entry.key;
                        final tab = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            avatar: Icon(
                              tab.icon,
                              size: 16,
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            label: Text(tab.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(
                                  () => _selectedSectionIndex = entry.key,
                                );
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                plusSettings.plusGlobalCornerRadius,
                              ),
                            ),
                            side: BorderSide.none,
                            showCheckmark: false,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
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
                        PlusFeaturesSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      if (_searchQuery.isNotEmpty ||
                          _selectedSectionIndex == 1) ...[
                        ThemeSettingsSection(
                          searchQuery: _searchQuery,
                          androidInfoFuture: _androidInfoFuture,
                          colorsNameMap: const <ColorSwatch<Object>, String>{},
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                        AppsViewSettingsSection(
                          searchQuery: _searchQuery,
                          onSetState: (fn) => setState(fn),
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      ],
                      if (_searchQuery.isNotEmpty ||
                          _selectedSectionIndex == 2) ...[
                        UpdateSettingsSection(
                          searchQuery: _searchQuery,
                          showIntervalLabel: _showIntervalLabel,
                          onIntervalLabelChange: (val) =>
                              setState(() => _showIntervalLabel = val),
                          androidInfoFuture: _androidInfoFuture,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                        InstallationSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      ],
                      if (_searchQuery.isNotEmpty || _selectedSectionIndex == 3)
                        NotificationSettingsSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      if (_searchQuery.isNotEmpty || _selectedSectionIndex == 4)
                        AppBehaviorSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      if (_searchQuery.isNotEmpty ||
                          _selectedSectionIndex == 5) ...[
                        AdvancedSettingsSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                        TroubleshootingSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      ],
                      const SizedBox(height: 48),
                      _buildFooter(context),
                      const SizedBox(height: 32),
                    ]
                    .asMap()
                    .entries
                    .map(
                      (e) => TweenAnimationBuilder<double>(
                        key: ValueKey('${e.key}_${_selectedSectionIndex}'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 300 + (e.key * 75).clamp(0, 600),
                        ),
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
                      ),
                    )
                    .toList(),
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
    final colorScheme = Theme.of(context).colorScheme;

    final links = [
      (
        icon: Icons.code_rounded,
        label: tr('appSource'),
        url: settingsProvider.sourceUrl,
        color: colorScheme.primary,
      ),
      (
        icon: Icons.help_outline_rounded,
        label: tr('wiki'),
        url: 'https://wiki.obtainium.imranr.dev/',
        color: colorScheme.secondary,
      ),
      (
        icon: Icons.apps_rounded,
        label: tr('crowdsourcedConfigsLabel'),
        url: 'https://apps.obtainium.imranr.dev/',
        color: colorScheme.tertiary,
      ),
    ];

    return Column(
      children: [
        Divider(
          indent: 32,
          endIndent: 32,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Row(
          children: links.map((link) {
            return Expanded(
              child: _FooterIcon(
                icon: link.icon,
                label: link.label,
                url: link.url,
                accentColor: link.color,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FooterIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color? accentColor;

  const _FooterIcon({
    required this.icon,
    required this.label,
    required this.url,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = accentColor ?? colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => launchUrlString(url, mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
