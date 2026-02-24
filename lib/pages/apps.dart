import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/category_icon_stack.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/components/apps/app_grid_view.dart';
import 'package:obtainium/components/apps/app_list_view.dart';
import 'package:obtainium/components/apps/category_sections.dart';
import 'package:obtainium/components/apps/app_changelog.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/components/search/command_center.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/sort_filter_panel.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({super.key, this.initialFilter});

  final AppsFilter? initialFilter;

  @override
  State<AppsPage> createState() => AppsPageState();
}

class AppsPageState extends State<AppsPage> {
  AppsFilter filter = AppsFilter();
  final AppsFilter neutralFilter = AppsFilter();
  Set<String> selectedAppIds = {};
  DateTime? refreshingSince;

  final Map<int, Color> _categoryColorCache = {};

  Color _getCachedCategoryColor(int colorInt) {
    return _categoryColorCache.putIfAbsent(
      colorInt,
      () => Color(colorInt),
    );
  }

  bool clearSelected() {
    if (selectedAppIds.isNotEmpty) {
      setState(() {
        selectedAppIds.clear();
      });
      return true;
    }
    return false;
  }

  void selectThese(List<App> apps) {
    if (selectedAppIds.isEmpty) {
      setState(() {
        for (var a in apps) {
          selectedAppIds.add(a.id);
        }
      });
    }
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  late final ScrollController scrollController = ScrollController();

  var sourceProvider = SourceProvider();

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      filter = widget.initialFilter!;
    }
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final sp = context.read<SettingsProvider>();
    if (!sp.plusEnableIconCaching) return;

    final appsProvider = context.read<AppsProvider>();
    final listedApps = appsProvider.getAppValues().toList();

    if (listedApps.isEmpty) return;

    final scrollOffset = scrollController.offset;
    final viewportHeight = scrollController.position.viewportDimension;
    final itemHeight = 72.0;

    final firstVisibleIndex = (scrollOffset / itemHeight).floor();
    final lastVisibleIndex = ((scrollOffset + viewportHeight) / itemHeight).ceil();

    final startIndex = (firstVisibleIndex - 10).clamp(0, listedApps.length);
    final endIndex = (lastVisibleIndex + 10).clamp(0, listedApps.length);

    final appIdsToCache = listedApps
        .sublist(startIndex, endIndex)
        .map((app) => app.app.id)
        .toList();

    appsProvider.precacheIcons(appIdsToCache);
  }

  @override
  Widget build(BuildContext context) {
    var appsProvider = context.watch<AppsProvider>();
    var viewSettings = context.watch<ViewSettingsProvider>();
    final updateSettings = context.watch<UpdateSettingsProvider>();
    var listedApps = appsProvider.getFilteredSortedApps(
      filter: filter,
      sortMethod: viewSettings.appSortMethod,
      sortColumn: viewSettings.sortColumn,
      sortOrder: viewSettings.sortOrder,
      pinUpdates: viewSettings.pinUpdates,
      groupByCategory: viewSettings.groupByCategory,
      buryNonInstalled: viewSettings.buryNonInstalled,
    );

    refresh() {
      HapticFeedback.lightImpact();
      setState(() {
        refreshingSince = DateTime.now();
      });
      return appsProvider
          .checkUpdates(ignoreCache: true)
          .catchError((e) {
            showError(e is Map ? e['errors'] : e, context);
            return <App>[];
          })
          .whenComplete(() {
            HapticFeedback.lightImpact();
            setState(() {
              refreshingSince = null;
            });
          });
    }

    if (!appsProvider.loadingApps &&
        appsProvider.apps.isNotEmpty &&
        context.read<SettingsProvider>().checkJustStarted() &&
        updateSettings.checkOnStart) {
      _refreshIndicatorKey.currentState?.show();
    }

    selectedAppIds = selectedAppIds
        .where((element) => listedApps.map((e) => e.app.id).contains(element))
        .toSet();

    toggleAppSelected(App app) {
      setState(() {
        if (selectedAppIds.map((e) => e).contains(app.id)) {
          selectedAppIds.removeWhere((a) => a == app.id);
        } else {
          selectedAppIds.add(app.id);
        }
      });
    }

    var existingUpdates = appsProvider.findExistingUpdates(installedOnly: true);
    var existingUpdateIds = existingUpdates.where((id) => selectedAppIds.isEmpty ? true : selectedAppIds.contains(id)).toList();
    var newInstallIds = appsProvider.findExistingUpdates(nonInstalledOnly: true).where((id) => selectedAppIds.isEmpty ? true : selectedAppIds.contains(id)).toList();

    List<String> trackOnlyUpdateIds = [];
    existingUpdateIds = existingUpdateIds.where((id) {
      if (appsProvider.apps[id]!.app.additionalSettings['trackOnly'] == true) {
        trackOnlyUpdateIds.add(id);
        return false;
      }
      return true;
    }).toList();

    List<String?> listedCategories = listedApps.map((e) => e.app.categories.isNotEmpty ? e.app.categories : [null]).expand((e) => e).toSet().toList();
    var customOrder = viewSettings.categoryOrder;
    listedCategories.sort((a, b) {
      var aIndex = a != null ? customOrder.indexOf(a) : -1;
      var bIndex = b != null ? customOrder.indexOf(b) : -1;
      if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;
      return a != null && b != null ? a.toLowerCase().compareTo(b.toLowerCase()) : (a == null ? 1 : -1);
    });

    getLoadingWidgets() {
      return [
        if (listedApps.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: appsProvider.loadingApps
                ? const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading apps',
                      strokeWidth: 3,
                    ),
                  )
                : EmptyStateWidget(
                    title: appsProvider.apps.isEmpty ? tr('noAppsYet') : tr('noMatchingApps'),
                    subtitle: appsProvider.apps.isEmpty
                        ? tr('startByAddingFirstApp')
                        : tr('tryAdjustingFilters'),
                    icon: appsProvider.apps.isEmpty ? Icons.apps_outage_rounded : Icons.search_off_rounded,
                    actionLabel: appsProvider.apps.isEmpty ? tr('addApp') : null,
                    onActionPressed: appsProvider.apps.isEmpty
                        ? () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddAppPage(),
                              ),
                            );
                          }
                        : null,
                    secondaryActionLabel: appsProvider.apps.isEmpty ? tr('discover') : null,
                    onSecondaryActionPressed: appsProvider.apps.isEmpty
                        ? () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddAppPage(initialTab: 1),
                              ),
                            );
                          }
                        : null,
                  ),
          ),
        if (refreshingSince != null || appsProvider.loadingApps)
          SliverToBoxAdapter(
            child: LinearProgressIndicator(
              value: appsProvider.loadingApps ? null : appsProvider.getAppValues().where((e) => !(e.app.lastUpdateCheck?.isBefore(refreshingSince!) ?? true)).length / (appsProvider.apps.isNotEmpty ? appsProvider.apps.length : 1),
              semanticsLabel: appsProvider.loadingApps ? tr('loadingApps') : tr('checkingForUpdates'),
            ),
          ),
      ];
    }

    getMassObtainFunction() {
      if (appsProvider.areDownloadsRunning() || (existingUpdateIds.isEmpty && newInstallIds.isEmpty && trackOnlyUpdateIds.isEmpty)) return null;
      return () {
        HapticFeedback.heavyImpact();
        List<GeneratedFormItem> formItems = [];
        if (existingUpdateIds.isNotEmpty) {
          formItems.add(GeneratedFormSwitch('updates', label: tr('updateX', args: [plural('apps', existingUpdateIds.length).toLowerCase()]), defaultValue: true));
        }
        if (newInstallIds.isNotEmpty) {
          formItems.add(GeneratedFormSwitch('installs', label: tr('installX', args: [plural('apps', newInstallIds.length).toLowerCase()]), defaultValue: existingUpdateIds.isEmpty));
        }
        if (trackOnlyUpdateIds.isNotEmpty) {
          formItems.add(GeneratedFormSwitch('trackonlies', label: tr('markXTrackOnlyAsUpdated', args: [plural('apps', trackOnlyUpdateIds.length)]), defaultValue: existingUpdateIds.isEmpty && newInstallIds.isEmpty));
        }
        showDialog<Map<String, dynamic>?>( 
          context: context,
          builder: (BuildContext ctx) {
            return GeneratedFormModal(
              title: tr('changeX', args: [plural('apps', existingUpdateIds.length + newInstallIds.length + trackOnlyUpdateIds.length).toLowerCase()]),
              items: formItems.map((e) => [e]).toList(),
              initValid: true,
            );
          },
        ).then((values) async {
          if (values != null) {
            if (values.isEmpty) values = getDefaultValuesFromFormItems([formItems]);
            List<String> toInstall = [];
            if (values['updates'] == true) toInstall.addAll(existingUpdateIds);
            if (values['installs'] == true) toInstall.addAll(newInstallIds);
            if (values['trackonlies'] == true) toInstall.addAll(trackOnlyUpdateIds);
            appsProvider.downloadAndInstallLatestApps(toInstall, globalNavigatorKey.currentContext).then((value) {
              if (value.isNotEmpty && values!['updates'] == true) showMessage(tr('appsUpdated'), context);
            });
          }
        });
      };
    }

    markSelectedAppsUpdated() async {
      var selectedApps = listedApps
          .where((e) => selectedAppIds.contains(e.app.id))
          .map((e) => e.app)
          .toList();
      if (selectedApps.isEmpty) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('markSelectedAppsUpdated')),
          content: Text(tr('markXSelectedAppsAsUpdated',
              args: [selectedApps.length.toString()])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('no'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('yes'))),
          ],
        ),
      );

      if (confirm == true) {
        for (var app in selectedApps) {
          app.installedVersion = app.latestVersion;
        }
        await appsProvider.saveApps(selectedApps);
        clearSelected();
        showMessage(tr('appsUpdated'), context);
      }
    }

    var isFilterOff = filter.isIdenticalTo(neutralFilter, context.read<SettingsProvider>());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: settingsProvider.plusShowLegacyUIComparison 
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.small(
                heroTag: 'ui_comparison_toggle',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  settingsProvider.plusEnableModernAppListTile = !settingsProvider.plusEnableModernAppListTile;
                },
                child: Icon(settingsProvider.plusEnableModernAppListTile 
                    ? Icons.visibility_outlined 
                    : Icons.visibility_off_outlined),
              ),
            )
          : null,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: refresh,
        child: Scrollbar(
          controller: scrollController,
          child: Consumer<ViewSettingsProvider>(
            builder: (context, viewSettings, _) {
              return CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  _buildAppBar(context, viewSettings, listedApps, isFilterOff),
                  ..._buildLoadingOverlay(appsProvider),
                  _buildContent(context, viewSettings, listedApps, listedCategories),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context, 
    ViewSettingsProvider viewSettings, 
    List<AppInMemory> listedApps,
    bool isFilterOff,
  ) {
    return SliverAppBar.large(
      pinned: true,
      floating: true,
      snap: false,
      leading: selectedAppIds.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: clearSelected,
              tooltip: tr('clear'),
            )
          : null,
      title: GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsPage(initialTab: 0),
            ),
          );
        },
        child: Text(
          selectedAppIds.isNotEmpty
              ? '${selectedAppIds.length}'
              : tr('appsString'),
        ),
      ),
      actions: [
        if (selectedAppIds.isNotEmpty)
          ..._buildSelectionActions(context, listedApps)
        else
          ..._buildNormalActions(context, viewSettings, isFilterOff),
        
        if (viewSettings.displayShowAppCount && selectedAppIds.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${listedApps.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSelectionActions(BuildContext context, List<AppInMemory> listedApps) {
    final appsProvider = context.read<AppsProvider>();
    return [
      IconButton(
        icon: Icon(
          selectedAppIds.length == listedApps.length
              ? Icons.deselect_outlined
              : Icons.select_all_outlined,
        ),
        onPressed: () {
          if (selectedAppIds.length == listedApps.length) {
            clearSelected();
          } else {
            selectThese(listedApps.map((e) => e.app).toList());
          }
        },
        tooltip: tr('selectAll'),
      ),
      if (_getMassObtainFunction(context) != null)
        IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: _getMassObtainFunction(context),
          tooltip: tr('installUpdateSelectedApps'),
        ),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          var selectedApps = listedApps
              .where((e) => selectedAppIds.contains(e.app.id))
              .map((e) => e.app)
              .toList();
          appsProvider.removeAppsWithModal(context, selectedApps);
        },
        tooltip: tr('remove'),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'markUpdated') {
            _markSelectedAppsUpdated(context, listedApps);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'markUpdated',
            child: ListTile(
              leading: const Icon(Icons.done_all),
              title: Text(tr('markSelectedAppsUpdated')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildNormalActions(
    BuildContext context, 
    ViewSettingsProvider viewSettings,
    bool isFilterOff,
  ) {
    return [
      IconButton(
        icon: Icon(isFilterOff
            ? Icons.search_rounded
            : Icons.search_off_rounded),
        onPressed: () {
          if (isFilterOff) {
            CommandCenter.show(context);
          } else {
            setState(() => filter = AppsFilter());
          }
        },
        tooltip: isFilterOff ? tr('search') : tr('clear'),
      ),
      Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              HapticFeedback.selectionClick();
              SortFilterPanel.show(
                context,
                filter: filter,
                onFilterChanged: () => setState(() {}),
                categories: viewSettings.categories,
              );
            },
            tooltip: tr('sortOptions'),
          ),
          if (!isFilterOff)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _buildLoadingOverlay(AppsProvider appsProvider) {
    return [
      if (refreshingSince != null || appsProvider.loadingApps)
        SliverToBoxAdapter(
          child: LinearProgressIndicator(
            value: appsProvider.loadingApps 
                ? null 
                : appsProvider.getAppValues().where((e) => !(e.app.lastUpdateCheck?.isBefore(refreshingSince!) ?? true)).length / (appsProvider.apps.isNotEmpty ? appsProvider.apps.length : 1),
            semanticsLabel: appsProvider.loadingApps ? tr('loadingApps') : tr('checkingForUpdates'),
          ),
        ),
    ];
  }

  Widget _buildContent(
    BuildContext context, 
    ViewSettingsProvider viewSettings,
    List<AppInMemory> listedApps,
    List<String?> listedCategories,
  ) {
    final appsProvider = context.read<AppsProvider>();
    if (listedApps.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: appsProvider.loadingApps
            ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
            : EmptyStateWidget(
                title: appsProvider.apps.isEmpty ? tr('noAppsYet') : tr('noMatchingApps'),
                subtitle: appsProvider.apps.isEmpty
                    ? tr('startByAddingFirstApp')
                    : tr('tryAdjustingFilters'),
                icon: appsProvider.apps.isEmpty ? Icons.apps_outage_rounded : Icons.search_off_rounded,
                actionLabel: appsProvider.apps.isEmpty ? tr('addApp') : null,
                onActionPressed: appsProvider.apps.isEmpty
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAppPage()));
                      }
                    : null,
                secondaryActionLabel: appsProvider.apps.isEmpty ? tr('discover') : null,
                onSecondaryActionPressed: appsProvider.apps.isEmpty
                    ? () {
                        HapticFeedback.lightImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddAppPage(initialTab: 1)));
                      }
                    : null,
              ),
      );
    }

    if (viewSettings.groupByCategory) {
      return CategorySections(
        listedApps: listedApps,
        listedCategories: listedCategories,
        selectedAppIds: selectedAppIds,
        toggleAppSelected: _toggleAppSelected,
        getChangeLogFn: getChangeLogFn,
        getCachedCategoryColor: _getCachedCategoryColor,
      );
    } else if (viewSettings.globalViewMode == ViewMode.grid) {
      return AppGridView(
          apps: listedApps,
          selectedAppIds: selectedAppIds,
          toggleAppSelected: _toggleAppSelected);
    } else {
      return AppListView(
          apps: listedApps,
          selectedAppIds: selectedAppIds,
          toggleAppSelected: _toggleAppSelected,
          getChangeLogFn: getChangeLogFn);
    }
  }

  void _toggleAppSelected(App app) {
    setState(() {
      if (selectedAppIds.contains(app.id)) {
        selectedAppIds.remove(app.id);
      } else {
        selectedAppIds.add(app.id);
      }
    });
  }

  VoidCallback? _getMassObtainFunction(BuildContext context) {
    final appsProvider = context.read<AppsProvider>();
    var existingUpdates = appsProvider.findExistingUpdates(installedOnly: true);
    var existingUpdateIds = existingUpdates.where((id) => selectedAppIds.isEmpty ? true : selectedAppIds.contains(id)).toList();
    var newInstallIds = appsProvider.findExistingUpdates(nonInstalledOnly: true).where((id) => selectedAppIds.isEmpty ? true : selectedAppIds.contains(id)).toList();

    List<String> trackOnlyUpdateIds = [];
    existingUpdateIds = existingUpdateIds.where((id) {
      if (appsProvider.apps[id]!.app.additionalSettings['trackOnly'] == true) {
        trackOnlyUpdateIds.add(id);
        return false;
      }
      return true;
    }).toList();

    if (appsProvider.areDownloadsRunning() || (existingUpdateIds.isEmpty && newInstallIds.isEmpty && trackOnlyUpdateIds.isEmpty)) return null;
    
    return () {
      HapticFeedback.heavyImpact();
      List<GeneratedFormItem> formItems = [];
      if (existingUpdateIds.isNotEmpty) {
        formItems.add(GeneratedFormSwitch('updates', label: tr('updateX', args: [plural('apps', existingUpdateIds.length).toLowerCase()]), defaultValue: true));
      }
      if (newInstallIds.isNotEmpty) {
        formItems.add(GeneratedFormSwitch('installs', label: tr('installX', args: [plural('apps', newInstallIds.length).toLowerCase()]), defaultValue: existingUpdateIds.isEmpty));
      }
      if (trackOnlyUpdateIds.isNotEmpty) {
        formItems.add(GeneratedFormSwitch('trackonlies', label: tr('markXTrackOnlyAsUpdated', args: [plural('apps', trackOnlyUpdateIds.length)]), defaultValue: existingUpdateIds.isEmpty && newInstallIds.isEmpty));
      }
      showDialog<Map<String, dynamic>?>( 
        context: context,
        builder: (BuildContext ctx) {
          return GeneratedFormModal(
            title: tr('changeX', args: [plural('apps', existingUpdateIds.length + newInstallIds.length + trackOnlyUpdateIds.length).toLowerCase()]),
            items: formItems.map((e) => [e]).toList(),
            initValid: true,
          );
        },
      ).then((values) async {
        if (values != null) {
          if (values.isEmpty) values = getDefaultValuesFromFormItems([formItems]);
          List<String> toInstall = [];
          if (values['updates'] == true) toInstall.addAll(existingUpdateIds);
          if (values['installs'] == true) toInstall.addAll(newInstallIds);
          if (values['trackonlies'] == true) toInstall.addAll(trackOnlyUpdateIds);
          appsProvider.downloadAndInstallLatestApps(toInstall, globalNavigatorKey.currentContext).then((value) {
            if (value.isNotEmpty && values!['updates'] == true) showMessage(tr('appsUpdated'), context);
          });
        }
      });
    };
  }

  void _markSelectedAppsUpdated(BuildContext context, List<AppInMemory> listedApps) async {
    final appsProvider = context.read<AppsProvider>();
    var selectedApps = listedApps
        .where((e) => selectedAppIds.contains(e.app.id))
        .map((e) => e.app)
        .toList();
    if (selectedApps.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('markSelectedAppsUpdated')),
        content: Text(tr('markXSelectedAppsAsUpdated',
            args: [selectedApps.length.toString()])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('no'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('yes'))),
        ],
      ),
    );

    if (confirm == true) {
      for (var app in selectedApps) {
        app.installedVersion = app.latestVersion;
      }
      await appsProvider.saveApps(selectedApps);
      clearSelected();
      showMessage(tr('appsUpdated'), context);
    }
  }


