import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:obtainium/components/app_grid_tile.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/tag_editor.dart';
import 'package:obtainium/components/category_icon_stack.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/apps/app_changelog.dart';
import 'package:obtainium/components/apps/app_dashboard.dart';
import 'package:obtainium/components/apps/app_grid_view.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';

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
import 'package:obtainium/utils/app_constants.dart';
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
  String? activeAppId;
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

  void _applyFilterMode(String mode) {
    setState(() {
      filter.statusFilter.clear();
      if (mode != 'all') {
        filter.statusFilter.add(mode);
      }
    });
  }

  String _getCurrentFilterMode() {
    if (filter.statusFilter.contains('updates')) return 'updates';
    if (filter.statusFilter.contains('trackonly')) return 'trackonly';
    if (filter.statusFilter.contains('installed')) return 'installed';
    return 'all';
  }

  Widget _buildDashboard(BuildContext context, AppsProvider appsProvider, Future<void> Function() onRefresh) {
    final settings = context.read<SettingsProvider>();
    if (!settings.plusEnableHomeDashboard || selectedAppIds.isNotEmpty || filter.nameFilter.isNotEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: AppDashboard(
        currentFilterMode: _getCurrentFilterMode(),
        onFilterChanged: _applyFilterMode,
        onSearchQuery: (query) {
          setState(() => filter.nameFilter = query);
          onRefresh();
        },
        onUrlInput: (url) {
          // Trigger the command center with the URL input
          CommandCenter.show(context, initialQuery: url);
        },
        onCheckUpdates: () {
          _applyFilterMode('updates');
        },
      ),
    );
  }

  Widget _buildPillSlider(BuildContext context, AppsProvider appsProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'all', 
              label: Text(tr('all')),
              icon: const Icon(Icons.apps_rounded, size: 18),
            ),
            ButtonSegment(
              value: 'updates', 
              label: Text(tr('updates')),
              icon: const Icon(Icons.update_rounded, size: 18),
            ),
            ButtonSegment(
              value: 'installed', 
              label: Text(tr('installed')),
              icon: const Icon(Icons.install_mobile_rounded, size: 18),
            ),
          ],
          selected: { _getCurrentFilterMode() },
          onSelectionChanged: (Set<String> selection) {
            HapticFeedback.selectionClick();
            _applyFilterMode(selection.first);
          },
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            selectedForegroundColor: colorScheme.onSecondaryContainer,
            selectedBackgroundColor: colorScheme.secondaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appsProvider = context.watch<AppsProvider>();
    var viewSettings = context.watch<ViewSettingsProvider>();
    final updateSettings = context.watch<UpdateSettingsProvider>();
    var settingsProvider = context.watch<SettingsProvider>();
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
            if (mounted) showError(e is Map ? e['errors'] : e, context);
            return <App>[];
          })
          .whenComplete(() {
            HapticFeedback.lightImpact();
            if (mounted) setState(() {
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: appsProvider.loadingApps
                ? const Center(
                    key: ValueKey('loading'),
                    child: ExpressiveCircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  )
                : EmptyStateWidget(
                    key: ValueKey(appsProvider.apps.isEmpty ? 'empty' : 'filtered'),
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
          ),
        if (refreshingSince != null || appsProvider.loadingApps)
          SliverToBoxAdapter(
            child: ExpressiveProgressIndicator(
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
              if (value.isNotEmpty && values!['updates'] == true && mounted) showMessage(tr('appsUpdated'), context);
            }).catchError((e) {
              if (mounted) showError(e, context);
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
        builder: (ctx) => GlassDialog(
          title: tr('markSelectedAppsUpdated'),
          icon: Icons.check_circle_outline,
          content: Text(tr('markXSelectedAppsAsUpdated',
              args: [selectedApps.length.toString()])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('no'))),
            FilledButton(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final useResponsive = settingsProvider.plusEnableResponsiveAppLayout && screenWidth > 800;

    if (useResponsive) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Row(
          children: [
            // Master View (App List)
            SizedBox(
              width: 350,
              child: _buildMainContent(appsProvider, listedApps, listedCategories, isFilterOff, refresh, settingsProvider, getLoadingWidgets()),
            ),
            const VerticalDivider(width: 1),
            // Detail View
            Expanded(
              child: activeAppId != null
                  ? AppPage(appId: activeAppId!, key: ValueKey(activeAppId))
                  : _buildDetailPlaceholder(context),
            ),
          ],
        ),
      );
    }

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
      body: Stack(
        children: [
          _buildMainContent(appsProvider, listedApps, listedCategories, isFilterOff, refresh, settingsProvider, getLoadingWidgets()),
          if (settingsProvider.plusEnableQuickFilters && selectedAppIds.isEmpty && !settingsProvider.plusTopUILayout)
            Positioned(
              left: 16,
              bottom: 16,
              child: _buildQuickActionStrip(context, viewSettings, isFilterOff),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    AppsProvider appsProvider, 
    List<AppInMemory> listedApps, 
    List<String?> listedCategories, 
    bool isFilterOff, 
    Future<void> Function() onRefresh,
    SettingsProvider settingsProvider,
    List<Widget> loadingWidgets,
  ) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, viewSettings, _) {
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: onRefresh,
          child: Scrollbar(
            controller: scrollController,
            child: CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                _buildAppBar(context, viewSettings, listedApps, isFilterOff),
                _buildDashboard(context, appsProvider, onRefresh),
                if (selectedAppIds.isEmpty && !settingsProvider.plusEnableHomeDashboard) _buildPillSlider(context, appsProvider),
                ...loadingWidgets,
                _buildContent(context, viewSettings, listedApps, listedCategories),
                // Bottom padding to prevent FAB / quick-filter strip from
                // obscuring the last list item.
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            tr('selectURL'), // Using an existing key, though a better one would be "Select an app to view details"
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context, 
    ViewSettingsProvider viewSettings, 
    List<AppInMemory> listedApps,
    bool isFilterOff,
  ) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Automatically use compact style if in Bottom Focus mode to reduce empty space
    final style = settings.plusTopUILayout 
        ? settings.getAppBarStyleForPage('apps') 
        : AppBarStyle.compact;

    if (style == AppBarStyle.large) {
      return SliverAppBar.large(
        pinned: true,
        floating: true,
        snap: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: settings.plusEnableGlassmorphism
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
                  ),
                ),
              )
            : Container(color: Theme.of(context).colorScheme.surface),
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

    // Compact style
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      flexibleSpace: settings.plusEnableGlassmorphism
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
                ),
              ),
            )
          : Container(color: Theme.of(context).colorScheme.surface),
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
          } else if (value == 'categorize') {
            _bulkCategorize(context, listedApps);
          } else if (value == 'tag') {
            _bulkTag(context, listedApps);
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
          PopupMenuItem(
            value: 'categorize',
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(tr('categorize')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'tag',
            child: ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(tr('addTags')),
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
    final settings = context.read<SettingsProvider>();
    final showTopActions = settings.plusTopUILayout || !settings.plusEnableQuickFilters;

    return [
      if (showTopActions && settings.plusShowAppBarSearch) ...[
        Tooltip(
          message: isFilterOff ? tr('search') : tr('clear'),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              if (isFilterOff) {
                CommandCenter.show(context);
              } else {
                setState(() => filter = AppsFilter());
              }
            },
            onLongPress: () {
              HapticFeedback.heavyImpact();
              settings.plusTopUILayout = !settings.plusTopUILayout;
              showMessage(tr('toggleUIFocus'), context);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(isFilterOff
                  ? Icons.search_rounded
                  : Icons.search_off_rounded),
            ),
          ),
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
      ],
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () {
          HapticFeedback.selectionClick();
          pushRoute(context, const SettingsPage());
        },
        tooltip: tr('settings'),
      ),
    ];
  }

  /// Floating bottom-left strip with search + filter for one-handed reachability.
  /// Shown when [plusEnableQuickFilters] is on and no apps are selected.
  Widget _buildQuickActionStrip(
    BuildContext context,
    ViewSettingsProvider viewSettings,
    bool isFilterOff,
  ) {
    final settings = context.read<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final enableGlass = settings.plusEnableGlassmorphism;

    final pill = Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: enableGlass ? 0.72 : 0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: enableGlass
              ? colorScheme.onSurface.withValues(alpha: 0.15)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: AppShadows.smooth(
          color: Colors.black,
          opacity: enableGlass ? 0.22 : 0.12,
          blurFactor: enableGlass ? 1.5 : 1.0,
        ),
      ),
      child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search
              if (settings.plusShowFloatingSearch)
                Tooltip(
                  message: tr('search'),
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      CommandCenter.show(context);
                    },
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      settings.plusTopUILayout = !settings.plusTopUILayout;
                      showMessage(tr('toggleUIFocus'), context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              // Divider
              if (settings.plusShowFloatingSearch)
                Container(
                  width: 1,
                  height: 24,
                  color: colorScheme.onSurface.withValues(alpha: 0.15),
                ),
              // Filter/Sort with active badge
              Tooltip(
                message: tr('sortOptions'),
                child: InkWell(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    SortFilterPanel.show(
                      context,
                      filter: filter,
                      onFilterChanged: () => setState(() {}),
                      categories: viewSettings.categories,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: isFilterOff
                              ? colorScheme.onSurface
                              : colorScheme.primary,
                        ),
                        if (!isFilterOff)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
      ),
    );

    if (!enableGlass) return pill;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: pill,
      ),
    );
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
            ? const Center(child: ExpressiveCircularProgressIndicator(strokeWidth: 3))
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
                        pushRoute(context, const AddAppPage());
                      }
                    : null,
                secondaryActionLabel: appsProvider.apps.isEmpty ? tr('discover') : null,
                onSecondaryActionPressed: appsProvider.apps.isEmpty
                    ? () {
                        HapticFeedback.lightImpact();
                        pushRoute(context, const AddAppPage(initialTab: 1));
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
        activeAppId: activeAppId,
        toggleAppSelected: _toggleAppSelected,
        onAppTap: _handleAppTap,
        getChangeLogFn: getChangeLogFn,
        getCachedCategoryColor: _getCachedCategoryColor,
      );
    } else if (viewSettings.globalViewMode == ViewMode.grid) {
      return AppGridView(
          apps: listedApps,
          selectedAppIds: selectedAppIds,
          activeAppId: activeAppId,
          toggleAppSelected: _toggleAppSelected,
          onAppTap: _handleAppTap);
    } else {
      return AppListView(
          apps: listedApps,
          selectedAppIds: selectedAppIds,
          activeAppId: activeAppId,
          toggleAppSelected: _toggleAppSelected,
          onAppTap: _handleAppTap,
          getChangeLogFn: getChangeLogFn);
    }
  }

  void _handleAppTap(App app) {
    final settingsProvider = context.read<SettingsProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final useResponsive = settingsProvider.plusEnableResponsiveAppLayout && screenWidth > 800;

    if (useResponsive) {
      setState(() {
        activeAppId = app.id;
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => AppPage(
          appId: app.id,
          isModal: true,
        ),
      );
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
            if (value.isNotEmpty && values!['updates'] == true && mounted) showMessage(tr('appsUpdated'), context);
          }).catchError((e) {
            if (mounted) showError(e, context);
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
      builder: (ctx) => GlassDialog(
        title: tr('markSelectedAppsUpdated'),
        icon: Icons.check_circle_outline,
        content: Text(tr('markXSelectedAppsAsUpdated',
            args: [selectedApps.length.toString()])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('no'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('yes'))),
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

  void _bulkCategorize(BuildContext context, List<AppInMemory> listedApps) async {
    final appsProvider = context.read<AppsProvider>();
    final selectedApps = listedApps
        .where((e) => selectedAppIds.contains(e.app.id))
        .map((e) => e.app)
        .toList();
    
    if (selectedApps.isEmpty) return;

    Set<String> commonCategories = {};
    if (selectedApps.length == 1) {
      commonCategories = selectedApps.first.categories.toSet();
    }

    final newCategories = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: tr('categorizeXApps', args: [selectedApps.length.toString()]),
        icon: Icons.label_outline,
        content: CategoryEditorSelector(
          alignment: WrapAlignment.start,
          preselected: commonCategories,
          onSelected: (categories) => Navigator.pop(ctx, categories),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
        ],
      ),
    );

    if (newCategories != null) {
      for (var app in selectedApps) {
        app.categories = newCategories.toList();
      }
      await appsProvider.saveApps(selectedApps);
      clearSelected();
      showMessage(tr('appsCategorized'), context);
    }
  }

  void _bulkTag(BuildContext context, List<AppInMemory> listedApps) async {
    final appsProvider = context.read<AppsProvider>();
    final selectedApps = listedApps
        .where((e) => selectedAppIds.contains(e.app.id))
        .map((e) => e.app)
        .toList();
    
    if (selectedApps.isEmpty) return;

    final allTags = appsProvider.getAppValues().expand((a) => a.app.tags).toSet().toList();
    allTags.sort();

    Set<String> commonTags = {};
    if (selectedApps.length == 1) {
      commonTags = selectedApps.first.tags.toSet();
    }

    final newTags = await showTagEditor(
      context: context,
      currentTags: commonTags.toList(),
      allTags: allTags,
    );

    if (newTags != null) {
      for (var app in selectedApps) {
        app.tags = newTags;
      }
      await appsProvider.saveApps(selectedApps);
      clearSelected();
      showMessage(tr('appsTagged'), context);
    }
  }
}

