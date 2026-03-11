import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/apps/app_shortcuts_menu.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:provider/provider.dart';

class AppGridView extends StatelessWidget {
  final List<AppInMemory> apps;
  final Set<String> selectedAppIds;
  final String? activeAppId;
  final Function(App) toggleAppSelected;
  final Function(App) onAppTap;

  const AppGridView({
    super.key,
    required this.apps,
    required this.selectedAppIds,
    this.activeAppId,
    required this.toggleAppSelected,
    required this.onAppTap,
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
    final columnCount = viewSettings.gridColumnCount == 0
        ? _calculateAdaptiveColumns(context)
        : viewSettings.gridColumnCount;

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

            void showAppShortcuts() => showAppShortcutsMenu(
                  context,
                  appId: app.app.id,
                  appUrl: app.app.url,
                  onToggleSelected: () => toggleAppSelected(app.app),
                );

            return RepaintBoundary(
              child: AppGridTile(
                appInMemory: app,
                isSelected: selectedAppIds.contains(app.app.id) || activeAppId == app.app.id,
                hasUpdate: hasUpdate,
                onTap: () {
                  if (selectedAppIds.isNotEmpty) {
                    toggleAppSelected(app.app);
                  } else {
                    onAppTap(app.app);
                  }
                },
                onLongPress: () {
                  if (selectedAppIds.isEmpty) {
                    showAppShortcuts();
                  } else {
                    toggleAppSelected(app.app);
                  }
                },
              ),
            );
          },
          childCount: apps.length,
        ),
      ),
    );
  }
}
