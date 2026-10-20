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
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/providers/apps_provider.dart' show getInstalledInfo;
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
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
  late final Future<dynamic> _versionFuture = getInstalledInfo(obtainiumId);
  final GlobalKey _resultsKey = GlobalKey();
  final List<GlobalKey> _chipKeys = List.generate(5, (_) => GlobalKey());
  final Map<String, GlobalKey> _jumpTargetKeys = {
    'theme': GlobalKey(),
    'appsView': GlobalKey(),
    'updates': GlobalKey(),
    'install': GlobalKey(),
    'advanced': GlobalKey(),
    'troubleshooting': GlobalKey(),
  };
  bool _noResults = false;

  void _jumpToTarget(String keyName) {
    final ctx = _jumpTargetKeys[keyName]?.currentContext;
    if (ctx == null) return;
    AppHaptics.segmentTick();
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.06,
      duration: const Duration(milliseconds: 320),
      curve: Easing.emphasizedDecelerate,
    );
  }

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
      final empty =
          _searchQuery.isNotEmpty &&
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
    final settingsProvider = context.watch<SettingsProvider>();
    _scheduleEmptyCheck();

    final screenWidth = MediaQuery.of(context).size.width;
    final double adaptiveMargin = screenWidth > 840
        ? ((screenWidth - 840) / 2).clamp(16.0, double.infinity)
        : 16.0;

    final useSettingsBottomBar =
        plusSettings.plusSettingsBottomNavBar &&
        (!plusSettings.plusEnableBottomNavBar || plusSettings.plusTopUILayout);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: useSettingsBottomBar
          ? ClipRect(
              child: AnimatedAlign(
                duration: Duration(
                  milliseconds: plusSettings.plusEnableEnhancedAnimations
                      ? 280
                      : 0,
                ),
                curve: Easing.emphasizedDecelerate,
                alignment: Alignment.topCenter,
                heightFactor: _searchQuery.isNotEmpty ? 0.0 : 1.0,
                child: NavigationBar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
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
            actions: [
              FutureBuilder<dynamic>(
                future: _versionFuture,
                builder: (context, snap) {
                  final String? v = snap.data?.versionName as String?;
                  final isM3E = plusSettings.plusEnableMaterialExpressive;
                  final colorScheme = Theme.of(context).colorScheme;
                  return ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.92,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ActionChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        avatar: Icon(
                          Icons.history_edu_rounded,
                          size: 15,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          (v != null && v.isNotEmpty) ? v : tr('viewChangelog'),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        shape: CardMetrics.shape(
                          CardMetrics.pill(plusSettings.plusGlobalCornerRadius),
                          expressive: isM3E,
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        backgroundColor: colorScheme.surfaceContainerLow,
                        onPressed: () {
                          AppHaptics.selectionClick();
                          showWhatsNewSheet(context);
                        },
                      ),
                    ),
                  );
                },
              ),
              ScaleTouchWrapper(
                hapticOnPressDown: false,
                scaleDownFactor: 0.88,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: tr('plusUseCompactSettings'),
                  icon: Icon(
                    plusSettings.plusUseCompactSettings
                        ? Icons.density_small_rounded
                        : Icons.density_medium_rounded,
                    size: 20,
                    color: plusSettings.plusUseCompactSettings
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () {
                    final next = !plusSettings.plusUseCompactSettings;
                    next ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                    plusSettings.plusUseCompactSettings = next;
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  adaptiveMargin,
                  0,
                  adaptiveMargin,
                  12,
                ),
                child: AnimatedContainer(
                  duration: Duration(
                    milliseconds: plusSettings.plusEnableEnhancedAnimations
                        ? 280
                        : 0,
                  ),
                  curve: Easing.emphasizedDecelerate,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      _searchQuery.isNotEmpty ? 18.0 : 28.0,
                    ),
                    boxShadow: _searchQuery.isNotEmpty
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.16),
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
                      return CardMetrics.shape(
                        isShifted ? 18.0 : 28.0,
                        expressive: plusSettings.plusEnableMaterialExpressive,
                        side: BorderSide(
                          color: isShifted
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant
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
            padding: EdgeInsets.symmetric(
              horizontal: adaptiveMargin,
              vertical: 2,
            ),
            sliver: SliverToBoxAdapter(
              child: PlusFeaturesSection(
                searchQuery: _searchQuery,
                showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
              ),
            ),
          ),
          if (!useSettingsBottomBar && _searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: plusSettings.plusUseCompactSettings ? 44 : 50,
                child: ListView(
                  key: const PageStorageKey<String>('settings_tabs_scroll'),
                  controller: _tabsScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: plusSettings.scrollPhysics,
                  padding: EdgeInsets.symmetric(horizontal: adaptiveMargin),
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
                        (key: 'settingsTabBehavior', icon: Icons.tune_rounded),
                        (
                          key: 'settingsTabAdvancedDebug',
                          icon: Icons.code_rounded,
                        ),
                      ].asMap().entries.map((entry) {
                        final isSelected = _selectedSectionIndex == entry.key;
                        final tab = entry.value;
                        final isM3E = plusSettings.plusEnableMaterialExpressive;
                        final colorScheme = Theme.of(context).colorScheme;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ScaleTouchWrapper(
                            hapticOnPressDown: true,
                            scaleDownFactor: 0.95,
                            child: ChoiceChip(
                              key: _chipKeys[entry.key],
                              visualDensity: plusSettings.plusUseCompactSettings
                                  ? VisualDensity.compact
                                  : null,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              avatar: Icon(
                                tab.icon,
                                size: 16,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                              label: Text(tr(tab.key)),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  AppHaptics.selectionClick();
                                  setState(() {
                                    _previousSectionIndex =
                                        _selectedSectionIndex;
                                    _selectedSectionIndex = entry.key;
                                  });
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                  );
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    final chipContext =
                                        _chipKeys[entry.key].currentContext;
                                    if (!mounted || chipContext == null) return;
                                    Scrollable.ensureVisible(
                                      chipContext,
                                      alignment: 0.5,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  });
                                }
                              },
                              shape: CardMetrics.shape(
                                CardMetrics.pill(
                                  plusSettings.plusGlobalCornerRadius,
                                ),
                                expressive: isM3E,
                                side: BorderSide(
                                  color: isSelected
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.35,
                                        )
                                      : colorScheme.outlineVariant.withValues(
                                          alpha: 0.22,
                                        ),
                                  width: isSelected ? 1.2 : 1.0,
                                ),
                              ),
                              showCheckmark: false,
                              backgroundColor: colorScheme.surfaceContainer,
                              selectedColor: colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: adaptiveMargin,
              vertical: plusSettings.plusUseCompactSettings ? 4 : 8,
            ),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: Duration(
                  milliseconds: plusSettings.plusEnableEnhancedAnimations
                      ? 260
                      : 0,
                ),
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
                      position:
                          Tween<Offset>(
                            begin: beginOffset,
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
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
                              jumpChips: _buildJumpChipsForTab(
                                _selectedSectionIndex,
                                plusSettings,
                              ),
                              onJump: _jumpToTarget,
                            ),
                          if (_searchQuery.isNotEmpty ||
                              _selectedSectionIndex == 0) ...[
                            if (_searchQuery.isEmpty &&
                                plusSettings.plusSettingsUseSubmenuHub) ...[
                              if (plusSettings.plusSettingsUseVisualThemePicker)
                                const VisualThemeSelector(),
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
                              const SettingsLayoutSelector(),
                            ] else ...[
                              KeyedSubtree(
                                key: _searchQuery.isEmpty
                                    ? _jumpTargetKeys['theme']
                                    : null,
                                child: ThemeSettingsSection(
                                  searchQuery: _searchQuery,
                                  androidInfoFuture: _androidInfoFuture,
                                  colorsNameMap:
                                      const <ColorSwatch<Object>, String>{},
                                  showAdvancedSettings:
                                      plusSettings.plusShowAdvancedSettings,
                                ),
                              ),
                              KeyedSubtree(
                                key: _searchQuery.isEmpty
                                    ? _jumpTargetKeys['appsView']
                                    : null,
                                child: AppsViewSettingsSection(
                                  searchQuery: _searchQuery,
                                  onSetState: (fn) => setState(fn),
                                  showAdvancedSettings:
                                      plusSettings.plusShowAdvancedSettings,
                                ),
                              ),
                            ],
                          ],
                          if (_searchQuery.isNotEmpty ||
                              _selectedSectionIndex == 1) ...[
                            KeyedSubtree(
                              key: _searchQuery.isEmpty
                                  ? _jumpTargetKeys['updates']
                                  : null,
                              child: UpdateSettingsSection(
                                searchQuery: _searchQuery,
                                showIntervalLabel: _showIntervalLabel,
                                onIntervalLabelChange: (val) =>
                                    setState(() => _showIntervalLabel = val),
                                androidInfoFuture: _androidInfoFuture,
                                showAdvancedSettings:
                                    plusSettings.plusShowAdvancedSettings,
                              ),
                            ),
                            if (_searchQuery.isEmpty) const _SectionConnector(),
                            KeyedSubtree(
                              key: _searchQuery.isEmpty
                                  ? _jumpTargetKeys['install']
                                  : null,
                              child: InstallationSection(
                                searchQuery: _searchQuery,
                                showAdvancedSettings:
                                    plusSettings.plusShowAdvancedSettings,
                              ),
                            ),
                          ],
                          if (_searchQuery.isNotEmpty ||
                              _selectedSectionIndex == 2)
                            NotificationSettingsSection(
                              searchQuery: _searchQuery,
                              showAdvancedSettings:
                                  plusSettings.plusShowAdvancedSettings,
                            ),
                          if (_searchQuery.isNotEmpty ||
                              _selectedSectionIndex == 3)
                            AppBehaviorSection(
                              searchQuery: _searchQuery,
                              showAdvancedSettings:
                                  plusSettings.plusShowAdvancedSettings,
                            ),
                          if (_searchQuery.isNotEmpty ||
                              _selectedSectionIndex == 4) ...[
                            KeyedSubtree(
                              key: _searchQuery.isEmpty
                                  ? _jumpTargetKeys['advanced']
                                  : null,
                              child: AdvancedSettingsSection(
                                searchQuery: _searchQuery,
                                showAdvancedSettings:
                                    plusSettings.plusShowAdvancedSettings,
                              ),
                            ),
                            if (_searchQuery.isEmpty) const _SectionConnector(),
                            KeyedSubtree(
                              key: _searchQuery.isEmpty
                                  ? _jumpTargetKeys['troubleshooting']
                                  : null,
                              child: TroubleshootingSection(
                                searchQuery: _searchQuery,
                                showAdvancedSettings:
                                    plusSettings.plusShowAdvancedSettings,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildFooter(context),
                      SizedBox(
                        height:
                            (plusSettings.plusEnableBottomNavBar &&
                                !plusSettings.plusTopUILayout &&
                                !settingsProvider.isTV)
                            ? (plusSettings.plusFloatingNavBar ? 108.0 : 92.0)
                            : (useSettingsBottomBar
                                  ? 92.0
                                  : 24 + MediaQuery.paddingOf(context).bottom),
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

  List<({String keyName, String label, IconData icon})> _buildJumpChipsForTab(
    int tabIndex,
    PlusSettingsProvider plusSettings,
  ) {
    if (tabIndex == 0 && !plusSettings.plusSettingsUseSubmenuHub) {
      return [
        (
          keyName: 'theme',
          label: tr('appearance'),
          icon: Icons.palette_rounded,
        ),
        (
          keyName: 'appsView',
          label: tr('appsString'),
          icon: Icons.grid_view_rounded,
        ),
      ];
    }
    if (tabIndex == 1) {
      return [
        (keyName: 'updates', label: tr('updates'), icon: Icons.update_rounded),
        (
          keyName: 'install',
          label: tr('install'),
          icon: Icons.install_mobile_rounded,
        ),
      ];
    }
    if (tabIndex == 4) {
      return [
        (
          keyName: 'advanced',
          label: tr('advanced'),
          icon: Icons.settings_applications_rounded,
        ),
        (
          keyName: 'troubleshooting',
          label: tr('troubleshootingAndSystem'),
          icon: Icons.bug_report_rounded,
        ),
      ];
    }
    return const [];
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

class _SettingsEmptyState extends StatelessWidget {
  final VoidCallback onClear;

  const _SettingsEmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('noResults'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tr('tryDifferentSearch'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.94,
            child: FilledButton.tonalIcon(
              onPressed: () {
                AppHaptics.selectionClick();
                onClear();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(tr('clearSearch')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabBanner extends StatelessWidget {
  final int tabIndex;
  final List<({String keyName, String label, IconData icon})> jumpChips;
  final void Function(String keyName)? onJump;

  const _SettingsTabBanner({
    super.key,
    required this.tabIndex,
    this.jumpChips = const [],
    this.onJump,
  });

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
    if (tabIndex < 0 || tabIndex >= _tabs.length)
      return const SizedBox.shrink();
    final tab = _tabs[tabIndex];
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final radius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(radius);
    final isCompact = plusSettings.plusUseCompactSettings;
    final badgeSize = isCompact ? 30.0 : 36.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 4 : 6,
        isCompact ? 2 : 4,
        isCompact ? 4 : 6,
        isCompact ? 4 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: badgeSize,
                height: badgeSize,
                decoration: ShapeDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  shape: CardMetrics.shape(innerRadius, expressive: isM3E),
                ),
                child: Icon(
                  tab.icon,
                  size: isCompact ? 16 : 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(tab.titleKey),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (!isCompact)
                      Text(
                        tr(tab.descKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (jumpChips.length > 1 && onJump != null) ...[
            SizedBox(height: isCompact ? 6 : 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: jumpChips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ScaleTouchWrapper(
                      hapticOnPressDown: false,
                      scaleDownFactor: 0.94,
                      child: ActionChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        avatar: Icon(
                          chip.icon,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          chip.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                        backgroundColor: colorScheme.surfaceContainerLow,
                        shape: CardMetrics.shape(
                          CardMetrics.pill(baseRadius),
                          expressive: isM3E,
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        onPressed: () => onJump!(chip.keyName),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
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
    final isM3E = context
        .watch<PlusSettingsProvider>()
        .plusEnableMaterialExpressive;
    final color = accentColor ?? colorScheme.primary;

    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      scaleDownFactor: 0.92,
      child: InkWell(
        customBorder: CardMetrics.shape(16, expressive: isM3E),
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
                decoration: ShapeDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: CardMetrics.shape(14, expressive: isM3E),
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
      ),
    );
  }
}
