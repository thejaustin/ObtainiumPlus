import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/apps/app_tile_skeleton.dart';
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
import 'package:provider/provider.dart';

class DiscoverPage extends StatefulWidget {
  final bool showAppBar;
  final bool showSearchBar;
  final String initialQuery;
  const DiscoverPage({super.key, this.showAppBar = true, this.showSearchBar = true, this.initialQuery = ''});

  @override
  State<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  bool searching = false;
  bool _isGridView = true;
  String searchQuery = '';
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
      // Error handling
    } finally {
      setState(() {
        searching = false;
      });
    }
  }

  void showSearchOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(tr('searchOptions')),
              content: SingleChildScrollView(
                child: Column(
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
                            // Sync with current settings
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('ok')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildListResultTile(String url, String name, String description, String sourceName) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          if (widget.showAppBar) CustomAppBar(title: tr('discover')),
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
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(const Duration(milliseconds: 800), () {
                          if (mounted && searchQuery.isNotEmpty) runSearch();
                        });
                      },
                      onSubmitted: (_) {
                        _searchDebounce?.cancel();
                        runSearch();
                      },
                    ),
                    const SizedBox(height: 12),
                    Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: searchableSources.map((source) {
                            final isSelected = !settingsProvider.searchDeselected.contains(source.name);
                            return FilterChip(
                              label: Text(source.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                final currentDeselected = List<String>.from(settingsProvider.searchDeselected);
                                if (selected) {
                                  currentDeselected.remove(source.name);
                                } else {
                                  currentDeselected.add(source.name);
                                }
                                settingsProvider.searchDeselected = currentDeselected;
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (searching || results.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                      onPressed: () => setState(() => _isGridView = !_isGridView),
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
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const AppTileSkeleton(isGrid: true),
                        childCount: 6,
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const AppTileSkeleton(isGrid: false),
                      childCount: 6,
                    ),
                  )
          else if (results.isNotEmpty)
            _isGridView
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final url = results.keys.elementAt(index);
                          final result = results[url]!;
                          final name = result.value.isNotEmpty ? result.value[0] : '';
                          final sourceName = result.key;
                          final settings = context.watch<SettingsProvider>();
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: settings.plusEnableGlassmorphism ? 10 : 0,
                                sigmaY: settings.plusEnableGlassmorphism ? 10 : 0,
                              ),
                              child: Card(
                                elevation: settings.plusEnableGlassmorphism ? 0 : 2,
                                margin: EdgeInsets.zero,
                                color: (isDark
                                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                                        : Theme.of(context).colorScheme.surface)
                                    .withOpacity(settings.plusEnableGlassmorphism ? 0.7 : 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(settings.plusEnableGlassmorphism ? 0.4 : 0.1,
                                    ),
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    final addAppState = context.findAncestorStateOfType<AddAppPageState>();
                                    if (addAppState != null) addAppState.linkFn(url);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          sourceName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FilledButton.tonal(
                                          onPressed: () {
                                            final addAppState = context.findAncestorStateOfType<AddAppPageState>();
                                            if (addAppState != null) addAppState.linkFn(url);
                                          },
                                          style: FilledButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          child: Text(tr('add')),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: results.length,
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final url = results.keys.elementAt(index);
                        final result = results[url]!;
                        final name = result.value.isNotEmpty ? result.value[0] : '';
                        final description = result.value.length > 1 ? result.value[1] : '';
                        final sourceName = result.key;
                        return _buildListResultTile(url, name, description, sourceName);
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
        ],
      ),
    );
  }
}
