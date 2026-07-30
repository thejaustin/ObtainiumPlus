import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
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

  const AppsViewSettingsSection({
    super.key,
    required this.onSetState,
    this.searchQuery,
    this.showAdvancedSettings,
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
    ];

    List<Widget> iconWidgets = [
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
      if (_matches(tr('plusModernAppPage')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.pages_outlined,
          title: tr('plusModernAppPage'),
          subtitle: tr('plusModernAppPageDescription'),
          value: (s) => s.plusEnableModernAppPage,
          onChanged: (s, v) => onSetState(() => s.plusEnableModernAppPage = v),
        ),
      if (_matches(tr('plusModernAddAppPage')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.add_box_outlined,
          title: tr('plusModernAddAppPage'),
          subtitle: tr('plusModernAddAppPageDescription'),
          value: (s) => s.plusEnableModernAddAppPage,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableModernAddAppPage = v),
        ),
      if (_matches(tr('plusHomeDashboard')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.dashboard_customize_outlined,
          title: tr('plusHomeDashboard'),
          subtitle: tr('plusHomeDashboardDescription'),
          value: (s) => s.plusEnableHomeDashboard,
          onChanged: (s, v) => onSetState(() => s.plusEnableHomeDashboard = v),
        ),
      if (_matches(tr('plusDeduplicateRecents')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.auto_awesome_mosaic_outlined,
          title: tr('plusDeduplicateRecents'),
          subtitle: tr('plusDeduplicateRecentsDescription'),
          value: (s) => s.plusDeduplicateRecents,
          onChanged: (s, v) => onSetState(() => s.plusDeduplicateRecents = v),
        ),
      if (_matches(tr('plusExpressiveProgress')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.gesture_rounded,
          title: tr('plusExpressiveProgress'),
          subtitle: tr('plusExpressiveProgressDescription'),
          value: (s) => s.plusEnableExpressiveProgress,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableExpressiveProgress = v),
        ),
      if (_matches(tr('plusResponsiveLayout'), isAdvanced: true))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.tablet_android_rounded,
          title: tr('plusResponsiveLayout'),
          subtitle: tr('plusResponsiveLayoutDescription'),
          value: (s) => s.plusEnableResponsiveAppLayout,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableResponsiveAppLayout = v),
        ),
      if (_matches(tr('plusCategoryReorder'), isAdvanced: true))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.drag_indicator_rounded,
          title: tr('plusCategoryReorder'),
          subtitle: tr('plusCategoryReorderDescription'),
          value: (s) => s.plusEnableCategoryReorder,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableCategoryReorder = v),
        ),
      if (_matches(tr('plusShowStatusHub')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.info_outline_rounded,
          title: tr('plusShowStatusHub'),
          subtitle: tr('plusShowStatusHubDescription'),
          value: (s) => s.plusShowStatusHub,
          onChanged: (s, v) => onSetState(() => s.plusShowStatusHub = v),
        ),
      if (_matches(tr('plusEnableBottomNavBar')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.navigation_rounded,
          title: tr('plusEnableBottomNavBar'),
          subtitle: tr('plusEnableBottomNavBarDescription'),
          value: (s) => s.plusEnableBottomNavBar,
          onChanged: (s, v) => onSetState(() => s.plusEnableBottomNavBar = v),
        ),
      if (_matches(tr('plusEnableFAB')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.add_circle_outline_rounded,
          title: tr('plusEnableFAB'),
          subtitle: tr('plusEnableFABDescription'),
          value: (s) => s.plusEnableFAB,
          onChanged: (s, v) => onSetState(() => s.plusEnableFAB = v),
        ),
      _buildGridSettings(context),
    ];

    final bool showFabMenuGrid =
        plusFeaturesEnabled &&
        (_matches(tr('fabShowSearch')) ||
            _matches(tr('fabShowAddByUrl')) ||
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

    List<Widget> displayWidgets = [
      if (_matches(tr('showAuthor')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.person_outline,
          title: tr('showAuthor'),
          subtitle: tr('showAuthorDescription'),
          value: (s) => s.displayShowAuthor,
          onChanged: (s, v) => onSetState(() => s.displayShowAuthor = v),
        ),
      if (_matches(tr('showVersion')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.code,
          title: tr('showVersion'),
          subtitle: tr('showVersionDescription'),
          value: (s) => s.displayShowVersion,
          onChanged: (s, v) => onSetState(() => s.displayShowVersion = v),
        ),
      if (_matches(tr('showDate')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.calendar_today_outlined,
          title: tr('showDate'),
          subtitle: tr('showDateDescription'),
          value: (s) => s.displayShowDate,
          onChanged: (s, v) => onSetState(() => s.displayShowDate = v),
        ),
      if (_matches(tr('plusModernAppListTile')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.view_list_rounded,
          title: tr('plusModernAppListTile'),
          subtitle: tr('plusModernAppListTileDescription'),
          value: (s) => s.plusEnableModernAppListTile,
          onChanged: (s, v) =>
              onSetState(() => s.plusEnableModernAppListTile = v),
        ),
      if (_matches(tr('plusEnableSwipeActions')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.swipe_rounded,
          title: tr('plusEnableSwipeActions'),
          subtitle: tr('plusEnableSwipeActionsDescription'),
          value: (s) => s.plusEnableSwipeActions,
          onChanged: (s, v) => onSetState(() => s.plusEnableSwipeActions = v),
        ),
    ];

    List<Widget> headerWidgets = [
      if (_matches(tr('showFilterChips')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.filter_list_outlined,
          title: tr('showFilterChips'),
          subtitle: tr('showFilterChipsDescription'),
          value: (s) => s.displayShowFilterChips,
          onChanged: (s, v) => onSetState(() => s.displayShowFilterChips = v),
        ),
      if (_matches(tr('showAppCount')))
        buildFeatureToggle<ViewSettingsProvider>(
          context,
          icon: Icons.summarize_outlined,
          title: tr('showAppCount'),
          subtitle: tr('showAppCountDescription'),
          value: (s) => s.displayShowAppCount,
          onChanged: (s, v) => onSetState(() => s.displayShowAppCount = v),
        ),
    ];

    List<Widget> searchWidgets = [
      if (_matches(tr('showAppBarSearch')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.vertical_align_top_rounded,
          title: tr('showAppBarSearch'),
          subtitle: tr('showAppBarSearchDescription'),
          value: (s) => s.plusShowAppBarSearch,
          onChanged: (s, v) => onSetState(() => s.plusShowAppBarSearch = v),
        ),
      if (_matches(tr('showDashboardSearch')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.dashboard_outlined,
          title: tr('showDashboardSearch'),
          subtitle: tr('showDashboardSearchDescription'),
          value: (s) => s.plusShowDashboardSearch,
          onChanged: (s, v) => onSetState(() => s.plusShowDashboardSearch = v),
        ),
      if (_matches(tr('showFloatingSearch')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.ads_click_rounded,
          title: tr('showFloatingSearch'),
          subtitle: tr('showFloatingSearchDescription'),
          value: (s) => s.plusShowFloatingSearch,
          onChanged: (s, v) => onSetState(() => s.plusShowFloatingSearch = v),
        ),
    ];

    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('appsString'),
      icon: Icons.grid_view_rounded,
      isExpandable: !isSearching,
      initiallyExpanded: false,
      children: [
        if (categoryWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('categorySettings'),
            isExpandable: true,
            initiallyExpanded: false,
            children: categoryWidgets,
          ),
        if (iconWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('categoryIconPreview'),
            isExpandable: true,
            initiallyExpanded: false,
            children: iconWidgets,
          ),
        if (viewWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('viewMode'),
            isExpandable: true,
            initiallyExpanded: false,
            children: viewWidgets,
          ),
        if (showFabMenuGrid)
          GenericBooleanControlGrid<PlusSettingsProvider>(
            title: tr('fabMenuItems'),
            settings: [
              if (_matches(tr('fabShowSearch')))
                (
                  icon: Icons.search_rounded,
                  label: tr('fabShowSearch'),
                  description: tr('fabShowSearchDescription'),
                  getValue: (s) => s.plusFabShowSearch,
                  setValue: (s, v) => onSetState(() => s.plusFabShowSearch = v),
                ),
              if (_matches(tr('fabShowAddByUrl')))
                (
                  icon: Icons.link_outlined,
                  label: tr('fabShowAddByUrl'),
                  description: tr('fabShowAddByUrlDescription'),
                  getValue: (s) => s.plusFabShowAddByUrl,
                  setValue: (s, v) =>
                      onSetState(() => s.plusFabShowAddByUrl = v),
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
        if (plusFeaturesEnabled && sortingWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('plusSectionOrganizationSorting'),
            isExpandable: true,
            initiallyExpanded: false,
            children: sortingWidgets,
          ),
        if (displayWidgets.isNotEmpty)
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
                  setValue: (s, v) =>
                      onSetState(() => s.displayShowVersion = v),
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
        if (plusFeaturesEnabled && searchWidgets.isNotEmpty)
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
              if (_matches(tr('showFloatingSearch')))
                (
                  icon: Icons.ads_click_rounded,
                  label: tr('showFloatingSearch'),
                  description: tr('showFloatingSearchDescription'),
                  getValue: (s) => s.plusShowFloatingSearch,
                  setValue: (s, v) =>
                      onSetState(() => s.plusShowFloatingSearch = v),
                ),
            ],
          ),
        if (headerWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('appListHeader'),
            isExpandable: true,
            initiallyExpanded: false,
            children: headerWidgets,
          ),
      ],
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
              ListTile(
                leading: const Icon(Icons.grid_view_outlined),
                title: Text(
                  tr('gridCategoryDisplay'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(tr('gridCategoryDisplayDescription')),
                trailing: DropdownButton<GridCategoryMode>(
                  underline: const SizedBox(),
                  value: settings.gridCategoryMode,
                  items: [
                    DropdownMenuItem(
                      value: GridCategoryMode.sections,
                      child: Text(tr('categorySections')),
                    ),
                    DropdownMenuItem(
                      value: GridCategoryMode.disabled,
                      child: Text(tr('flatGridOnly')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null)
                      onSetState(() => settings.gridCategoryMode = value);
                  },
                ),
              ),
            if (showCols) ...[
              ListTile(
                leading: const Icon(Icons.view_column_outlined),
                title: Text(
                  tr('gridColumns'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(
                  "${tr('gridColumnsDescription')} (${settings.gridColumnCount == 0 ? tr('auto') : settings.gridColumnCount.toString()})",
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Slider(
                  value: settings.gridColumnCount.toDouble(),
                  min: 0,
                  max: 6,
                  divisions: 6,
                  onChanged: (value) => onSetState(
                    () => settings.gridColumnCount = value.toInt(),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCategoryIconPositionDropdown(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.branding_watermark_outlined),
          title: Text(
            tr('iconPosition'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(tr('iconPositionDescription')),
          trailing: DropdownButton<CategoryIconPosition>(
            underline: const SizedBox(),
            value: settings.categoryIconPosition,
            items: [
              DropdownMenuItem(
                value: CategoryIconPosition.disabled,
                child: Text(tr('disabled')),
              ),
              DropdownMenuItem(
                value: CategoryIconPosition.leading,
                child: Text(tr('leading')),
              ),
              DropdownMenuItem(
                value: CategoryIconPosition.trailing,
                child: Text(tr('trailing')),
              ),
              DropdownMenuItem(
                value: CategoryIconPosition.below,
                child: Text(tr('belowName')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onSetState(() => settings.categoryIconPosition = value);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryIconCountSlider(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.numbers_outlined),
              title: Text(
                tr('iconCount'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(
                "${tr('iconCountDescription')} (${settings.categoryIconCount})",
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Slider(
                value: settings.categoryIconCount.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                onChanged:
                    settings.categoryIconPosition ==
                        CategoryIconPosition.disabled
                    ? null
                    : (value) => onSetState(
                        () => settings.categoryIconCount = value.toInt(),
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
