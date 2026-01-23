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

  // Memoization for sorting
  List<AppInMemory>? _cachedSortedApps;
  AppSortMethod? _lastSortMethod;
  SortColumnSettings? _lastSortColumn;
  SortOrderSettings? _lastSortOrder;
  int? _lastAppsHashCode;
  int? _lastFilterHashCode;

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
    var listedApps = appsProvider.getAppValues().toList();

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

    listedApps = listedApps.where((app) {
      if (filter.statusFilter.isNotEmpty) {
        bool hasUpdate = app.app.installedVersion != null && app.app.installedVersion != app.app.latestVersion;
        bool upToDate = app.app.installedVersion != null && app.app.installedVersion == app.app.latestVersion;
        bool notInstalled = app.app.installedVersion == null;

        bool matches = false;
        if (filter.statusFilter.contains('updates') && hasUpdate) matches = true;
        if (filter.statusFilter.contains('uptodate') && upToDate) matches = true;
        if (filter.statusFilter.contains('notinstalled') && notInstalled) matches = true;
        if (!matches) return false;
      }

      if (app.app.installedVersion == app.app.latestVersion &&
          !(filter.includeUptodate)) {
        return false;
      }
      if (app.app.installedVersion == null && !(filter.includeNonInstalled)) {
        return false;
      }
      if (filter.nameFilter.isNotEmpty || filter.authorFilter.isNotEmpty) {
        List<String> nameTokens = filter.nameFilter.split(' ').where((e) => e.trim().isNotEmpty).toList();
        List<String> authorTokens = filter.authorFilter.split(' ').where((e) => e.trim().isNotEmpty).toList();

        for (var t in nameTokens) {
          if (!app.name.toLowerCase().contains(t.toLowerCase())) return false;
        }
        for (var t in authorTokens) {
          if (!app.author.toLowerCase().contains(t.toLowerCase())) return false;
        }
      }
      if (filter.idFilter.isNotEmpty && !app.app.id.contains(filter.idFilter)) {
        return false;
      }
      if (filter.categoryFilter.isNotEmpty &&
          filter.categoryFilter.intersection(app.app.categories.toSet()).isEmpty) {
        return false;
      }
      if (filter.sourceFilter.isNotEmpty &&
          sourceProvider.getSource(app.app.url, overrideSource: app.app.overrideSource).runtimeType.toString() != filter.sourceFilter) {
        return false;
      }
      return true;
    }).toList();

    // Calculate hashes for memoization
    int filterHash = Object.hash(
      filter.nameFilter,
      filter.authorFilter,
      filter.idFilter,
      filter.includeUptodate,
      filter.includeNonInstalled,
      filter.sourceFilter,
      Object.hashAll(filter.categoryFilter),
      Object.hashAll(filter.statusFilter),
    );
    int appsHash = Object.hashAll(listedApps.map((e) => e.app.id));

    bool cacheValid = _cachedSortedApps != null &&
        _lastSortMethod == settingsProvider.appSortMethod &&
        _lastSortColumn == settingsProvider.sortColumn &&
        _lastSortOrder == settingsProvider.sortOrder &&
        _lastAppsHashCode == appsHash &&
        _lastFilterHashCode == filterHash;

    if (cacheValid) {
      listedApps = _cachedSortedApps!;
    } else {
      // Sorting logic
      if (settingsProvider.appSortMethod == AppSortMethod.latestUpdates) {
        listedApps.sort((a, b) {
          final aDate = a.installedInfo?.lastUpdateTime != null ? DateTime.fromMillisecondsSinceEpoch(a.installedInfo!.lastUpdateTime!) : null;
          final bDate = b.installedInfo?.lastUpdateTime != null ? DateTime.fromMillisecondsSinceEpoch(b.installedInfo!.lastUpdateTime!) : null;
          if (aDate == null && bDate == null) return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
      } else if (settingsProvider.appSortMethod == AppSortMethod.nameAZ) {
        listedApps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else if (settingsProvider.appSortMethod == AppSortMethod.nameZA) {
        listedApps.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      } else if (settingsProvider.appSortMethod == AppSortMethod.recentlyAdded) {
        listedApps.sort((a, b) => b.app.id.toLowerCase().compareTo(a.app.id.toLowerCase()));
      } else if (settingsProvider.appSortMethod == AppSortMethod.installStatus) {
        listedApps.sort((a, b) {
          if ((a.installedInfo != null) == (b.installedInfo != null)) return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return a.installedInfo != null ? -1 : 1;
        });
      } else {
        listedApps.sort((a, b) {
          int result = 0;
          if (settingsProvider.sortColumn == SortColumnSettings.authorName) {
            result = ((a.author + a.name).toLowerCase()).compareTo((b.author + b.name).toLowerCase());
          } else if (settingsProvider.sortColumn == SortColumnSettings.nameAuthor) {
            result = ((a.name + a.author).toLowerCase()).compareTo((b.name + b.author).toLowerCase());
          } else if (settingsProvider.sortColumn == SortColumnSettings.releaseDate) {
            final aDate = a.app.releaseDate;
            final bDate = b.app.releaseDate;
            if (aDate == null && bDate == null) {
              result = ((a.name + a.author).toLowerCase()).compareTo((b.name + b.author).toLowerCase());
            } else if (aDate == null) { result = 1; } else if (bDate == null) { result = -1; } else {
              result = aDate.compareTo(bDate);
            }
          }
          return result;
        });
        if (settingsProvider.sortOrder == SortOrderSettings.descending) listedApps = listedApps.reversed.toList();
      }

      // Update cache
      _cachedSortedApps = List.from(listedApps);
      _lastSortMethod = settingsProvider.appSortMethod;
      _lastSortColumn = settingsProvider.sortColumn;
      _lastSortOrder = settingsProvider.sortOrder;
      _lastAppsHashCode = appsHash;
      _lastFilterHashCode = filterHash;
    }

    var existingUpdates = appsProvider.findExistingUpdates(installedOnly: true);
    // Counts for chips
    int updatesCount = appsProvider.getAppValues().where((a) => a.app.installedVersion != null && a.app.installedVersion != a.app.latestVersion).length;
    int uptodateCount = appsProvider.getAppValues().where((a) => a.app.installedVersion != null && a.app.installedVersion == a.app.latestVersion).length;
    int notInstalledCount = appsProvider.getAppValues().where((a) => a.app.installedVersion == null).length;

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

    if (settingsProvider.pinUpdates) {
      var temp = listedApps.where((sa) => existingUpdates.contains(sa.app.id)).toList();
      listedApps.removeWhere((sa) => existingUpdates.contains(sa.app.id));
      listedApps = [...temp, ...listedApps];
    }

    var tempPinned = listedApps.where((a) => a.app.pinned).toList();
    var tempNotPinned = listedApps.where((a) => !a.app.pinned).toList();
    listedApps = [...tempPinned, ...tempNotPinned];

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
              GestureDetector(
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(initialTab: 2),
                    ),
                  );
                },
                child: FilterChip(
                  label: Text('${tr('updatesAvailable')} ($updatesCount)'),
                  selected: filter.statusFilter.contains('updates'),
                  onSelected: (val) {
                    setState(() {
                      val ? filter.statusFilter.add('updates') : filter.statusFilter.remove('updates');
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(initialTab: 2),
                    ),
                  );
                },
                child: FilterChip(
                  label: Text('${tr('upToDateApps')} ($uptodateCount)'),
                  selected: filter.statusFilter.contains('uptodate'),
                  onSelected: (val) {
                    setState(() {
                      val ? filter.statusFilter.add('uptodate') : filter.statusFilter.remove('uptodate');
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(initialTab: 2),
                    ),
                  );
                },
                child: FilterChip(
                  label: Text('${tr('notInstalled')} ($notInstalledCount)'),
                  selected: filter.statusFilter.contains('notinstalled'),
                  onSelected: (val) {
                    setState(() {
                      val ? filter.statusFilter.add('notinstalled') : filter.statusFilter.remove('notinstalled');
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

    getSelectAllButton() {
      return TextButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          selectedAppIds.isEmpty ? selectThese(listedApps.map((e) => e.app).toList()) : clearSelected();
        },
        icon: Icon(selectedAppIds.isEmpty ? Icons.select_all_outlined : Icons.deselect_outlined),
        label: Text(selectedAppIds.isEmpty ? listedApps.length.toString() : selectedAppIds.length.toString()),
      );
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
                GeneratedFormTextField('appName', label: tr('appName'), required: false, defaultValue: vals['appName']),
                GeneratedFormTextField('author', label: tr('author'), required: false, defaultValue: vals['author']),
              ],
              [GeneratedFormTextField('appId', label: tr('appId'), required: false, defaultValue: vals['appId'])],
              [GeneratedFormSwitch('upToDateApps', label: tr('upToDateApps'), defaultValue: vals['upToDateApps'])],
              [GeneratedFormSwitch('nonInstalledApps', label: tr('nonInstalledApps'), defaultValue: vals['nonInstalledApps'])],
              [
                GeneratedFormDropdown(
                  'sourceFilter',
                  label: tr('appSource'),
                  defaultValue: filter.sourceFilter,
                  [MapEntry('', tr('none')), ...sourceProvider.sources.map((e) => MapEntry(e.runtimeType.toString(), e.name))],
                ),
              ],
            ],
            additionalWidgets: [
              const SizedBox(height: 16),
              CategoryEditorSelector(
                preselected: filter.categoryFilter,
                onSelected: (categories) => filter.categoryFilter = categories.toSet(),
              ),
            ],
          );
        },
      );
      if (values != null) setState(() => filter.setFormValuesFromMap(values));
    }

    getFilterButtonsRow() {
      var isFilterOff = filter.isIdenticalTo(neutralFilter, settingsProvider);
      return Row(
        children: [
          getSelectAllButton(),
          IconButton(
            onPressed: isFilterOff ? showFilterDialog : () => setState(() => filter = AppsFilter()),
            icon: Icon(isFilterOff ? Icons.search_rounded : Icons.search_off_rounded),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const ImportExportPage(),
              );
            },
            icon: const Icon(Icons.import_export),
          ),
          IconButton(
            onPressed: () {
              showDialog(
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
                          AppSortMethod.values.map((e) => MapEntry(e.toString(), tr(e.toString().split('.').last))).toList(),
                        )
                      ],
                    ],
                  );
                },
              ).then((value) {
                if (value != null) {
                  settingsProvider.setAppSortMethod(
                    AppSortMethod.values.firstWhere(
                      (e) => e.toString() == value['sortMethod'],
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.sort_rounded),
          ),
          IconButton(
            onPressed: () {
              settingsProvider.globalViewMode = settingsProvider.globalViewMode == ViewMode.list
                  ? ViewMode.grid
                  : ViewMode.list;
            },
            icon: Icon(settingsProvider.globalViewMode == ViewMode.list ? Icons.grid_view : Icons.view_list),
          ),
          const Expanded(child: SizedBox()),
          IconButton(
            onPressed: getMassObtainFunction(),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(tr('appsString')),
        actions: [
          // Move Import/Export to AppBar as requested
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => const ImportExportPage(),
              );
            },
            icon: const Icon(Icons.import_export),
            tooltip: tr('importExport'),
          ),
          // Conditionally show help icon based on settings
          if (settingsProvider.enableContextualTips)
            IconButton(
              onPressed: () {
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
              },
              icon: const Icon(Icons.help_outline),
              tooltip: tr('help'),
            ),
          // Add settings icon as well
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: tr('settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: refresh,
          child: Scrollbar(
            controller: scrollController,
            child: Consumer<SettingsProvider>(
              builder: (context, settingsProvider, _) {
                Widget scrollView = CustomScrollView(
                  controller: scrollController,
                  slivers: <Widget>[
                    // Standard M3 Large App Bar
                    SliverAppBar.large(
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
                        child: Text(tr('appsString')),
                      ),
                      automaticallyImplyLeading: false,
                      actions: [
                        if (settingsProvider.displayShowAppCount)
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

                    // Filter Chips & App Count Context (Moved to body to prevent overlap)
                    if (settingsProvider.displayShowFilterChips)
                      getFilterChips(),
                    ...getLoadingWidgets(),
                    // These widgets return slivers (SliverList/SliverGrid), so they go directly in slivers list
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
                      AppGridView(apps: listedApps, selectedAppIds: selectedAppIds, toggleAppSelected: toggleAppSelected)
                    else
                      AppListView(apps: listedApps, selectedAppIds: selectedAppIds, toggleAppSelected: toggleAppSelected, getChangeLogFn: getChangeLogFn),
                  ],
                );

                // Conditionally wrap with GestureDetector based on settings
                if (settingsProvider.enableSwipeGestures) {
                  return GestureDetector(
                    onPanUpdate: (details) {
                      // Handle swipe gestures for additional functionality
                      if (details.delta.dx > 10) { // Swipe right
                        // Could implement pull-out menu or other functionality
                      } else if (details.delta.dx < -10) { // Swipe left
                        // Could implement quick actions menu
                      }
                    },
                    child: scrollView,
                  );
                } else {
                  return scrollView;
                }
              },
            ),
          ),
        ),
      bottomNavigationBar: appsProvider.apps.isEmpty
          ? null
          : _buildBottomNavigationBar(
              settingsProvider: settingsProvider,
              listedApps: listedApps,
              showFilterDialog: showFilterDialog,
              getMassObtainFunction: getMassObtainFunction,
            ),
    );
  }

  // New method to build the bottom navigation bar with proper spacing
  Widget _buildBottomNavigationBar({
    required SettingsProvider settingsProvider,
    required List<AppInMemory> listedApps,
    required Future<void> Function() showFilterDialog,
    required VoidCallback? Function() getMassObtainFunction,
  }) {
    var isFilterOff = filter.isIdenticalTo(neutralFilter, settingsProvider);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              // Select All button with increased touch target and improved accessibility
              Semantics(
                button: true,
                label: selectedAppIds.isEmpty
                  ? tr('selectAll')
                  : tr('deselectX', args: [selectedAppIds.length.toString()]),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      selectedAppIds.isEmpty ? selectThese(listedApps.map((e) => e.app).toList()) : clearSelected();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        selectedAppIds.isEmpty
                          ? Icons.select_all_outlined
                          : Icons.deselect_outlined,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(), // Push other buttons to the right

              // Search button
              Semantics(
                button: true,
                label: isFilterOff ? tr('search') : tr('clear'),
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(initialTab: 1),
                      ),
                    );
                  },
                  child: IconButton(
                    onPressed: () {
                      if (isFilterOff) {
                        showFilterDialog();
                      } else {
                        setState(() => filter = AppsFilter());
                      }
                    },
                    icon: Icon(isFilterOff ? Icons.search_rounded : Icons.search_off_rounded),
                    tooltip: isFilterOff ? tr('search') : tr('clear'),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                  ),
                ),
              ),

              // Sort button
              Semantics(
                button: true,
                label: tr('sortMethod'),
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(initialTab: 2),
                      ),
                    );
                  },
                  child: IconButton(
                    onPressed: () {
                      showDialog(
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
                                  AppSortMethod.values.map((e) => MapEntry(e.toString(), tr(e.toString().split('.').last))).toList(),
                                )
                              ],
                            ],
                          );
                        },
                      ).then((value) {
                        if (value != null) {
                          settingsProvider.setAppSortMethod(
                            AppSortMethod.values.firstWhere(
                              (e) => e.toString() == value['sortMethod'],
                            ),
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.sort_rounded),
                    tooltip: tr('sortMethod'),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                  ),
                ),
              ),

              // Filter button
              Semantics(
                button: true,
                label: tr('filter'),
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(initialTab: 2),
                      ),
                    );
                  },
                  child: IconButton(
                    onPressed: () {
                      showFilterDialog();
                    },
                    icon: const Icon(Icons.filter_alt_outlined),
                    tooltip: tr('filter'),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                  ),
                ),
              ),

              // View Toggle button
              Semantics(
                button: true,
                label: settingsProvider.globalViewMode == ViewMode.list ? tr('gridView') : tr('listView'),
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(initialTab: 2),
                      ),
                    );
                  },
                  child: IconButton(
                    onPressed: () {
                      settingsProvider.globalViewMode = settingsProvider.globalViewMode == ViewMode.list
                          ? ViewMode.grid
                          : ViewMode.list;
                    },
                    icon: Icon(settingsProvider.globalViewMode == ViewMode.list ? Icons.grid_view : Icons.view_list),
                    tooltip: settingsProvider.globalViewMode == ViewMode.list ? tr('gridView') : tr('listView'),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                  ),
                ),
              ),

              // Mass Obtain button (Download/Update)
              if (getMassObtainFunction() != null)
                Semantics(
                  button: true,
                  label: tr('installUpdateSelectedApps'),
                  child: GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(initialTab: 1),
                        ),
                      );
                    },
                    child: IconButton(
                      onPressed: getMassObtainFunction(),
                      icon: const Icon(Icons.file_download_outlined),
                      tooltip: tr('installUpdateSelectedApps'),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppsFilter {
  String nameFilter = '';
  String authorFilter = '';
  String idFilter = '';
  bool includeUptodate = true;
  bool includeNonInstalled = true;
  Set<String> categoryFilter = {};
  Set<String> statusFilter = {};
  String sourceFilter = '';

  AppsFilter();

  Map<String, dynamic> toFormValuesMap() => {
    'appName': nameFilter, 'author': authorFilter, 'appId': idFilter,
    'upToDateApps': includeUptodate, 'nonInstalledApps': includeNonInstalled, 'sourceFilter': sourceFilter,
  };

  void setFormValuesFromMap(Map<String, dynamic> values) {
    nameFilter = values['appName']!; authorFilter = values['author']!; idFilter = values['appId']!;
    includeUptodate = values['upToDateApps']; includeNonInstalled = values['nonInstalledApps']; sourceFilter = values['sourceFilter'];
  }

  bool isIdenticalTo(AppsFilter other, SettingsProvider settingsProvider) =>
      authorFilter == other.authorFilter && nameFilter == other.nameFilter && idFilter == other.idFilter &&
      includeUptodate == other.includeUptodate && includeNonInstalled == other.includeNonInstalled &&
      settingsProvider.setEqual(categoryFilter, other.categoryFilter) && sourceFilter == other.sourceFilter &&
      settingsProvider.setEqual(statusFilter, other.statusFilter);
}
