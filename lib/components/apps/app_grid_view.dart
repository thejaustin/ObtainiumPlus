import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/apps/app_actions_context_menu.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// The Material 3 Expressive apps grid: responsive adaptive columns,
/// separate pinned and main sections, and smooth drag-and-drop reordering.
class AppGridView extends StatefulWidget {
  final List<AppInMemory> apps;
  final Function(App) onAppTap;
  final Set<String> selectedAppIds;
  final void Function(App) onToggleSelected;
  final Set<String> updateAppIds;
  final double endInset;

  const AppGridView({
    super.key,
    required this.apps,
    required this.onAppTap,
    required this.selectedAppIds,
    required this.onToggleSelected,
    required this.updateAppIds,
    this.endInset = 0.0,
  });

  @override
  State<AppGridView> createState() => _AppGridViewState();
}

class _AppGridViewState extends State<AppGridView> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final viewSettings = context.watch<ViewSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardBorderRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardBorderRadius);

    final columnCount = GridMetrics.adaptiveColumns(
      context,
      preferred: viewSettings.gridColumnCount,
    );
    final bool showDetails =
        viewSettings.displayShowVersion ||
        viewSettings.displayShowAuthor ||
        viewSettings.displayShowDate ||
        plusSettings.plusShowTagsInList;
    final double aspectRatio = GridMetrics.childAspectRatio(
      columnCount: columnCount,
      hasExtraDetails: showDetails,
      squareTiles: plusSettings.plusGridSquareTiles,
    );

    // Separate pinned and unpinned apps
    final pinnedApps = <AppInMemory>[];
    final unpinnedApps = <AppInMemory>[];
    for (final a in widget.apps) {
      if (a.app.pinned) {
        pinnedApps.add(a);
      } else {
        unpinnedApps.add(a);
      }
    }

    // Preserve custom pinned order
    final pinnedOrder = plusSettings.plusPinnedAppsOrder;
    if (pinnedOrder.isNotEmpty) {
      final position = {for (final (i, a) in pinnedApps.indexed) a.app.id: i};
      int rank(AppInMemory a) {
        final i = pinnedOrder.indexOf(a.app.id);
        return i < 0 ? pinnedOrder.length : i;
      }

      pinnedApps.sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0
            ? byRank
            : position[a.app.id]!.compareTo(position[b.app.id]!);
      });
    }

    Widget buildSectionHeader({
      required IconData icon,
      required String title,
      required int count,
      Widget? trailingAction,
      IconData? trailingHintIcon,
      String? tooltip,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: ShapeDecoration(
                color: colorScheme.primary.withValues(alpha: 0.14),
                shape: CardMetrics.shape(innerRadius * 0.75, expressive: isM3E),
              ),
              child: Icon(icon, size: 14, color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.65,
                ),
                borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(),
            if (trailingAction != null)
              trailingAction
            else if (trailingHintIcon != null)
              Tooltip(
                message: tooltip ?? tr('pin'),
                child: Icon(
                  trailingHintIcon,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
              ),
          ],
        ),
      );
    }

    Widget buildGridTile(AppInMemory app, int index, {bool isPinned = false}) {
      final categoryColor =
          app.app.categories.isNotEmpty &&
              viewSettings.categories[app.app.categories.first] != null
          ? Color(viewSettings.categories[app.app.categories.first]!)
          : null;

      final tile = AppGridTile(
        appInMemory: app,
        isSelected: widget.selectedAppIds.contains(app.app.id),
        hasUpdate: widget.updateAppIds.contains(app.app.id),
        isAmbiguous:
            widget.updateAppIds.contains(app.app.id) &&
            app.app.additionalSettings['isAmbiguousUpdate'] == true,
        categoryColor: categoryColor,
        entranceDelay: plusSettings.plusEnableEnhancedAnimations
            ? Duration(milliseconds: index < 10 ? index * 30 : 0)
            : Duration.zero,
        onTap: () {
          if (widget.selectedAppIds.isNotEmpty) {
            widget.onToggleSelected(app.app);
          } else {
            widget.onAppTap(app.app);
          }
        },
        onLongPress: () {
          if (widget.selectedAppIds.isNotEmpty) {
            AppHaptics.selectionClick();
            widget.onToggleSelected(app.app);
          } else {
            AppHaptics.heavyImpact();
            AppActionsContextMenu.show(
              context,
              app,
              onEnterMultiSelect: () => widget.onToggleSelected(app.app),
            );
          }
        },
      );

      // In multi-selection mode or when not in reorder mode, disable dragging so selection taps and context menu long presses are instant
      if (widget.selectedAppIds.isNotEmpty || !isPinned || !_isReordering) {
        return RepaintBoundary(key: ValueKey(app.app.id), child: tile);
      }

      // Drag and drop reordering for pinned grid tiles
      return RepaintBoundary(
        key: ValueKey('draggable_${app.app.id}'),
        child: DragTarget<AppInMemory>(
          onWillAcceptWithDetails: (details) =>
              details.data.app.id != app.app.id,
          onAcceptWithDetails: (details) {
            final dragged = details.data;
            if (dragged.app.id == app.app.id) return;

            final oldIdx = pinnedApps.indexWhere(
              (a) => a.app.id == dragged.app.id,
            );
            final newIdx = pinnedApps.indexWhere((a) => a.app.id == app.app.id);

            if (oldIdx != -1 && newIdx != -1) {
              AppHaptics.selectionClick();
              setState(() {
                final moved = pinnedApps.removeAt(oldIdx);
                pinnedApps.insert(newIdx, moved);
                plusSettings.plusPinnedAppsOrder = pinnedApps
                    .map((a) => a.app.id)
                    .toList();
              });
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isTarget = candidateData.isNotEmpty;

            final tileContainer = AnimatedScale(
              scale: isTarget ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardBorderRadius),
                  border: Border.all(
                    color: isTarget
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.45),
                    width: isTarget ? 2.5 : 1.2,
                  ),
                ),
                child: Stack(
                  children: [
                    tile,
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 13,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            return LongPressDraggable<AppInMemory>(
              data: app,
              delay: const Duration(milliseconds: 80),
              onDragStarted: () {
                AppHaptics.mediumImpact();
              },
              feedback: Material(
                elevation: 12,
                color: Colors.transparent,
                shadowColor: colorScheme.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(cardBorderRadius),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = MediaQuery.sizeOf(context).width;
                    final availableWidth =
                        width - 24 - widget.endInset - (columnCount - 1) * 12;
                    final tileWidth = availableWidth / columnCount;
                    final tileHeight = tileWidth / aspectRatio;
                    return SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: Transform.scale(scale: 1.05, child: tile),
                    );
                  },
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.25, child: tileContainer),
              child: tileContainer,
            );
          },
        ),
      );
    }

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columnCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: aspectRatio,
    );

    // If no pinned apps exist, render standard clean grid
    if (pinnedApps.isEmpty) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(12, 6, 12 + widget.endInset, 6),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (ctx, index) => buildGridTile(unpinnedApps[index], index),
            childCount: unpinnedApps.length,
            addRepaintBoundaries: false,
            addAutomaticKeepAlives: false,
          ),
          gridDelegate: gridDelegate,
        ),
      );
    }

    // Sectioned grid with pinned apps at top and drag-and-drop organizing
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(12, 6, 12 + widget.endInset, 6),
      sliver: SliverMainAxisGroup(
        slivers: [
          // Pinned Apps Header
          SliverToBoxAdapter(
            child: buildSectionHeader(
              icon: Icons.star_rounded,
              title: tr('pin'),
              count: pinnedApps.length,
              trailingAction: pinnedApps.length > 1
                  ? ScaleTouchWrapper(
                      scaleDownFactor: 0.94,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          AppHaptics.selectionClick();
                          setState(() => _isReordering = !_isReordering);
                        },
                        icon: Icon(
                          _isReordering
                              ? Icons.check_circle_rounded
                              : Icons.drag_indicator_rounded,
                          size: 15,
                        ),
                        label: Text(
                          _isReordering ? tr('done') : tr('reorder'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 0,
                          ),
                          backgroundColor: _isReordering
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.65,
                                ),
                          foregroundColor: _isReordering
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          // Pinned Apps Grid (Draggable)
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, index) =>
                  buildGridTile(pinnedApps[index], index, isPinned: true),
              childCount: pinnedApps.length,
              addRepaintBoundaries: false,
              addAutomaticKeepAlives: false,
            ),
            gridDelegate: gridDelegate,
          ),
          // Unpinned Apps Section
          if (unpinnedApps.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: buildSectionHeader(
                  icon: Icons.apps_rounded,
                  title: tr('appsString'),
                  count: unpinnedApps.length,
                ),
              ),
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) => buildGridTile(
                  unpinnedApps[index],
                  index + pinnedApps.length,
                ),
                childCount: unpinnedApps.length,
                addRepaintBoundaries: false,
                addAutomaticKeepAlives: false,
              ),
              gridDelegate: gridDelegate,
            ),
          ],
        ],
      ),
    );
  }
}
