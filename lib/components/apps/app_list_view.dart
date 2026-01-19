import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/pages/app.dart';

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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final app = apps[index];
          final hasUpdate = app.app.installedVersion != null &&
              app.app.installedVersion != app.app.latestVersion;
          
          return RepaintBoundary(
            child: OpenContainer(
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
            ),
          );
        },
        childCount: apps.length,
      ),
    );
  }
}
