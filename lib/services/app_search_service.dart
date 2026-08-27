import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/logger.dart';

/// Result of [AppSearchService.searchAllSources] — carries not just the
/// merged results but whether every queried source actually failed, so
/// callers can tell "genuinely no matches" apart from "the network died
/// and nothing could be searched" instead of showing the same empty
/// state for both.
class AppSearchResult {
  final Map<String, MapEntry<String, List<String>>> results;
  final int sourcesQueried;
  final int sourcesFailed;

  const AppSearchResult({
    required this.results,
    required this.sourcesQueried,
    required this.sourcesFailed,
  });

  bool get allSourcesFailed =>
      sourcesQueried > 0 && sourcesFailed == sourcesQueried;
}

/// Aggregated multi-source app search shared by the Discover page, the
/// Add App live search, and the command center — these previously carried
/// three divergent copies of the same fan-out/merge loop.
///
/// Results map an app URL to (source name, [name, description, ...]).
/// A source that fails just drops out of the results instead of failing
/// the whole search.
class AppSearchService {
  static Future<AppSearchResult> searchAllSources(
    String query, {
    SourceProvider? sourceProvider,
    Map<String, Map<String, dynamic>> querySettings = const {},
    List<String> deselectedSources = const [],
  }) async {
    final provider = sourceProvider ?? SourceProvider();
    final sources = provider.sources
        .where((e) => e.canSearch && !deselectedSources.contains(e.name))
        .toList();

    int failedCount = 0;
    final searchResults = await Future.wait(
      sources.map((source) async {
        try {
          final res = await source
              .search(query, querySettings: querySettings[source.name] ?? {})
              .timeout(const Duration(seconds: 20));
          return MapEntry(source.name, res);
        } catch (e) {
          // A hung/slow source (network stall, dead host) must not block
          // every other source's results from ever showing up — drop it
          // and let the rest of the search complete.
          failedCount++;
          talker.warning('Search failed for ${source.name}: $e');
          return null;
        }
      }),
    );

    final aggregated = <String, MapEntry<String, List<String>>>{};
    for (final result in searchResults) {
      if (result == null) continue;
      result.value.forEach((url, info) {
        aggregated[url] = MapEntry(result.key, info);
      });
    }
    return AppSearchResult(
      results: aggregated,
      sourcesQueried: sources.length,
      sourcesFailed: failedCount,
    );
  }
}
