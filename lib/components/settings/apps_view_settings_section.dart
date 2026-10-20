import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

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

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    final plusFeaturesEnabled = context.select<PlusSettingsProvider, bool>(
      (s) => s.enableAllPlusFeatures,
    );

    List<Widget> categoryWidgets = [
      if (!isSearching || _matches('category'))
        CategoryEditorSelector(showLabelWhenNotEmpty: false),
      if (_matches(tr('groupByCategory')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.category_outlined,
          title: tr('groupByCategory'),
          subtitle: tr('groupByCategoryDescription'),
          value: (s) => s.groupByCategory,
          onChanged: (s, v) => onSetState(() => s.groupByCategory = v),
        ),
      if (_matches(tr('collapseCategoriesByDefault')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.unfold_less_outlined,
          title: tr('collapseCategoriesByDefault'),
          subtitle: tr('collapseCategoriesByDefaultDescription'),
          value: (s) => s.categoriesCollapsedByDefault,
          onChanged: (s, v) =>
              onSetState(() => s.categoriesCollapsedByDefault = v),
        ),
      if (_matches(tr('iconPosition')))
        _buildCategoryIconPositionDropdown(context),
      if (_matches(tr('iconCount'))) _buildCategoryIconCountSlider(context),
    ];

    List<Widget> viewWidgets = [
      if (_matches(tr('showWebInAppView')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.web_outlined,
          title: tr('showWebInAppView'),
          subtitle: tr('showWebInAppViewDescription'),
          value: (s) => s.showAppWebpage,
          onChanged: (s, v) => onSetState(() => s.showAppWebpage = v),
        ),
      if (_matches(tr('pinUpdates')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.push_pin_outlined,
          title: tr('pinUpdates'),
          subtitle: tr('pinUpdatesDescription'),
          value: (s) => s.pinUpdates,
          onChanged: (s, v) => onSetState(() => s.pinUpdates = v),
        ),
      if (_matches(tr('buryNonInstalled')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.archive_outlined,
          title: tr('buryNonInstalled'),
          subtitle: tr('buryNonInstalledDescription'),
          value: (s) => s.buryNonInstalled,
          onChanged: (s, v) => onSetState(() => s.buryNonInstalled = v),
        ),
      if (_matches(tr('defaultViewMode'))) _buildViewModeDropdown(context),
      if (_matches(tr('listDensity'))) _buildDensityDropdown(context),
      if (_matches(tr('appBarStyle'))) _buildAppBarStyleDropdown(context),
      _buildGridSettings(context),
    ];

    final bool showFabMenuGrid =
        plusFeaturesEnabled &&
        (_matches(tr('fabShowAddByUrl')) ||
            _matches(tr('fabShowGithubStarred')) ||
            _matches(tr('fabShowGithubPersonalRepos')) ||
            _matches(tr('fabShowImportInstalled')));

    List<Widget> sortingWidgets = [
      if (_matches(tr('plusIconCaching')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.cached_rounded,
          title: tr('plusIconCaching'),
          subtitle: tr('plusIconCachingDescription'),
          value: (s) => s.plusEnableIconCaching,
          onChanged: (s, v) => onSetState(() => s.plusEnableIconCaching = v),
        ),
      if (_matches(tr('plusQuickFilters')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.back_hand_outlined,
          title: tr('plusQuickFilters'),
          subtitle: tr('plusQuickFiltersDescription'),
          value: (s) => s.plusEnableQuickFilters,
          onChanged: (s, v) => onSetState(() => s.plusEnableQuickFilters = v),
        ),
      if (_matches(tr('plusShowTagsInList')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.label_outline,
          title: tr('plusShowTagsInList'),
          subtitle: tr('plusShowTagsInListDescription'),
          value: (s) => s.plusShowTagsInList,
          onChanged: (s, v) => onSetState(() => s.plusShowTagsInList = v),
        ),
      if (_matches(tr('plusEnableTags')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.label_important_outline,
          title: tr('plusEnableTags'),
          subtitle: tr('plusEnableTagsDescription'),
          value: (s) => s.plusEnableTags,
          onChanged: (s, v) => onSetState(() => s.plusEnableTags = v),
        ),
      if (_matches(tr('plusAdvancedSorting'), isAdvanced: true))
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
        _matches(tr('showAuthor')) ||
        _matches(tr('showVersion')) ||
        _matches(tr('showDate')) ||
        _matches(tr('plusEnableSwipeActions'));

    final bool showSearchGrid =
        _matches(tr('showAppBarSearch')) ||
        _matches(tr('showDashboardSearch')) ||
        _matches(tr('showFloatingSearch'));

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
          (_matches(tr('plusEnableBottomNavBar')) ||
              _matches(tr('plusFloatingNavBar')) ||
              _matches(tr('plusNavBarAlwaysShowLabels')) ||
              _matches(tr('plusSettingsBottomNavBar')) ||
              _matches(tr('plusEnableFAB')) ||
              _matches(tr('plusFloatingActionBar')) ||
              _matches(tr('plusShowStatusHub'))))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('settingsAppearanceLayoutNav'),
          settings: [
            if (_matches(tr('plusEnableBottomNavBar')))
              (
                icon: Icons.navigation_rounded,
                label: tr('plusEnableBottomNavBar'),
                description: tr('plusEnableBottomNavBarDescription'),
                getValue: (s) => s.plusEnableBottomNavBar,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableBottomNavBar = v),
              ),
            if (_matches(tr('plusFloatingNavBar')))
              (
                icon: Icons.dock_rounded,
                label: tr('plusFloatingNavBar'),
                description: tr('plusFloatingNavBarDescription'),
                getValue: (s) => s.plusFloatingNavBar,
                setValue: (s, v) => onSetState(() => s.plusFloatingNavBar = v),
              ),
            if (_matches(tr('plusNavBarAlwaysShowLabels')))
              (
                icon: Icons.label_important_rounded,
                label: tr('plusNavBarAlwaysShowLabels'),
                description: tr('plusNavBarAlwaysShowLabelsDescription'),
                getValue: (s) => s.plusNavBarAlwaysShowLabels,
                setValue: (s, v) =>
                    onSetState(() => s.plusNavBarAlwaysShowLabels = v),
              ),
            if (_matches(tr('plusSettingsBottomNavBar')))
              (
                icon: Icons.table_rows_rounded,
                label: tr('plusSettingsBottomNavBar'),
                description: tr('plusSettingsBottomNavBarDescription'),
                getValue: (s) => s.plusSettingsBottomNavBar,
                setValue: (s, v) =>
                    onSetState(() => s.plusSettingsBottomNavBar = v),
              ),
            if (_matches(tr('plusEnableFAB')))
              (
                icon: Icons.add_circle_outline_rounded,
                label: tr('plusEnableFAB'),
                description: tr('plusEnableFABDescription'),
                getValue: (s) => s.plusEnableFAB,
                setValue: (s, v) => onSetState(() => s.plusEnableFAB = v),
              ),
            if (_matches(tr('plusFloatingActionBar')))
              (
                icon: Icons.smart_button_rounded,
                label: tr('plusFloatingActionBar'),
                description: tr('plusFloatingActionBarDescription'),
                getValue: (s) => s.plusFloatingActionBar,
                setValue: (s, v) =>
                    onSetState(() => s.plusFloatingActionBar = v),
              ),
            if (_matches(tr('plusShowStatusHub')))
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
          (_matches(tr('plusModernAppPage')) ||
              _matches(tr('plusModernAddAppPage')) ||
              _matches(tr('plusHomeDashboard')) ||
              _matches(tr('plusDeduplicateRecents')) ||
              _matches(tr('plusHeaderContextSubtitle')) ||
              _matches(tr('plusExpressiveFilterChips')) ||
              _matches(tr('plusResponsiveLayout'), isAdvanced: true) ||
              _matches(tr('plusCategoryReorder'), isAdvanced: true)))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('settingsLayoutMode'),
          settings: [
            if (_matches(tr('plusModernAppPage')))
              (
                icon: Icons.pages_outlined,
                label: tr('plusModernAppPage'),
                description: tr('plusModernAppPageDescription'),
                getValue: (s) => s.plusEnableModernAppPage,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableModernAppPage = v),
              ),
            if (_matches(tr('plusModernAddAppPage')))
              (
                icon: Icons.add_box_outlined,
                label: tr('plusModernAddAppPage'),
                description: tr('plusModernAddAppPageDescription'),
                getValue: (s) => s.plusEnableModernAddAppPage,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableModernAddAppPage = v),
              ),
            if (_matches(tr('plusHomeDashboard')))
              (
                icon: Icons.dashboard_customize_outlined,
                label: tr('plusHomeDashboard'),
                description: tr('plusHomeDashboardDescription'),
                getValue: (s) => s.plusEnableHomeDashboard,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableHomeDashboard = v),
              ),
            if (_matches(tr('plusDeduplicateRecents')))
              (
                icon: Icons.auto_awesome_mosaic_outlined,
                label: tr('plusDeduplicateRecents'),
                description: tr('plusDeduplicateRecentsDescription'),
                getValue: (s) => s.plusDeduplicateRecents,
                setValue: (s, v) =>
                    onSetState(() => s.plusDeduplicateRecents = v),
              ),
            if (_matches(tr('plusHeaderContextSubtitle')))
              (
                icon: Icons.subtitles_rounded,
                label: tr('plusHeaderContextSubtitle'),
                description: tr('plusHeaderContextSubtitleDescription'),
                getValue: (s) => s.plusHeaderContextSubtitle,
                setValue: (s, v) =>
                    onSetState(() => s.plusHeaderContextSubtitle = v),
              ),
            if (_matches(tr('plusExpressiveFilterChips')))
              (
                icon: Icons.filter_alt_rounded,
                label: tr('plusExpressiveFilterChips'),
                description: tr('plusExpressiveFilterChipsDescription'),
                getValue: (s) => s.plusExpressiveFilterChips,
                setValue: (s, v) =>
                    onSetState(() => s.plusExpressiveFilterChips = v),
              ),
            if (_matches(tr('plusResponsiveLayout'), isAdvanced: true))
              (
                icon: Icons.tablet_android_rounded,
                label: tr('plusResponsiveLayout'),
                description: tr('plusResponsiveLayoutDescription'),
                getValue: (s) => s.plusEnableResponsiveAppLayout,
                setValue: (s, v) =>
                    onSetState(() => s.plusEnableResponsiveAppLayout = v),
              ),
            if (_matches(tr('plusCategoryReorder'), isAdvanced: true))
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
          (_matches(tr('showFilterChips')) || _matches(tr('showAppCount'))))
        GenericBooleanControlGrid<ViewSettingsProvider>(
          title: tr('filterChips'),
          settings: [
            if (_matches(tr('showFilterChips')))
              (
                icon: Icons.filter_list_outlined,
                label: tr('showFilterChips'),
                description: tr('showFilterChipsDescription'),
                getValue: (s) => s.displayShowFilterChips,
                setValue: (s, v) =>
                    onSetState(() => s.displayShowFilterChips = v),
              ),
            if (_matches(tr('showAppCount')))
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
          settings: [
            if (_matches(tr('fabShowAddByUrl')))
              (
                icon: Icons.link_outlined,
                label: tr('fabShowAddByUrl'),
                description: tr('fabShowAddByUrlDescription'),
                getValue: (s) => s.plusFabShowAddByUrl,
                setValue: (s, v) => onSetState(() => s.plusFabShowAddByUrl = v),
              ),
            if (_matches(tr('fabShowGithubStarred')))
              (
                icon: Icons.star_border_rounded,
                label: tr('fabShowGithubStarred'),
                description: tr('fabShowGithubStarredDescription'),
                getValue: (s) => s.plusFabShowGithubStarred,
                setValue: (s, v) =>
                    onSetState(() => s.plusFabShowGithubStarred = v),
              ),
            if (_matches(tr('fabShowGithubPersonalRepos')))
              (
                icon: Icons.person_outline_rounded,
                label: tr('fabShowGithubPersonalRepos'),
                description: tr('fabShowGithubPersonalReposDescription'),
                getValue: (s) => s.plusFabShowGithubPersonalRepos,
                setValue: (s, v) =>
                    onSetState(() => s.plusFabShowGithubPersonalRepos = v),
              ),
            if (_matches(tr('fabShowImportInstalled')))
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
      if (showTiles && showDisplayGrid)
        GenericBooleanControlGrid<ViewSettingsProvider>(
          title: tr('appTileDisplay'),
          settings: [
            if (_matches(tr('showAuthor')))
              (
                icon: Icons.person_outline,
                label: tr('showAuthor'),
                description: tr('showAuthorDescription'),
                getValue: (s) => s.displayShowAuthor,
                setValue: (s, v) => onSetState(() => s.displayShowAuthor = v),
              ),
            if (_matches(tr('showVersion')))
              (
                icon: Icons.code,
                label: tr('showVersion'),
                description: tr('showVersionDescription'),
                getValue: (s) => s.displayShowVersion,
                setValue: (s, v) => onSetState(() => s.displayShowVersion = v),
              ),
            if (_matches(tr('showDate')))
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
          (_matches(tr('plusPinnedBorderAccent')) ||
              _matches(tr('plusCategoryAccentRibbon')) ||
              _matches(tr('plusUpdateExpressiveBadge')) ||
              _matches(tr('plusIconRimBorder'))))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('plusAppTileStyling'),
          settings: [
            if (_matches(tr('plusPinnedBorderAccent')))
              (
                icon: Icons.push_pin_outlined,
                label: tr('plusPinnedBorderAccent'),
                description: tr('plusPinnedBorderAccentDescription'),
                getValue: (s) => s.plusPinnedBorderAccent,
                setValue: (s, v) =>
                    onSetState(() => s.plusPinnedBorderAccent = v),
              ),
            if (_matches(tr('plusCategoryAccentRibbon')))
              (
                icon: Icons.color_lens_outlined,
                label: tr('plusCategoryAccentRibbon'),
                description: tr('plusCategoryAccentRibbonDescription'),
                getValue: (s) => s.plusCategoryAccentRibbon,
                setValue: (s, v) =>
                    onSetState(() => s.plusCategoryAccentRibbon = v),
              ),
            if (_matches(tr('plusUpdateExpressiveBadge')))
              (
                icon: Icons.downloading_rounded,
                label: tr('plusUpdateExpressiveBadge'),
                description: tr('plusUpdateExpressiveBadgeDescription'),
                getValue: (s) => s.plusUpdateExpressiveBadge,
                setValue: (s, v) =>
                    onSetState(() => s.plusUpdateExpressiveBadge = v),
              ),
            if (_matches(tr('plusIconRimBorder')))
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
          (_matches(tr('plusEnableSwipeActions')) ||
              _matches(tr('plusEnableModernAppListTile'))))
        GenericBooleanControlGrid<PlusSettingsProvider>(
          title: tr('plusEnableSwipeActions'),
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
          settings: [
            if (_matches(tr('showAppBarSearch')))
              (
                icon: Icons.vertical_align_top_rounded,
                label: tr('showAppBarSearch'),
                description: tr('showAppBarSearchDescription'),
                getValue: (s) => s.plusShowAppBarSearch,
                setValue: (s, v) =>
                    onSetState(() => s.plusShowAppBarSearch = v),
              ),
            if (_matches(tr('showDashboardSearch')))
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

  Widget _buildGridSettings(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.globalViewMode != ViewMode.grid)
          return const SizedBox.shrink();

        bool showDisplay = _matches(tr('gridCategoryDisplay'));
        bool showCols = _matches(tr('gridColumns'));

        return Column(
          children: [
            if (showDisplay)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grid_view_outlined, size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            tr('gridCategoryDisplay'),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<GridCategoryMode>(
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.branding_watermark_outlined, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      tr('iconPosition'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<CategoryIconPosition>(
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
                  onSetState(() => settings.categoryIconPosition = value.first);
                },
                showSelectedIcon: false,
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

  Widget _buildViewModeDropdown(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.view_quilt_outlined),
              title: Text(
                tr('defaultViewMode'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('viewModeDescription')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ViewMode>(
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
    final currentStyle = settingsProvider.getAppBarStyleForPage('apps');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.vertical_align_top_rounded),
          title: Text(
            tr('appBarStyle'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(tr('appBarStyleDescription')),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppBarStyle>(
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

  Widget _buildDensityDropdown(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.globalViewMode != ViewMode.list)
          return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.density_medium_outlined),
              title: Text(
                tr('listDensity'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('listDensityDescription')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<AppListDensity>(
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
