import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/category_icon_stack.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/apps/app_list_tile.dart';
import 'package:obtainium/components/apps/app_grid_view.dart';
import 'package:obtainium/components/apps/app_list_view.dart';
import 'package:obtainium/components/apps/category_sections.dart';
import 'package:obtainium/components/apps/app_dialogs.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/components/search/command_center.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/models/settings_enums.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({super.key, this.initialFilter});

  final AppsFilter? initialFilter;

  @override
  State<AppsPage> createState() => AppsPageState();
}

void showChangeLogDialog(
  BuildContext context,
  App app,
  String? changesUrl,
  AppSource appSource,
  String changeLog,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return GeneratedFormModal(
        title: tr('changes'),
        items: const [],
        message: app.latestVersion,
        additionalWidgets: [
          changesUrl != null
              ? GestureDetector(
                  child: Text(
                    changesUrl,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  onTap: () {
                    launchUrlString(
                      changesUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                )
              : const SizedBox.shrink(),
          changesUrl != null
              ? const SizedBox(height: 16)
              : const SizedBox.shrink(),
          appSource.changeLogIfAnyIsMarkDown
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - 350,
                  child: Markdown(
                    styleSheet: MarkdownStyleSheet(
                      blockquoteDecoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                    data: changeLog,
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrlString(
                          href.startsWith('http://') ||
                                  href.startsWith('https://')
                              ? href
                              : '${Uri.parse(app.url).origin}/$href',
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    extensionSet: md.ExtensionSet(
                      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                      [
                        md.EmojiSyntax(),
                        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                      ],
                    ),
                  ),
                )
              : Text(changeLog),
        ],
        singleNullReturnButton: tr('ok'),
      );
    },
  );
}

Null Function()? getChangeLogFn(BuildContext context, App app) {
  AppSource appSource = SourceProvider().getSource(
    app.url,
    overrideSource: app.overrideSource,
  );
  String? changesUrl = appSource.changeLogPageFromStandardUrl(app.url);
  String? changeLog = app.changeLog;
  if (changeLog?.split('\n').length == 1) {
    if (RegExp(
      '(http|ftp|https)://([\w_-]+(?:(?:\\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?',
    ).hasMatch(changeLog!)) {
      if (changesUrl == null) {
        changesUrl = changeLog;
        changeLog = null;
      }
    }
  }
  return (changeLog == null && changesUrl == null)
      ? null
      : () {
          if (changeLog != null) {
            showChangeLogDialog(context, app, changesUrl, appSource, changeLog);
          } else {
            launchUrlString(changesUrl!, mode: LaunchMode.externalApplication);
          }
        };
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
    var settingsProvider = context.watch<SettingsProvider>();
    var listedApps = appsProvider.getFilteredSortedApps(
      filter: filter,
      sortMethod: settingsProvider.appSortMethod,
      sortColumn: settingsProvider.sortColumn,
      sortOrder: settingsProvider.sortOrder,
      pinUpdates: settingsProvider.pinUpdates,
      groupByCategory: settingsProvider.groupByCategory,
      buryNonInstalled: settingsProvider.buryNonInstalled,
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
        settingsProvider.checkJustStarted() &&
        settingsProvider.checkOnStart) {
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
    var customOrder = settingsProvider.categoryOrder;
    listedCategories.sort((a, b) {
      var aIndex = a != null ? customOrder.indexOf(a) : -1;
      var bIndex = b != null ? customOrder.indexOf(b) : -1;
      if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;
      return a != null && b != null ? a.toLowerCase().compareTo(b.toLowerCase()) : (a == null ? 1 : -1);
    });

    getFilterChips() {
      return SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(tr('all')),
                  selected: filter.statusFilter.isEmpty,
                  onSelected: (val) {
                    setState(() {
                      filter.statusFilter.clear();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(tr('installed')),
                  selected: filter.statusFilter.contains('installed'),
                  onSelected: (val) {
                    setState(() {
                      filter.statusFilter.clear();
                      if (val) filter.statusFilter.add('installed');
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(tr('trackOnly')),
                  selected: filter.statusFilter.contains('trackonly'),
                  onSelected: (val) {
                    setState(() {
                      filter.statusFilter.clear();
                      if (val) filter.statusFilter.add('trackonly');
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

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

    showFilterDialog() async {
      var values = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (BuildContext ctx) {
          var vals = filter.toFormValuesMap();
          return GeneratedFormModal(
            initValid: true,
            title: tr('filterApps'),
            items: [
              [
                GeneratedFormTextField('appName',
                    label: tr('appName'),
                    required: false,
                    defaultValue: vals['appName']),
                GeneratedFormTextField('author',
                    label: tr('author'),
                    required: false,
                    defaultValue: vals['author']),
              ],
              [
                GeneratedFormTextField('appId',
                    label: tr('appId'),
                    required: false,
                    defaultValue: vals['appId'])
              ],
              [
                GeneratedFormSwitch('upToDateApps',
                    label: tr('upToDateApps'), defaultValue: vals['upToDateApps'])
              ],
              [
                GeneratedFormSwitch('nonInstalledApps',
                    label: tr('nonInstalledApps'),
                    defaultValue: vals['nonInstalledApps'])
              ],
              [
                GeneratedFormDropdown(
                  'sourceFilter',
                  label: tr('appSource'),
                  defaultValue: filter.sourceFilter,
                  [
                    MapEntry('', tr('none')),
                    ...sourceProvider.sources.map(
                        (e) => MapEntry(e.runtimeType.toString(), e.name))
                  ],
                ),
              ],
            ],
            additionalWidgets: [
              const SizedBox(height: 16),
              CategoryEditorSelector(
                preselected: filter.categoryFilter,
                onSelected: (categories) =>
                    filter.categoryFilter = categories.toSet(),
              ),
            ],
          );
        },
      );
      if (values != null) setState(() => filter.setFormValuesFromMap(values));
    }

    showSortDialog() async {
      var value = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (context) {
          return GeneratedFormModal(
            title: tr('sortOptions'),
            items: [
              [
                GeneratedFormDropdown(
                  'sortMethod',
                  label: tr('sortMethod'),
                  defaultValue: settingsProvider.appSortMethod.toString(),
                  AppSortMethod.values
                      .map((e) => MapEntry(e.toString(),
                          tr(e.toString().split('.').last)))
                      .toList(),
                )
              ],
            ],
          );
        },
      );
      if (value != null) {
        settingsProvider.setAppSortMethod(
          AppSortMethod.values.firstWhere(
            (e) => e.toString() == value['sortMethod'],
          ),
        );
      }
    }

    showTipsDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(tr('tips')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('appManagementTips')),
                const SizedBox(height: 16),
                Text(tr('swipeActionsTip')),
                const SizedBox(height: 16),
                Text(tr('longPressSelectionTip')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('ok')),
              ),
            ],
          );
        },
      );
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

    var isFilterOff = filter.isIdenticalTo(neutralFilter, settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: refresh,
        child: Scrollbar(
          controller: scrollController,
          child: Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              return CustomScrollView(
                controller: scrollController,
                slivers: <Widget>[
                  // Consolidated M3 Large App Bar
                  SliverAppBar.large(
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
                      if (selectedAppIds.isNotEmpty) ...[
                        // Selection Mode Actions
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
                        if (getMassObtainFunction() != null)
                          IconButton(
                            icon: const Icon(Icons.download_outlined),
                            onPressed: getMassObtainFunction(),
                            tooltip: tr('installUpdateSelectedApps'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            var selectedApps = listedApps
                                .where((e) => selectedAppIds.contains(e.app.id))
                                .map((e) => e.app)
                                .toList();
                            appsProvider.removeAppsWithModal(
                                context, selectedApps);
                          },
                          tooltip: tr('remove'),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'markUpdated') {
                              markSelectedAppsUpdated();
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
                      ] else ...[
                        // Normal Mode Actions
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
                              icon: Icon(isFilterOff
                                  ? Icons.filter_alt_outlined
                                  : Icons.filter_alt),
                              onPressed: showFilterDialog,
                              tooltip: tr('filter'),
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
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            switch (value) {
                              case 'sort':
                                showSortDialog();
                                break;
                              case 'view':
                                settingsProvider.globalViewMode =
                                    settingsProvider.globalViewMode == ViewMode.list
                                        ? ViewMode.grid
                                        : ViewMode.list;
                                break;
                              case 'import':
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder: (context) => const ImportExportPage(),
                                );
                                break;
                              case 'help':
                                showTipsDialog();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'sort',
                              child: ListTile(
                                leading: const Icon(Icons.sort),
                                title: Text(tr('sortMethod')),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'view',
                              child: ListTile(
                                leading: Icon(
                                    settingsProvider.globalViewMode == ViewMode.list
                                        ? Icons.grid_view
                                        : Icons.view_list),
                                title: Text(
                                    settingsProvider.globalViewMode == ViewMode.list
                                        ? tr('gridView')
                                        : tr('listView')),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'import',
                              child: ListTile(
                                leading: const Icon(Icons.import_export),
                                title: Text(tr('importExport')),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (settingsProvider.enableContextualTips)
                              PopupMenuItem(
                                value: 'help',
                                child: ListTile(
                                  leading: const Icon(Icons.help_outline),
                                  title: Text(tr('help')),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (settingsProvider.displayShowAppCount &&
                          selectedAppIds.isEmpty)
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
                  ),

                  // Filter Chips
                  if (settingsProvider.displayShowFilterChips && selectedAppIds.isEmpty)
                    getFilterChips(),

                  ...getLoadingWidgets(),

                  // Content
                  if (settingsProvider.groupByCategory)
                    CategorySections(
                      listedApps: listedApps,
                      listedCategories: listedCategories,
                      selectedAppIds: selectedAppIds,
                      toggleAppSelected: toggleAppSelected,
                      getChangeLogFn: getChangeLogFn,
                      getCachedCategoryColor: _getCachedCategoryColor,
                    )
                  else if (settingsProvider.globalViewMode == ViewMode.grid)
                    AppGridView(
                        apps: listedApps,
                        selectedAppIds: selectedAppIds,
                        toggleAppSelected: toggleAppSelected)
                  else
                    AppListView(
                        apps: listedApps,
                        selectedAppIds: selectedAppIds,
                        toggleAppSelected: toggleAppSelected,
                        getChangeLogFn: getChangeLogFn),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


