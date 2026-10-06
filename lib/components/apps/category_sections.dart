import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/components/category_icon_stack.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/services/app_update_service.dart';

class CategorySections extends StatelessWidget {
  final List<AppInMemory> listedApps;
  final List<String?> listedCategories;
  final Set<String> selectedAppIds;
  final Set<String> pendingUpdates;
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
    required this.pendingUpdates,
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

    // Single-pass O(N) grouping by category to eliminate redundant multi-pass scans
    final appsByCategory = <String?, List<AppInMemory>>{
      for (final cat in listedCategories) cat: <AppInMemory>[],
    };
    for (final app in listedApps) {
      if (app.app.categories.isEmpty) {
        appsByCategory[null]?.add(app);
      } else {
        for (final cat in app.app.categories) {
          appsByCategory[cat]?.add(app);
        }
      }
    }

    // Pre-compute pending-update counts per category in O(N)
    final categoryUpdateCounts = <String?, int>{};
    appsByCategory.forEach((cat, apps) {
      categoryUpdateCounts[cat] =
          apps.where((a) => pendingUpdates.contains(a.app.id)).length;
    });

    if (isGridView) {
      return SliverMainAxisGroup(
        slivers: [
          for (int i = 0; i < listedCategories.length; i++)
            ..._buildCategoryGridSectionSlivers(
              context,
              i,
              viewSettings,
              plusSettings,
              appsByCategory[listedCategories[i]] ?? const [],
              categoryUpdateCounts[listedCategories[i]] ?? 0,
              pendingUpdates,
            ),
        ],
      );
    } else if (plusSettings.plusEnableCategoryReorder) {
      // Enable drag-to-reorder when Plus Feature is enabled
      return SliverReorderableList(
        itemBuilder: (BuildContext context, int index) {
          final catName = listedCategories[index];
          return _buildCategoryCollapsibleTile(
            context,
            index,
            viewSettings,
            appsByCategory[catName] ?? const [],
            categoryUpdateCounts[catName] ?? 0,
            pendingUpdates,
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
          final catName = listedCategories[index];
          return _buildCategoryCollapsibleTile(
            context,
            index,
            viewSettings,
            appsByCategory[catName] ?? const [],
            categoryUpdateCounts[catName] ?? 0,
            pendingUpdates,
            enableReorder: false,
          );
        }, childCount: listedCategories.length),
      );
    }
  }

  /// Returns a list of slivers [header, grid, spacer] for one category in grid mode.
  /// Using SliverGrid instead of GridView(shrinkWrap: true) allows lazy layout —
  /// only visible tiles are measured, eliminating the "layout all children to
  /// determine height" cost of shrinkWrap.
  List<Widget> _buildCategoryGridSectionSlivers(
    BuildContext context,
    int index,
    ViewSettingsProvider settingsProvider,
    PlusSettingsProvider plusSettings,
    List<AppInMemory> appsInCategory,
    int updateCount,
    Set<String> pendingUpdates,
  ) {
    final String? categoryName = listedCategories[index];
    final int? categoryColorInt = categoryName != null
        ? settingsProvider.categories[categoryName]
        : null;
    final Color? categoryColor = categoryColorInt != null
        ? getCachedCategoryColor(categoryColorInt)
        : null;

    final columnCount = settingsProvider.gridColumnCount == 0
        ? _calculateAdaptiveColumns(context)
        : settingsProvider.gridColumnCount;

    final bool showDetails = settingsProvider.displayShowVersion ||
        settingsProvider.displayShowAuthor ||
        plusSettings.plusShowTagsInList;
    final double aspectRatio = GridMetrics.childAspectRatio(
      columnCount: columnCount,
      hasExtraDetails: showDetails,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return [
      SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, 0),
              end: const Alignment(-0.97, 0),
              colors: [
                categoryColor ?? colorScheme.surface,
                colorScheme.surface.withValues(alpha: 0.0),
              ],
              stops: const [0.99, 1],
            ),
          ),
          child: Row(
            children: [
              Text(
                (categoryName ?? tr('noCategory')).toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildCategoryStats(context, appsInCategory.length, updateCount),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, appIndex) {
              final app = appsInCategory[appIndex];
              return AppGridTile(
                appInMemory: app,
                isSelected:
                    selectedAppIds.contains(app.app.id) ||
                    activeAppId == app.app.id,
                hasUpdate: pendingUpdates.contains(app.app.id),
                isAmbiguous:
                    app.app.additionalSettings['isAmbiguousUpdate'] == true,
                categoryColor: categoryColor,
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
            childCount: appsInCategory.length,
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  Widget _buildCategoryStats(
    BuildContext context,
    int totalCount,
    int updateCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (updateCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 12.5,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 3.5),
                Text(
                  '$updateCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: Text(
            '$totalCount',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCollapsibleTile(
    BuildContext context,
    int index,
    ViewSettingsProvider settingsProvider,
    List<AppInMemory> appsInCategory,
    int updateCount,
    Set<String> pendingUpdates, {
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
    ).colorScheme.surface.withValues(alpha: 0.0).value;

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
        key: PageStorageKey<String>('category_tile:${categoryName ?? '__uncategorized__'}'),
        initiallyExpanded: !settingsProvider.categoriesCollapsedByDefault,
        title: categoryTitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryStats(context, appsInCategory.length, updateCount),
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
                hasUpdate: app.app.installedVersion == null
                    ? app.app.additionalSettings['trackOnly'] != true
                    : pendingUpdates.contains(app.app.id),
                selected: selectedAppIds.contains(app.app.id),
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
