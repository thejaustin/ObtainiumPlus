import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/category_icon_stack.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:markdown/markdown.dart' as md;

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

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
      '(http|ftp|https)://([\\w_-]+(?:(?:\\.[\\w_-]+)+))([\\w.,@?^=%&:/~+#-]*[\\w@?^=%&/~+#-])?',
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
  var updatesOnlyFilter = AppsFilter(
    includeUptodate: false,
    includeNonInstalled: false,
  );
  Set<String> selectedAppIds = {};
  DateTime? refreshingSince;

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
          .checkUpdates()
          .catchError((e) {
            showError(e is Map ? e['errors'] : e, context);
            return <App>[];
          })
          .whenComplete(() {
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
      if (app.app.installedVersion == app.app.latestVersion &&
          !(filter.includeUptodate)) {
        return false;
      }
      if (app.app.installedVersion == null && !(filter.includeNonInstalled)) {
        return false;
      }
      if (filter.nameFilter.isNotEmpty || filter.authorFilter.isNotEmpty) {
        List<String> nameTokens = filter.nameFilter
            .split(' ')
            .where((element) => element.trim().isNotEmpty)
            .toList();
        List<String> authorTokens = filter.authorFilter
            .split(' ')
            .where((element) => element.trim().isNotEmpty)
            .toList();

        for (var t in nameTokens) {
          if (!app.name.toLowerCase().contains(t.toLowerCase())) {
            return false;
          }
        }
        for (var t in authorTokens) {
          if (!app.author.toLowerCase().contains(t.toLowerCase())) {
            return false;
          }
        }
      }
      if (filter.idFilter.isNotEmpty) {
        if (!app.app.id.contains(filter.idFilter)) {
          return false;
        }
      }
      if (filter.categoryFilter.isNotEmpty &&
          filter.categoryFilter
              .intersection(app.app.categories.toSet())
              .isEmpty) {
        return false;
      }
      if (filter.sourceFilter.isNotEmpty &&
          sourceProvider
                  .getSource(
                    app.app.url,
                    overrideSource: app.app.overrideSource,
                  )
                  .runtimeType
                  .toString() !=
              filter.sourceFilter) {
        return false;
      }
      return true;
    }).toList();

    // Apply sorting based on the selected method
    if (settingsProvider.appSortMethod == AppSortMethod.latestUpdates) {
      listedApps.sort((a, b) {
        final aDate = a.installedInfo?.lastUpdateTime != null
            ? DateTime.fromMillisecondsSinceEpoch(a.installedInfo!.lastUpdateTime!)
            : null;
        final bDate = b.installedInfo?.lastUpdateTime != null
            ? DateTime.fromMillisecondsSinceEpoch(b.installedInfo!.lastUpdateTime!)
            : null;
        if (aDate == null && bDate == null) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        } else if (aDate == null) {
          return 1;
        } else if (bDate == null) {
          return -1;
        } else {
          return bDate.compareTo(aDate); // Most recent first
        }
      });
    } else if (settingsProvider.appSortMethod == AppSortMethod.nameAZ) {
      listedApps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (settingsProvider.appSortMethod == AppSortMethod.nameZA) {
      listedApps.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (settingsProvider.appSortMethod == AppSortMethod.recentlyAdded) {
      listedApps.sort((a, b) {
        // Use app ID as proxy for added date (assuming sequential IDs)
        return b.app.id.toLowerCase().compareTo(a.app.id.toLowerCase());
      });
    } else if (settingsProvider.appSortMethod == AppSortMethod.installStatus) {
      listedApps.sort((a, b) {
        final aInstalled = a.installedInfo != null;
        final bInstalled = b.installedInfo != null;
        if (aInstalled == bInstalled) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return aInstalled ? -1 : 1; // Installed apps first
      });
    } else {
      // Default sort using existing logic
      listedApps.sort((a, b) {
        int result = 0;
        if (settingsProvider.sortColumn == SortColumnSettings.authorName) {
          result = ((a.author + a.name).toLowerCase()).compareTo(
            (b.author + b.name).toLowerCase(),
          );
        } else if (settingsProvider.sortColumn == SortColumnSettings.nameAuthor) {
          result = ((a.name + a.author).toLowerCase()).compareTo(
            (b.name + b.author).toLowerCase(),
          );
        } else if (settingsProvider.sortColumn ==
            SortColumnSettings.releaseDate) {
          // Handle null dates: apps with unknown release dates are grouped at the end
          final aDate = a.app.releaseDate;
          final bDate = b.app.releaseDate;
          if (aDate == null && bDate == null) {
            // Both null: sort by name for consistency
            result = ((a.name + a.author).toLowerCase()).compareTo(
              (b.name + b.author).toLowerCase(),
            );
          } else if (aDate == null) {
            // a has no date, push to end (ascending) or beginning (will be reversed for descending)
            result = 1;
          } else if (bDate == null) {
            // b has no date, push to end
            result = -1;
          } else {
            result = aDate.compareTo(bDate);
          }
        } else if (settingsProvider.sortColumn ==
            SortColumnSettings.lastUpdated) {
          final aDate = a.installedInfo?.lastUpdateTime != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  a.installedInfo!.lastUpdateTime!,
                )
              : null;
          final bDate = b.installedInfo?.lastUpdateTime != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  b.installedInfo!.lastUpdateTime!,
                )
              : null;
          if (aDate == null && bDate == null) {
            result = ((a.name + a.author).toLowerCase()).compareTo(
              (b.name + b.author).toLowerCase(),
            );
          } else if (aDate == null) {
            result = 1;
          } else if (bDate == null) {
            result = -1;
          } else {
            result = aDate.compareTo(bDate);
          }
        } else if (settingsProvider.sortColumn == SortColumnSettings.source) {
          result = sourceProvider
              .getSource(
                a.app.url,
                overrideSource: a.app.overrideSource,
              )
              .name
              .toLowerCase()
              .compareTo(
                sourceProvider
                    .getSource(
                      b.app.url,
                      overrideSource: b.app.overrideSource,
                    )
                    .name
                    .toLowerCase(),
              );
        } else if (settingsProvider.sortColumn == SortColumnSettings.installDate) {
          final aDate = a.installedInfo?.firstInstallTime != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  a.installedInfo!.firstInstallTime!,
                )
              : null;
          final bDate = b.installedInfo?.firstInstallTime != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  b.installedInfo!.firstInstallTime!,
                )
              : null;
          if (aDate == null && bDate == null) {
            result = ((a.name + a.author).toLowerCase()).compareTo(
              (b.name + b.author).toLowerCase(),
            );
          } else if (aDate == null) {
            result = 1;
          } else if (bDate == null) {
            result = -1;
          } else {
            result = aDate.compareTo(bDate);
          }
        } else if (settingsProvider.sortColumn ==
            SortColumnSettings.lastCheckDate) {
          final aDate = a.app.lastUpdateCheck;
          final bDate = b.app.lastUpdateCheck;
          if (aDate == null && bDate == null) {
            result = ((a.name + a.author).toLowerCase()).compareTo(
              (b.name + b.author).toLowerCase(),
            );
          } else if (aDate == null) {
            result = 1;
          } else if (bDate == null) {
            result = -1;
          } else {
            result = aDate.compareTo(bDate);
          }
        }
        return result;
      });

      if (settingsProvider.sortOrder == SortOrderSettings.descending) {
        listedApps = listedApps.reversed.toList();
      }
    }

    var existingUpdates = appsProvider.findExistingUpdates(installedOnly: true);

    var existingUpdateIdsAllOrSelected = existingUpdates
        .where(
          (element) => selectedAppIds.isEmpty
              ? listedApps.where((a) => a.app.id == element).isNotEmpty
              : selectedAppIds.map((e) => e).contains(element),
        )
        .toList();
    var newInstallIdsAllOrSelected = appsProvider
        .findExistingUpdates(nonInstalledOnly: true)
        .where(
          (element) => selectedAppIds.isEmpty
              ? listedApps.where((a) => a.app.id == element).isNotEmpty
              : selectedAppIds.map((e) => e).contains(element),
        )
        .toList();

    List<String> trackOnlyUpdateIdsAllOrSelected = [];
    existingUpdateIdsAllOrSelected = existingUpdateIdsAllOrSelected.where((id) {
      if (appsProvider.apps[id]!.app.additionalSettings['trackOnly'] == true) {
        trackOnlyUpdateIdsAllOrSelected.add(id);
        return false;
      }
      return true;
    }).toList();
    newInstallIdsAllOrSelected = newInstallIdsAllOrSelected.where((id) {
      if (appsProvider.apps[id]!.app.additionalSettings['trackOnly'] == true) {
        trackOnlyUpdateIdsAllOrSelected.add(id);
        return false;
      }
      return true;
    }).toList();

    if (settingsProvider.pinUpdates) {
      var temp = [];
      listedApps = listedApps.where((sa) {
        if (existingUpdates.contains(sa.app.id)) {
          temp.add(sa);
          return false;
        }
        return true;
      }).toList();
      listedApps = [...temp, ...listedApps];
    }

    if (settingsProvider.buryNonInstalled) {
      var temp = [];
      listedApps = listedApps.where((sa) {
        if (sa.app.installedVersion == null) {
          temp.add(sa);
          return false;
        }
        return true;
      }).toList();
      listedApps = [...listedApps, ...temp];
    }

    var tempPinned = [];
    var tempNotPinned = [];
    for (var a in listedApps) {
      if (a.app.pinned) {
        tempPinned.add(a);
      } else {
        tempNotPinned.add(a);
      }
    }
    listedApps = [...tempPinned, ...tempNotPinned];

    List<String?> getListedCategories() {
      var temp = listedApps.map(
        (e) => e.app.categories.isNotEmpty ? e.app.categories : [null],
      );
      return temp.isNotEmpty
          ? {
              ...temp.reduce((v, e) => [...v, ...e]),
            }.toList()
          : [];
    }

    var listedCategories = getListedCategories();

    // Sort categories using custom order if available, otherwise alphabetically
    var customOrder = settingsProvider.categoryOrder;
    if (customOrder.isNotEmpty) {
      listedCategories.sort((a, b) {
        var aIndex = a != null ? customOrder.indexOf(a) : -1;
        var bIndex = b != null ? customOrder.indexOf(b) : -1;

        // If both are in custom order, sort by their position
        if (aIndex != -1 && bIndex != -1) {
          return aIndex.compareTo(bIndex);
        }
        // If only a is in custom order, it comes first
        if (aIndex != -1) return -1;
        // If only b is in custom order, it comes first
        if (bIndex != -1) return 1;
        // If neither is in custom order, fall back to alphabetical
        return a != null && b != null
            ? a.toLowerCase().compareTo(b.toLowerCase())
            : a == null
            ? 1
            : -1;
      });
    } else {
      listedCategories.sort((a, b) {
        return a != null && b != null
            ? a.toLowerCase().compareTo(b.toLowerCase())
            : a == null
            ? 1
            : -1;
      });
    }

    Set<App> selectedApps = listedApps
        .map((e) => e.app)
        .where((a) => selectedAppIds.contains(a.id))
        .toSet();

    getLoadingWidgets() {
      return [
        if (listedApps.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                appsProvider.apps.isEmpty
                    ? appsProvider.loadingApps
                          ? tr('pleaseWait')
                          : tr('noApps')
                    : tr('noAppsForFilter'),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (refreshingSince != null || appsProvider.loadingApps)
          SliverToBoxAdapter(
            child: LinearProgressIndicator(
              value: appsProvider.loadingApps
                  ? null
                  : appsProvider
                            .getAppValues()
                            .where(
                              (element) =>
                                  !(element.app.lastUpdateCheck?.isBefore(
                                        refreshingSince!,
                                      ) ??
                                      true),
                            )
                            .length /
                        (appsProvider.apps.isNotEmpty
                            ? appsProvider.apps.length
                            : 1),
            ),
          ),
      ];
    }

    getUpdateButton(int appIndex) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        color: Theme.of(context).colorScheme.primary,
        tooltip:
            listedApps[appIndex].app.additionalSettings['trackOnly'] == true
            ? tr('markUpdated')
            : tr('update'),
        onPressed: appsProvider.areDownloadsRunning()
            ? null
            : () {
                appsProvider
                    .downloadAndInstallLatestApps([
                      listedApps[appIndex].app.id,
                    ], globalNavigatorKey.currentContext)
                    .catchError((e) {
                      showError(e, context);
                      return <String>[];
                    });
              },
        icon: Icon(
          listedApps[appIndex].app.additionalSettings['trackOnly'] == true
              ? Icons.check_circle_outline
              : Icons.install_mobile,
        ),
      );
    }

    getAppIcon(int appIndex) {
      return GestureDetector(
        child: FutureBuilder(
          future: appsProvider.updateAppIcon(listedApps[appIndex].app.id),
          builder: (ctx, val) {
            return listedApps[appIndex].icon != null
                ? Image.memory(
                    listedApps[appIndex].icon!,
                    gaplessPlayback: true,
                    opacity: AlwaysStoppedAnimation(
                      listedApps[appIndex].installedInfo == null ? 0.6 : 1,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationZ(0.31),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Image(
                            image: const AssetImage(
                              'assets/graphics/icon_small.png',
                            ),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.white.withOpacity(0.3),
                            colorBlendMode: BlendMode.modulate,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ],
                  );
          },
        ),
        onDoubleTap: () {
          pm.openApp(listedApps[appIndex].app.id);
        },
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppPage(
                appId: listedApps[appIndex].app.id,
                showOppositeOfPreferredView: true,
              ),
            ),
          );
        },
      );
    }

    getVersionText(int appIndex) {
      return listedApps[appIndex].app.installedVersion ?? tr('notInstalled');
    }

    getChangesButtonString(int appIndex, bool hasChangeLogFn) {
      return listedApps[appIndex].app.releaseDate == null
          ? hasChangeLogFn
                ? tr('changes')
                : ''
          : DateFormat(
              'yyyy-MM-dd',
            ).format(listedApps[appIndex].app.releaseDate!.toLocal());
    }

    getSingleAppHorizTile(int index) {
      var showChangesFn = getChangeLogFn(context, listedApps[index].app);
      var hasUpdate =
          listedApps[index].app.installedVersion != null &&
          listedApps[index].app.installedVersion !=
              listedApps[index].app.latestVersion;
      Widget trailingRow = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hasUpdate ? getUpdateButton(index) : const SizedBox.shrink(),
          hasUpdate ? const SizedBox(width: 5) : const SizedBox.shrink(),
          GestureDetector(
            onTap: showChangesFn,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    settingsProvider.highlightTouchTargets &&
                        showChangesFn != null
                    ? (Theme.of(context).brightness == Brightness.light
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColorLight)
                          .withAlpha(
                            Theme.of(context).brightness == Brightness.light
                                ? 20
                                : 40,
                          )
                    : null,
              ),
              padding: settingsProvider.highlightTouchTargets
                  ? const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0)
                  : const EdgeInsetsDirectional.fromSTEB(24, 0, 0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width / 4,
                        ),
                        child: Text(
                          getVersionText(index),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: isVersionPseudo(listedApps[index].app)
                              ? TextStyle(fontStyle: FontStyle.italic)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getChangesButtonString(index, showChangesFn != null),
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          decoration: showChangesFn != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      var transparent = Theme.of(
        context,
      ).colorScheme.surface.withAlpha(0).value;
      List<double> stops = [
        ...listedApps[index].app.categories.asMap().entries.map(
          (e) =>
              ((e.key / (listedApps[index].app.categories.length - 1)) -
              0.0001),
        ),
        1,
      ];
      if (stops.length == 2) {
        stops[0] = 0.9999;
      }
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: stops,
            begin: const Alignment(-1, 0),
            end: const Alignment(-0.97, 0),
            colors: [
              ...listedApps[index].app.categories.map(
                (e) => Color(
                  settingsProvider.categories[e] ?? transparent,
                ).withAlpha(255),
              ),
              Color(transparent),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              toggleAppSelected(listedApps[index].app);
            },
            onTap: () {
              if (selectedAppIds.isNotEmpty) {
                toggleAppSelected(listedApps[index].app);
              } else {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        AppPage(appId: listedApps[index].app.id),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 0.05);
                      const end = Offset.zero;
                      const curve = Curves.easeOutCubic;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              }
            },
            child: ListTile(
              tileColor: listedApps[index].app.pinned
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.transparent,
              selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(
                listedApps[index].app.pinned ? 0.2 : 0.1,
              ),
              selected: selectedAppIds
                  .map((e) => e)
                  .contains(listedApps[index].app.id),
              leading: getAppIcon(index),
              title: Text(
                maxLines: 1,
                listedApps[index].name,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: listedApps[index].app.pinned
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                tr('byX', args: [listedApps[index].author]),
                maxLines: 1,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: listedApps[index].app.pinned
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              trailing: listedApps[index].downloadProgress != null
                  ? SizedBox(
                      child: Text(
                        listedApps[index].downloadProgress! >= 0
                            ? tr(
                                'percentProgress',
                                args: [
                                  listedApps[index].downloadProgress!
                                      .toInt()
                                      .toString(),
                                ],
                              )
                            : tr('installing'),
                        textAlign: (listedApps[index].downloadProgress! >= 0)
                            ? TextAlign.start
                            : TextAlign.end,
                      ),
                    )
                  : trailingRow,
            ),
          ),
        ),
      );
    }

    void showCategorySettingsDialog(String? categoryName) {
      if (categoryName == null) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          var currentOverride = settingsProvider.getCategoryViewMode(categoryName);

          return AlertDialog(
            title: Text(tr('categorySettings')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ViewMode?>(
                  decoration: InputDecoration(
                    labelText: tr('viewMode'),
                  ),
                  value: currentOverride,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(tr('useGlobalSetting')),
                    ),
                    DropdownMenuItem(
                      value: ViewMode.list,
                      child: Row(
                        children: [
                          const Icon(Icons.view_list),
                          const SizedBox(width: 8),
                          Text(tr('listView')),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: ViewMode.grid,
                      child: Row(
                        children: [
                          const Icon(Icons.grid_view),
                          const SizedBox(width: 8),
                          Text(tr('gridView')),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (ViewMode? value) {
                    setState(() {
                      settingsProvider.setCategoryViewMode(categoryName, value);
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('close')),
              ),
            ],
          );
        },
      );
    }

    getCategoryCollapsibleTile(Key key, int index) {
      var tiles = listedApps
          .asMap()
          .entries
          .where(
            (e) =>
                e.value.app.categories.contains(listedCategories[index]) ||
                e.value.app.categories.isEmpty &&
                    listedCategories[index] == null,
          )
          .map((e) => getSingleAppHorizTile(e.key))
          .toList();

      capFirstChar(String str) => str[0].toUpperCase() + str.substring(1);

      var categoryName = listedCategories[index];
      var categoryColorInt =
          categoryName != null ? settingsProvider.categories[categoryName] : null;
      var categoryColor =
          categoryColorInt != null ? Color(categoryColorInt) : null;
      var transparent =
          Theme.of(context).colorScheme.surface.withAlpha(0).value;

      // Extract category icons for preview
      List<Uint8List?> categoryIcons = [];
      if (settingsProvider.categoryIconPosition != CategoryIconPosition.disabled &&
          settingsProvider.categoryIconCount > 0) {
        categoryIcons = listedApps
            .where((e) =>
                e.app.categories.contains(categoryName) ||
                (e.app.categories.isEmpty && categoryName == null))
            .take(settingsProvider.categoryIconCount)
            .map((e) => e.icon)
            .toList();
      }

      // Build title widget with optional icon preview
      Widget categoryTitle = Row(
        children: [
          if (settingsProvider.categoryIconPosition ==
                  CategoryIconPosition.leading &&
              categoryIcons.isNotEmpty) ...[
            CategoryIconStack(
              icons: categoryIcons,
              maxIcons: settingsProvider.categoryIconCount,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capFirstChar(listedCategories[index] ?? tr('noCategory')),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (settingsProvider.categoryIconPosition ==
                        CategoryIconPosition.below &&
                    categoryIcons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  CategoryIconStack(
                    icons: categoryIcons,
                    maxIcons: settingsProvider.categoryIconCount,
                  ),
                ],
              ],
            ),
          ),
          if (settingsProvider.categoryIconPosition ==
                  CategoryIconPosition.trailing &&
              categoryIcons.isNotEmpty) ...[
            const SizedBox(width: 12),
            CategoryIconStack(
              icons: categoryIcons,
              maxIcons: settingsProvider.categoryIconCount,
            ),
          ],
        ],
      );

      return Container(
        key: key,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1, 0),
            end: const Alignment(-0.97, 0),
            colors: [
              categoryColor ?? Color(transparent),
              Color(transparent),
            ],
            stops: const [0.99, 1],
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: ExpansionTile(
            initiallyExpanded: !settingsProvider.categoriesCollapsedByDefault,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: categoryTitle,
            controlAffinity: ListTileControlAffinity.leading,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tiles.length.toString()),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => showCategorySettingsDialog(categoryName),
                ),
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            children: tiles,
          ),
        ),
      );
    }

    getSelectAllButton() {
      return selectedAppIds.isEmpty
          ? TextButton.icon(
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onPressed: () {
                selectThese(listedApps.map((e) => e.app).toList());
              },
              icon: Icon(
                Icons.select_all_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(listedApps.length.toString()),
            )
          : TextButton.icon(
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              onPressed: () {
                selectedAppIds.isEmpty
                    ? selectThese(listedApps.map((e) => e.app).toList())
                    : clearSelected();
              },
              icon: Icon(
                selectedAppIds.isEmpty
                    ? Icons.select_all_outlined
                    : Icons.deselect_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(selectedAppIds.length.toString()),
            );
    }

    getMassObtainFunction() {
      return appsProvider.areDownloadsRunning() ||
              (existingUpdateIdsAllOrSelected.isEmpty &&
                  newInstallIdsAllOrSelected.isEmpty &&
                  trackOnlyUpdateIdsAllOrSelected.isEmpty)
          ? null
          : () {
              HapticFeedback.heavyImpact();
              List<GeneratedFormItem> formItems = [];
              if (existingUpdateIdsAllOrSelected.isNotEmpty) {
                formItems.add(
                  GeneratedFormSwitch(
                    'updates',
                    label: tr(
                      'updateX',
                      args: [
                        plural(
                          'apps',
                          existingUpdateIdsAllOrSelected.length,
                        ).toLowerCase(),
                      ],
                    ),
                    defaultValue: true,
                  ),
                );
              }
              if (newInstallIdsAllOrSelected.isNotEmpty) {
                formItems.add(
                  GeneratedFormSwitch(
                    'installs',
                    label: tr(
                      'installX',
                      args: [
                        plural(
                          'apps',
                          newInstallIdsAllOrSelected.length,
                        ).toLowerCase(),
                      ],
                    ),
                    defaultValue: existingUpdateIdsAllOrSelected.isEmpty,
                  ),
                );
              }
              if (trackOnlyUpdateIdsAllOrSelected.isNotEmpty) {
                formItems.add(
                  GeneratedFormSwitch(
                    'trackonlies',
                    label: tr(
                      'markXTrackOnlyAsUpdated',
                      args: [
                        plural('apps', trackOnlyUpdateIdsAllOrSelected.length),
                      ],
                    ),
                    defaultValue:
                        existingUpdateIdsAllOrSelected.isEmpty &&
                        newInstallIdsAllOrSelected.isEmpty,
                  ),
                );
              }
              showDialog<Map<String, dynamic>?>(
                context: context,
                builder: (BuildContext ctx) {
                  var totalApps =
                      existingUpdateIdsAllOrSelected.length +
                      newInstallIdsAllOrSelected.length +
                      trackOnlyUpdateIdsAllOrSelected.length;
                  return GeneratedFormModal(
                    title: tr(
                      'changeX',
                      args: [plural('apps', totalApps).toLowerCase()],
                    ),
                    items: formItems.map((e) => [e]).toList(),
                    initValid: true,
                  );
                },
              ).then((values) async {
                if (values != null) {
                  if (values.isEmpty) {
                    values = getDefaultValuesFromFormItems([formItems]);
                  }
                  bool shouldInstallUpdates = values['updates'] == true;
                  bool shouldInstallNew = values['installs'] == true;
                  bool shouldMarkTrackOnlies = values['trackonlies'] == true;
                  List<String> toInstall = [];
                  if (shouldInstallUpdates) {
                    toInstall.addAll(existingUpdateIdsAllOrSelected);
                  }
                  if (shouldInstallNew) {
                    toInstall.addAll(newInstallIdsAllOrSelected);
                  }
                  if (shouldMarkTrackOnlies) {
                    toInstall.addAll(trackOnlyUpdateIdsAllOrSelected);
                  }
                  appsProvider
                      .downloadAndInstallLatestApps(
                        toInstall,
                        globalNavigatorKey.currentContext,
                      )
                      .catchError((e) {
                        showError(e, context);
                        return <String>[];
                      })
                      .then((value) {
                        if (value.isNotEmpty && shouldInstallUpdates) {
                          showMessage(tr('appsUpdated'), context);
                        }
                      });
                }
              });
            };
    }

    launchCategorizeDialog() {
      return () async {
        try {
          Set<String>? preselected;
          var showPrompt = false;
          for (var element in selectedApps) {
            var currentCats = element.categories.toSet();
            if (preselected == null) {
              preselected = currentCats;
            } else {
              if (!settingsProvider.setEqual(currentCats, preselected)) {
                showPrompt = true;
                break;
              }
            }
          }
          var cont = true;
          if (showPrompt) {
            cont =
                await showDialog<Map<String, dynamic>?>(
                  context: context,
                  builder: (BuildContext ctx) {
                    return GeneratedFormModal(
                      title: tr('categorize'),
                      items: const [],
                      initValid: true,
                      message: tr('selectedCategorizeWarning'),
                    );
                  },
                ) !=
                null;
          }
          if (cont) {
            // ignore: use_build_context_synchronously
            await showDialog<Map<String, dynamic>?>(
              context: context,
              builder: (BuildContext ctx) {
                return GeneratedFormModal(
                  title: tr('categorize'),
                  items: const [],
                  initValid: true,
                  singleNullReturnButton: tr('continue'),
                  additionalWidgets: [
                    CategoryEditorSelector(
                      preselected: !showPrompt ? preselected ?? {} : {},
                      showLabelWhenNotEmpty: false,
                      onSelected: (categories) {
                        appsProvider.saveApps(
                          selectedApps.map((e) {
                            e.categories = categories;
                            return e;
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          }
        } catch (err) {
          showError(err, context);
        }
      };
    }

    showMassMarkDialog() {
      return showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text(
              tr(
                'markXSelectedAppsAsUpdated',
                args: [selectedAppIds.length.toString()],
              ),
            ),
            content: Text(
              tr('onlyWorksWithNonVersionDetectApps'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(tr('no')),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  appsProvider.saveApps(
                    selectedApps.map((a) {
                      if (a.installedVersion != null &&
                          !appsProvider.isVersionDetectionPossible(
                            appsProvider.apps[a.id],
                          )) {
                        a.installedVersion = a.latestVersion;
                      }
                      return a;
                    }).toList(),
                  );

                  Navigator.of(context).pop();
                },
                child: Text(tr('yes')),
              ),
            ],
          );
        },
      ).whenComplete(() {
        Navigator.of(context).pop();
      });
    }

    pinSelectedApps() {
      var pinStatus = selectedApps.where((element) => element.pinned).isEmpty;
      appsProvider.saveApps(
        selectedApps.map((e) {
          e.pinned = pinStatus;
          return e;
        }).toList(),
      );
      Navigator.of(context).pop();
    }

    showMoreOptionsDialog() {
      return showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            scrollable: true,
            content: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: pinSelectedApps,
                    child: Text(
                      selectedApps.where((element) => element.pinned).isEmpty
                          ? tr('pinToTop')
                          : tr('unpinFromTop'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
                  TextButton(
                    onPressed: () {
                      String urls = '';
                      for (var a in selectedApps) {
                        urls += '${a.url}\n';
                      }
                      urls = urls.substring(0, urls.length - 1);
                      Share.share(
                        urls,
                        subject: 'Obtainium - ${tr('appsString')}',
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      tr('shareSelectedAppURLs'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
                  TextButton(
                    onPressed: selectedAppIds.isEmpty
                        ? null
                        : () {
                            String urls = '';
                            for (var a in selectedApps) {
                              urls +=
                                  'https://apps.obtainium.imranr.dev/redirect?r=obtainium://app/${Uri.encodeComponent(jsonEncode({'id': a.id, 'url': a.url, 'author': a.author, 'name': a.name, 'preferredApkIndex': a.preferredApkIndex, 'additionalSettings': jsonEncode(a.additionalSettings), 'overrideSource': a.overrideSource}))}\n\n';
                            }
                            Share.share(
                              urls,
                              subject: 'Obtainium - ${tr('appsString')}',
                            );
                          },
                    child: Text(
                      tr('shareAppConfigLinks'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
                  TextButton(
                    onPressed: selectedAppIds.isEmpty
                        ? null
                        : () {
                            var encoder = const JsonEncoder.withIndent("    ");
                            var exportJSON = encoder.convert(
                              appsProvider.generateExportJSON(
                                appIds: selectedApps.map((e) => e.id).toList(),
                                overrideExportSettings: 0,
                              ),
                            );
                            String fn =
                                '${tr('obtainiumExportHyphenatedLowercase')}-${DateTime.now().toIso8601String().replaceAll(':', '-')}-count-${selectedApps.length}';
                            XFile f = XFile.fromData(
                              Uint8List.fromList(utf8.encode(exportJSON)),
                              mimeType: 'application/json',
                              name: fn,
                            );
                            Share.shareXFiles(
                              [f],
                              fileNameOverrides: ['$fn.json'],
                            );
                          },
                    child: Text(
                      '${tr('share')} - ${tr('obtainiumExport')}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
                  TextButton(
                    onPressed: () {
                      appsProvider
                          .downloadAppAssets(
                            selectedApps.map((e) => e.id).toList(),
                            globalNavigatorKey.currentContext ?? context,
                          )
                          .catchError(
                            // ignore: invalid_return_type_for_catch_error
                            (e) => showError(
                              e,
                              globalNavigatorKey.currentContext ?? context,
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      tr(
                        'downloadX',
                        args: [lowerCaseIfEnglish(tr('releaseAsset'))],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
                  TextButton(
                    onPressed: appsProvider.areDownloadsRunning()
                        ? null
                        : showMassMarkDialog,
                    child: Text(
                      tr('markSelectedAppsUpdated'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    showSortDialog() async {
      HapticFeedback.lightImpact();
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(tr('sort')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<AppSortMethod>(
                      title: const Text('Default'),
                      value: AppSortMethod.defaultSort,
                      groupValue: settingsProvider.appSortMethod,
                      onChanged: (AppSortMethod? value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.appSortMethod = value;
                          });
                          setDialogState(() {});
                        }
                      },
                    ),
                    RadioListTile<AppSortMethod>(
                      title: const Text('Latest Updates'),
                      value: AppSortMethod.latestUpdates,
                      groupValue: settingsProvider.appSortMethod,
                      onChanged: (AppSortMethod? value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.appSortMethod = value;
                          });
                          setDialogState(() {});
                        }
                      },
                    ),
                    RadioListTile<AppSortMethod>(
                      title: const Text('A-Z'),
                      value: AppSortMethod.nameAZ,
                      groupValue: settingsProvider.appSortMethod,
                      onChanged: (AppSortMethod? value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.appSortMethod = value;
                          });
                          setDialogState(() {});
                        }
                      },
                    ),
                    RadioListTile<AppSortMethod>(
                      title: const Text('Z-A'),
                      value: AppSortMethod.nameZA,
                      groupValue: settingsProvider.appSortMethod,
                      onChanged: (AppSortMethod? value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.appSortMethod = value;
                          });
                          setDialogState(() {});
                        }
                      },
                    ),
                    RadioListTile<AppSortMethod>(
                      title: const Text('Recently Added'),
                      value: AppSortMethod.recentlyAdded,
                      groupValue: settingsProvider.appSortMethod,
                      onChanged: (AppSortMethod? value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.appSortMethod = value;
                          });
                          setDialogState(() {});
                        }
                      },
                    ),
                    RadioListTile<AppSortMethod>(
                      title: const Text('Install Status'),
                      value: AppSortMethod.installStatus,
                      groupValue: settingsProvider.appSortMethod,
                      onChanged: (AppSortMethod? value) {
                        if (value != null) {
                          setState(() {
                            settingsProvider.appSortMethod = value;
                          });
                          setDialogState(() {});
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(tr('close')),
                  ),
                ],
              );
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            ),
          );
        },
      );
    }

    getMainBottomButtons() {
      return [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {
            HapticFeedback.lightImpact();
            showSortDialog();
          },
          tooltip: tr('sort'),
          icon: const Icon(Icons.sort),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: getMassObtainFunction() != null
              ? () {
                  HapticFeedback.mediumImpact();
                  getMassObtainFunction()!();
                }
              : null,
          tooltip: selectedAppIds.isEmpty
              ? tr('installUpdateApps')
              : tr('installUpdateSelectedApps'),
          icon: const Icon(Icons.file_download_outlined),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: selectedAppIds.isEmpty
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  appsProvider.removeAppsWithModal(
                    context,
                    selectedApps.toList(),
                  );
                },
          tooltip: tr('removeSelectedApps'),
          icon: const Icon(Icons.delete_outline_outlined),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: selectedAppIds.isEmpty
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  launchCategorizeDialog()!();
                },
          tooltip: tr('categorize'),
          icon: const Icon(Icons.category_outlined),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: selectedAppIds.isEmpty
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  showMoreOptionsDialog();
                },
          tooltip: tr('more'),
          icon: const Icon(Icons.more_horiz),
        ),
      ];
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
                GeneratedFormTextField(
                  'appName',
                  label: tr('appName'),
                  required: false,
                  defaultValue: vals['appName'],
                ),
                GeneratedFormTextField(
                  'author',
                  label: tr('author'),
                  required: false,
                  defaultValue: vals['author'],
                ),
              ],
              [
                GeneratedFormTextField(
                  'appId',
                  label: tr('appId'),
                  required: false,
                  defaultValue: vals['appId'],
                ),
              ],
              [
                GeneratedFormSwitch(
                  'upToDateApps',
                  label: tr('upToDateApps'),
                  defaultValue: vals['upToDateApps'],
                ),
              ],
              [
                GeneratedFormSwitch(
                  'nonInstalledApps',
                  label: tr('nonInstalledApps'),
                  defaultValue: vals['nonInstalledApps'],
                ),
              ],
              [
                GeneratedFormDropdown(
                  'sourceFilter',
                  label: tr('appSource'),
                  defaultValue: filter.sourceFilter,
                  [
                    MapEntry('', tr('none')),
                    ...sourceProvider.sources.map(
                      (e) => MapEntry(e.runtimeType.toString(), e.name),
                    ),
                  ],
                ),
              ],
            ],
            additionalWidgets: [
              const SizedBox(height: 16),
              CategoryEditorSelector(
                preselected: filter.categoryFilter,
                onSelected: (categories) {
                  filter.categoryFilter = categories.toSet();
                },
              ),
            ],
          );
        },
      );
      if (values != null) {
        setState(() {
          filter.setFormValuesFromMap(values);
        });
      }
    }

    getFilterButtonsRow() {
      var isFilterOff = filter.isIdenticalTo(neutralFilter, settingsProvider);
      return Row(
        children: [
          getSelectAllButton(),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            tooltip: isFilterOff
                ? tr('filterApps')
                : '${tr('filter')} - ${tr('remove')}',
            onPressed: isFilterOff
                ? showFilterDialog
                : () {
                    setState(() {
                      filter = AppsFilter();
                    });
                  },
            icon: Icon(
              isFilterOff ? Icons.search_rounded : Icons.search_off_rounded,
            ),
          ),
          const SizedBox(width: 10),
          const VerticalDivider(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: getMainBottomButtons(),
            ),
          ),
        ],
      );
    }

    int _calculateAdaptiveColumns(BuildContext context) {
      final width = MediaQuery.of(context).size.width;
      if (width >= 1200) return 6;
      if (width >= 900) return 5;
      if (width >= 600) return 4;
      if (width >= 400) return 3;
      return 2;
    }

    Widget getGridView(List<AppInMemory> apps) {
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

    Widget getCategoryGridSection(int index) {
      capFirstChar(String str) => str[0].toUpperCase() + str.substring(1);

      var categoryName = listedCategories[index];
      var categoryColorInt =
          categoryName != null ? settingsProvider.categories[categoryName] : null;
      var categoryColor =
          categoryColorInt != null ? Color(categoryColorInt) : null;

      var appsInCategory = listedApps
          .where((e) =>
              e.app.categories.contains(categoryName) ||
              (e.app.categories.isEmpty && categoryName == null))
          .toList();

      final columnCount = settingsProvider.gridColumnCount == 0
          ? _calculateAdaptiveColumns(context)
          : settingsProvider.gridColumnCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, 0),
                end: const Alignment(-0.97, 0),
                colors: [
                  categoryColor ?? Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withAlpha(0),
                ],
                stops: const [0.99, 1],
              ),
            ),
            child: Row(
              children: [
                Text(
                  capFirstChar(categoryName ?? tr('noCategory')),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  appsInCategory.length.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Grid of apps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: appsInCategory.length,
              itemBuilder: (context, appIndex) {
                var app = appsInCategory[appIndex];
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
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    getDisplayedList() {
      final isGridView = settingsProvider.globalViewMode == ViewMode.grid;
      final showCategoriesInGrid = settingsProvider.groupByCategory &&
          settingsProvider.gridCategoryMode == GridCategoryMode.sections;

      if (settingsProvider.groupByCategory &&
          !(listedCategories.isEmpty ||
              (listedCategories.length == 1 && listedCategories[0] == null))) {
        // Has categories
        if (isGridView && showCategoriesInGrid) {
          // Grid with category sections
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return getCategoryGridSection(index);
              },
              childCount: listedCategories.length,
            ),
          );
        } else if (isGridView &&
            settingsProvider.gridCategoryMode == GridCategoryMode.disabled) {
          // Pure grid, ignore categories
          return getGridView(listedApps);
        } else {
          // List view with categories (existing)
          return SliverReorderableList(
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              return getCategoryCollapsibleTile(
                ValueKey(listedCategories[index] ?? 'null_category'),
                index,
              );
            },
            itemCount: listedCategories.length,
            onReorder: (int oldIndex, int newIndex) {
              // Update category order
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = listedCategories.removeAt(oldIndex);
              listedCategories.insert(newIndex, item);

              // Save the new order to settings
              settingsProvider.categoryOrder = listedCategories
                  .where((c) => c != null)
                  .map((c) => c!)
                  .toList();
            },
          );
        }
      } else {
        // No categories
        if (isGridView) {
          return getGridView(listedApps);
        } else {
          return SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              return getSingleAppHorizTile(index);
            }, childCount: listedApps.length),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: refresh,
        child: Scrollbar(
          interactive: true,
          controller: scrollController,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            slivers: <Widget>[
              CustomAppBar(
                title: tr('appsString'),
                actions: [
                  IconButton(
                    icon: Icon(
                      settingsProvider.globalViewMode == ViewMode.grid
                          ? Icons.view_list
                          : Icons.grid_view,
                    ),
                    tooltip: settingsProvider.globalViewMode == ViewMode.grid
                        ? tr('switchToListView')
                        : tr('switchToGridView'),
                    onPressed: () {
                      setState(() {
                        settingsProvider.globalViewMode =
                            settingsProvider.globalViewMode == ViewMode.grid
                                ? ViewMode.list
                                : ViewMode.grid;
                      });
                    },
                  ),
                ],
              ),
              ...getLoadingWidgets(),
              getDisplayedList(),
            ],
          ),
        ),
      ),
      persistentFooterButtons: appsProvider.apps.isEmpty
          ? null
          : [getFilterButtonsRow()],
    );
  }
}

class AppsFilter {
  late String nameFilter;
  late String authorFilter;
  late String idFilter;
  late bool includeUptodate;
  late bool includeNonInstalled;
  late Set<String> categoryFilter;
  late String sourceFilter;

  AppsFilter({
    this.nameFilter = '',
    this.authorFilter = '',
    this.idFilter = '',
    this.includeUptodate = true,
    this.includeNonInstalled = true,
    this.categoryFilter = const {},
    this.sourceFilter = '',
  });

  Map<String, dynamic> toFormValuesMap() {
    return {
      'appName': nameFilter,
      'author': authorFilter,
      'appId': idFilter,
      'upToDateApps': includeUptodate,
      'nonInstalledApps': includeNonInstalled,
      'sourceFilter': sourceFilter,
    };
  }

  void setFormValuesFromMap(Map<String, dynamic> values) {
    nameFilter = values['appName']!;
    authorFilter = values['author']!;
    idFilter = values['appId']!;
    includeUptodate = values['upToDateApps'];
    includeNonInstalled = values['nonInstalledApps'];
    sourceFilter = values['sourceFilter'];
  }

  bool isIdenticalTo(AppsFilter other, SettingsProvider settingsProvider) =>
      authorFilter.trim() == other.authorFilter.trim() &&
      nameFilter.trim() == other.nameFilter.trim() &&
      idFilter.trim() == other.idFilter.trim() &&
      includeUptodate == other.includeUptodate &&
      includeNonInstalled == other.includeNonInstalled &&
      settingsProvider.setEqual(categoryFilter, other.categoryFilter) &&
      sourceFilter.trim() == other.sourceFilter.trim();
}
