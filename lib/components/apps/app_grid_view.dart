import 'package:flutter/material.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/components/apps/app_shortcuts_menu.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:provider/provider.dart';

class AppGridView extends StatelessWidget {
  final List<AppInMemory> apps;
  final String? activeAppId;
  final Function(App) onAppTap;

  const AppGridView({
    super.key,
    required this.apps,
    this.activeAppId,
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
    final plusSettings = context.watch<PlusSettingsProvider>();
    final appsProvider = context.watch<AppsProvider>();
    final isSelectionMode = appsProvider.isSelectionMode;

    // Adaptive column count and M3E aspect ratio
    int columnCount = GridMetrics.adaptiveColumns(
      context,
      preferred: viewSettings.gridColumnCount,
    );

    final bool showDetails = viewSettings.displayShowVersion ||
        viewSettings.displayShowAuthor ||
        plusSettings.plusShowTagsInList;

    double childAspectRatio = GridMetrics.childAspectRatio(
      columnCount: columnCount,
      hasExtraDetails: showDetails,
    );

    if (apps.length <= 2 && viewSettings.gridColumnCount == 0) {
      columnCount = apps.length == 1 ? 1 : 2;
      childAspectRatio = apps.length == 1 ? 2.5 : 1.0;
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            var app = apps[index];
            final inst = app.app.installedVersion;
            final latest = app.app.latestVersion;
            final hasUpdate = AppUpdateService.areVersionsDifferent(
              app.app,
              inst,
              latest,
            );

            void showAppShortcuts() => showAppShortcutsMenu(
              context,
              appId: app.app.id,
              appUrl: app.app.url,
              onToggleSelected: () =>
                  appsProvider.toggleAppSelection(app.app.id),
            );

            final categoryColor = app.app.categories.isNotEmpty &&
                    viewSettings.categories[app.app.categories.first] != null
                ? Color(viewSettings.categories[app.app.categories.first]!)
                : null;

            return RepaintBoundary(
              child: AppGridTile(
                appInMemory: app,
                isSelected:
                    appsProvider.selectedApps.contains(app.app.id) ||
                    activeAppId == app.app.id,
                hasUpdate: hasUpdate,
                categoryColor: categoryColor,
                onTap: () {
                  if (isSelectionMode) {
                    appsProvider.toggleAppSelection(app.app.id);
                  } else {
                    onAppTap(app.app);
                  }
                },
                onLongPress: () {
                  if (!isSelectionMode) {
                    showAppShortcuts();
                  } else {
                    appsProvider.toggleAppSelection(app.app.id);
                  }
                },
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
