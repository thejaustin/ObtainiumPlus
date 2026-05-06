import 'dart:async';
import 'dart:ui';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/app_sources/fdroid.dart';
import 'package:obtainium/components/apps/app_tile_skeleton.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/empty_state.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';

class DiscoverPage extends StatefulWidget {
  final bool showAppBar;
  final bool showSearchBar;
  final String initialQuery;
  const DiscoverPage({super.key, this.showAppBar = true, this.showSearchBar = true, this.initialQuery = ''});

  @override
  State<DiscoverPage> createState() => DiscoverPageState();
}

typedef _Category = ({String slug, String label, IconData icon});

const _fdroidCategories = <_Category>[
  (slug: 'connectivity', label: 'Connectivity', icon: Icons.wifi_rounded),
  (slug: 'development', label: 'Development', icon: Icons.code_rounded),
  (slug: 'games', label: 'Games', icon: Icons.sports_esports_rounded),
  (slug: 'graphics', label: 'Graphics', icon: Icons.palette_rounded),
  (slug: 'internet', label: 'Internet', icon: Icons.language_rounded),
  (slug: 'money', label: 'Money', icon: Icons.account_balance_wallet_rounded),
  (slug: 'multimedia', label: 'Multimedia', icon: Icons.play_circle_rounded),
  (slug: 'navigation', label: 'Navigation', icon: Icons.map_rounded),
  (slug: 'phone-sms', label: 'Phone & SMS', icon: Icons.phone_rounded),
  (slug: 'reading', label: 'Reading', icon: Icons.menu_book_rounded),
  (slug: 'security', label: 'Security', icon: Icons.security_rounded),
  (slug: 'system', label: 'System', icon: Icons.settings_rounded),
  (slug: 'theming', label: 'Theming', icon: Icons.style_rounded),
  (slug: 'time', label: 'Time', icon: Icons.access_time_rounded),
  (slug: 'writing', label: 'Writing', icon: Icons.edit_rounded),
];

class DiscoverPageState extends State<DiscoverPage> {
  bool searching = false;
  bool _isGridView = true;
  bool _loadingMore = false;
  String searchQuery = '';
  String? _selectedCategory;
  int _browsePage = 1;
  bool _browseHasMore = false;
  Map<String, MapEntry<String, List<String>>> results = {};
  SourceProvider sourceProvider = SourceProvider();
  final TextEditingController _searchController = TextEditingController();
  Map<String, Map<String, dynamic>> sourceQuerySettings = {};
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    
    // Initialize default query settings for searchable sources
    for (var source in searchableSources) {
      sourceQuerySettings[source.name] = getDefaultValuesFromFormItems(
        [source.searchQuerySettingFormItems],
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<AppSource> get searchableSources =>
      sourceProvider.sources.where((e) => e.canSearch).toList();

  Future<void> runSearch() async {
    if (searchQuery.isEmpty) return;

    setState(() {
      searching = true;
      results = {};
      _selectedCategory = null;
      _browsePage = 1;
      _browseHasMore = false;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();
      
      final List<MapEntry<String, Map<String, List<String>>>?> searchResults = await Future.wait(
        searchableSources.map((source) async {
          if (settingsProvider.searchDeselected.contains(source.name)) return null;
          try {
            final res = await source.search(
              searchQuery,
              querySettings: sourceQuerySettings[source.name] ?? {},
            );
            return MapEntry(source.name, res);
          } catch (e) {
            talker.warning('Discover search failed for ${source.name}: $e');
            return null;
          }
        }),
      );

      final Map<String, MapEntry<String, List<String>>> aggregatedResults = {};
      for (final result in searchResults) {
        if (result == null) continue;
        final sourceName = result.key;
        result.value.forEach((url, info) {
          aggregatedResults[url] = MapEntry(sourceName, info);
        });
      }

      setState(() {
        results = aggregatedResults;
      });
    } catch (e) {
      talker.warning('Discover search error: $e');
    } finally {
      setState(() {
        searching = false;
      });
    }
  }

  FDroid get _fdroidSource =>
      sourceProvider.sources.whereType<FDroid>().first;

  bool get _isBrowseMode => _selectedCategory != null && searchQuery.isEmpty;

  Future<void> _startBrowse(String slug) async {
    _searchDebounce?.cancel();
    setState(() {
      _selectedCategory = slug;
      _browsePage = 1;
      _browseHasMore = false;
      searching = true;
      results = {};
    });
    try {
      final res = await _fdroidSource.browseCategory(slug, page: 1);
      if (!mounted) return;
      setState(() {
        results = {
          for (final e in res.apps.entries)
            e.key: MapEntry('F-Droid', e.value),
        };
        _browsePage = 1;
        _browseHasMore = res.hasMore;
      });
    } catch (e) {
      talker.warning('Category browse failed for $slug: $e');
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Future<void> _loadMoreBrowse() async {
    if (_loadingMore || !_browseHasMore || _selectedCategory == null) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _browsePage + 1;
      final res = await _fdroidSource.browseCategory(
        _selectedCategory!,
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        for (final e in res.apps.entries) {
          results[e.key] = MapEntry('F-Droid', e.value);
        }
        _browsePage = nextPage;
        _browseHasMore = res.hasMore;
      });
    } catch (e) {
      talker.warning('Category load-more failed: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _clearBrowse() {
    setState(() {
      _selectedCategory = null;
      _browsePage = 1;
      _browseHasMore = false;
      results = {};
    });
  }

  void showSearchOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return GlassDialog(
          title: tr('searchOptions'),
          icon: Icons.tune_outlined,
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: searchableSources.where((s) => s.searchQuerySettingFormItems.isNotEmpty).map((source) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          source.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      GeneratedForm(
                        items: source.searchQuerySettingFormItems.map((e) {
                          if (sourceQuerySettings[source.name]?.containsKey(e.key) ?? false) {
                            e.defaultValue = sourceQuerySettings[source.name]![e.key];
                          }
                          return [e];
                        }).toList(),
                        onValueChanges: (values, valid, isBuilding) {
                          if (!isBuilding) {
                            sourceQuerySettings[source.name] = values;
                          }
                        },
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('ok')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListResultTile(String url, String name, String description, String sourceName) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(AppOpacity.half),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        sourceName,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      trailing: FilledButton.tonal(
        onPressed: () {
          final addAppState = context.findAncestorStateOfType<AddAppPageState>();
          if (addAppState != null) addAppState.linkFn(url);
        },
        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
        child: Text(tr('add')),
      ),
      onTap: () {
        final addAppState = context.findAncestorStateOfType<AddAppPageState>();
        if (addAppState != null) addAppState.linkFn(url);
      },
    );
  }

  Widget _buildAppGrid(String url, SettingsProvider settings) {
    final result = results[url];
    if (result == null) return const SizedBox.shrink();
    final name = result.value.isNotEmpty ? result.value[0] : '';
    final sourceName = result.key;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final cardRadius = (radius * 0.75).clamp(12.0, 24.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cardRadius),
      child: ConditionalBlur(
        sigma: 12,
        enabled: settings.plusEnableGlassmorphism,
        child: Container(
          decoration: BoxDecoration(
            color: (isDark
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surface)
                .withOpacity(settings.plusEnableGlassmorphism ? 0.65 : 1.0),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(
                settings.plusEnableGlassmorphism ? 0.15 : 0.08,
              ),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              if (settings.plusEnableGlassmorphism)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(cardRadius),
                onTap: () {
                  AppHaptics.selectionClick();
                  final addAppState = context.findAncestorStateOfType<AddAppPageState>();
                  if (addAppState != null) addAppState.linkFn(url);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 68,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(cardRadius * 0.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sourceName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.tonal(
                        onPressed: () {
                          AppHaptics.selectionClick();
                          final addAppState = context.findAncestorStateOfType<AddAppPageState>();
                          if (addAppState != null) addAppState.linkFn(url);
                        },
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius * 0.5)),
                        ),
                        child: Text(tr('add')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Browse F-Droid',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fdroidCategories.map((cat) {
                final isSelected = _selectedCategory == cat.slug;
                return FilterChip(
                  avatar: Icon(cat.icon, size: 16),
                  label: Text(cat.label),
                  selected: isSelected,
                  onSelected: (_) {
                    if (isSelected) {
                      _clearBrowse();
                    } else {
                      _startBrowse(cat.slug);
                    }
                  },
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          if (widget.showAppBar) AdaptiveSliverAppBar(title: tr('discover'), pageId: 'discover'),
          if (widget.showSearchBar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: tr('searchSomeSourcesLabel'),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: showSearchOptions,
                          tooltip: tr('searchOptions'),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: runSearch,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        searchQuery = value;
                        if (_selectedCategory != null) {
                          setState(() {
                            _selectedCategory = null;
                            results = {};
                          });
                        }
                        _searchDebounce?.cancel();
                        _searchDebounce =
                            Timer(const Duration(milliseconds: 800), () {
                          if (mounted && searchQuery.isNotEmpty) runSearch();
                        });
                      },
                      onSubmitted: (_) {
                        _searchDebounce?.cancel();
                        runSearch();
                      },
                    ),
                    if (searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Consumer<SettingsProvider>(
                        builder: (context, settingsProvider, child) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: searchableSources.map((source) {
                              final isSelected = !settingsProvider
                                  .searchDeselected
                                  .contains(source.name);
                              return FilterChip(
                                label: Text(source.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  final currentDeselected = List<String>.from(
                                    settingsProvider.searchDeselected,
                                  );
                                  if (selected) {
                                    currentDeselected.remove(source.name);
                                  } else {
                                    currentDeselected.add(source.name);
                                  }
                                  settingsProvider.searchDeselected =
                                      currentDeselected;
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Category chips — visible when no search query is active
          if (searchQuery.isEmpty) _buildCategoryChips(),
          if (searching || results.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _isGridView = !_isGridView),
                    ),
                  ],
                ),
              ),
            ),
          if (searching)
            _isGridView
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            const AppTileSkeleton(isGrid: true),
                        childCount: 6,
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          const AppTileSkeleton(isGrid: false),
                      childCount: 6,
                    ),
                  )
          else if (results.isNotEmpty)
            _isGridView
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildAppGrid(
                          results.keys.elementAt(index),
                          settings,
                        ),
                        childCount: results.length,
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final url = results.keys.elementAt(index);
                        final result = results[url];
                        if (result == null) return const SizedBox.shrink();
                        final name =
                            result.value.isNotEmpty ? result.value[0] : '';
                        final description =
                            result.value.length > 1 ? result.value[1] : '';
                        final sourceName = result.key;
                        return _buildListResultTile(
                          url,
                          name,
                          description,
                          sourceName,
                        );
                      },
                      childCount: results.length,
                    ),
                  )
          else if (!searching && searchQuery.isNotEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: tr('noResults'),
                subtitle: tr('tryAdjustingFilters'),
              ),
            ),
          // Load more button for browse mode
          if (_isBrowseMode && results.isNotEmpty && _browseHasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.tonal(
                  onPressed: _loadingMore ? null : _loadMoreBrowse,
                  child: _loadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
