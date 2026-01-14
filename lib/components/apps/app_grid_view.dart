import 'package:flutter/material.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/pages/app.dart';

class AppGridView extends StatelessWidget {
  final List<AppInMemory> apps;
  final Set<String> selectedAppIds;
  final Function(App) toggleAppSelected;

  const AppGridView({
    super.key,
    required this.apps,
    required this.selectedAppIds,
    required this.toggleAppSelected,
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
    final settingsProvider = context.watch<SettingsProvider>();
    final columnCount = settingsProvider.gridColumnCount == 0
        ? _calculateAdaptiveColumns(context)
        : settingsProvider.gridColumnCount;

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            var app = apps[index];
            var hasUpdate = app.app.installedVersion != null &&
                app.app.installedVersion != app.app.latestVersion;

            return AppGridTile(
              appInMemory: app,
              isSelected: selectedAppIds.contains(app.app.id),
              hasUpdate: hasUpdate,
              onTap: () {
                if (selectedAppIds.isNotEmpty) {
                  toggleAppSelected(app.app);
                } else {
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
            );
          },
          childCount: apps.length,
        ),
      ),
    );
  }
}
