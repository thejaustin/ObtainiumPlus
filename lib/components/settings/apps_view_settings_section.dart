import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
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

/// Apps, Categories, and View settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class AppsViewSettingsSection extends StatelessWidget {
  final Function(void Function()) onSetState;
  final String? searchQuery;
  final bool? showAdvancedSettings;
  final String? subCategory;

  const AppsViewSettingsSection({
    super.key,
    required this.onSetState,
    this.searchQuery,
    this.showAdvancedSettings,
    this.subCategory,
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
      if (_matches(tr('groupByCategory'), desc: tr('groupByCategoryDescription')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.category_outlined,
          title: tr('groupByCategory'),
          subtitle: tr('groupByCategoryDescription'),
          value: (s) => s.groupByCategory,
          onChanged: (s, v) => onSetState(() => s.groupByCategory = v),
        ),
      if (_matches(tr('collapseCategoriesByDefault'), desc: tr('collapseCategoriesByDefaultDescription')))
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
      if (_matches(tr('iconCount'), desc: tr('iconCountDescription'))) _buildCategoryIconCountSlider(context),
    ];

    List<Widget> viewWidgets = [
      if (_matches(tr('showWebInAppView'), desc: tr('showWebInAppViewDescription')) ||
          (_matches('default app details tab') || _matches(tr('searchKeywordDefaultAppDetailsTab'))) ||
          (_matches('description style') || _matches(tr('searchKeywordDescriptionStyle'))) ||
          (_matches('webpage') || _matches(tr('descriptionStyleWebpage'))))
        _buildAppDescriptionStyleSelector(context),
      if (_matches(tr('updatesPlacement'), desc: tr('updatesPlacementDescription')) ||
          _matches(tr('pinUpdates'), desc: tr('pinUpdatesDescription')) ||
          _matches(tr('recentUpdates')))
        _buildUpdatesPlacement(context),
      if (_matches(tr('buryNonInstalled'), desc: tr('buryNonInstalledDescription')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.archive_outlined,
          title: tr('buryNonInstalled'),
          subtitle: tr('buryNonInstalledDescription'),
          value: (s) => s.buryNonInstalled,
          onChanged: (s, v) => onSetState(() => s.buryNonInstalled = v),
        ),
      if (_matches(tr('defaultViewMode'))) _buildViewModeDropdown(context),
      if (_matches(tr('listDensity'), desc: tr('listDensityDescription'))) _buildDensityDropdown(context),
      if (_matches(tr('appBarStyle'), desc: tr('appBarStyleDescription'))) _buildAppBarStyleDropdown(context),
      _buildGridSettings(context),
    ];

    final bool showFabMenuGrid =
        plusFeaturesEnabled &&
        (_matches(tr('fabShowAddByUrl'), desc: tr('fabShowAddByUrlDescription')) ||
            _matches(tr('fabShowGithubStarred'), desc: tr('fabShowGithubStarredDescription')) ||
            _matches(tr('fabShowGithubPersonalRepos'), desc: tr('fabShowGithubPersonalReposDescription')) ||
            _matches(tr('fabShowImportInstalled'), desc: tr('fabShowImportInstalledDescription')));

    List<Widget> sortingWidgets = [
      if (_matches(tr('plusQuickFilters'), desc: tr('plusQuickFiltersDescription')))
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
      if (plusSettings.plusEnableTags && _matches(tr('plusShowTagsInList'), desc: tr('plusShowTagsInListDescription')))
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: buildFeatureToggle<PlusSettingsProvider>(
            context,
            icon: Icons.label_outline,
            title: tr('plusShowTagsInList'),
            subtitle: tr('plusShowTagsInListDescription'),
            value: (s) => s.plusShowTagsInList,
            onChanged: (s, v) => onSetState(() => s.plusShowTagsInList = v),
          ),
        ),
      if (_matches(tr('plusAdvancedSorting'), desc: tr('plusAdvancedSortingDescription'), isAdvanced: true))
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

    final bool showDisplayGrid =
        _matches(tr('showAuthor'), desc: tr('showAuthorDescription')) ||
        _matches(tr('showVersion'), desc: tr('showVersionDescription')) ||
        _matches(tr('showDate'), desc: tr('showDateDescription')) ||
        _matches(tr('plusEnableSwipeActions'), desc: tr('plusEnableSwipeActionsDescription'));

    final bool showSearchGrid =
        _matches(tr('showAppBarSearch'), desc: tr('showAppBarSearchDescription')) ||
        _matches(tr('showDashboardSearch'), desc: tr('showDashboardSearchDescription')) ||
        _matches(tr('showFloatingSearch'), desc: tr('showFloatingSearchDescription'));

    final showLayout = subCategory == null || subCategory == 'layout';
    final showTiles = subCategory == null || subCategory == 'tiles';

    final List<Widget> innerList = [
      if (showLayout && categoryWidgets.isNotEmpty)
        ExpressiveSettingsGroup(
          title: isSearching || subCategory != null
              ? null
              : tr('categorySettings'),
          persistKey: 'categorySettings',
          isExpandable: subCategory == null,
          initiallyExpanded: true,
          children: categoryWidgets,
        ),
      if (showLayout && viewWidgets.isNotEmpty)
        ExpressiveSettingsGroup(
          title: isSearching || subCategory != null ? null : tr('viewMode'),
          persistKey: 'viewMode',
          isExpandable: subCategory == null,
          initiallyExpanded: true,
          children: viewWidgets,
        ),
      if (showLayout &&
          plusFeaturesEnabled &&
          (_matches(tr('plusEnableBottomNavBar'), desc: tr('plusEnableBottomNavBarDescription')) ||
              _matches(tr('plusFloatingNavBar'), desc: tr('plusFloatingNavBarDescription')) ||
              _matches(tr('plusHideBottomBarOnScroll'), desc: tr('plusHideBottomBarOnScrollDescription')) ||
              _matches(tr('plusSettingsBottomNavBar'), desc: tr('plusSettingsBottomNavBarDescription')) ||
              _matches(tr('plusEnableFAB'), desc: tr('plusEnableFABDescription')) ||
              _matches(tr('plusFloatingActionBar'), desc: tr('plusFloatingActionBarDescription')) ||
              _matches(tr('plusShowStatusHub'), desc: tr('plusShowStatusHubDescription'))))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('settingsAppearanceLayoutNav'),
          embedded: subCategory == null,
          settings: [
            if (_matches(tr('plusEnableBottomNavBar'), desc: tr('plusEnableBottomNavBarDescription')))
              (
                icon: Icons.navigation_rounded,
                label: tr('plusEnableBottomNavBar'),
                description: tr('plusEnableBottomNavBarDescription'),
                getValue: (s) => s.plusEnableBottomNavBar,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableBottomNavBar = v),
              ),
            if (_matches(tr('plusFloatingNavBar'), desc: tr('plusFloatingNavBarDescription')))
              (
                icon: Icons.dock_rounded,
                label: tr('plusFloatingNavBar'),
                description: tr('plusFloatingNavBarDescription'),
                getValue: (s) => s.plusFloatingNavBar,
                setValue: (s, v) => onSetState(() => s.plusFloatingNavBar = v),
              ),
            if (_matches(tr('plusHideBottomBarOnScroll'), desc: tr('plusHideBottomBarOnScrollDescription')))
              (
                icon: Icons.unfold_more_rounded,
                label: tr('plusHideBottomBarOnScroll'),
                description: tr('plusHideBottomBarOnScrollDescription'),
                getValue: (s) => s.plusHideBottomBarOnScroll,
                setValue: (s, v) =>
                    onSetState(() => s.plusHideBottomBarOnScroll = v),
              ),
            if (_matches(tr('plusEnableFAB'), desc: tr('plusEnableFABDescription')))
              (
                icon: Icons.add_circle_outline_rounded,
                label: tr('plusEnableFAB'),
                description: tr('plusEnableFABDescription'),
                getValue: (s) => s.plusEnableFAB,
                setValue: (s, v) => onSetState(() => s.plusEnableFAB = v),
              ),
            if (_matches(tr('plusFloatingActionBar'), desc: tr('plusFloatingActionBarDescription')))
              (
                icon: Icons.smart_button_rounded,
                label: tr('plusFloatingActionBar'),
                description: tr('plusFloatingActionBarDescription'),
                getValue: (s) => s.plusFloatingActionBar,
                setValue: (s, v) =>
                    onSetState(() => s.plusFloatingActionBar = v),
              ),
            if (_matches(tr('plusShowStatusHub'), desc: tr('plusShowStatusHubDescription')))
              (
                icon: Icons.info_outline_rounded,
                label: tr('plusShowStatusHub'),
                description: tr('plusShowStatusHubDescription'),
                getValue: (s) => s.plusShowStatusHub,
                setValue: (s, v) => onSetState(() => s.plusShowStatusHub = v),
              ),
          ],
        ),
      if (showLayout &&
          plusFeaturesEnabled &&
          (_matches(tr('plusModernAddAppPage'), desc: tr('plusModernAddAppPageDescription')) ||
              _matches(tr('plusHomeDashboard'), desc: tr('plusHomeDashboardDescription')) ||
              _matches(tr('plusHeaderContextSubtitle'), desc: tr('plusHeaderContextSubtitleDescription')) ||
              _matches(tr('plusExpressiveFilterChips'), desc: tr('plusExpressiveFilterChipsDescription')) ||
              _matches(tr('plusResponsiveLayout'), desc: tr('plusResponsiveLayoutDescription'), isAdvanced: true) ||
              _matches(tr('plusCategoryReorder'), desc: tr('plusCategoryReorderDescription'), isAdvanced: true)))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('settingsLayoutMode'),
          embedded: subCategory == null,
          settings: [
            if (_matches(tr('plusModernAddAppPage'), desc: tr('plusModernAddAppPageDescription')))
              (
                icon: Icons.add_box_outlined,
                label: tr('plusModernAddAppPage'),
                description: tr('plusModernAddAppPageDescription'),
                getValue: (s) => s.plusEnableModernAddAppPage,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableModernAddAppPage = v),
              ),
            if (_matches(tr('plusHomeDashboard'), desc: tr('plusHomeDashboardDescription')))
              (
                icon: Icons.dashboard_customize_outlined,
                label: tr('plusHomeDashboard'),
                description: tr('plusHomeDashboardDescription'),
                getValue: (s) => s.plusEnableHomeDashboard,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableHomeDashboard = v),
              ),
            if (_matches(tr('plusHeaderContextSubtitle'), desc: tr('plusHeaderContextSubtitleDescription')))
              (
                icon: Icons.subtitles_rounded,
                label: tr('plusHeaderContextSubtitle'),
                description: tr('plusHeaderContextSubtitleDescription'),
                getValue: (s) => s.plusHeaderContextSubtitle,
                setValue: (s, v) =>
                    onSetState(() => s.plusHeaderContextSubtitle = v),
              ),
            if (_matches(tr('plusExpressiveFilterChips'), desc: tr('plusExpressiveFilterChipsDescription')))
              (
                icon: Icons.filter_alt_rounded,
                label: tr('plusExpressiveFilterChips'),
                description: tr('plusExpressiveFilterChipsDescription'),
                getValue: (s) => s.plusExpressiveFilterChips,
                setValue: (s, v) =>
                    onSetState(() => s.plusExpressiveFilterChips = v),
              ),
            if (_matches(tr('plusResponsiveLayout'), desc: tr('plusResponsiveLayoutDescription'), isAdvanced: true))
              (
                icon: Icons.tablet_android_rounded,
                label: tr('plusResponsiveLayout'),
                description: tr('plusResponsiveLayoutDescription'),
                getValue: (s) => s.plusEnableResponsiveAppLayout,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableResponsiveAppLayout = v),
              ),
            if (_matches(tr('plusCategoryReorder'), desc: tr('plusCategoryReorderDescription'), isAdvanced: true))
              (
                icon: Icons.drag_indicator_rounded,
                label: tr('plusCategoryReorder'),
                description: tr('plusCategoryReorderDescription'),
                getValue: (s) => s.plusEnableCategoryReorder,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableCategoryReorder = v),
              ),
          ],
        ),
      if (showLayout &&
          (_matches(tr('showFilterChips'), desc: tr('showFilterChipsDescription')) || _matches(tr('showAppCount'), desc: tr('showAppCountDescription'))))
        GenericBooleanControlGrid<ViewSettingsProvider>(
          title: tr('filterChips'),
          embedded: subCategory == null,
          settings: [
            if (_matches(tr('showFilterChips'), desc: tr('showFilterChipsDescription')))
              (
                icon: Icons.filter_list_outlined,
                label: tr('showFilterChips'),
                description: tr('showFilterChipsDescription'),
                getValue: (s) => s.displayShowFilterChips,
                setValue: (s, v) =>
                    onSetState(() => s.displayShowFilterChips = v),
              ),
            if (_matches(tr('showAppCount'), desc: tr('showAppCountDescription')))
              (
                icon: Icons.summarize_outlined,
                label: tr('showAppCount'),
                description: tr('showAppCountDescription'),
                getValue: (s) => s.displayShowAppCount,
                setValue: (s, v) => onSetState(() => s.displayShowAppCount = v),
              ),
          ],
        ),
      if (showLayout && showFabMenuGrid)
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('fabMenuItems'),
          embedded: subCategory == null,
          settings: [
            if (_matches(tr('fabShowAddByUrl'), desc: tr('fabShowAddByUrlDescription')))
              (
                icon: Icons.link_outlined,
                label: tr('fabShowAddByUrl'),
                description: tr('fabShowAddByUrlDescription'),
                getValue: (s) => s.plusFabShowAddByUrl,
                setValue: (s, v) => onSetState(() => s.plusFabShowAddByUrl = v),
              ),
            if (_matches(tr('fabShowGithubStarred'), desc: tr('fabShowGithubStarredDescription')))
              (
                icon: Icons.star_border_rounded,
                label: tr('fabShowGithubStarred'),
                description: tr('fabShowGithubStarredDescription'),
                getValue: (s) => s.plusFabShowGithubStarred,
                setValue: (s, v) =>
                    onSetState(() => s.plusFabShowGithubStarred = v),
              ),
            if (_matches(tr('fabShowGithubPersonalRepos'), desc: tr('fabShowGithubPersonalReposDescription')))
              (
                icon: Icons.person_outline_rounded,
                label: tr('fabShowGithubPersonalRepos'),
                description: tr('fabShowGithubPersonalReposDescription'),
                getValue: (s) => s.plusFabShowGithubPersonalRepos,
                setValue: (s, v) =>
                    onSetState(() => s.plusFabShowGithubPersonalRepos = v),
              ),
            if (_matches(tr('fabShowImportInstalled'), desc: tr('fabShowImportInstalledDescription')))
              (
                icon: Icons.install_mobile_outlined,
                label: tr('fabShowImportInstalled'),
                description: tr('fabShowImportInstalledDescription'),
                getValue: (s) => s.plusFabShowImportInstalled,
                setValue: (s, v) =>
                    onSetState(() => s.plusFabShowImportInstalled = v),
              ),
          ],
        ),
      if (showLayout && plusFeaturesEnabled && sortingWidgets.isNotEmpty)
        ExpressiveSettingsGroup(
          title: isSearching || subCategory != null
              ? null
              : tr('plusSectionOrganizationSorting'),
          persistKey: 'plusSectionOrganizationSorting',
          isExpandable: subCategory == null,
          initiallyExpanded: true,
          children: sortingWidgets,
        ),
      if (showTiles && !isSearching) _buildAppTileStylePreview(context),
      if (showTiles &&
          plusFeaturesEnabled &&
          (_matches(tr('plusGridSquareTiles'), desc: tr('plusGridSquareTilesDescription')) ||
              _matches(tr('plusGridCardlessStyle'), desc: tr('plusGridCardlessStyleDescription')) ||
              _matches(tr('plusGridAmbientIconHalo'), desc: tr('plusGridAmbientIconHaloDescription')) ||
              _matches(tr('plusGridShowSourceBadge'), desc: tr('plusGridShowSourceBadgeDescription'))))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('plusLauncherGridStyle'),
          embedded: subCategory == null,
          settings: [
            if (_matches(tr('plusGridSquareTiles'), desc: tr('plusGridSquareTilesDescription')))
              (
                icon: Icons.crop_square_rounded,
                label: tr('plusGridSquareTiles'),
                description: tr('plusGridSquareTilesDescription'),
                getValue: (s) => s.plusGridSquareTiles,
                setValue: (s, v) => onSetState(() => s.plusGridSquareTiles = v),
              ),
            if (_matches(tr('plusGridCardlessStyle'), desc: tr('plusGridCardlessStyleDescription')))
              (
                icon: Icons.border_clear_rounded,
                label: tr('plusGridCardlessStyle'),
                description: tr('plusGridCardlessStyleDescription'),
                getValue: (s) => s.plusGridCardlessStyle,
                setValue: (s, v) =>
                    onSetState(() => s.plusGridCardlessStyle = v),
              ),
            if (_matches(tr('plusGridAmbientIconHalo'), desc: tr('plusGridAmbientIconHaloDescription')))
              (
                icon: Icons.flare_rounded,
                label: tr('plusGridAmbientIconHalo'),
                description: tr('plusGridAmbientIconHaloDescription'),
                getValue: (s) => s.plusGridAmbientIconHalo,
                setValue: (s, v) =>
                    onSetState(() => s.plusGridAmbientIconHalo = v),
              ),
            if (_matches(tr('plusGridShowSourceBadge'), desc: tr('plusGridShowSourceBadgeDescription')))
              (
                icon: Icons.badge_outlined,
                label: tr('plusGridShowSourceBadge'),
                description: tr('plusGridShowSourceBadgeDescription'),
                getValue: (s) => s.plusGridShowSourceBadge,
                setValue: (s, v) =>
                    onSetState(() => s.plusGridShowSourceBadge = v),
              ),
          ],
        ),
      if (showTiles && showDisplayGrid)
        GenericBooleanControlGrid<ViewSettingsProvider>(
          title: tr('appTileDisplay'),
          embedded: subCategory == null,
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
      if (showTiles &&
          plusFeaturesEnabled &&
          (_matches(tr('plusPinnedBorderAccent'), desc: tr('plusPinnedBorderAccentDescription')) ||
              _matches(tr('plusCategoryAccentRibbon'), desc: tr('plusCategoryAccentRibbonDescription')) ||
              _matches(tr('plusUpdateExpressiveBadge'), desc: tr('plusUpdateExpressiveBadgeDescription')) ||
              _matches(tr('plusIconRimBorder'), desc: tr('plusIconRimBorderDescription'))))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('plusAppTileStyling'),
          embedded: subCategory == null,
          settings: [
            if (_matches(tr('plusPinnedBorderAccent'), desc: tr('plusPinnedBorderAccentDescription')))
              (
                icon: Icons.push_pin_outlined,
                label: tr('plusPinnedBorderAccent'),
                description: tr('plusPinnedBorderAccentDescription'),
                getValue: (s) => s.plusPinnedBorderAccent,
                setValue: (s, v) =>
                    onSetState(() => s.plusPinnedBorderAccent = v),
              ),
            if (_matches(tr('plusCategoryAccentRibbon'), desc: tr('plusCategoryAccentRibbonDescription')))
              (
                icon: Icons.color_lens_outlined,
                label: tr('plusCategoryAccentRibbon'),
                description: tr('plusCategoryAccentRibbonDescription'),
                getValue: (s) => s.plusCategoryAccentRibbon,
                setValue: (s, v) =>
                    onSetState(() => s.plusCategoryAccentRibbon = v),
              ),
            if (_matches(tr('plusUpdateExpressiveBadge'), desc: tr('plusUpdateExpressiveBadgeDescription')))
              (
                icon: Icons.downloading_rounded,
                label: tr('plusUpdateExpressiveBadge'),
                description: tr('plusUpdateExpressiveBadgeDescription'),
                getValue: (s) => s.plusUpdateExpressiveBadge,
                setValue: (s, v) =>
                    onSetState(() => s.plusUpdateExpressiveBadge = v),
              ),
            if (_matches(tr('plusIconRimBorder'), desc: tr('plusIconRimBorderDescription')))
              (
                icon: Icons.crop_square_rounded,
                label: tr('plusIconRimBorder'),
                description: tr('plusIconRimBorderDescription'),
                getValue: (s) => s.plusIconRimBorder,
                setValue: (s, v) => onSetState(() => s.plusIconRimBorder = v),
              ),
          ],
        ),
      if (showLayout &&
          plusFeaturesEnabled &&
          (_matches(tr('plusEnableSwipeActions'), desc: tr('plusEnableSwipeActionsDescription')) ||
              _matches(tr('plusEnableModernAppListTile'), desc: tr('plusEnableModernAppListTileDescription'))))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('plusEnableSwipeActions'),
          embedded: subCategory == null,
          settings: [
            (
              icon: Icons.view_agenda_rounded,
              label: tr('plusEnableModernAppListTile'),
              description: tr('plusEnableModernAppListTileDescription'),
              getValue: (s) => s.plusEnableModernAppListTile,
              setValue: (s, v) =>
                  onSetState(() => s.plusEnableModernAppListTile = v),
            ),
            (
              icon: Icons.swipe_rounded,
              label: tr('plusEnableSwipeActions'),
              description: tr('plusEnableSwipeActionsDescription'),
              getValue: (s) => s.plusEnableSwipeActions,
              setValue: (s, v) =>
                  onSetState(() => s.plusEnableSwipeActions = v),
            ),
          ],
        ),
      if (showLayout && plusFeaturesEnabled && showSearchGrid)
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('searchSettings'),
          embedded: subCategory == null,
          settings: [
            if (_matches(tr('showAppBarSearch'), desc: tr('showAppBarSearchDescription')))
              (
                icon: Icons.vertical_align_top_rounded,
                label: tr('showAppBarSearch'),
                description: tr('showAppBarSearchDescription'),
                getValue: (s) => s.plusShowAppBarSearch,
                setValue: (s, v) =>
                    onSetState(() => s.plusShowAppBarSearch = v),
              ),
            if (_matches(tr('showDashboardSearch'), desc: tr('showDashboardSearchDescription')))
              (
                icon: Icons.dashboard_outlined,
                label: tr('showDashboardSearch'),
                description: tr('showDashboardSearchDescription'),
                getValue: (s) => s.plusShowDashboardSearch,
                setValue: (s, v) =>
                    onSetState(() => s.plusShowDashboardSearch = v),
              ),
          ],
        ),
    ];

    if (subCategory != null) {
      return Column(children: innerList);
    }

    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('appsString'),
      persistKey: 'appsString',
      icon: Icons.grid_view_rounded,
      isExpandable: !isSearching,
      initiallyExpanded: true,
      children: innerList,
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
                Text(
                  tr('appTilePreview'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
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
        bool showDisplay = _matches(tr('gridCategoryDisplay'), desc: tr('gridCategoryDisplayDescription'));
        bool showCols = _matches(tr('gridColumns'), desc: tr('gridColumnsDescription'));

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
