import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/components/apps/app_shortcuts_menu.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final plusEnableSwipeActions = context.select<SettingsProvider, bool>(
      (sp) => sp.plusEnableSwipeActions,
    );
    final appsProvider = context.read<AppsProvider>();
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 800 ? (width - 800) / 2 : 0.0;
    final double verticalPadding = apps.length <= 3 ? 24.0 : 8.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
          final app = apps[index];
          final inst = app.app.installedVersion;
          final latest = app.app.latestVersion;
          final hasUpdate = inst != null &&
              inst != latest &&
              (reconcileVersionDifferences(inst, latest)?.key != true);

          Widget getActionIcon(AppSwipeAction action) {
            switch (action) {
              case AppSwipeAction.update: return const Icon(Icons.download, color: Colors.white);
              case AppSwipeAction.togglePin: return Icon(app.app.pinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.white);
              case AppSwipeAction.share: return const Icon(Icons.share, color: Colors.white);
              case AppSwipeAction.launch: return const Icon(Icons.launch, color: Colors.white);
              case AppSwipeAction.delete: return const Icon(Icons.delete, color: Colors.white);
              default: return const SizedBox.shrink();
            }
          }

          Color getActionColor(AppSwipeAction action) {
            switch (action) {
              case AppSwipeAction.update: return Colors.green;
              case AppSwipeAction.togglePin: return Colors.orange;
              case AppSwipeAction.share: return Colors.blue;
              case AppSwipeAction.launch: return Colors.purple;
              case AppSwipeAction.delete: return Colors.red;
              default: return Colors.grey;
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

          // Check if swipe actions are enabled via Plus Features AND user preference
          final swipeEnabled = plusEnableSwipeActions &&
              behaviorSettings.enableSwipeGestures &&
              !(behaviorSettings.swipeRightAction == AppSwipeAction.none && behaviorSettings.swipeLeftAction == AppSwipeAction.none);

          void _showAppShortcuts() => showAppShortcutsMenu(
                context,
                appId: app.app.id,
                appUrl: app.app.url,
                onToggleSelected: () => appsProvider.toggleAppSelection(app.app.id),
              );

          return Dismissible(
            key: Key('dismiss_${app.app.id}'),
            direction: !swipeEnabled
                ? DismissDirection.none
                : (behaviorSettings.swipeRightAction == AppSwipeAction.none ? DismissDirection.endToStart : (behaviorSettings.swipeLeftAction == AppSwipeAction.none ? DismissDirection.startToEnd : DismissDirection.horizontal)),
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
        },
        childCount: apps.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
      ),
    ),
  );
  }
}