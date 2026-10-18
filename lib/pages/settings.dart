import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/components/settings/appearance_hub.dart';
import 'package:obtainium/components/settings/settings_layout_selector.dart';
import 'package:obtainium/components/settings/app_behavior_section.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/installation_section.dart';
import 'package:obtainium/components/settings/notification_settings_section.dart';
import 'package:obtainium/components/settings/plus_features_section.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/visual_theme_selector.dart';
import 'package:obtainium/components/settings/troubleshooting_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart' show getInstalledInfo;
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/utils/locale_constants.dart';
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
  late final Future<dynamic> _versionFuture = getInstalledInfo(obtainiumId);
  final GlobalKey _resultsKey = GlobalKey();
  final List<GlobalKey> _chipKeys = List.generate(5, (_) => GlobalKey());
  bool _noResults = false;

  static int _mapInitialTab(int t) {
    if (t <= 2) return 0;
    if (t == 3 || t == 4) return 1;
    if (t == 5) return 2;
    if (t == 6) return 3;
    return 4;
  }

  void _scheduleEmptyCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _resultsKey.currentContext?.findRenderObject();
      final empty = _searchQuery.isNotEmpty &&
          box is RenderBox &&
          box.hasSize &&
          box.size.height < 1;
      if (empty != _noResults) setState(() => _noResults = empty);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex = _mapInitialTab(widget.initialTab ?? 0);
    _androidInfoFuture = DeviceInfoPlugin().androidInfo;
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      setState(() {
        _selectedSectionIndex = _mapInitialTab(widget.initialTab!);
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
    _scheduleEmptyCheck();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: plusSettings.plusSettingsBottomNavBar
          ? ClipRect(
              child: AnimatedAlign(
                duration: Duration(milliseconds: plusSettings.plusEnableEnhancedAnimations ? 280 : 0),
                curve: Easing.emphasizedDecelerate,
                alignment: Alignment.topCenter,
                heightFactor: _searchQuery.isNotEmpty ? 0.0 : 1.0,
                child: NavigationBar(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  selectedIndex: _selectedSectionIndex,
                  onDestinationSelected: (index) {
                    AppHaptics.selectionClick();
                    setState(() {
                      _previousSectionIndex = _selectedSectionIndex;
                      _selectedSectionIndex = index;
                    });
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.palette_outlined),
                      selectedIcon: const Icon(Icons.palette_rounded),
                      label: tr('appearance'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.system_update_outlined),
                      selectedIcon: const Icon(Icons.system_update_rounded),
                      label: tr('updates'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.notifications_outlined),
                      selectedIcon: const Icon(Icons.notifications_rounded),
                      label: tr('notifications'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.tune_outlined),
                      selectedIcon: const Icon(Icons.tune_rounded),
                      label: tr('settingsTabBehavior'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.code_rounded),
                      selectedIcon: const Icon(Icons.code_rounded),
                      label: tr('advanced'),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        key: const PageStorageKey<String>('settings_page_scroll'),
        controller: _scrollController,
        physics: plusSettings.scrollPhysics,
        slivers: [
          CustomAppBar(
            title: tr('settings'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: plusSettings.plusEnableEnhancedAnimations ? 280 : 0),
                  curve: Easing.emphasizedDecelerate,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _searchQuery.isNotEmpty ? 18.0 : 28.0,
                    ),
                    boxShadow: _searchQuery.isNotEmpty
                        ? [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.16),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: tr('searchSettings'),
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          tooltip: tr('clear'),
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        ),
                    ],
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.resolveWith((states) {
                      final isFocused = states.contains(WidgetState.focused);
                      final isShifted = isFocused || _searchQuery.isNotEmpty;
                      return RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isShifted ? 18.0 : 28.0,
                        ),
                        side: BorderSide(
                          color: isShifted
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.3),
                          width: isShifted ? 1.5 : 1.0,
                        ),
                      );
                    }),
                    backgroundColor: WidgetStateProperty.all(
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverToBoxAdapter(
                child: _SettingsHeaderCard(
                  versionFuture: _versionFuture,
                  links: _links(context),
                ),
              ),
            ),
          if (!plusSettings.plusSettingsBottomNavBar && _searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  key: const PageStorageKey<String>('settings_tabs_scroll'),
                  controller: _tabsScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: plusSettings.scrollPhysics,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
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
                        key: _chipKeys[entry.key],
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        avatar: Icon(
                          tab.icon,
                          size: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final chipContext =
                                  _chipKeys[entry.key].currentContext;
                              if (!mounted || chipContext == null) return;
                              Scrollable.ensureVisible(
                                chipContext,
                                alignment: 0.5,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                              );
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            CardMetrics.pill(),
                          ),
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainer,
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                duration: Duration(milliseconds: plusSettings.plusEnableEnhancedAnimations ? 260 : 0),
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
                      if (_searchQuery.isNotEmpty && _noResults)
                        _SettingsEmptyState(onClear: _searchController.clear),
                      Column(
                        key: _resultsKey,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      if (_searchQuery.isEmpty)
                        _SettingsTabBanner(
                          key: ValueKey('banner_$_selectedSectionIndex'),
                          tabIndex: _selectedSectionIndex,
                        ),
                      if (_searchQuery.isNotEmpty ||
                          _selectedSectionIndex == 0) ...[
                        if (_searchQuery.isEmpty &&
                            plusSettings.plusSettingsUseSubmenuHub) ...[
                          const VisualThemeSelector(),
                          const SizedBox(height: 4),
                          AppearanceHub(
                            androidInfoFuture: _androidInfoFuture,
                            themeContent: ThemeSettingsSection(
                              searchQuery: _searchQuery,
                              androidInfoFuture: _androidInfoFuture,
                              colorsNameMap:
                                  const <ColorSwatch<Object>, String>{},
                              showAdvancedSettings:
                                  plusSettings.plusShowAdvancedSettings,
                              subCategory: 'theme',
                            ),
                            appTileContent: AppsViewSettingsSection(
                              searchQuery: _searchQuery,
                              onSetState: (fn) => setState(fn),
                              showAdvancedSettings:
                                  plusSettings.plusShowAdvancedSettings,
                              subCategory: 'tiles',
                            ),
                            layoutNavContent: AppsViewSettingsSection(
                              searchQuery: _searchQuery,
                              onSetState: (fn) => setState(fn),
                              showAdvancedSettings:
                                  plusSettings.plusShowAdvancedSettings,
                              subCategory: 'layout',
                            ),
                            motionPhysicsContent: ThemeSettingsSection(
                              searchQuery: _searchQuery,
                              androidInfoFuture: _androidInfoFuture,
                              colorsNameMap:
                                  const <ColorSwatch<Object>, String>{},
                              showAdvancedSettings:
                                  plusSettings.plusShowAdvancedSettings,
                              subCategory: 'motion',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SettingsLayoutSelector(),
                        ] else ...[
                          ThemeSettingsSection(
                            searchQuery: _searchQuery,
                            androidInfoFuture: _androidInfoFuture,
                            colorsNameMap:
                                const <ColorSwatch<Object>, String>{},
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
                        if (_searchQuery.isEmpty)
                          const _SectionConnector(),
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
                        if (_searchQuery.isEmpty)
                          const _SectionConnector(),
                        TroubleshootingSection(
                          searchQuery: _searchQuery,
                          showAdvancedSettings:
                              plusSettings.plusShowAdvancedSettings,
                        ),
                      ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildFooter(context),
                      SizedBox(
                        height: 24 + MediaQuery.paddingOf(context).bottom,
                      ),
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

  List<_SettingsLink> _links(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    return [
      _SettingsLink(
        icon: Icons.code_rounded,
        label: tr('appSource'),
        url: settingsProvider.sourceUrl,
        color: colorScheme.primary,
      ),
      _SettingsLink(
        icon: Icons.help_outline_rounded,
        label: tr('wiki'),
        url: 'https://wiki.obtainium.imranr.dev/',
        color: colorScheme.secondary,
      ),
      _SettingsLink(
        icon: Icons.apps_rounded,
        label: tr('crowdsourcedConfigsLabel'),
        url: 'https://apps.obtainium.imranr.dev/',
        color: colorScheme.tertiary,
      ),
    ];
  }

  Widget _buildFooter(BuildContext context) {
    if (_searchQuery.isNotEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Divider(
          indent: 32,
          endIndent: 32,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Row(
          children: _links(context).map((link) {
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

class _SettingsLink {
  final IconData icon;
  final String label;
  final String url;
  final Color color;
  const _SettingsLink({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });
}

Future<void> _openSettingsUrl(String url) async {
  try {
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class _SettingsHeaderCard extends StatelessWidget {
  final Future<dynamic> versionFuture;
  final List<_SettingsLink> links;
  const _SettingsHeaderCard({required this.versionFuture, required this.links});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = CardMetrics.card(
      context.watch<PlusSettingsProvider>().plusGlobalCornerRadius,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(CardMetrics.inner(radius)),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obtainium+',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                FutureBuilder<dynamic>(
                  future: versionFuture,
                  builder: (context, snap) {
                    final String? v = snap.data?.versionName as String?;
                    if (v == null || v.isEmpty) return const SizedBox.shrink();
                    return Text(
                      v,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ...links.map(
            (l) => ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.90,
              child: IconButton.filledTonal(
                tooltip: l.label,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(l.icon),
                onPressed: () {
                  AppHaptics.selectionClick();
                  _openSettingsUrl(l.url);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsEmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _SettingsEmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('noResultsFound'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.94,
            child: FilledButton.tonal(onPressed: onClear, child: Text(tr('clear'))),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabBanner extends StatelessWidget {
  final int tabIndex;
  const _SettingsTabBanner({super.key, required this.tabIndex});

  static const _tabs = [
    (
      icon: Icons.palette_rounded,
      titleKey: 'settingsTabAppearance',
      descKey: 'settingsTabAppearanceDesc',
    ),
    (
      icon: Icons.system_update_rounded,
      titleKey: 'settingsTabUpdatesInstall',
      descKey: 'settingsTabUpdatesInstallDesc',
    ),
    (
      icon: Icons.notifications_rounded,
      titleKey: 'settingsTabNotifications',
      descKey: 'settingsTabNotificationsDesc',
    ),
    (
      icon: Icons.tune_rounded,
      titleKey: 'settingsTabBehavior',
      descKey: 'settingsTabBehaviorDesc',
    ),
    (
      icon: Icons.code_rounded,
      titleKey: 'settingsTabAdvancedDebug',
      descKey: 'settingsTabAdvancedDebugDesc',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (tabIndex < 0 || tabIndex >= _tabs.length) return const SizedBox.shrink();
    final tab = _tabs[tabIndex];
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final radius = CardMetrics.card(plusSettings.plusGlobalCornerRadius);
    final isCompact = plusSettings.plusUseCompactSettings;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 6.0 : 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCompact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isCompact ? 32 : 36,
              height: isCompact ? 32 : 36,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(CardMetrics.inner(radius)),
              ),
              child: Icon(
                tab.icon,
                size: isCompact ? 16 : 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr(tab.titleKey),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    tr(tab.descKey),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionConnector extends StatelessWidget {
  const _SectionConnector();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        indent: 24,
        endIndent: 24,
        color: colorScheme.outlineVariant.withValues(alpha: 0.25),
        thickness: 1,
      ),
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
      onTap: () {
        AppHaptics.selectionClick();
        _openSettingsUrl(url);
      },
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

class _LocaleDropdown extends StatelessWidget {
  const _LocaleDropdown();

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final forcedLocale = context.select<SettingsProvider, Locale?>(
      (p) => p.forcedLocale,
    );
    return TvDropdownMenu<Locale?>(
      expandedInsets: EdgeInsets.zero,
      label: Text(tr('language')),
      initialSelection: forcedLocale,
      dropdownMenuEntries: [
        DropdownMenuEntry<Locale?>(value: null, label: tr('followSystem')),
        ...supportedLocales.map(
          (e) => DropdownMenuEntry<Locale?>(value: e.key, label: e.value),
        ),
      ],
      onSelected: (value) {
        settingsProvider.forcedLocale = value;
        if (value != null) {
          context.setLocale(value);
        } else {
          settingsProvider.resetLocaleSafe(context);
        }
      },
    );
  }
}

class _ColourSchemeDropdown extends StatelessWidget {
  const _ColourSchemeDropdown();

  @override
  Widget build(BuildContext context) {
    final colourSchemeMode = context.select<SettingsProvider, ColourSchemeMode>(
      (p) => p.colourSchemeMode,
    );
    final settingsProvider = context.read<SettingsProvider>();
    return TvDropdownMenu<ColourSchemeMode>(
      expandedInsets: EdgeInsets.zero,
      label: Text(tr('colourScheme')),
      initialSelection: colourSchemeMode,
      dropdownMenuEntries: [
        DropdownMenuEntry(
          value: ColourSchemeMode.standard,
          label: tr('standard'),
        ),
        DropdownMenuEntry(
          value: ColourSchemeMode.vibrant,
          label: tr('vibrant'),
        ),
        DropdownMenuEntry(
          value: ColourSchemeMode.expressive,
          label: tr('expressive'),
        ),
        DropdownMenuEntry(
          value: ColourSchemeMode.materialYou,
          label: tr('useMaterialYou'),
        ),
      ],
      onSelected: (value) {
        if (value != null) {
          settingsProvider.colourSchemeMode = value;
        }
      },
    );
  }
}
