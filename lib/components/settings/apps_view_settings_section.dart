import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/settings_provider.dart';
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
      if (_matches(tr('groupByCategory'))) _buildGroupByCategoryToggle(context),
      if (_matches(tr('collapseCategoriesByDefault'))) _buildCollapseCategoriesToggle(context),
    ];

    List<Widget> iconWidgets = [
      if (_matches(tr('iconPosition'))) _buildCategoryIconPositionDropdown(context),
      if (_matches(tr('iconCount'))) _buildCategoryIconCountSlider(context),
    ];

    List<Widget> viewWidgets = [
      if (_matches(tr('defaultViewMode'))) _buildViewModeDropdown(context),
      if (_matches(tr('listDensity'))) _buildDensityDropdown(context),
      _buildGridSettings(context),
    ];

    List<Widget> displayWidgets = [
      if (_matches(tr('showAuthor'))) _buildShowAuthorToggle(context),
      if (_matches(tr('showVersion'))) _buildShowVersionToggle(context),
      if (_matches(tr('showDate'))) _buildShowDateToggle(context),
    ];

    List<Widget> headerWidgets = [
      if (_matches(tr('showFilterChips'))) _buildShowFilterChipsToggle(context),
      if (_matches(tr('showAppCount'))) _buildShowAppCountToggle(context),
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

  Widget _buildShowAuthorToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.person_outline),
          title: Text(tr('showAuthor'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.displayShowAuthor,
          onChanged: (value) => settings.displayShowAuthor = value,
        );
      },
    );
  }

  Widget _buildShowVersionToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.code),
          title: Text(tr('showVersion'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.displayShowVersion,
          onChanged: (value) => settings.displayShowVersion = value,
        );
      },
    );
  }

  Widget _buildShowDateToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.calendar_today_outlined),
          title: Text(tr('showDate'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.displayShowDate,
          onChanged: (value) => settings.displayShowDate = value,
        );
      },
    );
  }

  Widget _buildShowFilterChipsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.filter_list_outlined),
          title: Text(tr('showFilterChips'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.displayShowFilterChips,
          onChanged: (value) => settings.displayShowFilterChips = value,
        );
      },
    );
  }

  Widget _buildShowAppCountToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.summarize_outlined),
          title: Text(tr('showAppCount'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.displayShowAppCount,
          onChanged: (value) => settings.displayShowAppCount = value,
        );
      },
    );
  }

  Widget _buildGroupByCategoryToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.category_outlined),
          title: Text(tr('groupByCategory'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.groupByCategory,
          onChanged: (value) => settings.groupByCategory = value,
        );
      },
    );
  }

  Widget _buildCollapseCategoriesToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.unfold_less_outlined),
          title: Text(tr('collapseCategoriesByDefault'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.categoriesCollapsedByDefault,
          onChanged: (value) => settings.categoriesCollapsedByDefault = value,
        );
      },
    );
  }

  Widget _buildCategoryIconPositionDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.branding_watermark_outlined),
          title: Text(tr('iconPosition'), style: Theme.of(context).textTheme.bodyLarge),
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.numbers_outlined),
              title: Text(tr('iconCount'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(settings.categoryIconCount.toString()),
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.view_quilt_outlined),
          title: Text(tr('defaultViewMode'), style: Theme.of(context).textTheme.bodyLarge),
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

  Widget _buildDensityDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.globalViewMode != ViewMode.list) return const SizedBox.shrink();
        return ListTile(
          leading: const Icon(Icons.density_medium_outlined),
          title: Text(tr('listDensity'), style: Theme.of(context).textTheme.bodyLarge),
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

  Widget _buildGridSettings(BuildContext context) {
    return Consumer<SettingsProvider>(
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
                subtitle: Text(settings.gridColumnCount == 0 ? tr('auto') : settings.gridColumnCount.toString()),
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
}
