import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/components/settings/appearance_hub.dart';
import 'package:obtainium/components/settings/app_behavior_section.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/connected_settings_bar.dart';
import 'package:obtainium/components/settings/installation_section.dart';
import 'package:obtainium/components/settings/notification_settings_section.dart';
import 'package:obtainium/components/settings/plus_features_section.dart';
import 'package:obtainium/components/settings/plus_features_sheet.dart';
import 'package:obtainium/components/settings/settings_tab_masthead.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/visual_theme_selector.dart';
import 'package:obtainium/components/settings/troubleshooting_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/pages/developer_settings.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs.dart';
import 'package:obtainium/pages/microg_hub.dart';
import 'package:obtainium/pages/settings_subpage.dart';
import 'package:obtainium/pages/system_app_selector.dart';
import 'package:obtainium/pages/system_updates.dart';
import 'package:obtainium/pages/update_health.dart';
import 'package:obtainium/providers/apps_provider.dart' show getInstalledInfo;
import 'package:obtainium/utils/app_utils.dart';
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
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
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

  /// Floating section dock slides away while scrolling down through a
  /// section and returns on scroll-up, so it never sits on top of content.
  final ValueNotifier<bool> _dockVisible = ValueNotifier(true);

  bool _onUserScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.direction == ScrollDirection.reverse &&
        n.metrics.pixels > 24 &&
        n.metrics.extentAfter > 0) {
      _dockVisible.value = false;
    } else if (n.direction == ScrollDirection.forward ||
        n.metrics.pixels <= 24) {
      _dockVisible.value = true;
    }
    return false;
  }

  void scrollToTop() {
    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
    }
    if (!_scrollController.hasClients || _scrollController.offset <= 0) return;
    if (!context.read<PlusSettingsProvider>().plusEnableEnhancedAnimations) {
      _scrollController.jumpTo(0);
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectSection(int index) {
    if (_selectedSectionIndex == index) {
      AppHaptics.lightImpact();
      scrollToTop();
      return;
    }
    AppHaptics.selectionClick();
    setState(() {
      _previousSectionIndex = _selectedSectionIndex;
      _selectedSectionIndex = index;
    });
    _dockVisible.value = true;
    if (_scrollController.hasClients) {
      if (context.read<PlusSettingsProvider>().plusEnableEnhancedAnimations) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _chipKeys.length) return;
      final chipContext = _chipKeys[index].currentContext;
      if (chipContext == null) return;
      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: Duration(
          milliseconds:
              context.read<PlusSettingsProvider>().plusEnableEnhancedAnimations
              ? 250
              : 0,
        ),
        curve: Curves.easeOutCubic,
      );
    });
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
    _dockVisible.dispose();
    _tabsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    _scheduleEmptyCheck();

    final screenWidth = MediaQuery.of(context).size.width;
    final double adaptiveMargin = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;

    final hasMainBottomNavBar =
        plusSettings.plusEnableBottomNavBar &&
        !plusSettings.plusTopUILayout &&
        !settingsProvider.isTV;
    final useSettingsScaffoldBottomBar =
        plusSettings.plusSettingsBottomNavBar && !hasMainBottomNavBar;
    final useSettingsFloatingBottomDock =
        plusSettings.plusSettingsBottomNavBar && hasMainBottomNavBar;
    final showTopPinnedCategoryBar =
        !plusSettings.plusSettingsBottomNavBar && _searchQuery.isEmpty;
    final isCompact = plusSettings.plusUseCompactSettings;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: useSettingsScaffoldBottomBar
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
                  onDestinationSelected: _selectSection,
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
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onUserScroll,
            child: CustomScrollView(
              key: const PageStorageKey<String>('settings_page_scroll'),
              controller: _scrollController,
              physics: plusSettings.scrollPhysics,
              slivers: [
                CustomAppBar(
                  title: tr('settings'),
                  actions: [
                    ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.92,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          avatar: Icon(
                            Icons.stars_rounded,
                            size: 15,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            'Obtainium+',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          shape: CardMetrics.shape(
                            CardMetrics.pill(
                              plusSettings.plusGlobalCornerRadius,
                            ),
                            expressive:
                                plusSettings.plusEnableMaterialExpressive,
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          onPressed: () {
                            AppHaptics.selectionClick();
                            showPlusFeaturesSheet(context: context);
                          },
                        ),
                      ),
                    ),
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
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: Icon(
                                Icons.history_edu_rounded,
                                size: 15,
                                color: colorScheme.primary,
                              ),
                              label: Text(
                                (v != null && v.isNotEmpty)
                                    ? v
                                    : tr('viewChangelog'),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                              shape: CardMetrics.shape(
                                CardMetrics.pill(
                                  plusSettings.plusGlobalCornerRadius,
                                ),
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
                    preferredSize: Size.fromHeight(isCompact ? 54 : 60),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        adaptiveMargin,
                        0,
                        adaptiveMargin,
                        isCompact ? 8 : 12,
                      ),
                      child: AnimatedContainer(
                        duration: Duration(
                          milliseconds:
                              plusSettings.plusEnableEnhancedAnimations
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
                                    color: Theme.of(context).colorScheme.primary
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
                          constraints: BoxConstraints(
                            minHeight: isCompact ? 42 : 48,
                            maxHeight: isCompact ? 46 : 52,
                          ),
                          hintText: tr('searchSettings'),
                          leading: const Icon(Icons.search, size: 20),
                          trailing: [
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: tr('clear'),
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _searchController.clear(),
                              ),
                          ],
                          elevation: WidgetStateProperty.all(0),
                          shape: WidgetStateProperty.resolveWith((states) {
                            final isFocused = states.contains(
                              WidgetState.focused,
                            );
                            final isShifted =
                                isFocused || _searchQuery.isNotEmpty;
                            return CardMetrics.shape(
                              isShifted ? 18.0 : 28.0,
                              expressive:
                                  plusSettings.plusEnableMaterialExpressive,
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
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: adaptiveMargin,
                      vertical: 2,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: PlusFeaturesSection(
                        searchQuery: _searchQuery,
                        showAdvancedSettings:
                            plusSettings.plusShowAdvancedSettings,
                      ),
                    ),
                  ),
                if (showTopPinnedCategoryBar)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SettingsCategoryBarDelegate(
                      height: isCompact ? 48.0 : 54.0,
                      scrollController: _tabsScrollController,
                      scrollPhysics: plusSettings.scrollPhysics,
                      adaptiveMargin: adaptiveMargin,
                      selectedIndex: _selectedSectionIndex,
                      isCompact: isCompact,
                      isM3E: plusSettings.plusEnableMaterialExpressive,
                      cornerRadius: plusSettings.plusGlobalCornerRadius,
                      colorScheme: Theme.of(context).colorScheme,
                      chipKeys: _chipKeys,
                      onSelect: _selectSection,
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
                            ? 280
                            : 0,
                      ),
                      switchInCurve: Easing.emphasizedDecelerate,
                      switchOutCurve: Easing.emphasizedAccelerate,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            final bool isForward =
                                _selectedSectionIndex >= _previousSectionIndex;
                            final beginOffset = _searchQuery.isNotEmpty
                                ? const Offset(0.0, 0.03)
                                : Offset(isForward ? 0.04 : -0.04, 0.0);
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Easing.emphasizedDecelerate,
                              ),
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: beginOffset,
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Easing.emphasizedDecelerate,
                                      ),
                                    ),
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.985, end: 1.0)
                                      .animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Easing.emphasizedDecelerate,
                                        ),
                                      ),
                                  child: child,
                                ),
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
                              _SettingsEmptyState(
                                onClear: _searchController.clear,
                                onSelectSection: (index) {
                                  _searchController.clear();
                                  _selectSection(index);
                                },
                              ),
                            Column(
                              key: _resultsKey,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_searchQuery.isNotEmpty ||
                                    _selectedSectionIndex == 0) ...[
                                  if (_searchQuery.isEmpty) ...[
                                    SettingsTabMasthead(
                                      icon: Icons.palette_rounded,
                                      title: tr('settingsTabAppearance'),
                                      description: tr(
                                        'settingsTabAppearanceDesc',
                                      ),
                                      accentColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    if (plusSettings
                                        .plusSettingsUseVisualThemePicker)
                                      const VisualThemeSelector(),
                                    AppearanceHub(
                                      androidInfoFuture: _androidInfoFuture,
                                      themeContent: ThemeSettingsSection(
                                        searchQuery: _searchQuery,
                                        androidInfoFuture: _androidInfoFuture,
                                        colorsNameMap:
                                            const <
                                              ColorSwatch<Object>,
                                              String
                                            >{},
                                        showAdvancedSettings: plusSettings
                                            .plusShowAdvancedSettings,
                                        subCategory: 'theme',
                                      ),
                                      appTileContent: AppsViewSettingsSection(
                                        searchQuery: _searchQuery,
                                        onSetState: (fn) => setState(fn),
                                        showAdvancedSettings: plusSettings
                                            .plusShowAdvancedSettings,
                                        subCategory: 'tiles',
                                      ),
                                      layoutNavContent: AppsViewSettingsSection(
                                        searchQuery: _searchQuery,
                                        onSetState: (fn) => setState(fn),
                                        showAdvancedSettings: plusSettings
                                            .plusShowAdvancedSettings,
                                        subCategory: 'layout',
                                      ),
                                      motionPhysicsContent:
                                          ThemeSettingsSection(
                                            searchQuery: _searchQuery,
                                            androidInfoFuture:
                                                _androidInfoFuture,
                                            colorsNameMap:
                                                const <
                                                  ColorSwatch<Object>,
                                                  String
                                                >{},
                                            showAdvancedSettings: plusSettings
                                                .plusShowAdvancedSettings,
                                            subCategory: 'motion',
                                          ),
                                    ),
                                  ] else ...[
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isWide =
                                            constraints.maxWidth >= 720 &&
                                            _searchQuery.isEmpty;
                                        final themeSection =
                                            ThemeSettingsSection(
                                              searchQuery: _searchQuery,
                                              androidInfoFuture:
                                                  _androidInfoFuture,
                                              colorsNameMap:
                                                  const <
                                                    ColorSwatch<Object>,
                                                    String
                                                  >{},
                                              showAdvancedSettings: plusSettings
                                                  .plusShowAdvancedSettings,
                                            );
                                        final appsViewSection =
                                            AppsViewSettingsSection(
                                              searchQuery: _searchQuery,
                                              onSetState: (fn) => setState(fn),
                                              showAdvancedSettings: plusSettings
                                                  .plusShowAdvancedSettings,
                                            );
                                        if (isWide) {
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: themeSection),
                                              const SizedBox(width: 14),
                                              Expanded(child: appsViewSection),
                                            ],
                                          );
                                        }
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            themeSection,
                                            const SizedBox(height: 12),
                                            appsViewSection,
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ],
                                if (_searchQuery.isNotEmpty ||
                                    _selectedSectionIndex == 1) ...[
                                  if (_searchQuery.isEmpty)
                                    SettingsTabMasthead(
                                      icon: Icons.system_update_alt_rounded,
                                      title: tr('settingsTabUpdatesInstall'),
                                      description: tr(
                                        'settingsTabUpdatesInstallDesc',
                                      ),
                                      accentColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide =
                                          constraints.maxWidth >= 720 &&
                                          _searchQuery.isEmpty;
                                      final updateSection =
                                          UpdateSettingsSection(
                                            searchQuery: _searchQuery,
                                            showIntervalLabel:
                                                _showIntervalLabel,
                                            onIntervalLabelChange: (val) =>
                                                setState(
                                                  () =>
                                                      _showIntervalLabel = val,
                                                ),
                                            androidInfoFuture:
                                                _androidInfoFuture,
                                            showAdvancedSettings: plusSettings
                                                .plusShowAdvancedSettings,
                                          );
                                      final installSection =
                                          InstallationSection(
                                            searchQuery: _searchQuery,
                                            showAdvancedSettings: plusSettings
                                                .plusShowAdvancedSettings,
                                          );
                                      if (isWide) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: updateSection),
                                            const SizedBox(width: 14),
                                            Expanded(child: installSection),
                                          ],
                                        );
                                      }
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          updateSection,
                                          const SizedBox(height: 12),
                                          installSection,
                                        ],
                                      );
                                    },
                                  ),
                                ],
                                if (_searchQuery.isNotEmpty ||
                                    _selectedSectionIndex == 2) ...[
                                  if (_searchQuery.isEmpty)
                                    SettingsTabMasthead(
                                      icon: Icons.notifications_active_rounded,
                                      title: tr('settingsTabNotifications'),
                                      description: tr(
                                        'settingsTabNotificationsDesc',
                                      ),
                                      accentColor: Theme.of(
                                        context,
                                      ).colorScheme.tertiary,
                                    ),
                                  NotificationSettingsSection(
                                    searchQuery: _searchQuery,
                                    showAdvancedSettings:
                                        plusSettings.plusShowAdvancedSettings,
                                  ),
                                ],
                                if (_searchQuery.isNotEmpty ||
                                    _selectedSectionIndex == 3) ...[
                                  if (_searchQuery.isEmpty)
                                    SettingsTabMasthead(
                                      icon: Icons.tune_rounded,
                                      title: tr('settingsTabBehavior'),
                                      description: tr(
                                        'settingsTabBehaviorDesc',
                                      ),
                                      accentColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  AppBehaviorSection(
                                    searchQuery: _searchQuery,
                                    showAdvancedSettings:
                                        plusSettings.plusShowAdvancedSettings,
                                  ),
                                ],
                                if (_searchQuery.isNotEmpty ||
                                    _selectedSectionIndex == 4) ...[
                                  if (_searchQuery.isEmpty)
                                    SettingsTabMasthead(
                                      icon: Icons.code_rounded,
                                      title: tr('settingsTabAdvancedDebug'),
                                      description: tr(
                                        'settingsTabAdvancedDebugDesc',
                                      ),
                                      accentColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide =
                                          constraints.maxWidth >= 720 &&
                                          _searchQuery.isEmpty;
                                      final advancedSection =
                                          AdvancedSettingsSection(
                                            searchQuery: _searchQuery,
                                            showAdvancedSettings: plusSettings
                                                .plusShowAdvancedSettings,
                                          );
                                      final troubleshootingSection =
                                          TroubleshootingSection(
                                            searchQuery: _searchQuery,
                                            showAdvancedSettings: plusSettings
                                                .plusShowAdvancedSettings,
                                          );
                                      if (isWide) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: advancedSection),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: troubleshootingSection,
                                            ),
                                          ],
                                        );
                                      }
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          advancedSection,
                                          const SizedBox(height: 12),
                                          troubleshootingSection,
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                            if (_searchQuery.isEmpty)
                              _buildConnectedSettingsForSection(
                                context,
                                _selectedSectionIndex,
                                isCompact,
                              ),
                            const SizedBox(height: 24),
                            _buildFooter(context),
                            SizedBox(
                              // paddingOf(bottom) already includes the main
                              // nav bar (Home uses extendBody) plus the system
                              // gesture inset, so only add our own clearance.
                              height: useSettingsScaffoldBottomBar
                                  ? 24.0
                                  : MediaQuery.paddingOf(context).bottom +
                                        (useSettingsFloatingBottomDock
                                            ? 88.0
                                            : 24.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (useSettingsFloatingBottomDock && _searchQuery.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _dockVisible,
                    builder: (context, visible, child) {
                      final anims = plusSettings.plusEnableEnhancedAnimations;
                      return IgnorePointer(
                        ignoring: !visible,
                        child: AnimatedSlide(
                          offset: visible ? Offset.zero : const Offset(0, 1.6),
                          duration: Duration(milliseconds: anims ? 260 : 0),
                          curve: visible
                              ? Easing.emphasizedDecelerate
                              : Easing.emphasizedAccelerate,
                          child: AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: Duration(milliseconds: anims ? 200 : 0),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _SettingsFloatingSectionDock(
                      selectedIndex: _selectedSectionIndex,
                      isM3E: plusSettings.plusEnableMaterialExpressive,
                      animsEnabled: plusSettings.plusEnableEnhancedAnimations,
                      cornerRadius: plusSettings.plusGlobalCornerRadius,
                      onSelect: _selectSection,
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

  List<SettingsSubpageSibling> _getAppearanceSiblings(BuildContext context) {
    final plusSettings = context.read<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return [
      SettingsSubpageSibling(
        title: tr('settingsAppearanceThemesAndColors'),
        subtitle: tr('settingsAppearanceThemesAndColorsDesc'),
        icon: Icons.palette_rounded,
        accentColor: colorScheme.primary,
        child: ThemeSettingsSection(
          searchQuery: _searchQuery,
          androidInfoFuture: _androidInfoFuture,
          colorsNameMap: const <ColorSwatch<Object>, String>{},
          showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
          subCategory: 'theme',
        ),
      ),
      SettingsSubpageSibling(
        title: tr('settingsAppearanceAppTileStyling'),
        subtitle: tr('settingsAppearanceAppTileStylingDesc'),
        icon: Icons.style_rounded,
        accentColor: colorScheme.secondary,
        child: AppsViewSettingsSection(
          searchQuery: _searchQuery,
          onSetState: (fn) => setState(fn),
          showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
          subCategory: 'tiles',
        ),
      ),
      SettingsSubpageSibling(
        title: tr('settingsAppearanceLayoutNav'),
        subtitle: tr('settingsAppearanceLayoutNavDesc'),
        icon: Icons.dashboard_customize_outlined,
        accentColor: colorScheme.tertiary,
        child: AppsViewSettingsSection(
          searchQuery: _searchQuery,
          onSetState: (fn) => setState(fn),
          showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
          subCategory: 'layout',
        ),
      ),
      SettingsSubpageSibling(
        title: tr('settingsAppearanceMotionPhysics'),
        subtitle: tr('settingsAppearanceMotionPhysicsDesc'),
        icon: Icons.auto_awesome_motion_rounded,
        accentColor: colorScheme.primary,
        child: ThemeSettingsSection(
          searchQuery: _searchQuery,
          androidInfoFuture: _androidInfoFuture,
          colorsNameMap: const <ColorSwatch<Object>, String>{},
          showAdvancedSettings: plusSettings.plusShowAdvancedSettings,
          subCategory: 'motion',
        ),
      ),
    ];
  }

  Widget _buildConnectedSettingsForSection(
    BuildContext context,
    int sectionIndex,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    List<ConnectedSettingItem> items = [];

    switch (sectionIndex) {
      case 0: // Appearance
        items = [
          ConnectedSettingItem(
            icon: Icons.dashboard_customize_outlined,
            title: tr('settingsAppearanceLayoutNav'),
            subtitle: tr('settingsAppearanceLayoutNavDesc'),
            accentColor: colorScheme.tertiary,
            onTap: () {
              final siblings = _getAppearanceSiblings(context);
              pushRoute(
                context,
                SettingsSubpage(
                  title: tr('settingsAppearanceLayoutNav'),
                  subtitle: tr('settingsAppearanceLayoutNavDesc'),
                  icon: Icons.dashboard_customize_outlined,
                  accentColor: colorScheme.tertiary,
                  siblings: siblings,
                  currentSiblingIndex: 2,
                  child: siblings[2].child,
                ),
              );
            },
          ),
          ConnectedSettingItem(
            icon: Icons.notifications_active_outlined,
            title: tr('settingsTabNotifications'),
            subtitle: tr('settingsTabNotificationsDesc'),
            accentColor: colorScheme.primary,
            onTap: () => _selectSection(2),
          ),
          ConnectedSettingItem(
            icon: Icons.auto_awesome_motion_rounded,
            title: tr('settingsAppearanceMotionPhysics'),
            subtitle: tr('settingsAppearanceMotionPhysicsDesc'),
            accentColor: colorScheme.secondary,
            onTap: () {
              final siblings = _getAppearanceSiblings(context);
              pushRoute(
                context,
                SettingsSubpage(
                  title: tr('settingsAppearanceMotionPhysics'),
                  subtitle: tr('settingsAppearanceMotionPhysicsDesc'),
                  icon: Icons.auto_awesome_motion_rounded,
                  accentColor: colorScheme.secondary,
                  siblings: siblings,
                  currentSiblingIndex: 3,
                  child: siblings[3].child,
                ),
              );
            },
          ),
          ConnectedSettingItem(
            icon: Icons.import_export_rounded,
            title: tr('importExport'),
            subtitle: 'Backup, export, or restore settings and apps',
            accentColor: colorScheme.tertiary,
            onTap: () => pushRoute(context, const ImportExportPage()),
          ),
        ];
        break;

      case 1: // Updates & Install
        items = [
          ConnectedSettingItem(
            icon: Icons.notifications_active_outlined,
            title: tr('settingsTabNotifications'),
            subtitle: tr('settingsTabNotificationsDesc'),
            accentColor: colorScheme.tertiary,
            onTap: () => _selectSection(2),
          ),
          ConnectedSettingItem(
            icon: Icons.healing_outlined,
            title: tr('updateHealth'),
            subtitle: tr('updateHealthSubtitle'),
            accentColor: colorScheme.primary,
            onTap: () => pushRoute(context, const UpdateHealthPage()),
          ),
          ConnectedSettingItem(
            icon: Icons.battery_charging_full_rounded,
            title: tr('disableBatteryOptimisation'),
            subtitle: 'Manage background restrictions and OEM limits',
            accentColor: colorScheme.secondary,
            onTap: () => showDeviceOptimizationSheet(context: context),
          ),
          ConnectedSettingItem(
            icon: Icons.apps_rounded,
            title: tr('showSystemApps'),
            subtitle: 'Configure tracked packages and system apps',
            accentColor: colorScheme.primary,
            onTap: () => pushRoute(context, const SystemAppSelector()),
          ),
        ];
        break;

      case 2: // Notifications
        items = [
          ConnectedSettingItem(
            icon: Icons.schedule_rounded,
            title: tr('settingsTabUpdatesInstall'),
            subtitle: tr('settingsTabUpdatesInstallDesc'),
            accentColor: colorScheme.primary,
            onTap: () => _selectSection(1),
          ),
          ConnectedSettingItem(
            icon: Icons.tune_rounded,
            title: tr('settingsTabBehavior'),
            subtitle: tr('settingsTabBehaviorDesc'),
            accentColor: colorScheme.secondary,
            onTap: () => _selectSection(3),
          ),
          ConnectedSettingItem(
            icon: Icons.healing_outlined,
            title: tr('updateHealth'),
            subtitle: tr('updateHealthSubtitle'),
            accentColor: colorScheme.tertiary,
            onTap: () => pushRoute(context, const UpdateHealthPage()),
          ),
          ConnectedSettingItem(
            icon: Icons.apps_rounded,
            title: tr('showSystemApps'),
            subtitle: 'Configure tracked packages and system apps',
            accentColor: colorScheme.primary,
            onTap: () => pushRoute(context, const SystemAppSelector()),
          ),
        ];
        break;

      case 3: // Behavior
        items = [
          ConnectedSettingItem(
            icon: Icons.palette_outlined,
            title: tr('settingsTabAppearance'),
            subtitle: tr('settingsTabAppearanceDesc'),
            accentColor: colorScheme.primary,
            onTap: () => _selectSection(0),
          ),
          ConnectedSettingItem(
            icon: Icons.shield_outlined,
            title: tr('updateHealth'),
            subtitle: tr('updateHealthSubtitle'),
            accentColor: colorScheme.tertiary,
            onTap: () => pushRoute(context, const UpdateHealthPage()),
          ),
          ConnectedSettingItem(
            icon: Icons.import_export_rounded,
            title: tr('importExport'),
            subtitle: 'Backup, export, or restore settings and apps',
            accentColor: colorScheme.secondary,
            onTap: () => pushRoute(context, const ImportExportPage()),
          ),
          ConnectedSettingItem(
            icon: Icons.code_rounded,
            title: tr('settingsTabAdvancedDebug'),
            subtitle: tr('settingsTabAdvancedDebugDesc'),
            accentColor: colorScheme.primary,
            onTap: () => _selectSection(4),
          ),
        ];
        break;

      case 4: // Advanced & Debug
        items = [
          ConnectedSettingItem(
            icon: Icons.receipt_long_rounded,
            title: tr('logs'),
            subtitle: 'Real-time diagnostic logs and traces',
            accentColor: colorScheme.primary,
            onTap: () => pushRoute(context, const LogsPage()),
          ),
          ConnectedSettingItem(
            icon: Icons.extension_rounded,
            title: tr('microGHub'),
            subtitle: tr('microGHubDescription'),
            accentColor: colorScheme.secondary,
            onTap: () => pushRoute(context, const MicroGHubPage()),
          ),
          ConnectedSettingItem(
            icon: Icons.developer_mode_rounded,
            title: tr('developerAndDiagnostics'),
            subtitle: 'Experimental developer preferences and tools',
            accentColor: colorScheme.tertiary,
            onTap: () => pushRoute(context, const DeveloperSettingsPage()),
          ),
          ConnectedSettingItem(
            icon: Icons.system_update_rounded,
            title: tr('systemUpdates'),
            subtitle: 'OTA system package updates and sources',
            accentColor: colorScheme.primary,
            onTap: () => pushRoute(context, const SystemUpdatesPage()),
          ),
        ];
        break;
    }

    return ConnectedSettingsBar(items: items, isCompact: isCompact);
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
  final ValueChanged<int>? onSelectSection;

  const _SettingsEmptyState({required this.onClear, this.onSelectSection});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isCompact = plusSettings.plusUseCompactSettings;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 32.0 : 48.0,
        horizontal: 20.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 18 : 24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: isCompact ? 48 : 64,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: isCompact ? 16 : 24),
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
          const SizedBox(height: 20),
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
          if (onSelectSection != null) ...[
            const SizedBox(height: 28),
            Text(
              tr('relatedSettings'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickCategoryChip(
                  context,
                  0,
                  Icons.palette_outlined,
                  tr('settingsTabAppearance'),
                ),
                _buildQuickCategoryChip(
                  context,
                  1,
                  Icons.system_update_outlined,
                  tr('settingsTabUpdatesInstall'),
                ),
                _buildQuickCategoryChip(
                  context,
                  2,
                  Icons.notifications_outlined,
                  tr('settingsTabNotifications'),
                ),
                _buildQuickCategoryChip(
                  context,
                  3,
                  Icons.tune_outlined,
                  tr('settingsTabBehavior'),
                ),
                _buildQuickCategoryChip(
                  context,
                  4,
                  Icons.code_rounded,
                  tr('settingsTabAdvancedDebug'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickCategoryChip(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final cs = Theme.of(context).colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final radius = CardMetrics.pill(plusSettings.plusGlobalCornerRadius);
    final isM3E = plusSettings.plusEnableMaterialExpressive;

    return ActionChip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(label),
      shape: CardMetrics.shape(radius, expressive: isM3E),
      backgroundColor: cs.surfaceContainerHigh,
      onPressed: () {
        AppHaptics.selectionClick();
        onSelectSection?.call(index);
      },
    );
  }
}

class _SettingsCategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final ScrollController scrollController;
  final ScrollPhysics scrollPhysics;
  final double adaptiveMargin;
  final int selectedIndex;
  final bool isCompact;
  final bool isM3E;
  final double cornerRadius;
  final ColorScheme colorScheme;
  final List<GlobalKey> chipKeys;
  final ValueChanged<int> onSelect;

  const _SettingsCategoryBarDelegate({
    required this.height,
    required this.scrollController,
    required this.scrollPhysics,
    required this.adaptiveMargin,
    required this.selectedIndex,
    required this.isCompact,
    required this.isM3E,
    required this.cornerRadius,
    required this.colorScheme,
    required this.chipKeys,
    required this.onSelect,
  });

  static const _tabs = [
    (
      key: 'settingsTabAppearance',
      icon: Icons.palette_outlined,
      selectedIcon: Icons.palette_rounded,
    ),
    (
      key: 'settingsTabUpdatesInstall',
      icon: Icons.system_update_outlined,
      selectedIcon: Icons.system_update_rounded,
    ),
    (
      key: 'settingsTabNotifications',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    (
      key: 'settingsTabBehavior',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
    ),
    (
      key: 'settingsTabAdvancedDebug',
      icon: Icons.code_rounded,
      selectedIcon: Icons.code_rounded,
    ),
  ];

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isPinnedScrolled = overlapsContent || shrinkOffset > 0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isPinnedScrolled
            ? colorScheme.surface.withValues(alpha: 0.96)
            : colorScheme.surface,
        border: isPinnedScrolled
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              )
            : null,
      ),
      child: ListView.builder(
        key: const PageStorageKey<String>('settings_tabs_scroll'),
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: scrollPhysics,
        padding: EdgeInsets.symmetric(horizontal: adaptiveMargin, vertical: 4),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final tab = _tabs[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ScaleTouchWrapper(
              hapticOnPressDown: false,
              scaleDownFactor: 0.95,
              child: ChoiceChip(
                key: chipKeys[index],
                visualDensity: isCompact ? VisualDensity.compact : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: Icon(
                  isSelected ? tab.selectedIcon : tab.icon,
                  size: 16,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text(tr(tab.key)),
                selected: isSelected,
                onSelected: (_) => onSelect(index),
                shape: CardMetrics.shape(
                  CardMetrics.pill(cornerRadius),
                  expressive: isM3E,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.38)
                        : colorScheme.outlineVariant.withValues(alpha: 0.25),
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SettingsCategoryBarDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isCompact != isCompact ||
        oldDelegate.isM3E != isM3E ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.adaptiveMargin != adaptiveMargin;
  }
}

class _SettingsFloatingSectionDock extends StatelessWidget {
  final int selectedIndex;
  final bool isM3E;
  final bool animsEnabled;
  final double cornerRadius;
  final ValueChanged<int> onSelect;

  const _SettingsFloatingSectionDock({
    required this.selectedIndex,
    required this.isM3E,
    required this.animsEnabled,
    required this.cornerRadius,
    required this.onSelect,
  });

  static const _items = [
    (
      icon: Icons.palette_outlined,
      selectedIcon: Icons.palette_rounded,
      key: 'appearance',
    ),
    (
      icon: Icons.system_update_outlined,
      selectedIcon: Icons.system_update_rounded,
      key: 'updates',
    ),
    (
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      key: 'notifications',
    ),
    (
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
      key: 'settingsTabBehavior',
    ),
    (
      icon: Icons.code_rounded,
      selectedIcon: Icons.code_rounded,
      key: 'advanced',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outer = CardMetrics.pill(cornerRadius);
    final inner = CardMetrics.inner(cornerRadius);
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      color: cs.surfaceContainerHigh.withValues(alpha: 0.96),
      shape: CardMetrics.shape(
        outer,
        expressive: isM3E,
        side: BorderSide(color: cs.primary.withValues(alpha: 0.22), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_items.length, (i) {
            final sel = i == selectedIndex;
            final item = _items[i];
            return Expanded(
              // Selected section gets the room for its label.
              flex: sel ? 2 : 1,
              child: Semantics(
                button: true,
                selected: sel,
                label: tr(item.key),
                excludeSemantics: true,
                child: Tooltip(
                  message: tr(item.key),
                  child: ScaleTouchWrapper(
                    hapticOnPressDown: false,
                    scaleDownFactor: 0.92,
                    child: InkWell(
                      customBorder: CardMetrics.shape(inner, expressive: isM3E),
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: Duration(
                          milliseconds: animsEnabled ? 240 : 0,
                        ),
                        curve: Easing.emphasizedDecelerate,
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        decoration: ShapeDecoration(
                          color: sel ? cs.primaryContainer : Colors.transparent,
                          shape: CardMetrics.shape(inner, expressive: isM3E),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              sel ? item.selectedIcon : item.icon,
                              size: 18,
                              color: sel
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                            if (sel) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  tr(item.key),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onPrimaryContainer,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
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
