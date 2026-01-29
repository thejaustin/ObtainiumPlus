import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

class AppListView extends StatelessWidget {
  final List<AppInMemory> apps;
  final Set<String> selectedAppIds;
  final Function(App) toggleAppSelected;
  final Function(BuildContext, App) getChangeLogFn;

  const AppListView({
    super.key,
    required this.apps,
    required this.selectedAppIds,
    required this.toggleAppSelected,
    required this.getChangeLogFn,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final appsProvider = context.read<AppsProvider>();
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 800 ? (width - 800) / 2 : 0.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
          final app = apps[index];
          final hasUpdate = app.app.installedVersion != null &&
              app.app.installedVersion != app.app.latestVersion;

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

          // Check if swipe actions are enabled via Plus Features
          final swipeEnabled = settings.plusEnableSwipeActions &&
              !(settings.swipeRightAction == AppSwipeAction.none && settings.swipeLeftAction == AppSwipeAction.none);

          return Dismissible(
            key: Key('dismiss_${app.app.id}'),
            direction: !swipeEnabled
                ? DismissDirection.none
                : (settings.swipeRightAction == AppSwipeAction.none ? DismissDirection.endToStart : (settings.swipeLeftAction == AppSwipeAction.none ? DismissDirection.startToEnd : DismissDirection.horizontal)),
            background: Container(
              color: getActionColor(settings.swipeRightAction),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20.0),
              child: getActionIcon(settings.swipeRightAction),
            ),
            secondaryBackground: Container(
              color: getActionColor(settings.swipeLeftAction),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: getActionIcon(settings.swipeLeftAction),
            ),
            confirmDismiss: (direction) {
              if (direction == DismissDirection.startToEnd) {
                return handleSwipe(settings.swipeRightAction);
              } else {
                return handleSwipe(settings.swipeLeftAction);
              }
            },
            child: RepaintBoundary(
              child: settings.plusEnableEnhancedAnimations
                  ? OpenContainer(
                      tappable: false,
                      transitionType: ContainerTransitionType.fadeThrough,
                      openBuilder: (BuildContext context, VoidCallback _) {
                        return AppPage(appId: app.app.id);
                      },
                      closedElevation: 0,
                      closedColor: Colors.transparent,
                      closedBuilder: (BuildContext context, VoidCallback openContainer) {
                        return AppListTile(
                          appInMemory: app,
                          isSelected: selectedAppIds.contains(app.app.id),
                          hasUpdate: hasUpdate,
                          onTap: () {
                            if (selectedAppIds.isNotEmpty) {
                              toggleAppSelected(app.app);
                            } else {
                              openContainer();
                            }
                          },
                          onLongPress: () {
                            toggleAppSelected(app.app);
                          },
                          onShowChanges: getChangeLogFn(context, app.app),
                        );
                      },
                    )
                  : AppListTile(
                      appInMemory: app,
                      isSelected: selectedAppIds.contains(app.app.id),
                      hasUpdate: hasUpdate,
                      onTap: () {
                        if (selectedAppIds.isNotEmpty) {
                          toggleAppSelected(app.app);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AppPage(appId: app.app.id)),
                          );
                        }
                      },
                      onLongPress: () {
                        toggleAppSelected(app.app);
                      },
                      onShowChanges: getChangeLogFn(context, app.app),
                    ),
            ),
          );
        },
        childCount: apps.length,
      ),
    ),
  );
  }
}