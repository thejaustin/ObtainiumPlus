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
  final String initialQuery;
  const DiscoverPage({super.key, this.showAppBar = true, this.initialQuery = ''});

  @override
  State<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  bool searching = false;
  String searchQuery = '';
  Map<String, MapEntry<String, List<String>>> results = {};
  SourceProvider sourceProvider = SourceProvider();
  final TextEditingController _searchController = TextEditingController();
  Map<String, Map<String, dynamic>> sourceQuerySettings = {};

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

  void _showSearchOptions() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          if (widget.showAppBar) CustomAppBar(title: tr('discover')),
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
                        onPressed: _showSearchOptions,
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
                    onChanged: (value) => searchQuery = value,
                    onSubmitted: (_) => runSearch(),
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
          if (searching)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const AppTileSkeleton(isGrid: true),
                  childCount: 6,
                ),
              ),
            )
          else if (results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final url = results.keys.elementAt(index);
                    final result = results[url]!;
                    final name = result.value.isNotEmpty ? result.value[0] : '';
                    final description = result.value.length > 1 ? result.value[1] : '';
                    final sourceName = result.key;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final addAppState = context.findAncestorStateOfType<AddAppPageState>();
                          if (addAppState != null) {
                            addAppState.linkFn(url);
                          }
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
                                      color: Theme.of(context).colorScheme.primaryContainer,
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
                                maxLines: 1,
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
                                  if (addAppState != null) {
                                    addAppState.linkFn(url);
                                  }
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
                    );
                  },
                  childCount: results.length,
                ),
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
