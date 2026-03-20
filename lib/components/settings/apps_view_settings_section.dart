import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:provider/provider.dart';

/// Apps, Categories, and View settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class AppsViewSettingsSection extends StatelessWidget {
  final Function(void Function()) onSetState;
  final String? searchQuery;

  const AppsViewSettingsSection({
    super.key,
    required this.onSetState,
    this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    List<Widget> categoryWidgets = [
      if (!isSearching || _matches('category')) CategoryEditorSelector(showLabelWhenNotEmpty: false),
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
        onChanged: (s, v) => onSetState(() => s.categoriesCollapsedByDefault = v),
        visible: (s) => _matches(tr('collapseCategoriesByDefault')),
      ),
    ];

    List<Widget> iconWidgets = [
      if (_matches(tr('iconPosition'))) _buildCategoryIconPositionDropdown(context),
      if (_matches(tr('iconCount'))) _buildCategoryIconCountSlider(context),
    ];

    List<Widget> viewWidgets = [
      if (_matches(tr('defaultViewMode'))) _buildViewModeDropdown(context),
      if (_matches(tr('listDensity'))) _buildDensityDropdown(context),
      if (_matches(tr('appBarStyle'))) _buildAppBarStyleDropdown(context),
      _buildFeatureToggle<SettingsProvider>(
        context,
        icon: Icons.pages_outlined,
        title: tr('plusModernAppPage'),
        subtitle: tr('plusModernAppPageDescription'),
        value: (s) => s.plusEnableModernAppPage,
        onChanged: (s, v) => onSetState(() => s.plusEnableModernAppPage = v),
        visible: (s) => _matches(tr('plusModernAppPage')),
      ),
      _buildFeatureToggle<SettingsProvider>(
        context,
        icon: Icons.dashboard_customize_outlined,
        title: tr('plusHomeDashboard'),
        subtitle: tr('plusHomeDashboardDescription'),
        value: (s) => s.plusEnableHomeDashboard,
        onChanged: (s, v) => onSetState(() => s.plusEnableHomeDashboard = v),
        visible: (s) => _matches(tr('plusHomeDashboard')),
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
      _buildFeatureToggle<SettingsProvider>(
        context,
        icon: Icons.view_list_rounded,
        title: tr('plusModernAppListTile'),
        subtitle: tr('plusModernAppListTileDescription'),
        value: (s) => s.plusEnableModernAppListTile,
        onChanged: (s, v) => onSetState(() => s.plusEnableModernAppListTile = v),
        visible: (s) => _matches(tr('plusModernAppListTile')),
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
      _buildFeatureToggle<SettingsProvider>(
        context,
        icon: Icons.vertical_align_top_rounded,
        title: tr('showAppBarSearch'),
        subtitle: tr('showAppBarSearchDescription'),
        value: (s) => s.plusShowAppBarSearch,
        onChanged: (s, v) => onSetState(() => s.plusShowAppBarSearch = v),
        visible: (s) => _matches(tr('showAppBarSearch')),
      ),
      _buildFeatureToggle<SettingsProvider>(
        context,
        icon: Icons.dashboard_outlined,
        title: tr('showDashboardSearch'),
        subtitle: tr('showDashboardSearchDescription'),
        value: (s) => s.plusShowDashboardSearch,
        onChanged: (s, v) => onSetState(() => s.plusShowDashboardSearch = v),
        visible: (s) => _matches(tr('showDashboardSearch')),
      ),
      _buildFeatureToggle<SettingsProvider>(
        context,
        icon: Icons.ads_click_rounded,
        title: tr('showFloatingSearch'),
        subtitle: tr('showFloatingSearchDescription'),
        value: (s) => s.plusShowFloatingSearch,
        onChanged: (s, v) => onSetState(() => s.plusShowFloatingSearch = v),
        visible: (s) => _matches(tr('showFloatingSearch')),
      ),
    ];

    return Column(
      children: [
        if (categoryWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('categorySettings'),
            children: categoryWidgets,
          ),
        if (iconWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('categoryIconPreview'),
            children: iconWidgets,
          ),
        if (searchWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('searchSettings'),
            children: searchWidgets,
          ),
        if (viewWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('viewOptions'),
            children: viewWidgets,
          ),
        if (displayWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('appTileDisplay'),
            children: displayWidgets,
          ),
        if (headerWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('appListHeader'),
            children: headerWidgets,
          ),
      ],
    );
  }

  Widget _buildGridSettings(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.globalViewMode != ViewMode.grid) return const SizedBox.shrink();

        bool showDisplay = _matches(tr('gridCategoryDisplay'));
        bool showCols = _matches(tr('gridColumns'));

        return Column(
          children: [
            if (showDisplay)
              ListTile(
                leading: const Icon(Icons.grid_view_outlined),
                title: Text(tr('gridCategoryDisplay'), style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(tr('gridCategoryDisplayDescription')),
                trailing: DropdownButton<GridCategoryMode>(
                  underline: const SizedBox(),
                  value: settings.gridCategoryMode,
                  items: [
                    DropdownMenuItem(value: GridCategoryMode.sections, child: Text(tr('categorySections'))),
                    DropdownMenuItem(value: GridCategoryMode.disabled, child: Text(tr('flatGridOnly'))),
                  ],
                  onChanged: (value) {
                    if (value != null) onSetState(() => settings.gridCategoryMode = value);
                  },
                ),
              ),
            if (showCols) ...[
              ListTile(
                leading: const Icon(Icons.view_column_outlined),
                title: Text(tr('gridColumns'), style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text("${tr('gridColumnsDescription')} (${settings.gridColumnCount == 0 ? tr('auto') : settings.gridColumnCount.toString()})"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Slider(
                  value: settings.gridColumnCount.toDouble(),
                  min: 0,
                  max: 6,
                  divisions: 6,
                  onChanged: (value) => onSetState(() => settings.gridColumnCount = value.toInt()),
                ),
              ),
            ]
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
          title: Text(tr('iconPosition'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('iconPositionDescription')),
          trailing: DropdownButton<CategoryIconPosition>(
            underline: const SizedBox(),
            value: settings.categoryIconPosition,
            items: [
              DropdownMenuItem(value: CategoryIconPosition.disabled, child: Text(tr('disabled'))),
              DropdownMenuItem(value: CategoryIconPosition.leading, child: Text(tr('leading'))),
              DropdownMenuItem(value: CategoryIconPosition.trailing, child: Text(tr('trailing'))),
              DropdownMenuItem(value: CategoryIconPosition.below, child: Text(tr('belowName'))),
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
              title: Text(tr('iconCount'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text("${tr('iconCountDescription')} (${settings.categoryIconCount})"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Slider(
                value: settings.categoryIconCount.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                onChanged: settings.categoryIconPosition == CategoryIconPosition.disabled
                    ? null
                    : (value) => onSetState(() => settings.categoryIconCount = value.toInt()),
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
        return ListTile(
          leading: const Icon(Icons.view_quilt_outlined),
          title: Text(tr('defaultViewMode'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('viewModeDescription')),
          trailing: DropdownButton<ViewMode>(
            underline: const SizedBox(),
            value: settings.globalViewMode,
            items: [
              DropdownMenuItem(value: ViewMode.list, child: Text(tr('listView'))),
              DropdownMenuItem(value: ViewMode.grid, child: Text(tr('gridView'))),
            ],
            onChanged: (value) {
              if (value != null) {
                onSetState(() => settings.globalViewMode = value);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildAppBarStyleDropdown(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    return ListTile(
      leading: const Icon(Icons.vertical_align_top_rounded),
      title: Text(tr('appBarStyle'), style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(tr('appBarStyleDescription')),
      trailing: DropdownButton<AppBarStyle>(
        underline: const SizedBox(),
        value: settingsProvider.getAppBarStyleForPage('apps'),
        items: AppBarStyle.values.map((e) => DropdownMenuItem(
          value: e, 
          child: Text(e.name.substring(0, 1).toUpperCase() + e.name.substring(1))
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            onSetState(() {
              settingsProvider.prefs?.setInt('appBarStyle_apps', value.index);
              settingsProvider.notifyListeners();
            });
          }
        },
      ),
    );
  }

  Widget _buildDensityDropdown(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.globalViewMode != ViewMode.list) return const SizedBox.shrink();
        return ListTile(
          leading: const Icon(Icons.density_medium_outlined),
          title: Text(tr('listDensity'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('listDensityDescription')),
          trailing: DropdownButton<AppListDensity>(
            underline: const SizedBox(),
            value: settings.appListDensity,
            items: AppListDensity.values.map((e) => DropdownMenuItem(value: e, child: Text(tr('density_${e.name}')))).toList(),
            onChanged: (value) {
              if (value != null) {
                onSetState(() => settings.appListDensity = value);
              }
            },
          ),
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
  }) {
    return Consumer<T>(
      builder: (context, settings, child) {
        if (!visible(settings)) return const SizedBox.shrink();
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
