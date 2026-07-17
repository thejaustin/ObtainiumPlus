import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
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

    List<Widget> categoryWidgets = [
      if (!isSearching || _matches('category'))
        CategoryEditorSelector(showLabelWhenNotEmpty: false),
      _buildFeatureToggle<ViewSettingsProvider>(
        context,
        icon: Icons.category_outlined,
        title: tr('groupByCategory'),
        subtitle: tr('groupByCategoryDescription'),
        value: (s) => s.groupByCategory,
        onChanged: (s, v) => onSetState(() => s.groupByCategory = v),
        visible: (s) => _matches(tr('groupByCategory')),
      ),
      _buildFeatureToggle<ViewSettingsProvider>(
        context,
        icon: Icons.unfold_less_outlined,
        title: tr('collapseCategoriesByDefault'),
        subtitle: tr('collapseCategoriesByDefaultDescription'),
        value: (s) => s.categoriesCollapsedByDefault,
        onChanged: (s, v) =>
            onSetState(() => s.categoriesCollapsedByDefault = v),
        visible: (s) => _matches(tr('collapseCategoriesByDefault')),
      ),
    ];

    List<Widget> iconWidgets = [
      if (_matches(tr('iconPosition')))
        _buildCategoryIconPositionDropdown(context),
      if (_matches(tr('iconCount'))) _buildCategoryIconCountSlider(context),
    ];

    List<Widget> viewWidgets = [
      if (_matches(tr('defaultViewMode'))) _buildViewModeDropdown(context),
      if (_matches(tr('listDensity'))) _buildDensityDropdown(context),
      if (_matches(tr('appBarStyle'))) _buildAppBarStyleDropdown(context),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.pages_outlined,
        title: tr('plusModernAppPage'),
        subtitle: tr('plusModernAppPageDescription'),
        value: (s) => s.plusEnableModernAppPage,
        onChanged: (s, v) => onSetState(() => s.plusEnableModernAppPage = v),
        visible: (s) => _matches(tr('plusModernAppPage')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.add_box_outlined,
        title: tr('plusModernAddAppPage'),
        subtitle: tr('plusModernAddAppPageDescription'),
        value: (s) => s.plusEnableModernAddAppPage,
        onChanged: (s, v) => onSetState(() => s.plusEnableModernAddAppPage = v),
        visible: (s) => _matches(tr('plusModernAddAppPage')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.dashboard_customize_outlined,
        title: tr('plusHomeDashboard'),
        subtitle: tr('plusHomeDashboardDescription'),
        value: (s) => s.plusEnableHomeDashboard,
        onChanged: (s, v) => onSetState(() => s.plusEnableHomeDashboard = v),
        visible: (s) => _matches(tr('plusHomeDashboard')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.auto_awesome_mosaic_outlined,
        title: tr('plusDeduplicateRecents'),
        subtitle: tr('plusDeduplicateRecentsDescription'),
        value: (s) => s.plusDeduplicateRecents,
        onChanged: (s, v) => onSetState(() => s.plusDeduplicateRecents = v),
        visible: (s) => _matches(tr('plusDeduplicateRecents')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.gesture_rounded,
        title: tr('plusExpressiveProgress'),
        subtitle: tr('plusExpressiveProgressDescription'),
        value: (s) => s.plusEnableExpressiveProgress,
        onChanged: (s, v) =>
            onSetState(() => s.plusEnableExpressiveProgress = v),
        visible: (s) => _matches(tr('plusExpressiveProgress')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.tablet_android_rounded,
        title: tr('plusResponsiveLayout'),
        subtitle: tr('plusResponsiveLayoutDescription'),
        value: (s) => s.plusEnableResponsiveAppLayout,
        onChanged: (s, v) =>
            onSetState(() => s.plusEnableResponsiveAppLayout = v),
        visible: (s) => _matches(tr('plusResponsiveLayout')),
        isAdvanced: true,
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.drag_indicator_rounded,
        title: tr('plusCategoryReorder'),
        subtitle: tr('plusCategoryReorderDescription'),
        value: (s) => s.plusEnableCategoryReorder,
        onChanged: (s, v) => onSetState(() => s.plusEnableCategoryReorder = v),
        visible: (s) => _matches(tr('plusCategoryReorder')),
        isAdvanced: true,
      ),
      _buildGridSettings(context),
    ];

    List<Widget> displayWidgets = [
      _buildFeatureToggle<ViewSettingsProvider>(
        context,
        icon: Icons.person_outline,
        title: tr('showAuthor'),
        subtitle: tr('showAuthorDescription'),
        value: (s) => s.displayShowAuthor,
        onChanged: (s, v) => onSetState(() => s.displayShowAuthor = v),
        visible: (s) => _matches(tr('showAuthor')),
      ),
      _buildFeatureToggle<ViewSettingsProvider>(
        context,
        icon: Icons.code,
        title: tr('showVersion'),
        subtitle: tr('showVersionDescription'),
        value: (s) => s.displayShowVersion,
        onChanged: (s, v) => onSetState(() => s.displayShowVersion = v),
        visible: (s) => _matches(tr('showVersion')),
      ),
      _buildFeatureToggle<ViewSettingsProvider>(
        context,
        icon: Icons.calendar_today_outlined,
        title: tr('showDate'),
        subtitle: tr('showDateDescription'),
        value: (s) => s.displayShowDate,
        onChanged: (s, v) => onSetState(() => s.displayShowDate = v),
        visible: (s) => _matches(tr('showDate')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.view_list_rounded,
        title: tr('plusModernAppListTile'),
        subtitle: tr('plusModernAppListTileDescription'),
        value: (s) => s.plusEnableModernAppListTile,
        onChanged: (s, v) =>
            onSetState(() => s.plusEnableModernAppListTile = v),
        visible: (s) => _matches(tr('plusModernAppListTile')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.swipe_rounded,
        title: tr('plusEnableSwipeActions'),
        subtitle: tr('plusEnableSwipeActionsDescription'),
        value: (s) => s.plusEnableSwipeActions,
        onChanged: (s, v) => onSetState(() => s.plusEnableSwipeActions = v),
        visible: (s) => _matches(tr('plusEnableSwipeActions')),
      ),
    ];

    List<Widget> headerWidgets = [
      _buildFeatureToggle<ViewSettingsProvider>(
        context,
        icon: Icons.filter_list_outlined,
        title: tr('showFilterChips'),
        subtitle: tr('showFilterChipsDescription'),
        value: (s) => s.displayShowFilterChips,
        onChanged: (s, v) => onSetState(() => s.displayShowFilterChips = v),
        visible: (s) => _matches(tr('showFilterChips')),
      ),
      _buildFeatureToggle<ViewSettingsProvider>(
        context,
        icon: Icons.summarize_outlined,
        title: tr('showAppCount'),
        subtitle: tr('showAppCountDescription'),
        value: (s) => s.displayShowAppCount,
        onChanged: (s, v) => onSetState(() => s.displayShowAppCount = v),
        visible: (s) => _matches(tr('showAppCount')),
      ),
    ];

    List<Widget> searchWidgets = [
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.vertical_align_top_rounded,
        title: tr('showAppBarSearch'),
        subtitle: tr('showAppBarSearchDescription'),
        value: (s) => s.plusShowAppBarSearch,
        onChanged: (s, v) => onSetState(() => s.plusShowAppBarSearch = v),
        visible: (s) => _matches(tr('showAppBarSearch')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.dashboard_outlined,
        title: tr('showDashboardSearch'),
        subtitle: tr('showDashboardSearchDescription'),
        value: (s) => s.plusShowDashboardSearch,
        onChanged: (s, v) => onSetState(() => s.plusShowDashboardSearch = v),
        visible: (s) => _matches(tr('showDashboardSearch')),
      ),
      _buildFeatureToggle<PlusSettingsProvider>(
        context,
        icon: Icons.ads_click_rounded,
        title: tr('showFloatingSearch'),
        subtitle: tr('showFloatingSearchDescription'),
        value: (s) => s.plusShowFloatingSearch,
        onChanged: (s, v) => onSetState(() => s.plusShowFloatingSearch = v),
        visible: (s) => _matches(tr('showFloatingSearch')),
      ),
    ];

    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('appsString'),
      icon: Icons.grid_view_rounded,
      isExpandable: !isSearching,
      initiallyExpanded: false,
      children: [
        if (categoryWidgets.any((w) => w is! SizedBox))
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('categorySettings'),
            isExpandable: true,
            initiallyExpanded: false,
            children: categoryWidgets,
          ),
        if (iconWidgets.any((w) => w is! SizedBox))
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('categoryIconPreview'),
            isExpandable: true,
            initiallyExpanded: false,
            children: iconWidgets,
          ),
        if (viewWidgets.any((w) => w is! SizedBox))
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('viewMode'),
            isExpandable: true,
            initiallyExpanded: false,
            children: viewWidgets,
          ),
        if (displayWidgets.any((w) => w is! SizedBox))
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
        if (searchWidgets.any((w) => w is! SizedBox))
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
        if (headerWidgets.any((w) => w is! SizedBox))
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
                  settingsProvider.prefs?.setInt(
                    'appBarStyle_apps',
                    value.first.index,
                  );
                  settingsProvider.notifyListeners();
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

  Widget _buildFeatureToggle<T extends ChangeNotifier>(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required dynamic Function(T) value,
    required void Function(T, bool) onChanged,
    required bool Function(T) visible,
    bool isAdvanced = false,
  }) {
    return Consumer<T>(
      builder: (context, settings, child) {
        if (!visible(settings) ||
            (isAdvanced && !(showAdvancedSettings ?? false)))
          return const SizedBox.shrink();
        return SwitchListTile.adaptive(
          secondary: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(subtitle),
          value: value(settings),
          onChanged: (v) => onChanged(settings, v),
        );
      },
    );
  }
}
