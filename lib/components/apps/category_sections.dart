import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/category_icon_stack.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/pages/app.dart';

class CategorySections extends StatelessWidget {
  final List<AppInMemory> listedApps;
  final List<String?> listedCategories;
  final Set<String> selectedAppIds;
  final String? activeAppId;
  final Function(App) toggleAppSelected;
  final Function(App) onAppTap;
  final Function(BuildContext, App) getChangeLogFn;
  final Color Function(int) getCachedCategoryColor;

  const CategorySections({
    super.key,
    required this.listedApps,
    required this.listedCategories,
    required this.selectedAppIds,
    this.activeAppId,
    required this.toggleAppSelected,
    required this.onAppTap,
    required this.getChangeLogFn,
    required this.getCachedCategoryColor,
  });

  int _calculateAdaptiveColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    if (width >= 400) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final viewSettings = context.watch<ViewSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isGridView = viewSettings.globalViewMode == ViewMode.grid;

    if (isGridView) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return _buildCategoryGridSection(context, index, viewSettings);
        }, childCount: listedCategories.length),
      );
    } else if (plusSettings.plusEnableCategoryReorder) {
      // Enable drag-to-reorder when Plus Feature is enabled
      return SliverReorderableList(
        itemBuilder: (BuildContext context, int index) {
          return _buildCategoryCollapsibleTile(
            context,
            index,
            viewSettings,
            enableReorder: true,
          );
        },
        itemCount: listedCategories.length,
        onReorder: (int oldIndex, int newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = listedCategories.removeAt(oldIndex);
          listedCategories.insert(newIndex, item);
          viewSettings.categoryOrder = listedCategories
              .where((c) => c != null)
              .map((c) => c!)
              .toList();
        },
      );
    } else {
      // Simple list when reorder is disabled
      return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return _buildCategoryCollapsibleTile(
            context,
            index,
            viewSettings,
            enableReorder: false,
          );
        }, childCount: listedCategories.length),
      );
    }
  }

  Widget _buildCategoryGridSection(
    BuildContext context,
    int index,
    ViewSettingsProvider settingsProvider,
  ) {
    final String? categoryName = listedCategories[index];
    final int? categoryColorInt = categoryName != null
        ? settingsProvider.categories[categoryName]
        : null;
    final Color? categoryColor = categoryColorInt != null
        ? getCachedCategoryColor(categoryColorInt)
        : null;

    final appsInCategory = listedApps
        .where(
          (e) =>
              e.app.categories.contains(categoryName) ||
              (e.app.categories.isEmpty && categoryName == null),
        )
        .toList();

    final columnCount = settingsProvider.gridColumnCount == 0
        ? _calculateAdaptiveColumns(context)
        : settingsProvider.gridColumnCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, 0),
              end: const Alignment(-0.97, 0),
              colors: [
                categoryColor ?? Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.0),
              ],
              stops: const [0.99, 1],
            ),
          ),
          child: Row(
            children: [
              Text(
                (categoryName ?? tr('noCategory')).toUpperCase(), // Simplified
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(appsInCategory.length.toString()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            addRepaintBoundaries: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: appsInCategory.length,
            itemBuilder: (context, appIndex) {
              final app = appsInCategory[appIndex];
              return AppGridTile(
                appInMemory: app,
                isSelected:
                    selectedAppIds.contains(app.app.id) ||
                    activeAppId == app.app.id,
                hasUpdate: app.app.installedVersion != app.app.latestVersion,
                onTap: () {
                  if (selectedAppIds.isNotEmpty) {
                    toggleAppSelected(app.app);
                  } else {
                    onAppTap(app.app);
                  }
                },
                onLongPress: () => toggleAppSelected(app.app),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryCollapsibleTile(
    BuildContext context,
    int index,
    ViewSettingsProvider settingsProvider, {
    bool enableReorder = true,
  }) {
    final String? categoryName = listedCategories[index];
    final categoryColorInt = categoryName != null
        ? settingsProvider.categories[categoryName]
        : null;
    final categoryColor = categoryColorInt != null
        ? getCachedCategoryColor(categoryColorInt)
        : null;
    final transparent = Theme.of(
      context,
    ).colorScheme.surface.withOpacity(0.0).value;

    final appsInCategory = listedApps
        .where(
          (e) =>
              e.app.categories.contains(categoryName) ||
              (e.app.categories.isEmpty && categoryName == null),
        )
        .toList();

    List<Uint8List?> categoryIcons = [];
    if (settingsProvider.categoryIconPosition !=
            CategoryIconPosition.disabled &&
        settingsProvider.categoryIconCount > 0) {
      categoryIcons = settingsProvider.categoryIconCount >= 20
          ? appsInCategory.map((e) => e.icon).toList()
          : appsInCategory
                .take(settingsProvider.categoryIconCount)
                .map((e) => e.icon)
                .toList();
    }

    Widget categoryTitle = Row(
      children: [
        if (settingsProvider.categoryIconPosition ==
                CategoryIconPosition.leading &&
            categoryIcons.isNotEmpty) ...[
          CategoryIconStack(
            icons: categoryIcons,
            maxIcons: settingsProvider.categoryIconCount,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName ?? tr('noCategory'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (settingsProvider.categoryIconPosition ==
                      CategoryIconPosition.below &&
                  categoryIcons.isNotEmpty) ...[
                const SizedBox(height: 8),
                CategoryIconStack(
                  icons: categoryIcons,
                  maxIcons: settingsProvider.categoryIconCount,
                ),
              ],
            ],
          ),
        ),
        if (settingsProvider.categoryIconPosition ==
                CategoryIconPosition.trailing &&
            categoryIcons.isNotEmpty) ...[
          const SizedBox(width: 12),
          CategoryIconStack(
            icons: categoryIcons,
            maxIcons: settingsProvider.categoryIconCount,
          ),
        ],
      ],
    );

    return Container(
      key: ValueKey(categoryName ?? 'null_category'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-1, 0),
          end: const Alignment(-0.97, 0),
          colors: [categoryColor ?? Color(transparent), Color(transparent)],
          stops: const [0.99, 1],
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: !settingsProvider.categoriesCollapsedByDefault,
        title: categoryTitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(appsInCategory.length.toString()),
            if (enableReorder) ...[
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ],
        ),
        children: appsInCategory
            .map(
              (app) => AppListTile(
                appInMemory: app,
                hasUpdate: app.app.installedVersion != app.app.latestVersion,
                onTap: () {
                  if (selectedAppIds.isNotEmpty) {
                    toggleAppSelected(app.app);
                  } else {
                    onAppTap(app.app);
                  }
                },
                onLongPress: () => toggleAppSelected(app.app),
                onShowChanges: getChangeLogFn(context, app.app),
              ),
            )
            .toList(),
      ),
    );
  }
}
