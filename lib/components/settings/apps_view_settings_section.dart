import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Apps, Categories, and View settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class AppsViewSettingsSection extends StatelessWidget {
  final Function(void Function()) onSetState;

  const AppsViewSettingsSection({
    super.key,
    required this.onSetState,
  });

  @override
  Widget build(BuildContext context) {
    const height8 = SizedBox(height: 8);
    const height16 = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories section
        height16,
        CategoryEditorSelector(showLabelWhenNotEmpty: false),
        height16,
        _buildGroupByCategoryToggle(context),
        height16,
        _buildCollapseCategoriesToggle(context),
        height16,
        const Divider(),
        height16,
        Text(
          tr('categoryIconPreview'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        height8,
        _buildCategoryIconPositionDropdown(context),
        height16,
        _buildCategoryIconCountSlider(context),

        // View Options section
        const SizedBox(height: 32),
        Text(
          tr('viewOptions'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        height8,
        _buildViewModeDropdown(context),
        _buildGridSettings(context),
      ],
    );
  }

  Widget _buildGroupByCategoryToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('groupByCategory'))),
            Switch(
              value: settings.groupByCategory,
              onChanged: (value) {
                settings.groupByCategory = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollapseCategoriesToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('collapseCategoriesByDefault'))),
            Switch(
              value: settings.categoriesCollapsedByDefault,
              onChanged: (value) {
                settings.categoriesCollapsedByDefault = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryIconPositionDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return DropdownButtonFormField<CategoryIconPosition>(
          decoration: InputDecoration(labelText: tr('iconPosition')),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
              onSetState(() {
                settings.categoryIconPosition = value;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildCategoryIconCountSlider(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          children: [
            Expanded(
              child: Text(
                '${tr('iconCount')}: ${settings.categoryIconCount}',
              ),
            ),
            Expanded(
              flex: 2,
              child: Slider(
                value: settings.categoryIconCount.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                label: settings.categoryIconCount == 0
                    ? tr('disabled')
                    : settings.categoryIconCount == 20
                        ? 'All'
                        : settings.categoryIconCount.toString(),
                onChanged: settings.categoryIconPosition == CategoryIconPosition.disabled
                    ? null
                    : (value) {
                        onSetState(() {
                          settings.categoryIconCount = value.toInt();
                        });
                      },
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
        return DropdownButtonFormField<ViewMode>(
          decoration: InputDecoration(labelText: tr('defaultViewMode')),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
          value: settings.globalViewMode,
          items: [
            DropdownMenuItem(
              value: ViewMode.list,
              child: Row(
                children: [
                  const Icon(Icons.view_list),
                  const SizedBox(width: 8),
                  Text(tr('listView')),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ViewMode.grid,
              child: Row(
                children: [
                  const Icon(Icons.grid_view),
                  const SizedBox(width: 8),
                  Text(tr('gridView')),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onSetState(() {
                settings.globalViewMode = value;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildGridSettings(BuildContext context) {
    const height16 = SizedBox(height: 16);

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.globalViewMode != ViewMode.grid) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            height16,
            DropdownButtonFormField<GridCategoryMode>(
              decoration: InputDecoration(labelText: tr('gridCategoryDisplay')),
              dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                DropdownMenuItem(
                  value: GridCategoryMode.folders,
                  child: Row(
                    children: [
                      Text(tr('categoryFolders')),
                      const SizedBox(width: 8),
                      Text(
                        '(${tr('comingSoon')})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null && value != GridCategoryMode.folders) {
                  onSetState(() {
                    settings.gridCategoryMode = value;
                  });
                }
              },
            ),
            height16,
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${tr('gridColumns')}: ${settings.gridColumnCount == 0 ? tr('auto') : settings.gridColumnCount}',
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: settings.gridColumnCount.toDouble(),
                    min: 0,
                    max: 6,
                    divisions: 6,
                    label: settings.gridColumnCount == 0
                        ? tr('auto')
                        : settings.gridColumnCount.toString(),
                    onChanged: (value) {
                      onSetState(() {
                        settings.gridColumnCount = value.toInt();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
