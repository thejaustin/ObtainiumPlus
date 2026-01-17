import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends State<DiscoverPage> {
  bool searching = false;
  String searchQuery = '';
  Map<String, MapEntry<String, List<String>>> results = {};
  SourceProvider sourceProvider = SourceProvider();

  Future<void> runSearch() async {
    if (searchQuery.isEmpty) return;

    setState(() {
      searching = true;
      results = {};
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();
      final searchableSources = sourceProvider.sources.where((e) => e.canSearch).toList();
      
      final List<MapEntry<String, Map<String, List<String>>>?> searchResults = await Future.wait(
        searchableSources.map((source) async {
          if (settingsProvider.searchDeselected.contains(source.name)) return null;
          try {
            final res = await source.search(searchQuery);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          CustomAppBar(title: tr('discover')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: tr('searchSomeSourcesLabel'),
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
                  if (searching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
          if (results.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final url = results.keys.elementAt(index);
                  final result = results[url]!;
                  final name = result.value.isNotEmpty ? result.value[0] : '';
                  final description = result.value.length > 1 ? result.value[1] : '';
                  final sourceName = result.key;

                  return ListTile(
                    title: Text(name),
                    subtitle: Text('$sourceName • $description', maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      final homeState = context.findAncestorStateOfType<HomePageState>();
                      if (homeState != null) {
                        homeState.switchToPage(2);
                        // Wait for page to build then call linkFn
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final addAppKey = homeState.pages[2].widget.key as GlobalKey<AddAppPageState>?;
                          addAppKey?.currentState?.linkFn(url);
                        });
                      }
                    },
                  );
                },
                childCount: results.length,
              ),
            )
          else if (!searching && searchQuery.isNotEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No results found')),
            ),
        ],
      ),
    );
  }
}
