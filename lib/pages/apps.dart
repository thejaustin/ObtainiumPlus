import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/sideloading_notice.dart';
import 'package:obtainium/components/apps/app_actions_context_menu.dart';
import 'package:obtainium/components/apps/tag_filter_bar.dart';
import 'package:obtainium/components/apps/app_dashboard.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/components/search/command_center.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/generated_form_renderer.dart'
    show TvTextFieldFocus;
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/components/apps/active_operations_banner.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/apps/category_sections.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/components/ui_widgets.dart';

class AppsPage extends StatefulWidget {
  final AppsFilter? initialFilter;
  final int? initialTab;
  const AppsPage({super.key, this.initialFilter, this.initialTab});

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
              ? InkWell(
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
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: appSource.changeLogIfAnyIsMarkDown
                ? Markdown(
                    shrinkWrap: true,
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
                  )
                : SingleChildScrollView(child: Text(changeLog)),
          ),
        ],
        singleNullReturnButton: tr('ok'),
      );
    },
  );
}

Null Function()? getChangeLogFn(BuildContext context, App app) {
  String? changesUrl;
  String? changeLog = app.changeLog;
  if (changeLog?.split('\n').length == 1 &&
      RegExp(
        '(http|ftp|https)://([\\w_-]+(?:(?:\\.[\\w_-]+)+))([\\w.,@?^=%&:/~+#-]*[\\w@?^=%&/~+#-])?',
      ).hasMatch(changeLog!)) {
    changesUrl = changeLog;
    changeLog = null;
  }
  if (changeLog == null && changesUrl == null) return null;
  return () {
    var appSource = SourceProvider().getSource(
      app.url,
      overrideSource: app.overrideSource,
    );
    if (changesUrl == null) {
      changesUrl = appSource.changeLogPageFromStandardUrl(app.url);
    }
    if (changeLog != null) {
      showChangeLogDialog(context, app, changesUrl, appSource, changeLog);
    } else if (changesUrl != null) {
      launchUrlString(changesUrl!, mode: LaunchMode.externalApplication);
    }
  };
}

class AppsPageState extends State<AppsPage> {
  late AppsFilter filter = widget.initialFilter ?? AppsFilter();
  final AppsFilter neutralFilter = AppsFilter();
  var updatesOnlyFilter = AppsFilter(
    includeUptodate: false,
    includeNonInstalled: false,
  );
  Set<String> selectedAppIds = {};
  String? activeTag;
  DateTime? refreshingSince;

  /// Clears the current selection, if any. Returns whether there was a
  /// selection to clear, so callers (e.g. the system-back handler) can decide
  /// whether to treat the back gesture as "clear selection" or fall through
  /// to normal back-navigation behavior.
  bool clearSelected() {
    final hadSelection = selectedAppIds.isNotEmpty;
    setState(() {
      selectedAppIds.clear();
    });
    return hadSelection;
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
    final plusSettings = context.watch<PlusSettingsProvider>();
    final appsProvider = context.watch<AppsProvider>();

    if (appsProvider.apps.isEmpty && !appsProvider.loadingApps) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: EmptyStateWidget(
          title: tr('noApps'),
          subtitle: tr('onboardingAddAppsSubtitle'),
          icon: Icons.auto_awesome_rounded,
          actionLabel: tr('addApp'),
          onActionPressed: () {
            showAddAppSheet(context: context);
          },
        ),
      );
    }

    final settingsProvider = context.watch<SettingsProvider>();
    // Top nav (TabBar) and bottom nav both already provide their own
    // settings entry point (an AppBar gear icon or a Settings tab,
    // respectively) — showing this page's own gear too would give the
    // user two ways to reach Settings on screen at once.
    final hasExternalSettingsEntry =
        (plusSettings.plusTopUILayout && !settingsProvider.isTV) ||
        plusSettings.plusEnableBottomNavBar;
    final viewSettings = context.watch<ViewSettingsProvider>();
    final updateSettings = context.watch<UpdateSettingsProvider>();
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final listedAppsAll = appsProvider.getAppValues().toList();
    var listedApps = List<AppInMemory>.from(listedAppsAll);

    refresh() {
      AppHaptics.lightImpact();
      if (mounted) {
        setState(() {
          refreshingSince = DateTime.now();
        });
      }
      var refreshFailed = false;
      return appsProvider
          .checkUpdates()
          .catchError((e) {
            refreshFailed = true;
            if (context.mounted) showError(e is Map ? e['errors'] : e, context);
            return <App>[];
          })
          .whenComplete(() {
            if (refreshFailed) {
              AppHaptics.heavyImpact();
            } else {
              AppHaptics.lightImpact();
            }
            if (mounted) {
              setState(() {
                refreshingSince = null;
              });
            }
          });
    }

    if (!appsProvider.loadingApps &&
        appsProvider.apps.isNotEmpty &&
        settingsProvider.checkJustStarted() &&
        updateSettings.checkOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshIndicatorKey.currentState?.show();
      });
    }

    var listedAppIdSet = listedApps.map((e) => e.app.id).toSet();
    selectedAppIds = selectedAppIds.where(listedAppIdSet.contains).toSet();

    toggleAppSelected(App app) {
      setState(() {
        if (selectedAppIds.contains(app.id)) {
          selectedAppIds.remove(app.id);
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
      if (activeTag != null && !app.app.tags.contains(activeTag)) {
        return false;
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

    listedApps.sort((a, b) {
      int result = 0;
      if (viewSettings.sortColumn == SortColumnSettings.authorName) {
        result = ((a.author + a.name).toLowerCase()).compareTo(
          (b.author + b.name).toLowerCase(),
        );
      } else if (viewSettings.sortColumn == SortColumnSettings.nameAuthor) {
        result = ((a.name + a.author).toLowerCase()).compareTo(
          (b.name + b.author).toLowerCase(),
        );
      } else if (viewSettings.sortColumn == SortColumnSettings.releaseDate) {
        // Handle null dates: apps with unknown release dates are grouped at the end
        final aDate = a.app.releaseDate;
        final bDate = b.app.releaseDate;
        final isDescending =
            viewSettings.sortOrder == SortOrderSettings.descending;
        if (aDate == null && bDate == null) {
          // Both null: sort by name for consistency
          result = ((a.name + a.author).toLowerCase()).compareTo(
            (b.name + b.author).toLowerCase(),
          );
        } else if (aDate == null) {
          // a has no date, always push to end regardless of sort direction
          result = isDescending ? -1 : 1;
        } else if (bDate == null) {
          // b has no date, always push to end regardless of sort direction
          result = isDescending ? 1 : -1;
        } else {
          result = aDate.compareTo(bDate);
        }
      }
      return result;
    });

    if (viewSettings.sortOrder == SortOrderSettings.descending) {
      listedApps = listedApps.reversed.toList();
    }

    var existingUpdates = appsProvider.findExistingUpdates(installedOnly: true);

    var existingUpdateIdsAllOrSelected = existingUpdates
        .where(
          (element) => selectedAppIds.isEmpty
              ? listedAppIdSet.contains(element)
              : selectedAppIds.contains(element),
        )
        .toList();
    var newInstallIdsAllOrSelected = appsProvider
        .findExistingUpdates(nonInstalledOnly: true)
        .where(
          (element) => selectedAppIds.isEmpty
              ? listedAppIdSet.contains(element)
              : selectedAppIds.contains(element),
        )
        .toList();

    List<String> trackOnlyUpdateIdsAllOrSelected = [];
    bool isNotTrackOnly(String id) {
      final app = appsProvider.apps[id];
      if (app != null && app.app.additionalSettings['trackOnly'] == true) {
        trackOnlyUpdateIdsAllOrSelected.add(id);
        return false;
      }
      return true;
    }

    existingUpdateIdsAllOrSelected = existingUpdateIdsAllOrSelected
        .where(isNotTrackOnly)
        .toList();
    newInstallIdsAllOrSelected = newInstallIdsAllOrSelected
        .where(isNotTrackOnly)
        .toList();

    if (viewSettings.pinUpdates) {
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

    if (viewSettings.buryNonInstalled) {
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

    var tempRenamed = [];
    var tempPinned = [];
    var tempNotPinned = [];
    for (var a in listedApps) {
      if (a.app.hasPendingRepoRename) {
        tempRenamed.add(a);
      } else if (a.app.pinned) {
        tempPinned.add(a);
      } else {
        tempNotPinned.add(a);
      }
    }
    listedApps = [...tempRenamed, ...tempPinned, ...tempNotPinned];

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
    listedCategories.sort((a, b) {
      return a != null && b != null
          ? a.toLowerCase().compareTo(b.toLowerCase())
          : a == null
          ? 1
          : -1;
    });

    Set<App> selectedApps = listedApps
        .map((e) => e.app)
        .where((a) => selectedAppIds.contains(a.id))
        .toSet();

    getLoadingWidgets() {
      return [
        if (listedApps.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Icon(
                              appsProvider.apps.isEmpty &&
                                      !appsProvider.loadingApps
                                  ? Icons.apps_outage_rounded
                                  : appsProvider.loadingApps
                                  ? Icons.hourglass_empty_rounded
                                  : Icons.search_off_rounded,
                              size: 80,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      appsProvider.apps.isEmpty
                          ? appsProvider.loadingApps
                                ? tr('pleaseWait')
                                : tr('noApps')
                          : tr('noAppsForFilter'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (appsProvider.apps.isEmpty &&
                        !appsProvider.loadingApps) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Tap the + button to add your first app',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (filter.nameFilter.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          AppHaptics.selectionClick();
                          CommandCenter.show(
                            context,
                            initialQuery: filter.nameFilter,
                          );
                        },
                        icon: const Icon(Icons.travel_explore_rounded),
                        label: Text(
                          '${tr('search')} "${filter.nameFilter}"',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (refreshingSince != null || appsProvider.loadingApps)
          SliverToBoxAdapter(
            child: ExpressiveProgressIndicator(
              value: appsProvider.loadingApps
                  ? null
                  : appsProvider.apps.values
                            .where(
                              (element) =>
                                  !(element.app.lastUpdateCheck?.isBefore(
                                        refreshingSince ?? DateTime.now(),
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
                    .then((res) {
                      if (res.isNotEmpty) {
                        var np = context.read<NotificationsProvider>();
                        np.cancel(UpdateNotification([]).id);
                        np.cancel(
                          SilentUpdateAttemptNotification(
                            [],
                            id: res[0].hashCode,
                          ).id,
                        );
                      }
                    })
                    .catchError((e) {
                      if (context.mounted) showError(e, context);
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

    getVersionText(int appIndex) {
      var installed = listedApps[appIndex].app.installedVersion;
      var latest = listedApps[appIndex].app.latestVersion;
      if (installed != null && installed != latest) {
        return '$installed → $latest';
      }
      return installed ?? tr('notInstalled');
    }

    getChangesButtonString(int appIndex, bool hasChangeLogFn) {
      final releaseDate = listedApps[appIndex].app.releaseDate;
      return releaseDate == null
          ? (hasChangeLogFn ? tr('changes') : '')
          : DateFormat('yyyy-MM-dd').format(releaseDate.toLocal());
    }

    Widget buildAuthorText(int appIndex) {
      return Text(
        tr('byX', args: [listedApps[appIndex].author]),
        maxLines: 1,
        style: TextStyle(
          overflow: TextOverflow.ellipsis,
          fontWeight: listedApps[appIndex].app.pinned
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      );
    }

    Widget buildRepoMovedRow() {
      final colorScheme = Theme.of(context).colorScheme;
      final infoColor = colorScheme.primary.withValues(alpha: 0.7);
      final textColor = colorScheme.onSurfaceVariant;
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: infoColor, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                tr('repoRenamed'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    getSingleAppHorizTile(int index) {
      var showChangesFn = getChangeLogFn(context, listedApps[index].app);
      var trackOnly =
          listedApps[index].app.additionalSettings['trackOnly'] == true;
      var hasUpdate =
          listedApps[index].app.installedVersion != null &&
          listedApps[index].app.installedVersion !=
              listedApps[index].app.latestVersion;
      // Also show the install button for uninstalled, non-track-only apps
      var needsInstall =
          !trackOnly && listedApps[index].app.installedVersion == null;
      Widget trailingRow = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (hasUpdate || needsInstall)
              ? getUpdateButton(index)
              : const SizedBox.shrink(),
          (hasUpdate || needsInstall)
              ? const SizedBox(width: 5)
              : const SizedBox.shrink(),
          InkWell(
            onTap: showChangesFn,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  (plusSettings.plusGlobalCornerRadius * 0.6).clamp(8.0, 20.0),
                ),
                color:
                    behaviorSettings.highlightTouchTargets &&
                        showChangesFn != null
                    ? (Theme.of(context).brightness == Brightness.light
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).primaryColorLight)
                          .withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.light
                                ? 20 / 255
                                : 40 / 255,
                          )
                    : null,
              ),
              padding: behaviorSettings.highlightTouchTargets
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
      ).colorScheme.surface.withValues(alpha: 0).value;
      var categories = listedApps[index].app.categories;
      List<double> stops = [
        if (categories.isNotEmpty)
          ...categories.asMap().entries.map(
            (e) => ((e.key / (categories.length - 1)) - 0.0001),
          ),
        1,
      ];
      if (stops.length == 2) {
        stops[0] = 0.9999;
      }
      return Container(
        decoration: BoxDecoration(
          gradient: categories.isEmpty
              ? null
              : LinearGradient(
                  stops: stops,
                  begin: const Alignment(-1, 0),
                  end: const Alignment(-0.97, 0),
                  colors: [
                    ...categories.map(
                      (e) => Color(
                        viewSettings.categories[e] ?? transparent,
                      ).withValues(alpha: 1),
                    ),
                    Color(transparent),
                  ],
                ),
        ),
        child: ListTile(
          autofocus: index == 0 && settingsProvider.isTV,
          tileColor: listedApps[index].app.pinned
              ? Colors.grey.withValues(alpha: 0.1)
              : Colors.transparent,
          selectedTileColor: Theme.of(context).colorScheme.primary.withValues(
            alpha: listedApps[index].app.pinned ? 0.2 : 0.1,
          ),
          selected: selectedAppIds.contains(listedApps[index].app.id),
          onLongPress: () {
            if (selectedAppIds.isNotEmpty) {
              AppHaptics.selectionClick();
              toggleAppSelected(listedApps[index].app);
            } else {
              AppHaptics.heavyImpact();
              AppActionsContextMenu.show(
                context,
                listedApps[index],
                onEnterMultiSelect: () {
                  toggleAppSelected(listedApps[index].app);
                },
              );
            }
          },
          leading: (settingsProvider.isTV)
              ? Checkbox(
                  value: selectedAppIds.contains(listedApps[index].app.id),
                  onChanged: (_) {
                    toggleAppSelected(listedApps[index].app);
                  },
                )
              : AppIconWidget(
                  appId: listedApps[index].app.id,
                  installed: listedApps[index].installedInfo != null,
                  appsProvider: appsProvider,
                ),
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
          subtitle: listedApps[index].app.hasPendingRepoRename
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [buildAuthorText(index), buildRepoMovedRow()],
                )
              : buildAuthorText(index),
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
          onTap: () {
            if (selectedAppIds.isNotEmpty) {
              toggleAppSelected(listedApps[index].app);
            } else {
              AppHaptics.selectionClick();
              showDraggableModalBottomSheet(
                context: context,
                builder: (context, controller) => AppPage(
                  appId: listedApps[index].app.id,
                  isModal: true,
                  scrollController: controller,
                ),
              );
            }
          },
        ),
      );
    }

    getCategoryCollapsibleTile(int index) {
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
      return ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          capFirstChar(listedCategories[index] ?? tr('noCategory')),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        trailing: Text(tiles.length.toString()),
        children: tiles,
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
              AppHaptics.heavyImpact();
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
                      .then((value) {
                        if (value.isNotEmpty) {
                          if (shouldInstallUpdates && context.mounted) {
                            showMessage(tr('appsUpdated'), context);
                          }
                          var np = context.read<NotificationsProvider>();
                          np.cancel(UpdateNotification([]).id);
                        }
                      })
                      .catchError((e) {
                        if (e is MultiAppMultiError &&
                            e.successfulAppIds.isNotEmpty) {
                          final count = e.successfulAppIds.length;
                          final failedCount = e.idsByErrorString.values
                              .fold<int>(0, (acc, list) => acc + list.length);
                          if (shouldInstallUpdates && context.mounted) {
                            showMessage(
                              '$count apps updated ($failedCount failed)',
                              context,
                            );
                          }
                          var np = context.read<NotificationsProvider>();
                          np.cancel(UpdateNotification([]).id);
                        }
                        if (context.mounted) showError(e, context);
                        return <String>[];
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
          if (!context.mounted) return;
          if (cont) {
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
          if (context.mounted) showError(err, context);
        }
      };
    }

    showMassMarkDialog() {
      return showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return GlassDialog(
            title: tr(
              'markXSelectedAppsAsUpdated',
              args: [selectedAppIds.length.toString()],
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
                  AppHaptics.selectionClick();
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
        if (context.mounted) Navigator.of(context).pop();
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
          return GlassDialog(
            title: tr('moreOptions'),
            icon: Icons.more_vert_rounded,
            content: Column(
              mainAxisSize: MainAxisSize.min,
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
                                'https://apps.obtainium.page/redirect?r=obtainium://app/${Uri.encodeComponent(jsonEncode({'id': a.id, 'url': a.url, 'author': a.author, 'name': a.name, 'preferredApkIndex': a.preferredApkIndex, 'additionalSettings': safeJsonEncode(a.additionalSettings), 'overrideSource': a.overrideSource}))}\n\n';
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
          );
        },
      );
    }

    getMainBottomButtons() {
      return [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: getMassObtainFunction(),
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
          onPressed: selectedAppIds.isEmpty ? null : launchCategorizeDialog(),
          tooltip: tr('categorize'),
          icon: const Icon(Icons.category_outlined),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: selectedAppIds.isEmpty ? null : showMoreOptionsDialog,
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
      final isGrid = viewSettings.globalViewMode == ViewMode.grid;
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
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            tooltip: isGrid ? tr('listView') : tr('gridView'),
            onPressed: () {
              viewSettings.globalViewMode = isGrid
                  ? ViewMode.list
                  : ViewMode.grid;
            },
            icon: Icon(
              isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
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

    getDisplayedList() {
      final isGrid = viewSettings.globalViewMode == ViewMode.grid;

      if (viewSettings.groupByCategory &&
          !(listedCategories.isEmpty ||
              (listedCategories.length == 1 && listedCategories[0] == null))) {
        return CategorySections(
          listedApps: listedApps,
          listedCategories: listedCategories,
          selectedAppIds: selectedAppIds,
          toggleAppSelected: toggleAppSelected,
          onAppTap: (app) {
            AppHaptics.selectionClick();
            showDraggableModalBottomSheet(
              context: context,
              builder: (context, controller) => AppPage(
                appId: app.id,
                isModal: true,
                scrollController: controller,
              ),
            );
          },
          getChangeLogFn: getChangeLogFn,
          getCachedCategoryColor: (colorVal) => Color(colorVal),
        );
      }

      if (isGrid) {
        final width = MediaQuery.of(context).size.width;
        final columnCount = viewSettings.gridColumnCount != 0
            ? viewSettings.gridColumnCount
            : width >= 600
            ? 4
            : width >= 400
            ? 3
            : 2;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((ctx, index) {
              final app = listedApps[index];
              return AppGridTile(
                appInMemory: app,
                isSelected: selectedAppIds.contains(app.app.id),
                hasUpdate: existingUpdates.contains(app.app.id),
                onTap: () {
                  if (selectedAppIds.isNotEmpty) {
                    toggleAppSelected(app.app);
                  } else {
                    AppHaptics.selectionClick();
                    showDraggableModalBottomSheet(
                      context: context,
                      builder: (context, controller) => AppPage(
                        appId: app.app.id,
                        isModal: true,
                        scrollController: controller,
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (selectedAppIds.isNotEmpty) {
                    AppHaptics.selectionClick();
                    toggleAppSelected(app.app);
                  } else {
                    AppHaptics.heavyImpact();
                    AppActionsContextMenu.show(
                      context,
                      app,
                      onEnterMultiSelect: () {
                        toggleAppSelected(app.app);
                      },
                    );
                  }
                },
              );
            }, childCount: listedApps.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          return getSingleAppHorizTile(index);
        }, childCount: listedApps.length),
      );
    }

    return PopScope(
      canPop: selectedAppIds.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          clearSelected();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: refresh,
          child: Scrollbar(
            interactive: true,
            controller: scrollController,
            child: CustomScrollView(
              physics: plusSettings.scrollPhysics,
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: <Widget>[
                settingsProvider.getAppBarStyleForPage('apps') ==
                        AppBarStyle.large
                    ? SliverAppBar.large(
                        automaticallyImplyLeading: false,
                        actions: [
                          // The dashboard layout has its own always-visible
                          // Omnibar; without it, this is the only reachable
                          // search entry point on the Apps screen.
                          if (plusSettings.plusShowAppBarSearch &&
                              !plusSettings.plusEnableHomeDashboard)
                            IconButton(
                              icon: const Icon(Icons.search_rounded),
                              tooltip: tr('search'),
                              onPressed: () {
                                AppHaptics.selectionClick();
                                CommandCenter.show(context);
                              },
                            ),
                          if (!plusSettings.plusEnableFAB)
                            // A single InkWell handles tap+long-press on
                            // one recognizer — nesting IconButton's own
                            // tap recognizer inside an outer
                            // GestureDetector(onLongPress:) put two
                            // recognizers in the same arena and could
                            // delay/suppress the plain tap.
                            Tooltip(
                              message: tr('moreAddOptionsHint'),
                              child: InkResponse(
                                radius: 24,
                                onTap: () {
                                  AppHaptics.selectionClick();
                                  CommandCenter.show(context);
                                },
                                onLongPress: () {
                                  AppHaptics.heavyImpact();
                                  AppActionsFAB.showAddAppMenu(context);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.add_rounded),
                                ),
                              ),
                            ),
                          if (!hasExternalSettingsEntry)
                            IconButton(
                              icon: const Icon(Icons.settings_rounded),
                              tooltip: tr('settings'),
                              onPressed: () {
                                AppHaptics.selectionClick();
                                pushRoute(context, const SettingsPage());
                              },
                            ),
                        ],
                        title: Text(
                          tr('appsString'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : CustomAppBar(
                        title: tr('appsString'),
                        actions: [
                          if (plusSettings.plusShowAppBarSearch &&
                              !plusSettings.plusEnableHomeDashboard)
                            IconButton(
                              icon: const Icon(Icons.search_rounded),
                              tooltip: tr('search'),
                              onPressed: () {
                                AppHaptics.selectionClick();
                                CommandCenter.show(context);
                              },
                            ),
                          if (!plusSettings.plusEnableFAB)
                            // A single InkWell handles tap+long-press on
                            // one recognizer — nesting IconButton's own
                            // tap recognizer inside an outer
                            // GestureDetector(onLongPress:) put two
                            // recognizers in the same arena and could
                            // delay/suppress the plain tap.
                            Tooltip(
                              message: tr('moreAddOptionsHint'),
                              child: InkResponse(
                                radius: 24,
                                onTap: () {
                                  AppHaptics.selectionClick();
                                  CommandCenter.show(context);
                                },
                                onLongPress: () {
                                  AppHaptics.heavyImpact();
                                  AppActionsFAB.showAddAppMenu(context);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.add_rounded),
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              viewSettings.globalViewMode == ViewMode.grid
                                  ? Icons.view_list_rounded
                                  : Icons.grid_view_rounded,
                            ),
                            tooltip: viewSettings.globalViewMode == ViewMode.grid
                                ? tr('listView')
                                : tr('gridView'),
                            onPressed: () {
                              AppHaptics.selectionClick();
                              setState(() {
                                viewSettings.globalViewMode =
                                    viewSettings.globalViewMode == ViewMode.grid
                                        ? ViewMode.list
                                        : ViewMode.grid;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              filter.isIdenticalTo(neutralFilter, settingsProvider)
                                  ? Icons.filter_list_rounded
                                  : Icons.filter_list_off_rounded,
                              color: filter.isIdenticalTo(neutralFilter, settingsProvider)
                                  ? null
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: filter.isIdenticalTo(neutralFilter, settingsProvider)
                                ? tr('filterApps')
                                : '${tr('filter')} - ${tr('remove')}',
                            onPressed: () {
                              AppHaptics.selectionClick();
                              if (filter.isIdenticalTo(neutralFilter, settingsProvider)) {
                                showFilterDialog();
                              } else {
                                setState(() {
                                  filter = AppsFilter();
                                });
                              }
                            },
                          ),
                          if (!hasExternalSettingsEntry)
                            IconButton(
                              icon: const Icon(Icons.settings_rounded),
                              tooltip: tr('settings'),
                              onPressed: () {
                                AppHaptics.selectionClick();
                                pushRoute(context, const SettingsPage());
                              },
                            ),
                        ],
                      ),
                const SliverToBoxAdapter(child: SideloadingNotice()),
                if (plusSettings.plusEnableHomeDashboard)
                  SliverToBoxAdapter(
                    child: AppDashboard(
                      currentFilterMode: filter.statusFilter.isEmpty
                          ? 'all'
                          : filter.statusFilter.first,
                      onFilterChanged: (newFilter) {
                        setState(() {
                          if (newFilter == 'all') {
                            filter.statusFilter = {};
                          } else {
                            filter.statusFilter = {newFilter};
                          }
                        });
                      },
                      onSearchQuery: (query) {
                        setState(() {
                          filter.nameFilter = query;
                        });
                      },
                      onUrlInput: (url) {
                        context.read<AppsProvider>().addAppsByURL([
                          url,
                        ]).then((errors) {
                          if (!context.mounted) return;
                          if (errors.isNotEmpty) {
                            showError(errors[0][1], context);
                          } else {
                            showMessage(tr('appAdded'), context);
                          }
                        });
                      },
                      onCheckUpdates: refresh,
                    ),
                  ),
                const SliverToBoxAdapter(child: ActiveOperationsBanner()),
                if (plusSettings.plusEnableTags)
                  TagFilterBar(
                    activeTag: activeTag,
                    onTagSelected: (tag) {
                      AppHaptics.selectionClick();
                      setState(() {
                        activeTag = tag;
                      });
                    },
                  ),
                ...getLoadingWidgets(),
                getDisplayedList(),
              ],
            ),
          ),
        ),
        persistentFooterButtons: appsProvider.apps.isEmpty ||
                (plusSettings.plusEnableBottomNavBar && selectedAppIds.isEmpty)
            ? null
            : [getFilterButtonsRow()],
      ),
    );
  }

  void openAppById(String appId) {
    AppsProvider appsProvider = context.read<AppsProvider>();

    AppInMemory? app = appsProvider.apps[appId];

    // Should exist, since we just looked it up, but just in case...
    if (app == null) {
      return;
    }

    AppHaptics.selectionClick();
    showDraggableModalBottomSheet(
      context: context,
      builder: (context, controller) => AppPage(
        appId: app.app.id,
        isModal: true,
        scrollController: controller,
      ),
    );
  }
}

class AppIconWidget extends StatefulWidget {
  final String appId;
  final bool installed;
  final AppsProvider appsProvider;

  const AppIconWidget({
    super.key,
    required this.appId,
    required this.installed,
    required this.appsProvider,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  late final Future<void> _iconFuture;

  @override
  void initState() {
    super.initState();
    _iconFuture = widget.appsProvider.updateAppIcon(widget.appId);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: FutureBuilder(
        future: _iconFuture,
        builder: (ctx, val) {
          var icon = widget.appsProvider.apps[widget.appId]?.icon;
          return icon != null
              ? SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.memory(
                    icon,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    fit: BoxFit.contain,
                    opacity: AlwaysStoppedAnimation(widget.installed ? 1 : 0.6),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.3),
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
        pm.openApp(widget.appId);
      },
      onLongPress: () {
        AppHaptics.selectionClick();
        showDraggableModalBottomSheet(
          context: context,
          builder: (context, controller) => AppPage(
            appId: widget.appId,
            showOppositeOfPreferredView: true,
            isModal: true,
            scrollController: controller,
          ),
        );
      },
    );
  }
}

class _RefreshProgressBar extends StatelessWidget {
  const _RefreshProgressBar();

  @override
  Widget build(BuildContext context) {
    final progressNotifier = context.read<AppsProvider>().refreshProgress;
    return ValueListenableBuilder<double?>(
      valueListenable: progressNotifier,
      builder: (context, refreshProgress, _) {
        if (refreshProgress == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
            child: ExpressiveProgressIndicator(value: refreshProgress),
          ),
        );
      },
    );
  }
}

class _BulkUpdateDialog extends StatefulWidget {
  final List<String> existingUpdateIds;
  final List<String> newInstallIds;
  final List<String> trackOnlyUpdateIds;
  final int totalApps;
  final Map<String, AppInMemory> apps;

  const _BulkUpdateDialog({
    required this.existingUpdateIds,
    required this.newInstallIds,
    required this.trackOnlyUpdateIds,
    required this.totalApps,
    required this.apps,
  });

  @override
  State<_BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<_BulkUpdateDialog> {
  late Set<String> selectedIds;

  @override
  void initState() {
    super.initState();
    selectedIds = {...widget.existingUpdateIds, ...widget.trackOnlyUpdateIds};
    if (widget.existingUpdateIds.isEmpty) {
      selectedIds.addAll(widget.newInstallIds);
    }
  }

  bool get allSelected => selectedIds.length == widget.totalApps;

  void _toggleAll() {
    setState(() {
      if (allSelected) {
        selectedIds.clear();
      } else {
        selectedIds = {
          ...widget.existingUpdateIds,
          ...widget.newInstallIds,
          ...widget.trackOnlyUpdateIds,
        };
      }
    });
  }

  Widget _sectionHeader(String label, List<String> ids, ColorScheme cs) {
    if (ids.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          Text(
            ' (${ids.length})',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _appCheckRow(String id, ColorScheme cs) {
    final aim = widget.apps[id];
    if (aim == null) return const SizedBox.shrink();
    final isNewInstall = aim.app.installedVersion == null;
    final isUpdate =
        aim.app.installedVersion != null &&
        aim.app.installedVersion != aim.app.latestVersion;
    final versionLabel = isUpdate
        ? '${aim.app.installedVersion} → ${aim.app.latestVersion}'
        : aim.app.latestVersion;
    return CheckboxListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 4, right: 4),
      visualDensity: VisualDensity.compact,
      value: selectedIds.contains(id),
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            selectedIds.add(id);
          } else {
            selectedIds.remove(id);
          }
        });
      },
      secondary: AppIcon(
        bytes: aim.icon,
        size: 36,
        radius: 8,
        dimmed: isNewInstall,
      ),
      title: Text(
        aim.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (aim.author.isNotEmpty)
            Text(
              tr('byX', args: [aim.author]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          if (versionLabel.isNotEmpty)
            Text(
              versionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      title: Text(
        tr('changeX', args: [plural('apps', widget.totalApps).toLowerCase()]),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: allSelected,
                  tristate: selectedIds.isNotEmpty && !allSelected,
                  onChanged: (_) => _toggleAll(),
                  visualDensity: VisualDensity.compact,
                ),
                TextButton(
                  onPressed: _toggleAll,
                  child: Text(
                    allSelected
                        ? tr('deselectX', args: [widget.totalApps.toString()])
                        : tr('selectAll'),
                  ),
                ),
              ],
            ),
            _sectionHeader(tr('updates'), widget.existingUpdateIds, cs),
            ...widget.existingUpdateIds.map((id) => _appCheckRow(id, cs)),
            _sectionHeader(tr('nonInstalledApps'), widget.newInstallIds, cs),
            ...widget.newInstallIds.map((id) => _appCheckRow(id, cs)),
            if (widget.trackOnlyUpdateIds.isNotEmpty) ...[
              _sectionHeader(tr('trackOnly'), widget.trackOnlyUpdateIds, cs),
              ...widget.trackOnlyUpdateIds.map((id) => _appCheckRow(id, cs)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          autofocus: context.read<SettingsProvider>().isTV,
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: selectedIds.isEmpty
              ? null
              : () {
                  AppHaptics.selectionClick();
                  Navigator.of(context).pop(selectedIds);
                },
          child: Text(tr('continue')),
        ),
      ],
    );
  }
}

class _TVSearchBar extends StatefulWidget {
  const _TVSearchBar({
    required this.controller,
    required this.onChanged,
    required this.trailing,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<Widget> trailing;
  final String hintText;

  @override
  State<_TVSearchBar> createState() => _TVSearchBarState();
}

class _TVSearchBarState extends State<_TVSearchBar> {
  final FocusNode _textFocus = FocusNode();

  @override
  void dispose() {
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TvTextFieldFocus(
          textFocusNode: _textFocus,
          borderRadius: 28,
          child: TextField(
            focusNode: _textFocus,
            controller: widget.controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: widget.trailing,
        ),
      ],
    );
  }
}
