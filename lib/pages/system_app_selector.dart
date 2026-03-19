import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/main.dart';
import 'package:provider/provider.dart';

enum SystemAppSortMethod {
  nameAZ,
  nameZA,
  recentlyUpdated,
  recentlyInstalled,
  size,
  systemFirst,
  userFirst,
}

enum SystemAppViewMode {
  list,
  grid,
}

class SystemAppSelector extends StatefulWidget {
  const SystemAppSelector({super.key});

  @override
  State<SystemAppSelector> createState() => _SystemAppSelectorState();
}

class _SystemAppSelectorState extends State<SystemAppSelector> {
  bool _isLoading = true;
  bool _showSystemApps = false;
  String _searchQuery = '';
  List<_EnhancedPackageInfo> _apps = [];
  final SourceProvider _sourceProvider = SourceProvider();
  
  // View settings
  SystemAppViewMode _viewMode = SystemAppViewMode.list;
  SystemAppSortMethod _sortMethod = SystemAppSortMethod.nameAZ;
  bool _sortAscending = true;
  
  // Category/Label settings
  Map<String, List<String>> _appLabels = {}; // packageName -> [labels]
  Set<String> _selectedLabels = {};
  
  // Grid settings
  double _gridIconSize = 48.0;
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
          _apps = installed.map((pkg) => _EnhancedPackageInfo.fromPackageInfo(pkg)).toList();
          _isLoading = false;
        });
        _sortApps();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortApps() {
    setState(() {
      _apps.sort((a, b) {
        int result = 0;
        
        switch (_sortMethod) {
          case SystemAppSortMethod.nameAZ:
            result = (a.appName ?? a.packageName ?? '').compareTo(b.appName ?? b.packageName ?? '');
            break;
          case SystemAppSortMethod.nameZA:
            result = (b.appName ?? b.packageName ?? '').compareTo(a.appName ?? a.packageName ?? '');
            break;
          case SystemAppSortMethod.recentlyUpdated:
            result = (b.lastUpdateTime ?? 0).compareTo(a.lastUpdateTime ?? 0);
            break;
          case SystemAppSortMethod.recentlyInstalled:
            result = (b.firstInstallTime ?? 0).compareTo(a.firstInstallTime ?? 0);
            break;
          case SystemAppSortMethod.size:
            result = (b.size ?? 0).compareTo(a.size ?? 0);
            break;
          case SystemAppSortMethod.systemFirst:
            result = b.isSystemApp ? -1 : 1;
            break;
          case SystemAppSortMethod.userFirst:
            result = a.isSystemApp ? -1 : 1;
            break;
        }
        
        return _sortAscending ? result : -result;
      });
    });
  }

  List<String> _getAllLabels() {
    final labels = <String>{};
    for (final appLabels in _appLabels.values) {
      labels.addAll(appLabels);
    }
    return labels.toList()..sort();
  }

  List<_EnhancedPackageInfo> _getFilteredApps() {
    return _apps.where((pkg) {
      // Filter out apps already tracked
      if (context.read<AppsProvider>().apps.containsKey(pkg.packageName)) return false;

      // Filter by system status
      if (!_showSystemApps && pkg.isSystemApp) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final searchText = '${pkg.appName ?? ''} ${pkg.packageName ?? ''}'.toLowerCase();
        if (!searchText.contains(_searchQuery.toLowerCase())) return false;
      }

      // Filter by selected labels
      if (_selectedLabels.isNotEmpty) {
        final appLabels = _appLabels[pkg.packageName] ?? [];
        if (!appLabels.any((label) => _selectedLabels.contains(label))) return false;
      }

      return true;
    }).toList();
  }

  void _showLabelEditor(String packageName) {
    final currentLabels = _appLabels[packageName] ?? [];
    final allLabels = _getAllLabels();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final selectedLabels = Set<String>.from(currentLabels);
          
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  DragHandle(width: 40, margin: const EdgeInsets.only(bottom: 16)),
                const SizedBox(height: 20),
                
                Text(
                  tr('editLabels'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Existing labels
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
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedLabels.add(label);
                            } else {
                              selectedLabels.remove(label);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Add new label
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: tr('newLabel'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setSheetState(() {
                              selectedLabels.add(value.trim());
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // Add from text field handled by onSubmitted
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Actions
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
                        setState(() {
                          _appLabels[packageName] = selectedLabels.toList();
                        });
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

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final settings = context.watch<SettingsProvider>();
    final filteredApps = _getFilteredApps();
    final allLabels = _getAllLabels();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(tr('importInstalledApps')),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: settings.plusEnableGlassmorphism ? 15 : 0,
              sigmaY: settings.plusEnableGlassmorphism ? 15 : 0,
            ),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(settings.plusEnableGlassmorphism ? 0.7 : 1.0,
              ),
            ),
          ),
        ),
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(_viewMode == SystemAppViewMode.list ? Icons.grid_view_outlined : Icons.view_list_outlined),
            onPressed: () => setState(() => _viewMode = _viewMode == SystemAppViewMode.list ? SystemAppViewMode.grid : SystemAppViewMode.list),
            tooltip: _viewMode == SystemAppViewMode.list ? tr('gridView') : tr('listView'),
          ),
          
          // Sort menu
          PopupMenuButton<SystemAppSortMethod>(
            icon: const Icon(Icons.sort_outlined),
            tooltip: tr('sortBy'),
            onSelected: (value) {
              setState(() {
                if (_sortMethod == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortMethod = value;
                  _sortAscending = true;
                }
                _sortApps();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: SystemAppSortMethod.nameAZ, child: Text(tr('nameAZ'))),
              PopupMenuItem(value: SystemAppSortMethod.nameZA, child: Text(tr('nameZA'))),
              PopupMenuItem(value: SystemAppSortMethod.recentlyUpdated, child: Text(tr('recentlyUpdated'))),
              PopupMenuItem(value: SystemAppSortMethod.recentlyInstalled, child: Text(tr('recentlyInstalled'))),
              PopupMenuItem(value: SystemAppSortMethod.size, child: Text(tr('size'))),
              PopupMenuItem(value: SystemAppSortMethod.systemFirst, child: Text(tr('systemAppsFirst'))),
              PopupMenuItem(value: SystemAppSortMethod.userFirst, child: Text(tr('userAppsFirst'))),
            ],
          ),
          
          // System apps toggle
          IconButton(
            icon: Icon(_showSystemApps ? Icons.system_update_rounded : Icons.person_outline_rounded),
            onPressed: () => setState(() => _showSystemApps = !_showSystemApps),
            tooltip: tr('showSystemApps'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_viewMode == SystemAppViewMode.grid ? 140 : 120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search bar
                SearchBar(
                  hintText: tr('searchApps'),
                  leading: const Icon(Icons.search),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(settings.plusEnableGlassmorphism ? 0.5 : 1.0,
                  )),
                ),
                
                // Labels filter (if any exist)
                if (allLabels.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allLabels.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Clear filter chip
                          return FilterChip(
                            label: Text(tr('all')),
                            selected: _selectedLabels.isEmpty,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedLabels.clear());
                              }
                            },
                          );
                        }
                        final label = allLabels[index - 1];
                        return FilterChip(
                          label: Text(label),
                          selected: _selectedLabels.contains(label),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedLabels.add(label);
                              } else {
                                _selectedLabels.remove(label);
                              }
                            });
                          },
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + (_viewMode == SystemAppViewMode.grid ? 140 : 120)),
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
                          itemBuilder: (context, index) {
                            final pkg = filteredApps[index];
                            return _buildAppTile(pkg, appsProvider);
                          },
                        )
                      : GridView.builder(
                          itemCount: filteredApps.length,
                          padding: const EdgeInsets.all(8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _gridColumnCount,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, index) {
                            final pkg = filteredApps[index];
                            return _buildGridAppTile(pkg, appsProvider);
                          },
                        ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: filteredApps.isEmpty ? null : () => _importSelectedApps(filteredApps, appsProvider),
        icon: const Icon(Icons.download_outlined),
        label: Text(tr('importXApps', args: [filteredApps.length.toString()])),
      ),
    );
  }

  Widget _buildAppTile(_EnhancedPackageInfo pkg, AppsProvider appsProvider) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appLabels = _appLabels[pkg.packageName] ?? [];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _importApp(pkg, appsProvider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: pkg.icon != null 
                      ? Image.memory(pkg.icon!, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.apps, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Info
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
                      pkg.packageName ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (appLabels.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: appLabels.map((label) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showLabelEditor(pkg.packageName!),
                    tooltip: tr('editLabels'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 4),
                  Checkbox(
                    value: pkg.isSelected,
                    onChanged: (value) {
                      setState(() => pkg.isSelected = value ?? false);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridAppTile(_EnhancedPackageInfo pkg, AppsProvider appsProvider) {
    final settings = context.read<SettingsProvider>();
    final appLabels = _appLabels[pkg.packageName] ?? [];
    
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _importApp(pkg, appsProvider),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Icon
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pkg.icon != null 
                      ? Image.memory(pkg.icon!, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.apps, 
                            size: _gridIconSize,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Name
              Text(
                pkg.appName ?? pkg.packageName ?? '',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              
              // Labels
              if (appLabels.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: appLabels.take(2).map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Checkbox(
                      value: pkg.isSelected,
                      onChanged: (value) {
                        setState(() => pkg.isSelected = value ?? false);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showLabelEditor(pkg.packageName!),
                    tooltip: tr('editLabels'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importApp(_EnhancedPackageInfo pkg, AppsProvider appsProvider) async {
    if (pkg.packageName == null) return;
    
    try {
      final url = 'https://play.google.com/store/apps/details?id=${pkg.packageName}';
      await appsProvider.addAppsByURL([url]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('importedX', args: [pkg.appName ?? pkg.packageName ?? ''])),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showError(e, context);
      }
    }
  }

  Future<void> _importSelectedApps(List<_EnhancedPackageInfo> apps, AppsProvider appsProvider) async {
    final selectedApps = apps.where((a) => a.isSelected).toList();
    if (selectedApps.isEmpty) return;
    
    try {
      final urls = selectedApps.map((a) => 'https://play.google.com/store/apps/details?id=${a.packageName}').toList();
      await appsProvider.addAppsByURL(urls);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('importedXApps', args: [selectedApps.length.toString()])),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showError(e, context);
      }
    }
  }
}

class _EnhancedPackageInfo {
  String? packageName;
  String? appName;
  Uint8List? icon;
  bool isSystemApp;
  bool isSelected;
  int? size;
  int? firstInstallTime;
  int? lastUpdateTime;
  
  _EnhancedPackageInfo({
    this.packageName,
    this.appName,
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
      appName: pkg.applicationInfo?.getAppLabel()?.toString() ?? pkg.packageName,
      icon: null,
      isSystemApp: (pkg.applicationInfo?.flags ?? 0) & 1 != 0,
      size: null,
      firstInstallTime: pkg.firstInstallTime,
      lastUpdateTime: pkg.lastUpdateTime,
    );
  }
}
