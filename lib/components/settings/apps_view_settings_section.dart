import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/settings/app_behavior_section.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/motion.dart';

/// Home & library tab: app list, tiles, categories, swipe actions,
/// navigation, the add button, library and Discover.
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class AppsViewSettingsSection extends StatelessWidget {
  final Function(void Function()) onSetState;
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const AppsViewSettingsSection({
    super.key,
    required this.onSetState,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  bool _matches(String text, {bool isAdvanced = false, String? desc}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    final q = searchQuery!.toLowerCase();
    return text.toLowerCase().contains(q) ||
        (desc != null && desc.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final plusFeaturesEnabled = plusSettings.enableAllPlusFeatures;

    List<Widget> categoryWidgets = [
      if (!isSearching || (_matches('category') || _matches(tr('category'))))
        CategoryEditorSelector(showLabelWhenNotEmpty: false),
      if (_matches(
        tr('groupByCategory'),
        desc: tr('groupByCategoryDescription'),
      ))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.category_outlined,
          title: tr('groupByCategory'),
          subtitle: tr('groupByCategoryDescription'),
          value: (s) => s.groupByCategory,
          onChanged: (s, v) => onSetState(() => s.groupByCategory = v),
        ),
      if (_matches(
        tr('collapseCategoriesByDefault'),
        desc: tr('collapseCategoriesByDefaultDescription'),
      ))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.unfold_less_outlined,
          title: tr('collapseCategoriesByDefault'),
          subtitle: tr('collapseCategoriesByDefaultDescription'),
          value: (s) => s.categoriesCollapsedByDefault,
          onChanged: (s, v) =>
              onSetState(() => s.categoriesCollapsedByDefault = v),
        ),
      if (_matches(tr('iconPosition'), desc: tr('iconPositionDescription')))
        _buildCategoryIconPositionDropdown(context),
      if (_matches(tr('iconCount'), desc: tr('iconCountDescription')))
        _buildCategoryIconCountSlider(context),
    ];

    List<Widget> sortingWidgets = [
      if (_matches(
        tr('plusQuickFilters'),
        desc: tr('plusQuickFiltersDescription'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.filter_list_rounded,
          title: tr('plusQuickFilters'),
          subtitle: tr('plusQuickFiltersDescription'),
          value: (s) => s.plusEnableQuickFilters,
          onChanged: (s, v) => onSetState(() => s.plusEnableQuickFilters = v),
        ),
      if (_matches(tr('plusEnableTags'), desc: tr('plusEnableTagsDescription')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.label_important_outline,
          title: tr('plusEnableTags'),
          subtitle: tr('plusEnableTagsDescription'),
          value: (s) => s.plusEnableTags,
          onChanged: (s, v) => onSetState(() => s.plusEnableTags = v),
        ),
      if (_matches(
        tr('plusAdvancedSorting'),
        desc: tr('plusAdvancedSortingDescription'),
        isAdvanced: true,
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.sort_rounded,
          title: tr('plusAdvancedSorting'),
          subtitle: tr('plusAdvancedSortingDescription'),
          value: (s) => s.plusEnableAdvancedSorting,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableAdvancedSorting = v),
        ),
    ];

    String? label(String key) => isSearching ? null : tr(key);
    Widget group(
      String titleKey,
      String persistKey,
      IconData icon,
      List<Widget> children, {
      bool collapsible = false,
    }) => ExpressiveSettingsGroup(
      title: label(titleKey),
      persistKey: persistKey,
      icon: icon,
      isExpandable: collapsible && !isSearching,
      initiallyExpanded: true,
      children: children,
    );

    // ── App list ──────────────────────────────────────────────────────────
    final appListWidgets = <Widget>[
      if (_matches(tr('defaultViewMode'))) _buildViewModeDropdown(context),
      if (_matches(tr('listDensity'), desc: tr('listDensityDescription')))
        _buildDensityDropdown(context),
      if (_matches(
            tr('showWebInAppView'),
            desc: tr('showWebInAppViewDescription'),
          ) ||
          (_matches('default app details tab') ||
              _matches(tr('searchKeywordDefaultAppDetailsTab'))) ||
          (_matches('description style') ||
              _matches(tr('searchKeywordDescriptionStyle'))) ||
          (_matches('webpage') || _matches(tr('descriptionStyleWebpage'))))
        _buildAppDescriptionStyleSelector(context),
      if (_matches(tr('appBarStyle'), desc: tr('appBarStyleDescription')))
        _buildAppBarStyleDropdown(context),
      _buildGridSettings(context),
    ];

    // ── Tiles ─────────────────────────────────────────────────────────────
    final plusTileItems = [
      if (_matches(
        tr('plusGridShowSourceBadge'),
        desc: tr('plusGridShowSourceBadgeDescription'),
      ))
        (
          icon: Icons.badge_outlined,
          label: tr('plusGridShowSourceBadge'),
          description: tr('plusGridShowSourceBadgeDescription'),
          getValue: (PlusSettingsProvider s) => s.plusGridShowSourceBadge,
          setValue: (PlusSettingsProvider s, bool v) =>
              onSetState(() => s.plusGridShowSourceBadge = v),
        ),
      if (plusSettings.plusEnableTags &&
          _matches(
            tr('plusShowTagsInList'),
            desc: tr('plusShowTagsInListDescription'),
          ))
        (
          icon: Icons.label_outline,
          label: tr('plusShowTagsInList'),
          description: tr('plusShowTagsInListDescription'),
          getValue: (PlusSettingsProvider s) => s.plusShowTagsInList,
          setValue: (PlusSettingsProvider s, bool v) =>
              onSetState(() => s.plusShowTagsInList = v),
        ),
    ];
    final tileWidgets = <Widget>[
      if (!isSearching) _buildAppTileStylePreview(context),
      if (_matches(tr('showAuthor'), desc: tr('showAuthorDescription')) ||
          _matches(tr('showVersion'), desc: tr('showVersionDescription')) ||
          _matches(tr('showDate'), desc: tr('showDateDescription')))
        GenericBooleanControlGrid<ViewSettingsProvider>(
          title: tr('appTileDisplay'),
          embedded: true,
          settings: [
            if (_matches(tr('showAuthor'), desc: tr('showAuthorDescription')))
              (
                icon: Icons.person_outline,
                label: tr('showAuthor'),
                description: tr('showAuthorDescription'),
                getValue: (s) => s.displayShowAuthor,
                setValue: (s, v) => onSetState(() => s.displayShowAuthor = v),
              ),
            if (_matches(tr('showVersion'), desc: tr('showVersionDescription')))
              (
                icon: Icons.code,
                label: tr('showVersion'),
                description: tr('showVersionDescription'),
                getValue: (s) => s.displayShowVersion,
                setValue: (s, v) => onSetState(() => s.displayShowVersion = v),
              ),
            if (_matches(tr('showDate'), desc: tr('showDateDescription')))
              (
                icon: Icons.calendar_today_outlined,
                label: tr('showDate'),
                description: tr('showDateDescription'),
                getValue: (s) => s.displayShowDate,
                setValue: (s, v) => onSetState(() => s.displayShowDate = v),
              ),
          ],
        ),
      if (plusFeaturesEnabled && plusTileItems.isNotEmpty)
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('settingsGroupTiles'),
          embedded: true,
          settings: plusTileItems,
        ),
    ];

    // ── Tile style (+) ────────────────────────────────────────────────────
    final tileStyleItems = [
      for (final e
          in <
            (
              IconData,
              String,
              bool Function(PlusSettingsProvider),
              void Function(PlusSettingsProvider, bool),
            )
          >[
            (
              Icons.crop_square_rounded,
              'plusGridSquareTiles',
              (s) => s.plusGridSquareTiles,
              (s, v) => s.plusGridSquareTiles = v,
            ),
            (
              Icons.border_clear_rounded,
              'plusGridCardlessStyle',
              (s) => s.plusGridCardlessStyle,
              (s, v) => s.plusGridCardlessStyle = v,
            ),
            (
              Icons.flare_rounded,
              'plusGridAmbientIconHalo',
              (s) => s.plusGridAmbientIconHalo,
              (s, v) => s.plusGridAmbientIconHalo = v,
            ),
            (
              Icons.push_pin_outlined,
              'plusPinnedBorderAccent',
              (s) => s.plusPinnedBorderAccent,
              (s, v) => s.plusPinnedBorderAccent = v,
            ),
            (
              Icons.color_lens_outlined,
              'plusCategoryAccentRibbon',
              (s) => s.plusCategoryAccentRibbon,
              (s, v) => s.plusCategoryAccentRibbon = v,
            ),
            (
              Icons.downloading_rounded,
              'plusUpdateExpressiveBadge',
              (s) => s.plusUpdateExpressiveBadge,
              (s, v) => s.plusUpdateExpressiveBadge = v,
            ),
            (
              Icons.crop_square_rounded,
              'plusIconRimBorder',
              (s) => s.plusIconRimBorder,
              (s, v) => s.plusIconRimBorder = v,
            ),
            (
              Icons.view_agenda_rounded,
              'plusEnableModernAppListTile',
              (s) => s.plusEnableModernAppListTile,
              (s, v) => s.plusEnableModernAppListTile = v,
            ),
          ])
        if (_matches(tr(e.$2), desc: tr('${e.$2}Description')))
          (
            icon: e.$1,
            label: tr(e.$2),
            description: tr('${e.$2}Description'),
            getValue: e.$3,
            setValue: (PlusSettingsProvider s, bool v) =>
                onSetState(() => e.$4(s, v)),
          ),
    ];

    // ── Categories & sorting ──────────────────────────────────────────────
    final categorySortWidgets = <Widget>[
      ...categoryWidgets,
      if (_matches(
        tr('plusCategoryReorder'),
        desc: tr('plusCategoryReorderDescription'),
        isAdvanced: true,
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.drag_indicator_rounded,
          title: tr('plusCategoryReorder'),
          subtitle: tr('plusCategoryReorderDescription'),
          value: (s) => s.plusEnableCategoryReorder,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableCategoryReorder = v),
        ),
      ...sortingWidgets,
    ];

    // ── Updates in the list ───────────────────────────────────────────────
    final updatesInListWidgets = <Widget>[
      if (_matches(
            tr('updatesPlacement'),
            desc: tr('updatesPlacementDescription'),
          ) ||
          _matches(tr('pinUpdates'), desc: tr('pinUpdatesDescription')) ||
          _matches(tr('recentUpdates')))
        _buildUpdatesPlacement(context),
      if (_matches(
        tr('buryNonInstalled'),
        desc: tr('buryNonInstalledDescription'),
      ))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.archive_outlined,
          title: tr('buryNonInstalled'),
          subtitle: tr('buryNonInstalledDescription'),
          value: (s) => s.buryNonInstalled,
          onChanged: (s, v) => onSetState(() => s.buryNonInstalled = v),
        ),
    ];

    // ── Navigation & search ───────────────────────────────────────────────
    final navItems = [
      for (final e
          in <
            (
              IconData,
              String,
              bool Function(PlusSettingsProvider),
              void Function(PlusSettingsProvider, bool),
            )
          >[
            (
              Icons.navigation_rounded,
              'plusEnableBottomNavBar',
              (s) => s.plusEnableBottomNavBar,
              (s, v) => s.plusEnableBottomNavBar = v,
            ),
            (
              Icons.dock_rounded,
              'plusFloatingNavBar',
              (s) => s.plusFloatingNavBar,
              (s, v) => s.plusFloatingNavBar = v,
            ),
            (
              Icons.unfold_more_rounded,
              'plusHideBottomBarOnScroll',
              (s) => s.plusHideBottomBarOnScroll,
              (s, v) => s.plusHideBottomBarOnScroll = v,
            ),
            (
              Icons.info_outline_rounded,
              'plusShowStatusHub',
              (s) => s.plusShowStatusHub,
              (s, v) => s.plusShowStatusHub = v,
            ),
            (
              Icons.vertical_align_top_rounded,
              'showAppBarSearch',
              (s) => s.plusShowAppBarSearch,
              (s, v) => s.plusShowAppBarSearch = v,
            ),
            (
              Icons.dashboard_outlined,
              'showDashboardSearch',
              (s) => s.plusShowDashboardSearch,
              (s, v) => s.plusShowDashboardSearch = v,
            ),
            (
              Icons.filter_alt_rounded,
              'plusExpressiveFilterChips',
              (s) => s.plusExpressiveFilterChips,
              (s, v) => s.plusExpressiveFilterChips = v,
            ),
          ])
        if (_matches(tr(e.$2), desc: tr('${e.$2}Description')))
          (
            icon: e.$1,
            label: tr(e.$2),
            description: tr('${e.$2}Description'),
            getValue: e.$3,
            setValue: (PlusSettingsProvider s, bool v) =>
                onSetState(() => e.$4(s, v)),
          ),
    ];
    final navSearchWidgets = <Widget>[
      if (plusFeaturesEnabled && navItems.isNotEmpty)
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('settingsGroupNavSearch'),
          embedded: true,
          settings: navItems,
        ),
      if (_matches(
            tr('showFilterChips'),
            desc: tr('showFilterChipsDescription'),
          ) ||
          _matches(tr('showAppCount'), desc: tr('showAppCountDescription')))
        GenericBooleanControlGrid<ViewSettingsProvider>(
          title: tr('filterChips'),
          embedded: true,
          settings: [
            if (_matches(
              tr('showFilterChips'),
              desc: tr('showFilterChipsDescription'),
            ))
              (
                icon: Icons.filter_list_outlined,
                label: tr('showFilterChips'),
                description: tr('showFilterChipsDescription'),
                getValue: (s) => s.displayShowFilterChips,
                setValue: (s, v) =>
                    onSetState(() => s.displayShowFilterChips = v),
              ),
            if (_matches(
              tr('showAppCount'),
              desc: tr('showAppCountDescription'),
            ))
              (
                icon: Icons.summarize_outlined,
                label: tr('showAppCount'),
                description: tr('showAppCountDescription'),
                getValue: (s) => s.displayShowAppCount,
                setValue: (s, v) => onSetState(() => s.displayShowAppCount = v),
              ),
          ],
        ),
    ];

    // ── Add button (+): the FAB is the master of its menu rows ───────────
    final fabChildren = <Widget>[
      for (final e
          in <
            (
              IconData,
              String,
              bool Function(PlusSettingsProvider),
              void Function(PlusSettingsProvider, bool),
            )
          >[
            (
              Icons.smart_button_rounded,
              'plusFloatingActionBar',
              (s) => s.plusFloatingActionBar,
              (s, v) => s.plusFloatingActionBar = v,
            ),
            (
              Icons.link_outlined,
              'fabShowAddByUrl',
              (s) => s.plusFabShowAddByUrl,
              (s, v) => s.plusFabShowAddByUrl = v,
            ),
            (
              Icons.star_border_rounded,
              'fabShowGithubStarred',
              (s) => s.plusFabShowGithubStarred,
              (s, v) => s.plusFabShowGithubStarred = v,
            ),
            (
              Icons.person_outline_rounded,
              'fabShowGithubPersonalRepos',
              (s) => s.plusFabShowGithubPersonalRepos,
              (s, v) => s.plusFabShowGithubPersonalRepos = v,
            ),
            (
              Icons.install_mobile_outlined,
              'fabShowImportInstalled',
              (s) => s.plusFabShowImportInstalled,
              (s, v) => s.plusFabShowImportInstalled = v,
            ),
          ])
        if (_matches(tr(e.$2), desc: tr('${e.$2}Description')))
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            icon: e.$1,
            title: tr(e.$2),
            subtitle: tr('${e.$2}Description'),
            value: e.$3,
            onChanged: (s, v) => onSetState(() => e.$4(s, v)),
          ),
    ];
    final addButtonWidgets = <Widget>[
      if (_matches(tr('plusEnableFAB'), desc: tr('plusEnableFABDescription')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.add_circle_outline_rounded,
          title: tr('plusEnableFAB'),
          subtitle: tr('plusEnableFABDescription'),
          value: (s) => s.plusEnableFAB,
          onChanged: (s, v) => onSetState(() => s.plusEnableFAB = v),
        ),
      if (fabChildren.isNotEmpty)
        SettingsChildRows(
          enabled: plusSettings.plusEnableFAB,
          children: fabChildren,
        ),
      if (_matches(
        tr('plusModernAddAppPage'),
        desc: tr('plusModernAddAppPageDescription'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.add_box_outlined,
          title: tr('plusModernAddAppPage'),
          subtitle: tr('plusModernAddAppPageDescription'),
          value: (s) => s.plusEnableModernAddAppPage,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableModernAddAppPage = v),
        ),
    ];

    // ── Home & details (+) ────────────────────────────────────────────────
    final homeDetailsWidgets = <Widget>[
      for (final e
          in <
            (
              IconData,
              String,
              bool,
              bool Function(PlusSettingsProvider),
              void Function(PlusSettingsProvider, bool),
            )
          >[
            (
              Icons.dashboard_customize_outlined,
              'plusHomeDashboard',
              false,
              (s) => s.plusEnableHomeDashboard,
              (s, v) => s.plusEnableHomeDashboard = v,
            ),
            (
              Icons.subtitles_rounded,
              'plusHeaderContextSubtitle',
              false,
              (s) => s.plusHeaderContextSubtitle,
              (s, v) => s.plusHeaderContextSubtitle = v,
            ),
            (
              Icons.tablet_android_rounded,
              'plusResponsiveLayout',
              true,
              (s) => s.plusEnableResponsiveAppLayout,
              (s, v) => s.plusEnableResponsiveAppLayout = v,
            ),
            (
              Icons.unfold_less_rounded,
              'plusCollapsibleAbout',
              false,
              (s) => s.plusEnablePopupSlider,
              (s, v) => s.plusEnablePopupSlider = v,
            ),
          ])
        if (_matches(
          tr(e.$2),
          desc: tr('${e.$2}Description'),
          isAdvanced: e.$3,
        ))
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            icon: e.$1,
            title: tr(e.$2),
            subtitle: tr('${e.$2}Description'),
            value: e.$4,
            onChanged: (s, v) => onSetState(() => e.$5(s, v)),
          ),
    ];

    Widget behaviorPart(AppBehaviorPart part) => AppBehaviorSection(
      searchQuery: searchQuery,
      showAdvancedSettings: showAdvancedSettings,
      part: part,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (appListWidgets.isNotEmpty)
          group(
            'settingsGroupAppList',
            'home.appList',
            Icons.view_list_rounded,
            appListWidgets,
          ),
        if (tileWidgets.isNotEmpty)
          group(
            'settingsGroupTiles',
            'home.tiles',
            Icons.style_rounded,
            tileWidgets,
          ),
        if (plusFeaturesEnabled && tileStyleItems.isNotEmpty)
          group(
            'settingsGroupTileStyle',
            'home.tileStyle',
            Icons.auto_awesome_mosaic_outlined,
            [
              GenericBooleanControlGrid<PlusSettingsProvider>(
                title: tr('settingsGroupTileStyle'),
                embedded: true,
                settings: tileStyleItems,
              ),
            ],
            collapsible: true,
          ),
        if (categorySortWidgets.isNotEmpty)
          group(
            'settingsGroupCategoriesSorting',
            'categorySettings',
            Icons.category_outlined,
            categorySortWidgets,
          ),
        if (updatesInListWidgets.isNotEmpty)
          group(
            'settingsGroupUpdatesInList',
            'home.updatesInList',
            Icons.update_rounded,
            updatesInListWidgets,
          ),
        behaviorPart(AppBehaviorPart.swipe),
        if (navSearchWidgets.isNotEmpty)
          group(
            'settingsGroupNavSearch',
            'home.navSearch',
            Icons.navigation_outlined,
            navSearchWidgets,
          ),
        if (plusFeaturesEnabled && addButtonWidgets.isNotEmpty)
          group(
            'settingsGroupAddButton',
            'home.addButton',
            Icons.add_circle_outline_rounded,
            addButtonWidgets,
          ),
        if (plusFeaturesEnabled && homeDetailsWidgets.isNotEmpty)
          group(
            'settingsGroupHomeDetails',
            'home.homeDetails',
            Icons.home_outlined,
            homeDetailsWidgets,
          ),
        behaviorPart(AppBehaviorPart.library),
        behaviorPart(AppBehaviorPart.discover),
      ],
    );
  }

  Widget _buildAppTileStylePreview(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final tileAnimDuration = AppMotion.duration(
      context,
      const Duration(milliseconds: 220),
    );
    final viewSettings = context.watch<ViewSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = plusSettings.plusUseCompactSettings;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final isSquare = plusSettings.plusGridSquareTiles;
    final isCardless = plusSettings.plusGridCardlessStyle;
    final showHalo = plusSettings.plusGridAmbientIconHalo;
    final showSource = plusSettings.plusGridShowSourceBadge;
    final expressiveUpdate = plusSettings.plusUpdateExpressiveBadge;
    final showRibbon = plusSettings.plusCategoryAccentRibbon;
    final showPinnedBorder = plusSettings.plusPinnedBorderAccent;
    final showIconRim = plusSettings.plusIconRimBorder;

    Widget buildMockTile({
      required String name,
      required IconData appIcon,
      required Color accentColor,
      required String version,
      required bool hasUpdate,
      required bool isPinned,
    }) {
      final tileCardless = isCardless && !hasUpdate;
      final itemRadius = CardMetrics.inner(radius);
      final borderSide = tileCardless
          ? BorderSide.none
          : BorderSide(
              color: hasUpdate
                  ? colorScheme.primary.withValues(alpha: 0.42)
                  : isPinned && showPinnedBorder
                  ? colorScheme.primary.withValues(alpha: 0.55)
                  : colorScheme.outlineVariant.withValues(
                      alpha: isDark ? 0.35 : 0.65,
                    ),
              width: hasUpdate || (isPinned && showPinnedBorder) ? 1.5 : 1.0,
            );

      return AspectRatio(
        aspectRatio: isSquare ? 1.0 : 0.85,
        child: AnimatedContainer(
          duration: tileAnimDuration,
          curve: AppConstants.expressiveStandard,
          decoration: ShapeDecoration(
            color: tileCardless
                ? Colors.transparent
                : hasUpdate
                ? colorScheme.primaryContainer.withValues(alpha: 0.28)
                : isPinned
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
                : colorScheme.surfaceContainerLow,
            shape: CardMetrics.shape(
              radius,
              expressive: plusSettings.plusEnableMaterialExpressive,
              side: borderSide,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (showRibbon)
                Positioned(
                  top: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              if (isPinned)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.85,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.push_pin_rounded,
                      size: 10,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          if (showHalo)
                            Positioned(
                              width: 60,
                              height: 60,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      accentColor.withValues(
                                        alpha: isDark ? 0.30 : 0.20,
                                      ),
                                      accentColor.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.15, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: ShapeDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              shape: CardMetrics.shape(
                                itemRadius,
                                expressive:
                                    plusSettings.plusEnableMaterialExpressive,
                                side: showIconRim
                                    ? BorderSide(
                                        color: colorScheme.outlineVariant
                                            .withValues(alpha: 0.55),
                                        width: 1.0,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                            child: Icon(appIcon, size: 22, color: accentColor),
                          ),
                          if (hasUpdate && !expressiveUpdate)
                            Positioned(
                              right: -5,
                              bottom: -5,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.download_rounded,
                                  size: 11,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (viewSettings.displayShowVersion) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!hasUpdate && showSource) ...[
                            Icon(
                              Icons.terminal_rounded,
                              size: 10,
                              color: colorScheme.primary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 3),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: hasUpdate && expressiveUpdate ? 8 : 6,
                              vertical: hasUpdate && expressiveUpdate ? 2.5 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: hasUpdate
                                  ? (expressiveUpdate
                                        ? colorScheme.primary
                                        : colorScheme.primary.withValues(
                                            alpha: 0.14,
                                          ))
                                  : colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(
                                CardMetrics.pillRadius,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasUpdate) ...[
                                  Icon(
                                    expressiveUpdate
                                        ? Icons.download_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 9,
                                    color: expressiveUpdate
                                        ? colorScheme.onPrimary
                                        : colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  version,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: hasUpdate
                                        ? (expressiveUpdate
                                              ? colorScheme.onPrimary
                                              : colorScheme.primary)
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        isCompact ? 4 : 6,
        12,
        isCompact ? 6 : 10,
      ),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 10 : 14),
        decoration: ShapeDecoration(
          color: colorScheme.surfaceContainerLowest.withValues(
            alpha: isDark ? 0.55 : 0.85,
          ),
          shape: CardMetrics.shape(
            CardMetrics.inner(radius),
            expressive: plusSettings.plusEnableMaterialExpressive,
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tr('appTilePreview'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${isSquare ? "1:1" : "Portrait"}${isCardless ? " · Cardless" : ""}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Row(
                  children: [
                    Expanded(
                      child: buildMockTile(
                        name: 'Obtainium+',
                        appIcon: Icons.auto_awesome_rounded,
                        accentColor: colorScheme.primary,
                        version: '1.6.17',
                        hasUpdate: false,
                        isPinned: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildMockTile(
                        name: 'Shizuku+',
                        appIcon: Icons.bolt_rounded,
                        accentColor: colorScheme.tertiary,
                        version: '2.4.0',
                        hasUpdate: true,
                        isPinned: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSettings(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        final isCompact = context.select<PlusSettingsProvider, bool>(
          (s) => s.plusUseCompactSettings,
        );
        bool showDisplay = _matches(
          tr('gridCategoryDisplay'),
          desc: tr('gridCategoryDisplayDescription'),
        );
        bool showCols = _matches(
          tr('gridColumns'),
          desc: tr('gridColumnsDescription'),
        );

        return Column(
          children: [
            if (showDisplay)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  isCompact ? 4 : 8,
                  16,
                  isCompact ? 4 : 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        buildSettingsIconBadge(
                          context,
                          Icons.grid_view_outlined,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tr('gridCategoryDisplay'),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<GridCategoryMode>(
                        style: SegmentedButton.styleFrom(
                          visualDensity: isCompact
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                        ),
                        segments: [
                          ButtonSegment(
                            value: GridCategoryMode.sections,
                            label: Text(tr('categorySections')),
                            icon: const Icon(Icons.category_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: GridCategoryMode.disabled,
                            label: Text(tr('flatGridOnly')),
                            icon: const Icon(Icons.grid_3x3_rounded, size: 16),
                          ),
                        ],
                        selected: {settings.gridCategoryMode},
                        onSelectionChanged: (value) {
                          AppHaptics.selectionClick();
                          onSetState(
                            () => settings.gridCategoryMode = value.first,
                          );
                        },
                        showSelectedIcon: false,
                      ),
                    ),
                  ],
                ),
              ),
            if (showCols)
              SettingsSliderTile(
                icon: Icons.view_column_outlined,
                title: tr('gridColumns'),
                value: settings.gridColumnCount.toDouble(),
                defaultValue: 0.0,
                min: 0,
                max: 6,
                divisions: 6,
                labelBuilder: (v) =>
                    v.toInt() == 0 ? tr('auto') : v.toInt().toString(),
                onChanged: (value) =>
                    onSetState(() => settings.gridColumnCount = value.toInt()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryIconPositionDropdown(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        final isCompact = context.select<PlusSettingsProvider, bool>(
          (s) => s.plusUseCompactSettings,
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            isCompact ? 4 : 8,
            16,
            isCompact ? 4 : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  buildSettingsIconBadge(
                    context,
                    Icons.branding_watermark_outlined,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      tr('iconPosition'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<CategoryIconPosition>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: isCompact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                  ),
                  segments: [
                    ButtonSegment(
                      value: CategoryIconPosition.disabled,
                      label: Text(tr('disabled')),
                    ),
                    ButtonSegment(
                      value: CategoryIconPosition.leading,
                      label: Text(tr('leading')),
                    ),
                    ButtonSegment(
                      value: CategoryIconPosition.trailing,
                      label: Text(tr('trailing')),
                    ),
                    ButtonSegment(
                      value: CategoryIconPosition.below,
                      label: Text(tr('belowName')),
                    ),
                  ],
                  selected: {settings.categoryIconPosition},
                  onSelectionChanged: (value) {
                    AppHaptics.selectionClick();
                    onSetState(
                      () => settings.categoryIconPosition = value.first,
                    );
                  },
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryIconCountSlider(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        final disabled =
            settings.categoryIconPosition == CategoryIconPosition.disabled;
        return Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: IgnorePointer(
            ignoring: disabled,
            child: SettingsSliderTile(
              icon: Icons.numbers_outlined,
              title: tr('iconCount'),
              value: settings.categoryIconCount.toDouble(),
              defaultValue: 0.0,
              min: 0,
              max: 20,
              divisions: 20,
              labelBuilder: (v) => v.toInt().toString(),
              onChanged: (value) =>
                  onSetState(() => settings.categoryIconCount = value.toInt()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppDescriptionStyleSelector(BuildContext context) {
    return Consumer<PlusSettingsProvider>(
      builder: (context, plusSettings, child) {
        final isCompact = plusSettings.plusUseCompactSettings;
        final currentStyle = plusSettings.plusAppDescriptionStyle;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: isCompact,
              visualDensity: isCompact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              leading: buildSettingsIconBadge(
                context,
                Icons.auto_awesome_outlined,
              ),
              title: Text(
                'Default App Details Tab',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: isCompact
                  ? null
                  : const Text(
                      'Default style when viewing app details: Obtainium+, README, Play Store, Webpage, or Raw',
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, isCompact ? 8 : 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SegmentedButton<AppDescriptionStyle>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: isCompact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                  ),
                  segments: [
                    ButtonSegment(
                      value: AppDescriptionStyle.obtainiumPlus,
                      label: Text('Obtainium+'),
                      icon: Icon(Icons.rocket_launch_rounded),
                    ),
                    ButtonSegment(
                      value: AppDescriptionStyle.githubReadme,
                      label: Text(tr('descriptionStyleReadme')),
                      icon: Icon(Icons.code_rounded),
                    ),
                    ButtonSegment(
                      value: AppDescriptionStyle.playStore,
                      label: Text(tr('playStore')),
                      icon: Icon(Icons.shop_two_outlined),
                    ),
                    ButtonSegment(
                      value: AppDescriptionStyle.liveWebpage,
                      label: Text(tr('descriptionStyleWebpage')),
                      icon: Icon(Icons.language_rounded),
                    ),
                    ButtonSegment(
                      value: AppDescriptionStyle.rawMarkdown,
                      label: Text(tr('descriptionStyleRaw')),
                      icon: Icon(Icons.text_snippet_outlined),
                    ),
                  ],
                  selected: {currentStyle},
                  onSelectionChanged: (value) {
                    AppHaptics.selectionClick();
                    onSetState(() {
                      plusSettings.plusAppDescriptionStyle = value.first;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewModeDropdown(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        final isCompact = context.select<PlusSettingsProvider, bool>(
          (s) => s.plusUseCompactSettings,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: isCompact,
              visualDensity: isCompact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              leading: buildSettingsIconBadge(
                context,
                Icons.view_quilt_outlined,
              ),
              title: Text(
                tr('defaultViewMode'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: isCompact ? null : Text(tr('viewModeDescription')),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, isCompact ? 8 : 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ViewMode>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: isCompact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                  ),
                  segments: [
                    ButtonSegment(
                      value: ViewMode.list,
                      label: Text(tr('listView')),
                      icon: const Icon(Icons.view_list_rounded),
                    ),
                    ButtonSegment(
                      value: ViewMode.grid,
                      label: Text(tr('gridView')),
                      icon: const Icon(Icons.grid_view_rounded),
                    ),
                  ],
                  selected: {settings.globalViewMode},
                  onSelectionChanged: (value) {
                    AppHaptics.selectionClick();
                    onSetState(() => settings.globalViewMode = value.first);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBarStyleDropdown(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isCompact = context.select<PlusSettingsProvider, bool>(
      (s) => s.plusUseCompactSettings,
    );
    final currentStyle = settingsProvider.getAppBarStyleForPage('apps');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: isCompact,
          visualDensity: isCompact
              ? VisualDensity.compact
              : VisualDensity.standard,
          leading: buildSettingsIconBadge(
            context,
            Icons.vertical_align_top_rounded,
          ),
          title: Text(
            tr('appBarStyle'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: isCompact ? null : Text(tr('appBarStyleDescription')),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, isCompact ? 8 : 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppBarStyle>(
              style: SegmentedButton.styleFrom(
                visualDensity: isCompact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
              ),
              segments: AppBarStyle.values
                  .map(
                    (e) => ButtonSegment(
                      value: e,
                      label: Text(
                        e.name.substring(0, 1).toUpperCase() +
                            e.name.substring(1),
                      ),
                    ),
                  )
                  .toList(),
              selected: {currentStyle},
              onSelectionChanged: (value) {
                AppHaptics.selectionClick();
                onSetState(() {
                  settingsProvider.setAppBarStyleForPage('apps', value.first);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Updates can show in the dashboard row, pinned to the top of the list,
  /// both or neither.
  Widget _buildUpdatesPlacement(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        final isCompact = context.select<PlusSettingsProvider, bool>(
          (s) => s.plusUseCompactSettings,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: isCompact,
              visualDensity: isCompact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              leading: buildSettingsIconBadge(context, Icons.push_pin_outlined),
              title: Text(
                tr('updatesPlacement'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: isCompact
                  ? null
                  : Text(tr('updatesPlacementDescription')),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, isCompact ? 8 : 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: isCompact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                  ),
                  multiSelectionEnabled: true,
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: 'row',
                      icon: const Icon(Icons.view_carousel_outlined),
                      label: Text(tr('updatesPlacementRow')),
                    ),
                    ButtonSegment(
                      value: 'pinned',
                      icon: const Icon(Icons.vertical_align_top_rounded),
                      label: Text(tr('updatesPlacementPinned')),
                    ),
                  ],
                  selected: {
                    if (settings.showUpdatesRow) 'row',
                    if (settings.pinUpdates) 'pinned',
                  },
                  onSelectionChanged: (value) {
                    AppHaptics.selectionClick();
                    onSetState(() {
                      settings.showUpdatesRow = value.contains('row');
                      settings.pinUpdates = value.contains('pinned');
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDensityDropdown(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        final isCompact = context.select<PlusSettingsProvider, bool>(
          (s) => s.plusUseCompactSettings,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: isCompact,
              visualDensity: isCompact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              leading: buildSettingsIconBadge(
                context,
                Icons.density_medium_outlined,
              ),
              title: Text(
                tr('listDensity'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: isCompact ? null : Text(tr('listDensityDescription')),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, isCompact ? 8 : 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<AppListDensity>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: isCompact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                  ),
                  segments: AppListDensity.values
                      .map(
                        (e) => ButtonSegment(
                          value: e,
                          label: Text(tr('density_${e.name}')),
                        ),
                      )
                      .toList(),
                  selected: {settings.appListDensity},
                  onSelectionChanged: (value) {
                    AppHaptics.selectionClick();
                    onSetState(() => settings.appListDensity = value.first);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
