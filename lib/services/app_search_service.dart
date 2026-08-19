import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/logger.dart';

/// Aggregated multi-source app search shared by the Discover page, the
/// Add App live search, and the command center — these previously carried
/// three divergent copies of the same fan-out/merge loop.
///
/// Results map an app URL to (source name, [name, description, ...]).
/// A source that fails just drops out of the results instead of failing
/// the whole search.
class AppSearchService {
  static Future<Map<String, MapEntry<String, List<String>>>> searchAllSources(
    String query, {
    SourceProvider? sourceProvider,
    Map<String, Map<String, dynamic>> querySettings = const {},
    List<String> deselectedSources = const [],
  }) async {
    final provider = sourceProvider ?? SourceProvider();
    final sources = provider.sources.where((e) => e.canSearch).toList();

    final searchResults = await Future.wait(
      sources.map((source) async {
        if (deselectedSources.contains(source.name)) return null;
        try {
          final res = await source
              .search(query, querySettings: querySettings[source.name] ?? {})
              .timeout(const Duration(seconds: 20));
          return MapEntry(source.name, res);
        } catch (e) {
          // A hung/slow source (network stall, dead host) must not block
          // every other source's results from ever showing up — drop it
          // and let the rest of the search complete.
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
    return aggregated;
  }
}
