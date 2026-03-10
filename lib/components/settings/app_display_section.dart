import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// App list display and layout settings
class AppDisplaySection extends StatelessWidget {
  final String? searchQuery;

  const AppDisplaySection({
    super.key,
    this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    List<Widget> children = [
      // View Mode
      if (_matches(tr('viewMode')))
        Consumer<ViewSettingsProvider>(
          builder: (context, settings, child) {
            return ListTile(
              leading: const Icon(Icons.view_kanban_outlined),
              title: Text(tr('viewMode'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(tr('viewModeDescription')),
              trailing: DropdownButton<ViewMode>(
                value: settings.globalViewMode,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: ViewMode.list, child: Text(tr('list'))),
                  DropdownMenuItem(value: ViewMode.grid, child: Text(tr('grid'))),
                ],
                onChanged: (value) {
                  if (value != null) settings.globalViewMode = value;
                },
              ),
            );
          },
        ),
      
      // Grid Column Count
      if (_matches(tr('gridColumns')))
        Consumer<ViewSettingsProvider>(
          builder: (context, settings, child) {
            return ListTile(
              leading: const Icon(Icons.grid_view_outlined),
              title: Text(tr('gridColumns'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(settings.gridColumnCount == 0 ? tr('auto') : '${settings.gridColumnCount}'),
              trailing: DropdownButton<int>(
                value: settings.gridColumnCount == 0 ? null : settings.gridColumnCount,
                hint: Text(tr('auto')),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: null, child: Text(tr('auto'))),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                ],
                onChanged: (value) {
                  settings.gridColumnCount = value ?? 0;
                },
              ),
            );
          },
        ),
      
      // App List Density
      if (_matches(tr('listDensity')))
        Consumer<ViewSettingsProvider>(
          builder: (context, settings, child) {
            return ListTile(
              leading: const Icon(Icons.view_list_outlined),
              title: Text(tr('listDensity'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(tr('listDensityDescription')),
              trailing: DropdownButton<AppListDensity>(
                value: settings.appListDensity,
                underline: const SizedBox(),
                items: AppListDensity.values.map((e) => DropdownMenuItem(value: e, child: Text(tr('density_${e.name}')))).toList(),
                onChanged: (value) {
                  if (value != null) settings.appListDensity = value;
                },
              ),
            );
          },
        ),
      
      // Show Author
      _buildDisplayToggle(
        context,
        key: 'displayShowAuthor',
        icon: Icons.person_outline,
        title: tr('showAuthor'),
        subtitle: tr('showAuthorDescription'),
      ),
      
      // Show Version
      _buildDisplayToggle(
        context,
        key: 'displayShowVersion',
        icon: Icons.tag_outlined,
        title: tr('showVersion'),
        subtitle: tr('showVersionDescription'),
      ),
      
      // Show Date
      _buildDisplayToggle(
        context,
        key: 'displayShowDate',
        icon: Icons.calendar_today_outlined,
        title: tr('showDate'),
        subtitle: tr('showDateDescription'),
      ),
      
      // Show Filter Chips
      _buildDisplayToggle(
        context,
        key: 'displayShowFilterChips',
        icon: Icons.filter_list_outlined,
        title: tr('showFilterChips'),
        subtitle: tr('showFilterChipsDescription'),
      ),
      
      // Show App Count
      _buildDisplayToggle(
        context,
        key: 'displayShowAppCount',
        icon: Icons.format_list_numbered_outlined,
        title: tr('showAppCount'),
        subtitle: tr('showAppCountDescription'),
      ),
      
      // Group by Category
      _buildDisplayToggle<ViewSettingsProvider>(
        context,
        key: 'displayGroupByCategory',
        icon: Icons.folder_outlined,
        title: tr('groupByCategory'),
        subtitle: tr('groupByCategoryDescription'),
        value: (s) => s.groupByCategory,
        onChanged: (s, v) => s.groupByCategory = v,
        visible: (s) => _matches(tr('groupByCategory')),
      ),

      // Collapse Categories by Default
      _buildDisplayToggle<ViewSettingsProvider>(
        context,
        key: 'displayCollapseCategoriesByDefault',
        icon: Icons.unfold_less_outlined,
        title: tr('collapseCategoriesByDefault'),
        subtitle: tr('collapseCategoriesByDefaultDescription'),
        value: (s) => s.categoriesCollapsedByDefault,
        onChanged: (s, v) => s.categoriesCollapsedByDefault = v,
        visible: (s) => _matches(tr('collapseCategoriesByDefault')),
      ),
    ];

    return SettingsGroup(
      title: isSearching ? null : tr('appDisplay'),
      children: children,
    );
  }

  Widget _buildDisplayToggle<T>(
    BuildContext context, {
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    bool Function(T)? value,
    void Function(T, bool)? onChanged,
    bool Function(T)? visible,
  }) {
    if (value != null && onChanged != null && visible != null) {
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
    
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        if (!_matches(title)) return const SizedBox.shrink();
        bool currentValue;
        switch (key) {
          case 'displayShowAuthor':
            currentValue = settings.displayShowAuthor;
            break;
          case 'displayShowVersion':
            currentValue = settings.displayShowVersion;
            break;
          case 'displayShowDate':
            currentValue = settings.displayShowDate;
            break;
          case 'displayShowFilterChips':
            currentValue = settings.displayShowFilterChips;
            break;
          case 'displayShowAppCount':
            currentValue = settings.displayShowAppCount;
            break;
          default:
            return const SizedBox.shrink();
        }
        return SwitchListTile.adaptive(
          secondary: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(subtitle),
          value: currentValue,
          onChanged: (v) {
            switch (key) {
              case 'displayShowAuthor':
                settings.displayShowAuthor = v;
                break;
              case 'displayShowVersion':
                settings.displayShowVersion = v;
                break;
              case 'displayShowDate':
                settings.displayShowDate = v;
                break;
              case 'displayShowFilterChips':
                settings.displayShowFilterChips = v;
                break;
              case 'displayShowAppCount':
                settings.displayShowAppCount = v;
                break;
            }
          },
        );
      },
    );
  }
}
