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
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
      categoryUpdateCounts[cat] = apps
          .where((a) => pendingUpdates.contains(a.app.id))
          .length;
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
            plusSettings,
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
            plusSettings,
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

    final columnCount = GridMetrics.adaptiveColumns(
      context,
      preferred: settingsProvider.gridColumnCount,
    );

    final bool showDetails =
        settingsProvider.displayShowVersion ||
        settingsProvider.displayShowAuthor ||
        settingsProvider.displayShowDate ||
        plusSettings.plusShowTagsInList;
    final double aspectRatio = GridMetrics.childAspectRatio(
      columnCount: columnCount,
      hasExtraDetails: showDetails,
      squareTiles: plusSettings.plusGridSquareTiles,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = categoryColor ?? colorScheme.primary;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;

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

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: ShapeDecoration(
              color: colorScheme.surfaceContainerLow.withValues(
                alpha: plusSettings.plusEnableGlassmorphism ? 0.55 : 0.85,
              ),
              shape: CardMetrics.shape(
                CardMetrics.inner(radius),
                expressive: plusSettings.plusEnableMaterialExpressive,
                side: BorderSide(
                  color: accentColor.withValues(alpha: 0.22),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                if (settingsProvider.categoryIconPosition ==
                        CategoryIconPosition.leading &&
                    categoryIcons.isNotEmpty) ...[
                  CategoryIconStack(
                    icons: categoryIcons,
                    maxIcons: settingsProvider.categoryIconCount,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    categoryName ?? tr('noCategory'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (settingsProvider.categoryIconPosition ==
                        CategoryIconPosition.trailing &&
                    categoryIcons.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  CategoryIconStack(
                    icons: categoryIcons,
                    maxIcons: settingsProvider.categoryIconCount,
                  ),
                ],
                const SizedBox(width: 8),
                _buildCategoryStats(
                  context,
                  appsInCategory.length,
                  updateCount,
                ),
              ],
            ),
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
              return RepaintBoundary(
                key: ValueKey(app.app.id),
                child: AppGridTile(
                  appInMemory: app,
                  isSelected:
                      selectedAppIds.contains(app.app.id) ||
                      activeAppId == app.app.id,
                  hasUpdate: pendingUpdates.contains(app.app.id),
                  isAmbiguous:
                      app.app.additionalSettings['isAmbiguousUpdate'] == true,
                  categoryColor: categoryColor,
                  entranceDelay: plusSettings.plusEnableEnhancedAnimations
                      ? Duration(
                          milliseconds: appIndex < 10 ? appIndex * 35 : 0,
                        )
                      : Duration.zero,
                  onTap: () {
                    if (selectedAppIds.isNotEmpty) {
                      toggleAppSelected(app.app);
                    } else {
                      onAppTap(app.app);
                    }
                  },
                  onLongPress: () => toggleAppSelected(app.app),
                ),
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
        if (context.watch<ViewSettingsProvider>().displayShowAppCount)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.65,
              ),
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
    PlusSettingsProvider plusSettings,
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
    final accentColor = categoryColor ?? Theme.of(context).colorScheme.primary;

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
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
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

    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final appsProvider = context.read<AppsProvider>();
    final plusEnableSwipeActions = plusSettings.plusEnableSwipeActions;
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = settingsProvider.appListDensity == AppListDensity.compact;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;

    Widget getActionIcon(AppSwipeAction action, AppInMemory app) {
      switch (action) {
        case AppSwipeAction.update:
          return Icon(Icons.download, color: colorScheme.onPrimary);
        case AppSwipeAction.togglePin:
          return Icon(
            app.app.pinned ? Icons.push_pin_outlined : Icons.push_pin,
            color: colorScheme.onTertiary,
          );
        case AppSwipeAction.share:
          return Icon(Icons.share, color: colorScheme.onSecondary);
        case AppSwipeAction.launch:
          return Icon(Icons.launch, color: colorScheme.onPrimaryContainer);
        case AppSwipeAction.delete:
          return Icon(Icons.delete, color: colorScheme.onError);
        default:
          return const SizedBox.shrink();
      }
    }

    Color getActionColor(AppSwipeAction action) {
      switch (action) {
        case AppSwipeAction.update:
          return colorScheme.primary;
        case AppSwipeAction.togglePin:
          return colorScheme.tertiary;
        case AppSwipeAction.share:
          return colorScheme.secondary;
        case AppSwipeAction.launch:
          return colorScheme.primaryContainer;
        case AppSwipeAction.delete:
          return colorScheme.error;
        default:
          return colorScheme.surfaceContainerHighest;
      }
    }

    Future<bool> handleSwipe(
      AppInMemory app,
      AppSwipeAction action,
      bool hasUpdate,
    ) async {
      AppHaptics.mediumImpact();
      switch (action) {
        case AppSwipeAction.update:
          if (hasUpdate) {
            appsProvider.downloadAndInstallLatestApps([app.app.id], context);
          }
          break;
        case AppSwipeAction.togglePin:
          app.app.pinned = !app.app.pinned;
          appsProvider.saveApps([app.app]);
          break;
        case AppSwipeAction.share:
          Share.share(app.app.url);
          break;
        case AppSwipeAction.launch:
          AppInstallService.openApp(app.app.id);
          break;
        case AppSwipeAction.delete:
          appsProvider.removeAppsWithModal(context, [app.app]);
          break;
        case AppSwipeAction.none:
          break;
      }
      return false;
    }

    final swipeEnabled =
        plusEnableSwipeActions &&
        behaviorSettings.enableSwipeGestures &&
        !(behaviorSettings.swipeRightAction == AppSwipeAction.none &&
            behaviorSettings.swipeLeftAction == AppSwipeAction.none);

    return Container(
      key: ValueKey(categoryName ?? 'null_category'),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        key: PageStorageKey<String>(
          'category_tile:${categoryName ?? '__uncategorized__'}',
        ),
        onExpansionChanged: (_) => AppHaptics.selectionClick(),
        expansionAnimationStyle: AnimationStyle(
          curve: Easing.emphasizedDecelerate,
          reverseCurve: Easing.emphasizedAccelerate,
          duration: const Duration(milliseconds: 260),
        ),
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
        children: appsInCategory.asMap().entries.map((entry) {
          final app = entry.value;
          final hasUpdate = app.app.installedVersion == null
              ? app.app.additionalSettings['trackOnly'] != true
              : pendingUpdates.contains(app.app.id);

          final tile = AppListTile(
            appInMemory: app,
            hasUpdate: hasUpdate,
            selected: selectedAppIds.contains(app.app.id),
            entranceDelay: plusSettings.plusEnableEnhancedAnimations
                ? Duration(milliseconds: entry.key < 8 ? entry.key * 25 : 0)
                : Duration.zero,
            onTap: () {
              if (selectedAppIds.isNotEmpty) {
                toggleAppSelected(app.app);
              } else {
                onAppTap(app.app);
              }
            },
            onLongPress: () => toggleAppSelected(app.app),
            onShowChanges: getChangeLogFn(context, app.app),
          );

          if (!swipeEnabled) {
            return RepaintBoundary(key: ValueKey(app.app.id), child: tile);
          }

          return Dismissible(
            key: Key('cat_dismiss_${app.app.id}'),
            direction: behaviorSettings.swipeRightAction == AppSwipeAction.none
                ? DismissDirection.endToStart
                : (behaviorSettings.swipeLeftAction == AppSwipeAction.none
                      ? DismissDirection.startToEnd
                      : DismissDirection.horizontal),
            background: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 8,
                vertical: isCompact ? 2 : 6,
              ),
              child: Container(
                decoration: ShapeDecoration(
                  color: getActionColor(behaviorSettings.swipeRightAction),
                  shape: CardMetrics.shape(
                    radius,
                    expressive: plusSettings.plusEnableMaterialExpressive,
                  ),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20.0),
                child: getActionIcon(behaviorSettings.swipeRightAction, app),
              ),
            ),
            secondaryBackground: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 8,
                vertical: isCompact ? 2 : 6,
              ),
              child: Container(
                decoration: ShapeDecoration(
                  color: getActionColor(behaviorSettings.swipeLeftAction),
                  shape: CardMetrics.shape(
                    radius,
                    expressive: plusSettings.plusEnableMaterialExpressive,
                  ),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: getActionIcon(behaviorSettings.swipeLeftAction, app),
              ),
            ),
            confirmDismiss: (direction) {
              if (direction == DismissDirection.startToEnd) {
                return handleSwipe(
                  app,
                  behaviorSettings.swipeRightAction,
                  hasUpdate,
                );
              } else {
                return handleSwipe(
                  app,
                  behaviorSettings.swipeLeftAction,
                  hasUpdate,
                );
              }
            },
            child: RepaintBoundary(key: ValueKey(app.app.id), child: tile),
          );
        }).toList(),
      ),
    );
  }
}
