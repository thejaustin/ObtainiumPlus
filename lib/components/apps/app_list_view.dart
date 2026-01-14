import 'package:flutter/material.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/providers/apps_provider.dart';

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
            child: AppListTile(
              appInMemory: app,
              isSelected: selectedAppIds.contains(app.app.id),
              hasUpdate: hasUpdate,
              onTap: () {
                if (selectedAppIds.isNotEmpty) {
                  toggleAppSelected(app.app);
                } else {
                  // Navigation handled in ListTile usually, 
                  // but we'll follow the pattern from apps.dart
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppPage(appId: app.app.id),
                    ),
                  );
                }
              },
              onLongPress: () {
                toggleAppSelected(app.app);
              },
              onShowChanges: getChangeLogFn(context, app.app),
            ),
          );
        },
        childCount: apps.length,
      ),
    );
  }
}

// Placeholder for AppPage to avoid import error if not available in context
class AppPage extends StatelessWidget {
  final String appId;
  const AppPage({super.key, required this.appId});
  @override
  Widget build(BuildContext context) => Container();
}
