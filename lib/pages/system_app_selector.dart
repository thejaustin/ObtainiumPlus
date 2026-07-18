import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/utils/haptic_utils.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/import_error_dialog.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/app_constants.dart';

enum SystemAppSortMethod {
  nameAZ,
  nameZA,
  recentlyUpdated,
  recentlyInstalled,
  size,
  systemFirst,
  userFirst,
}

enum SystemAppViewMode { list, grid }

class SystemAppSelector extends StatefulWidget {
  /// When true, tapping an app pops the route with its URL string instead of
  /// toggling selection. Used by AddAppPage to pre-fill the URL field.
  final bool returnUrlOnSelect;
  final bool isModal;
  final ScrollController? scrollController;

  const SystemAppSelector({
    super.key,
    this.returnUrlOnSelect = false,
    this.isModal = false,
    this.scrollController,
  });

  @override
  State<SystemAppSelector> createState() => _SystemAppSelectorState();
}

class _SystemAppSelectorState extends State<SystemAppSelector> {
  bool _isLoading = true;
  bool _showSystemApps = false;
  String _searchQuery = '';
  List<_EnhancedPackageInfo> _apps = [];

  // View settings
  SystemAppViewMode _viewMode = SystemAppViewMode.list;
  SystemAppSortMethod _sortMethod = SystemAppSortMethod.nameAZ;
  bool _sortAscending = true;

  // Label filter
  Map<String, List<String>> _appLabels = {};
  Set<String> _selectedLabels = {};

  // Grid column count
  int _gridColumnCount = 3;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final installed = await AppInstallService.getAllInstalledInfo();
      if (mounted) {
        setState(() {
          _apps = installed
              .map((pkg) => _EnhancedPackageInfo.fromPackageInfo(pkg))
              .toList();
          _isLoading = false;
        });
        _sortApps();
        _loadIcons(installed);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadIcons(List<PackageInfo> packages) async {
    const batchSize = 10;
    for (int i = 0; i < packages.length; i += batchSize) {
      if (!mounted) return;
      final batch = packages.sublist(
        i,
        (i + batchSize).clamp(0, packages.length),
      );
      await Future.wait(
        batch.map((pkg) async {
          try {
            final iconBytes = await pkg.applicationInfo?.getAppIcon();
            final appName = await pkg.applicationInfo?.getAppLabel();
            if (!mounted) return;
            final idx = _apps.indexWhere(
              (a) => a.packageName == pkg.packageName,
            );
            if (idx != -1) {
              setState(() {
                if (iconBytes != null) _apps[idx].icon = iconBytes;
                if (appName != null) _apps[idx].appName = appName;
              });
            }
          } catch (_) {}
        }),
      );
    }
  }

  void _sortApps() {
    setState(() {
      _apps.sort((a, b) {
        int result;
        switch (_sortMethod) {
          case SystemAppSortMethod.nameAZ:
          case SystemAppSortMethod.nameZA:
            result = (a.appName ?? a.packageName ?? '').compareTo(
              b.appName ?? b.packageName ?? '',
            );
            if (_sortMethod == SystemAppSortMethod.nameZA) result = -result;
          case SystemAppSortMethod.recentlyUpdated:
            result = (b.lastUpdateTime ?? 0).compareTo(a.lastUpdateTime ?? 0);
          case SystemAppSortMethod.recentlyInstalled:
            result = (b.firstInstallTime ?? 0).compareTo(
              a.firstInstallTime ?? 0,
            );
          case SystemAppSortMethod.size:
            result = (b.size ?? 0).compareTo(a.size ?? 0);
          case SystemAppSortMethod.systemFirst:
            result = b.isSystemApp ? -1 : 1;
          case SystemAppSortMethod.userFirst:
            result = a.isSystemApp ? -1 : 1;
        }
        return _sortAscending ? result : -result;
      });
    });
  }

  List<String> _getAllLabels() {
    final labels = <String>{};
    for (final labels_ in _appLabels.values) {
      labels.addAll(labels_);
    }
    return labels.toList()..sort();
  }

  List<_EnhancedPackageInfo> _getFilteredApps() {
    final trackedApps = context.read<AppsProvider>().apps;
    return _apps.where((pkg) {
      if (trackedApps.containsKey(pkg.packageName)) return false;
      if (!_showSystemApps && pkg.isSystemApp) return false;
      if (_searchQuery.isNotEmpty) {
        final text = '${pkg.appName ?? ''} ${pkg.packageName ?? ''}'
            .toLowerCase();
        if (!text.contains(_searchQuery.toLowerCase())) return false;
      }
      if (_selectedLabels.isNotEmpty) {
        final appLabels = _appLabels[pkg.packageName] ?? [];
        if (!appLabels.any((l) => _selectedLabels.contains(l))) return false;
      }
      return true;
    }).toList();
  }

  int get _selectedCount => _apps.where((a) => a.isSelected).length;

  void _toggleSelectAll(List<_EnhancedPackageInfo> filtered) {
    final allSelected = filtered.every((a) => a.isSelected);
    setState(() {
      for (final app in filtered) {
        app.isSelected = !allSelected;
      }
    });
  }

  void _showLabelEditor(String packageName) {
    final currentLabels = _appLabels[packageName] ?? [];
    final allLabels = _getAllLabels();
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedLabels = Set<String>.from(currentLabels);

          void addLabel(String value) {
            final trimmed = value.trim();
            if (trimmed.isEmpty) return;
            setSheetState(() => selectedLabels.add(trimmed));
            controller.clear();
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: DragHandle(
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                  ),
                  Text(
                    tr('editLabels'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (allLabels.isNotEmpty) ...[
                    Text(
                      tr('existingLabels'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allLabels.map((label) {
                        final isSelected = selectedLabels.contains(label);
                        return FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (val) => setSheetState(() {
                            if (val)
                              selectedLabels.add(label);
                            else
                              selectedLabels.remove(label);
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Add new label
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: tr('newLabel'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: addLabel,
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => addLabel(controller.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          setState(
                            () => _appLabels[packageName] = selectedLabels
                                .toList(),
                          );
                          Navigator.pop(context);
                        },
                        child: Text(tr('save')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _appBarBottomHeight(bool hasLabels) {
    // Search bar ~56px + padding 12px bottom + 8px top gap = ~76px base
    // Labels row: 40px + 8px gap
    double height = 68;
    if (hasLabels) height += 48;
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final settings = context.watch<SettingsProvider>();
    final filteredApps = _getFilteredApps();
    final allLabels = _getAllLabels();
    final hasLabels = allLabels.isNotEmpty;
    final bottomHeight = _appBarBottomHeight(hasLabels);
    final allFilteredSelected =
        filteredApps.isNotEmpty && filteredApps.every((a) => a.isSelected);

    final plusSettings = context.watch<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;

    final viewWidget = _isLoading
        ? const Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: ExpressiveCircularProgressIndicator(),
            ),
          )
        : filteredApps.isEmpty
        ? EmptyStateWidget(
            icon: Icons.apps_rounded,
            title: tr('noMatchingApps'),
            subtitle: tr('tryAdjustingFilters'),
          )
        : _viewMode == SystemAppViewMode.list
        ? ListView.builder(
            controller: widget.scrollController,
            itemCount: filteredApps.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (_, index) =>
                _buildAppTile(filteredApps[index], appsProvider),
          )
        : GridView.builder(
            controller: widget.scrollController,
            itemCount: filteredApps.length,
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridColumnCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, index) =>
                _buildGridAppTile(filteredApps[index], appsProvider),
          );

    if (widget.isModal) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radius.clamp(20.0, 48.0)),
        ),
        child: ConditionalBlur(
          enabled: plusSettings.plusEnableGlassmorphism,
          sigma: 20,
          child: Container(
            color: Theme.of(context).colorScheme.surface.withValues(
              alpha: plusSettings.plusEnableGlassmorphism ? 0.85 : 1.0,
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('importInstalledApps'),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (!widget.returnUrlOnSelect &&
                            filteredApps.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              allFilteredSelected
                                  ? Icons.deselect_rounded
                                  : Icons.select_all_rounded,
                            ),
                            tooltip: allFilteredSelected
                                ? tr('deselectAll')
                                : tr('selectAll'),
                            onPressed: () => _toggleSelectAll(filteredApps),
                          ),
                        IconButton(
                          icon: Icon(
                            _viewMode == SystemAppViewMode.list
                                ? Icons.grid_view_outlined
                                : Icons.view_list_outlined,
                          ),
                          onPressed: () => setState(
                            () =>
                                _viewMode = _viewMode == SystemAppViewMode.list
                                ? SystemAppViewMode.grid
                                : SystemAppViewMode.list,
                          ),
                          tooltip: _viewMode == SystemAppViewMode.list
                              ? tr('gridView')
                              : tr('listView'),
                        ),
                        PopupMenuButton<SystemAppSortMethod>(
                          icon: const Icon(Icons.sort_outlined),
                          tooltip: tr('sortBy'),
                          onSelected: (value) => setState(() {
                            if (_sortMethod == value) {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortMethod = value;
                              _sortAscending = true;
                            }
                            _sortApps();
                          }),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: SystemAppSortMethod.nameAZ,
                              child: Text(tr('nameAZ')),
                            ),
                            PopupMenuItem(
                              value: SystemAppSortMethod.nameZA,
                              child: Text(tr('nameZA')),
                            ),
                            PopupMenuItem(
                              value: SystemAppSortMethod.recentlyUpdated,
                              child: Text(tr('recentlyUpdated')),
                            ),
                            PopupMenuItem(
                              value: SystemAppSortMethod.recentlyInstalled,
                              child: Text(tr('recentlyInstalled')),
                            ),
                            PopupMenuItem(
                              value: SystemAppSortMethod.size,
                              child: Text(tr('size')),
                            ),
                            PopupMenuItem(
                              value: SystemAppSortMethod.systemFirst,
                              child: Text(tr('systemAppsFirst')),
                            ),
                            PopupMenuItem(
                              value: SystemAppSortMethod.userFirst,
                              child: Text(tr('userAppsFirst')),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            _showSystemApps
                                ? Icons.system_update_rounded
                                : Icons.person_outline_rounded,
                          ),
                          onPressed: () => setState(
                            () => _showSystemApps = !_showSystemApps,
                          ),
                          tooltip: tr('showSystemApps'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: tr('close'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: SearchBar(
                      hintText: tr('searchApps'),
                      leading: const Icon(Icons.search),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh.withValues(
                          alpha: plusSettings.plusEnableGlassmorphism
                              ? 0.5
                              : 1.0,
                        ),
                      ),
                      trailing: _isLoading
                          ? null
                          : [
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  '${filteredApps.length}',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                    ),
                  ),
                  if (hasLabels) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: allLabels.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return FilterChip(
                              label: Text(tr('all')),
                              selected: _selectedLabels.isEmpty,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _selectedLabels.clear());
                              },
                            );
                          }
                          final label = allLabels[index - 1];
                          return FilterChip(
                            label: Text(label),
                            selected: _selectedLabels.contains(label),
                            onSelected: (selected) => setState(() {
                              if (selected)
                                _selectedLabels.add(label);
                              else
                                _selectedLabels.remove(label);
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Expanded(child: viewWidget),
                ],
              ),
              floatingActionButton: widget.returnUrlOnSelect
                  ? null
                  : AnimatedScale(
                      scale: _selectedCount > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.tertiary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          onPressed: _selectedCount == 0
                              ? null
                              : () {
                                  AppHaptics.selectionClick();
                                  _importSelectedApps(appsProvider);
                                },
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          hoverElevation: 0,
                          focusElevation: 0,
                          highlightElevation: 0,
                          icon: Icon(
                            Icons.download_outlined,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          label: Text(
                            tr(
                              'importXApps',
                              args: [_selectedCount.toString()],
                            ),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(tr('importInstalledApps')),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: ConditionalBlur(
            sigma: 15,
            enabled: settings.plusEnableGlassmorphism,
            child: Container(
              color: Theme.of(context).colorScheme.surface.withValues(
                alpha: settings.plusEnableGlassmorphism ? 0.7 : 1.0,
              ),
            ),
          ),
        ),
        actions: [
          if (!widget.returnUrlOnSelect && filteredApps.isNotEmpty)
            IconButton(
              icon: Icon(
                allFilteredSelected
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
              ),
              tooltip: allFilteredSelected
                  ? tr('deselectAll')
                  : tr('selectAll'),
              onPressed: () => _toggleSelectAll(filteredApps),
            ),
          IconButton(
            icon: Icon(
              _viewMode == SystemAppViewMode.list
                  ? Icons.grid_view_outlined
                  : Icons.view_list_outlined,
            ),
            onPressed: () => setState(
              () => _viewMode = _viewMode == SystemAppViewMode.list
                  ? SystemAppViewMode.grid
                  : SystemAppViewMode.list,
            ),
            tooltip: _viewMode == SystemAppViewMode.list
                ? tr('gridView')
                : tr('listView'),
          ),
          PopupMenuButton<SystemAppSortMethod>(
            icon: const Icon(Icons.sort_outlined),
            tooltip: tr('sortBy'),
            onSelected: (value) => setState(() {
              if (_sortMethod == value) {
                _sortAscending = !_sortAscending;
              } else {
                _sortMethod = value;
                _sortAscending = true;
              }
              _sortApps();
            }),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SystemAppSortMethod.nameAZ,
                child: Text(tr('nameAZ')),
              ),
              PopupMenuItem(
                value: SystemAppSortMethod.nameZA,
                child: Text(tr('nameZA')),
              ),
              PopupMenuItem(
                value: SystemAppSortMethod.recentlyUpdated,
                child: Text(tr('recentlyUpdated')),
              ),
              PopupMenuItem(
                value: SystemAppSortMethod.recentlyInstalled,
                child: Text(tr('recentlyInstalled')),
              ),
              PopupMenuItem(
                value: SystemAppSortMethod.size,
                child: Text(tr('size')),
              ),
              PopupMenuItem(
                value: SystemAppSortMethod.systemFirst,
                child: Text(tr('systemAppsFirst')),
              ),
              PopupMenuItem(
                value: SystemAppSortMethod.userFirst,
                child: Text(tr('userAppsFirst')),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _showSystemApps
                  ? Icons.system_update_rounded
                  : Icons.person_outline_rounded,
            ),
            onPressed: () => setState(() => _showSystemApps = !_showSystemApps),
            tooltip: tr('showSystemApps'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(bottomHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchBar(
                  hintText: tr('searchApps'),
                  leading: const Icon(Icons.search),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh.withValues(
                      alpha: settings.plusEnableGlassmorphism
                          ? AppOpacity.half
                          : 1.0,
                    ),
                  ),
                  trailing: _isLoading
                      ? null
                      : [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '${filteredApps.length}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                ),
                if (hasLabels) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allLabels.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return FilterChip(
                            label: Text(tr('all')),
                            selected: _selectedLabels.isEmpty,
                            onSelected: (selected) {
                              if (selected)
                                setState(() => _selectedLabels.clear());
                            },
                          );
                        }
                        final label = allLabels[index - 1];
                        return FilterChip(
                          label: Text(label),
                          selected: _selectedLabels.contains(label),
                          onSelected: (selected) => setState(() {
                            if (selected)
                              _selectedLabels.add(label);
                            else
                              _selectedLabels.remove(label);
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: ExpressiveCircularProgressIndicator(),
              ),
            )
          : Padding(
              padding: EdgeInsets.only(
                top:
                    MediaQuery.of(context).padding.top +
                    kToolbarHeight +
                    bottomHeight,
              ),
              child: filteredApps.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.apps_rounded,
                      title: tr('noMatchingApps'),
                      subtitle: tr('tryAdjustingFilters'),
                    )
                  : _viewMode == SystemAppViewMode.list
                  ? ListView.builder(
                      itemCount: filteredApps.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (_, index) =>
                          _buildAppTile(filteredApps[index], appsProvider),
                    )
                  : GridView.builder(
                      itemCount: filteredApps.length,
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridColumnCount,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (_, index) =>
                          _buildGridAppTile(filteredApps[index], appsProvider),
                    ),
            ),
      floatingActionButton: widget.returnUrlOnSelect
          ? null
          : AnimatedScale(
              scale: _selectedCount > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _selectedCount == 0
                      ? null
                      : () {
                          AppHaptics.selectionClick();
                          _importSelectedApps(appsProvider);
                        },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  hoverElevation: 0,
                  focusElevation: 0,
                  highlightElevation: 0,
                  icon: Icon(
                    Icons.download_outlined,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    tr('importXApps', args: [_selectedCount.toString()]),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildIconWidget(Uint8List? icon, double size) {
    if (icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          icon,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    return AppIconShimmer(size: size);
  }

  Widget _buildAppTile(_EnhancedPackageInfo pkg, AppsProvider appsProvider) {
    final appLabels = _appLabels[pkg.packageName] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: pkg.isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: AppOpacity.moderate,
            )
          : Theme.of(context).colorScheme.surfaceContainerLow.withValues(
              alpha: AppOpacity.half,
            ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (widget.returnUrlOnSelect) {
            if (pkg.packageName == null) return;
            Navigator.pop(
              context,
              'https://play.google.com/store/apps/details?id=${pkg.packageName}',
            );
          } else {
            setState(() => pkg.isSelected = !pkg.isSelected);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildIconWidget(pkg.icon, 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.appName ?? pkg.packageName ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        pkg.packageName ?? '',
                        if (pkg.versionName != null) pkg.versionName!,
                      ].join('  ·  '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (appLabels.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: appLabels
                            .map((label) => _buildLabelChip(label))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (!widget.returnUrlOnSelect) ...[
                IconButton(
                  icon: const Icon(Icons.label_outline, size: 20),
                  onPressed: () => _showLabelEditor(pkg.packageName!),
                  tooltip: tr('editLabels'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Checkbox(
                  value: pkg.isSelected,
                  onChanged: (value) =>
                      setState(() => pkg.isSelected = value ?? false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridAppTile(
    _EnhancedPackageInfo pkg,
    AppsProvider appsProvider,
  ) {
    final appLabels = _appLabels[pkg.packageName] ?? [];

    return Card(
      elevation: 0,
      color: pkg.isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: AppOpacity.moderate,
            )
          : Theme.of(context).colorScheme.surfaceContainerLow.withValues(
              alpha: AppOpacity.half,
            ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (widget.returnUrlOnSelect) {
            if (pkg.packageName == null) return;
            Navigator.pop(
              context,
              'https://play.google.com/store/apps/details?id=${pkg.packageName}',
            );
          } else {
            setState(() => pkg.isSelected = !pkg.isSelected);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(child: _buildIconWidget(pkg.icon, double.infinity)),
              const SizedBox(height: 6),
              Text(
                pkg.appName ?? pkg.packageName ?? '',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (pkg.versionName != null) ...[
                const SizedBox(height: 2),
                Text(
                  pkg.versionName!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
              if (appLabels.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: appLabels
                      .take(2)
                      .map((l) => _buildLabelChip(l, small: true))
                      .toList(),
                ),
              ],
              if (!widget.returnUrlOnSelect) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Checkbox(
                      value: pkg.isSelected,
                      onChanged: (v) =>
                          setState(() => pkg.isSelected = v ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.label_outline, size: 16),
                      onPressed: () => _showLabelEditor(pkg.packageName!),
                      tooltip: tr('editLabels'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 8,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: AppOpacity.half),
        borderRadius: BorderRadius.circular(small ? 4 : 8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: small ? 8 : null,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Future<void> _importSelectedApps(AppsProvider appsProvider) async {
    final selectedApps = _apps.where((a) => a.isSelected).toList();
    if (selectedApps.isEmpty) return;

    final urls = selectedApps
        .map(
          (a) =>
              'https://play.google.com/store/apps/details?id=${a.packageName}',
        )
        .toList();

    try {
      final errors = await appsProvider.addAppsByURL(urls);
      if (!mounted) return;
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('importedX', args: [selectedApps.length.toString()]),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) =>
              ImportErrorDialog(urlsLength: urls.length, errors: errors),
        );
      }
    } catch (e) {
      if (mounted) showError(e, context);
    }
  }
}

class _EnhancedPackageInfo {
  String? packageName;
  String? appName;
  String? versionName;
  Uint8List? icon;
  bool isSystemApp;
  bool isSelected;
  int? size;
  int? firstInstallTime;
  int? lastUpdateTime;

  _EnhancedPackageInfo({
    this.packageName,
    this.appName,
    this.versionName,
    this.icon,
    this.isSystemApp = false,
    this.isSelected = false,
    this.size,
    this.firstInstallTime,
    this.lastUpdateTime,
  });

  factory _EnhancedPackageInfo.fromPackageInfo(PackageInfo pkg) {
    return _EnhancedPackageInfo(
      packageName: pkg.packageName,
      appName: pkg.packageName, // Set asynchronously in _loadIcons
      versionName: pkg.versionName,
      icon: null,
      isSystemApp: (pkg.applicationInfo?.flags ?? 0) & 1 != 0,
      firstInstallTime: pkg.firstInstallTime,
      lastUpdateTime: pkg.lastUpdateTime,
    );
  }
}
