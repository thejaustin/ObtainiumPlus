import 'dart:convert';
import 'package:http/http.dart' as http;

/// App metadata resolved from public open databases (F-Droid, IzzyOnDroid, Google Play)
/// without burning GitHub API rate limits.
class OnlineAppMetadata {
  final String packageName;
  final String name;
  final String? author;
  final String? latestVersion;
  final String? summary;
  final String? iconUrl;
  final String sourceDatabase;

  const OnlineAppMetadata({
    required this.packageName,
    required this.name,
    this.author,
    this.latestVersion,
    this.summary,
    this.iconUrl,
    required this.sourceDatabase,
  });
}

class OnlineAppDatabaseService {
  OnlineAppDatabaseService._();

  static final Map<String, OnlineAppMetadata> _cache = {};
  static const int _maxCacheEntries = 200;

  static void _putCache(String packageName, OnlineAppMetadata meta) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[packageName] = meta;
  }

  /// Queries open-access online app registries (F-Droid, IzzyOnDroid) for package metadata.
  /// Bypasses GitHub API rate limits completely.
  static Future<OnlineAppMetadata?> lookupPackage(String packageName) async {
    if (_cache.containsKey(packageName)) {
      return _cache[packageName];
    }

    final encodedPkg = Uri.encodeComponent(packageName);

    // 1. Try F-Droid Official API (free, open, unmetered)
    try {
      final uri = Uri.tryParse(
        'https://f-droid.org/api/v1/packages/$encodedPkg',
      );
      if (uri != null) {
        final res = await http
            .get(uri, headers: {'User-Agent': 'ObtainiumPlus/1.7.3'})
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final meta = OnlineAppMetadata(
            packageName: packageName,
            name: data['packageName'] ?? packageName,
            author: data['authorName'],
            latestVersion: data['suggestedVersionName']?.toString(),
            summary: data['summary'],
            iconUrl: data['icon'] != null
                ? 'https://f-droid.org/repo/icons-640/${data['icon']}'
                : null,
            sourceDatabase: 'F-Droid Open Registry',
          );
          _putCache(packageName, meta);
          return meta;
        }
      }
    } catch (_) {}

    // 2. Try IzzyOnDroid API (thousands of GitHub open-source apps mirrored)
    try {
      final uri = Uri.tryParse(
        'https://apt.izzysoft.de/api/v1/app/$encodedPkg',
      );
      if (uri != null) {
        final res = await http
            .get(uri, headers: {'User-Agent': 'ObtainiumPlus/1.7.3'})
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map && data['name'] != null) {
            final meta = OnlineAppMetadata(
              packageName: packageName,
              name: data['name'] ?? packageName,
              author: data['author'],
              latestVersion: data['version']?.toString(),
              summary: data['summary'],
              iconUrl: data['icon'],
              sourceDatabase: 'IzzyOnDroid Open Registry',
            );
            _putCache(packageName, meta);
            return meta;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Extracts GitHub owner and repo from a GitHub URL
  static (String owner, String repo)? parseGitHubUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.host != 'github.com' && uri.host != 'www.github.com')) {
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2) {
      return (segments[0], segments[1]);
    }
    return null;
  }

  /// Fetches latest release tag directly from the public Atom feed, avoiding GitHub REST API rate limits.
  static Future<String?> fetchGitHubReleaseFromAtom(
    String owner,
    String repo,
  ) async {
    final uri = Uri.tryParse('https://github.com/$owner/$repo/releases.atom');
    if (uri == null) return null;
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final tagMatch = RegExp(
          r'<id>[^<]*/tag/([^<]+)</id>',
        ).firstMatch(res.body);
        if (tagMatch != null) {
          return tagMatch.group(1);
        }
      }
    } catch (_) {}
    return null;
  }
}
