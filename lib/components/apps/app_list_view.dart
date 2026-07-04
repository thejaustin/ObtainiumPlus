import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/components/apps/app_shortcuts_menu.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class AppListView extends StatelessWidget {
  final List<AppInMemory> apps;
  final String? activeAppId;
  final Function(App) onAppTap;
  final Function(BuildContext, App) getChangeLogFn;

  const AppListView({
    super.key,
    required this.apps,
    this.activeAppId,
    required this.onAppTap,
    required this.getChangeLogFn,
  });

  @override
  Widget build(BuildContext context) {
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final plusEnableSwipeActions = plusSettings.plusEnableSwipeActions;
    final appsProvider = context.watch<AppsProvider>();
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 800 ? (width - 800) / 2 : 0.0;
    final double verticalPadding = apps.length <= 3 ? 24.0 : 8.0;

    final pinnedApps = apps.where((a) => a.app.pinned).toList();
    final unpinnedApps = apps.where((a) => !a.app.pinned).toList();

    Widget _buildAppItem(AppInMemory app, bool isPinned, int index) {
      final inst = app.app.installedVersion;
      final latest = app.app.latestVersion;
      final hasUpdate = AppUpdateService.areVersionsDifferent(
        app.app,
        inst,
        latest,
      );
      Widget getActionIcon(AppSwipeAction action) {
        switch (action) {
          case AppSwipeAction.update:
            return const Icon(Icons.download, color: Colors.white);
          case AppSwipeAction.togglePin:
            return Icon(
              app.app.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              color: Colors.white,
            );
          case AppSwipeAction.share:
            return const Icon(Icons.share, color: Colors.white);
          case AppSwipeAction.launch:
            return const Icon(Icons.launch, color: Colors.white);
          case AppSwipeAction.delete:
            return const Icon(Icons.delete, color: Colors.white);
          default:
            return const SizedBox.shrink();
        }
      }

      Color getActionColor(AppSwipeAction action) {
        switch (action) {
          case AppSwipeAction.update:
            return Colors.green;
          case AppSwipeAction.togglePin:
            return Colors.orange;
          case AppSwipeAction.share:
            return Colors.blue;
          case AppSwipeAction.launch:
            return Colors.purple;
          case AppSwipeAction.delete:
            return Colors.red;
          default:
            return Colors.grey;
        }
      }

      Future<bool> handleSwipe(AppSwipeAction action) async {
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

      final swipeEnabled =
          plusEnableSwipeActions &&
          behaviorSettings.enableSwipeGestures &&
          !(behaviorSettings.swipeRightAction == AppSwipeAction.none &&
              behaviorSettings.swipeLeftAction == AppSwipeAction.none);

      void _showAppShortcuts() => showAppShortcutsMenu(
        context,
        appId: app.app.id,
        appUrl: app.app.url,
        onToggleSelected: () => appsProvider.toggleAppSelection(app.app.id),
      );

      Widget child = Dismissible(
        key: Key('dismiss_${app.app.id}'),
        direction: !swipeEnabled
            ? DismissDirection.none
            : (behaviorSettings.swipeRightAction == AppSwipeAction.none
                  ? DismissDirection.endToStart
                  : (behaviorSettings.swipeLeftAction == AppSwipeAction.none
                        ? DismissDirection.startToEnd
                        : DismissDirection.horizontal)),
        background: Container(
          color: getActionColor(behaviorSettings.swipeRightAction),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20.0),
          child: getActionIcon(behaviorSettings.swipeRightAction),
        ),
        secondaryBackground: Container(
          color: getActionColor(behaviorSettings.swipeLeftAction),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          child: getActionIcon(behaviorSettings.swipeLeftAction),
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
              onTap: () {
                if (appsProvider.isSelectionMode) {
                  appsProvider.toggleAppSelection(app.app.id);
                } else {
                  onAppTap(app.app);
                }
              },
              onLongPress: () {
                if (!appsProvider.isSelectionMode) {
                  _showAppShortcuts();
                } else {
                  appsProvider.toggleAppSelection(app.app.id);
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

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (pinnedApps.isNotEmpty)
            SliverReorderableList(
              itemCount: pinnedApps.length,
              itemBuilder: (context, index) =>
                  _buildAppItem(pinnedApps[index], true, index),
              onReorder: (oldIndex, newIndex) {
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
          if (pinnedApps.isNotEmpty && unpinnedApps.isNotEmpty)
            const SliverToBoxAdapter(
              child: Divider(height: 32, indent: 16, endIndent: 16),
            ),
          if (unpinnedApps.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return _buildAppItem(unpinnedApps[index], false, index);
                },
                childCount: unpinnedApps.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
              ),
            ),
        ],
      ),
    );
  }
}
