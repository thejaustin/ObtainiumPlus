import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/components/apps/app_actions_context_menu.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// The expressive apps list: AppListTile rows, configurable swipe actions
/// and drag-to-reorder pinned apps. Selection state is owned by AppsPage.
class AppListView extends StatelessWidget {
  final List<AppInMemory> apps;
  final String? activeAppId;
  final Function(App) onAppTap;
  final Function(BuildContext, App) getChangeLogFn;
  final Set<String> selectedAppIds;
  final void Function(App) onToggleSelected;
  final Set<String> updateAppIds;

  const AppListView({
    super.key,
    required this.apps,
    this.activeAppId,
    required this.onAppTap,
    required this.getChangeLogFn,
    required this.selectedAppIds,
    required this.onToggleSelected,
    required this.updateAppIds,
  });

  @override
  Widget build(BuildContext context) {
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final viewSettings = context.watch<ViewSettingsProvider>();
    final plusEnableSwipeActions = plusSettings.plusEnableSwipeActions;
    final appsProvider = context.read<AppsProvider>();
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 800 ? (width - 800) / 2 : 0.0;
    const verticalPadding = 8.0;
    final pinnedApps = <AppInMemory>[];
    final unpinnedApps = <AppInMemory>[];
    for (final a in apps) {
      if (a.app.pinned) {
        pinnedApps.add(a);
      } else {
        unpinnedApps.add(a);
      }
    }
    // Honour the user's drag order for pinned apps; unknown ones keep their
    // sorted position after the ordered ones.
    final pinnedOrder = plusSettings.plusPinnedAppsOrder;
    if (pinnedOrder.isNotEmpty) {
      final position = {for (final (i, a) in pinnedApps.indexed) a.app.id: i};
      int rank(AppInMemory a) {
        final i = pinnedOrder.indexOf(a.app.id);
        return i < 0 ? pinnedOrder.length : i;
      }

      // List.sort is not stable: tie-break on the incoming (sorted) position.
      pinnedApps.sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0
            ? byRank
            : position[a.app.id]!.compareTo(position[b.app.id]!);
      });
    }

    Widget _buildAppItem(AppInMemory app, bool isPinned, int index) {
      final hasUpdate = updateAppIds.contains(app.app.id);
      // Swipe surfaces use scheme roles instead of raw palette colors so
      // they harmonize with Material You dynamic color in both brightnesses
      final colorScheme = Theme.of(context).colorScheme;
      final isCompact = viewSettings.appListDensity == AppListDensity.compact;
      final radius = plusSettings.plusOverrideIndividualCornerRadius
          ? plusSettings.plusHomeCornerRadius
          : plusSettings.plusGlobalCornerRadius;

      Widget getActionIcon(AppSwipeAction action) {
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

      Future<bool> handleSwipe(AppSwipeAction action) async {
        AppHaptics.mediumImpact();
        switch (action) {
          case AppSwipeAction.update:
            appsProvider.downloadAndInstallLatestApps([app.app.id], context);
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
        return false; // Don't dismiss the row
      }

      String getActionLabel(AppSwipeAction action) {
        switch (action) {
          case AppSwipeAction.update:
            return tr('update');
          case AppSwipeAction.togglePin:
            return app.app.pinned ? tr('unpin') : tr('pin');
          case AppSwipeAction.share:
            return tr('share');
          case AppSwipeAction.launch:
            return tr('open');
          case AppSwipeAction.delete:
            return tr('remove');
          default:
            return '';
        }
      }

      Color getActionForegroundColor(AppSwipeAction action) {
        switch (action) {
          case AppSwipeAction.update:
            return colorScheme.onPrimary;
          case AppSwipeAction.togglePin:
            return colorScheme.onTertiary;
          case AppSwipeAction.share:
            return colorScheme.onSecondary;
          case AppSwipeAction.launch:
            return colorScheme.onPrimaryContainer;
          case AppSwipeAction.delete:
            return colorScheme.onError;
          default:
            return colorScheme.onSurface;
        }
      }

      Widget buildSwipePill(AppSwipeAction action, {required bool alignRight}) {
        final fg = getActionForegroundColor(action);
        final label = getActionLabel(action);
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 8,
            vertical: isCompact ? 2 : 6,
          ),
          child: Container(
            decoration: ShapeDecoration(
              color: getActionColor(action),
              shape: CardMetrics.shape(
                radius,
                expressive: plusSettings.plusEnableMaterialExpressive,
              ),
            ),
            alignment: alignRight
                ? Alignment.centerRight
                : Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alignRight && label.isNotEmpty) ...[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                getActionIcon(action),
                if (!alignRight && label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      final swipeEnabled =
          plusEnableSwipeActions &&
          behaviorSettings.enableSwipeGestures &&
          !(behaviorSettings.swipeRightAction == AppSwipeAction.none &&
              behaviorSettings.swipeLeftAction == AppSwipeAction.none);

      Widget child = Dismissible(
        key: Key('dismiss_${app.app.id}'),
        direction: !swipeEnabled
            ? DismissDirection.none
            : (behaviorSettings.swipeRightAction == AppSwipeAction.none
                  ? DismissDirection.endToStart
                  : (behaviorSettings.swipeLeftAction == AppSwipeAction.none
                        ? DismissDirection.startToEnd
                        : DismissDirection.horizontal)),
        background: buildSwipePill(
          behaviorSettings.swipeRightAction,
          alignRight: false,
        ),
        secondaryBackground: buildSwipePill(
          behaviorSettings.swipeLeftAction,
          alignRight: true,
        ),
        confirmDismiss: (direction) {
          if (direction == DismissDirection.startToEnd) {
            return handleSwipe(behaviorSettings.swipeRightAction);
          } else {
            return handleSwipe(behaviorSettings.swipeLeftAction);
          }
        },
        child: RepaintBoundary(
          child: Transform.scale(
            scale: apps.length <= 2 ? 1.02 : 1.0,
            child: AppListTile(
              appInMemory: app,
              hasUpdate: hasUpdate,
              selected: selectedAppIds.contains(app.app.id),
              entranceDelay: plusSettings.plusEnableEnhancedAnimations
                  ? Duration(milliseconds: index < 12 ? index * 30 : 0)
                  : Duration.zero,
              onTap: () {
                AppHaptics.selectionClick();
                if (selectedAppIds.isNotEmpty) {
                  onToggleSelected(app.app);
                } else {
                  onAppTap(app.app);
                }
              },
              onLongPress: () {
                if (selectedAppIds.isNotEmpty) {
                  AppHaptics.selectionClick();
                  onToggleSelected(app.app);
                } else {
                  AppHaptics.heavyImpact();
                  AppActionsContextMenu.show(
                    context,
                    app,
                    onEnterMultiSelect: () => onToggleSelected(app.app),
                  );
                }
              },
              onShowChanges: getChangeLogFn(context, app.app),
            ),
          ),
        ),
      );

      if (isPinned) {
        return ReorderableDelayedDragStartListener(
          key: Key('reorder_${app.app.id}'),
          index: index,
          child: child,
        );
      }
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final innerRadius = CardMetrics.inner(CardMetrics.card(baseRadius));

    Widget buildSectionHeader({
      required IconData icon,
      required String title,
      required int count,
      IconData? trailingHintIcon,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
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
            if (trailingHintIcon != null)
              Icon(
                trailingHintIcon,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
          ],
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (pinnedApps.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: buildSectionHeader(
                icon: Icons.star_rounded,
                title: tr('pin'),
                count: pinnedApps.length,
                trailingHintIcon: pinnedApps.length > 1
                    ? Icons.drag_indicator_rounded
                    : null,
              ),
            ),
            SliverReorderableList(
              itemCount: pinnedApps.length,
              itemBuilder: (context, index) =>
                  _buildAppItem(pinnedApps[index], true, index),
              onReorder: (oldIndex, newIndex) {
                AppHaptics.selectionClick();
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final app = pinnedApps.removeAt(oldIndex);
                pinnedApps.insert(newIndex, app);

                plusSettings.plusPinnedAppsOrder = pinnedApps
                    .map((a) => a.app.id)
                    .toList();
              },
            ),
          ],
          if (pinnedApps.isNotEmpty && unpinnedApps.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: buildSectionHeader(
                  icon: Icons.apps_rounded,
                  title: tr('appsString'),
                  count: unpinnedApps.length,
                ),
              ),
            ),
          if (unpinnedApps.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return _buildAppItem(unpinnedApps[index], false, index);
                },
                childCount: unpinnedApps.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
              ),
            ),
        ],
      ),
    );
  }
}
