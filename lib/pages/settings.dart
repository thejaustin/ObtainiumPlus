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
import 'package:obtainium/utils/haptic_utils.dart';
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
  final ScrollController _tabsScrollController = ScrollController();
  String _searchQuery = '';
  bool _showIntervalLabel = true;
  late Future<AndroidDeviceInfo> _androidInfoFuture;
  int _selectedSectionIndex = 0;
  int _previousSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    int initTab = widget.initialTab ?? 0;
    if (initTab <= 2) {
      initTab = 0;
    } else if (initTab == 3 || initTab == 4) {
      initTab = 1;
    } else if (initTab == 5) {
      initTab = 2;
    } else if (initTab == 6) {
      initTab = 3;
    } else if (initTab == 7 || initTab == 8) {
      initTab = 4;
    }
    _selectedSectionIndex = initTab.clamp(0, 4);
    _androidInfoFuture = DeviceInfoPlugin().androidInfo;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      int initTab = widget.initialTab!;
      if (initTab <= 2) {
        initTab = 0;
      } else if (initTab == 3 || initTab == 4) {
        initTab = 1;
      } else if (initTab == 5) {
        initTab = 2;
      } else if (initTab == 6) {
        initTab = 3;
      } else if (initTab == 7 || initTab == 8) {
        initTab = 4;
      }
      setState(() {
        _selectedSectionIndex = initTab.clamp(0, 4);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabsScrollController.dispose();
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: PlusFeaturesSection(
                searchQuery: _searchQuery,
                showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
              ),
            ),
          ),
          if (_searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  controller: _tabsScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      [
                        (
                          key: 'settingsTabAppearance',
                          icon: Icons.palette_outlined,
                        ),
                        (
                          key: 'settingsTabUpdatesInstall',
                          icon: Icons.system_update_rounded,
                        ),
                        (
                          key: 'settingsTabNotifications',
                          icon: Icons.notifications_outlined,
                        ),
                        (
                          key: 'settingsTabBehavior',
                          icon: Icons.tune_rounded,
                        ),
                        (
                          key: 'settingsTabAdvancedDebug',
                          icon: Icons.code_rounded,
                        ),
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
                            label: Text(tr(tab.key)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                AppHaptics.selectionClick();
                                setState(() {
                                  _previousSectionIndex = _selectedSectionIndex;
                                  _selectedSectionIndex = entry.key;
                                });
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                                if (_tabsScrollController.hasClients) {
                                  final targetOffset =
                                      (entry.key * 130.0 - 48.0).clamp(
                                    0.0,
                                    _tabsScrollController
                                        .position.maxScrollExtent,
                                  );
                                  _tabsScrollController.animateTo(
                                    targetOffset,
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
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
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final bool isForward =
                      _selectedSectionIndex >= _previousSectionIndex;
                  final beginOffset = _searchQuery.isNotEmpty
                      ? const Offset(0.0, 0.03)
                      : Offset(isForward ? 0.05 : -0.05, 0.0);
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: beginOffset,
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    _searchQuery.isNotEmpty
                        ? 'search_$_searchQuery'
                        : 'tab_$_selectedSectionIndex',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_searchQuery.isNotEmpty ||
                          _selectedSectionIndex == 0) ...[
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
                          _selectedSectionIndex == 1) ...[
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
                      if (_searchQuery.isNotEmpty || _selectedSectionIndex == 2)
                        NotificationSettingsSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      if (_searchQuery.isNotEmpty || _selectedSectionIndex == 3)
                        AppBehaviorSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      if (_searchQuery.isNotEmpty ||
                          _selectedSectionIndex == 4) ...[
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
                    ],
                  ),
                ),
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
