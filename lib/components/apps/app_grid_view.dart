import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/pages/app.dart';
import 'package:share_plus/share_plus.dart';

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

            void showAppShortcuts() {
              HapticFeedback.heavyImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: Text(tr('editAppSettings')),
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (context) => AppPage(
                              appId: app.app.id,
                              isModal: true,
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.refresh_outlined),
                        title: Text(tr('forceUpdate')),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<AppsProvider>().downloadAndInstallLatestApps([app.app.id], context, useExisting: false);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.share_outlined),
                        title: Text(tr('share')),
                        onTap: () {
                          Navigator.pop(context);
                          Share.share(app.app.url);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.select_all_outlined),
                        title: Text(tr('select')),
                        onTap: () {
                          Navigator.pop(context);
                          toggleAppSelected(app.app);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return RepaintBoundary(
              child: AppGridTile(
                appInMemory: app,
                isSelected: selectedAppIds.contains(app.app.id),
                hasUpdate: hasUpdate,
                onTap: () {
                  if (selectedAppIds.isNotEmpty) {
                    toggleAppSelected(app.app);
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => AppPage(
                        appId: app.app.id,
                        isModal: true,
                      ),
                    );
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
