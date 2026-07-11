import 'dart:convert';
import 'dart:math';

import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single suggested app shown in the Discover feed.
class DiscoverFeedApp {
  final String url;
  final String name;
  final String description;
  final String sourceName;

  const DiscoverFeedApp({
    required this.url,
    required this.name,
    required this.description,
    required this.sourceName,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'description': description,
    'sourceName': sourceName,
  };

  factory DiscoverFeedApp.fromJson(Map<String, dynamic> json) =>
      DiscoverFeedApp(
        url: json['url'] as String,
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        sourceName: (json['sourceName'] as String?) ?? '',
      );
}

/// Fetches and caches a default feed of suggested apps for the Discover
/// section so it can show content immediately, without a search or a
/// category tap.
///
/// Source: the Obtainium crowdsourced app catalog at
/// https://apps.obtainium.imranr.dev/apps — a community-maintained list of
/// apps people actually track with Obtainium (GitHub, F-Droid, IzzyOnDroid
/// and more). Each listed app carries an `obtainium://app/<json>` deep link
/// whose payload includes the app's name, source URL and description, which
/// is what this service parses.
///
/// Caching follows the KnownIssuesService pattern: the parsed feed is stored
/// as a JSON string in SharedPreferences with a timestamp. Reads are
/// stale-while-revalidate — callers render the cached feed instantly and
/// refresh in the background when it is older than [_cacheTtlHours]. All
/// network and parse failures degrade silently to the cached (or empty)
/// feed; this must never surface an error to the Discover page.
class DiscoverFeedService {
  static const _feedUrl = 'https://apps.obtainium.imranr.dev/apps';
  static const _deepLinkPrefix = 'obtainium://app/';
  static const _cacheKey = 'discoverFeedCache';
  static const _cacheTimestampKey = 'discoverFeedCacheTs';

  /// Cache TTL: refresh in the background at most once every 24 hours.
  static const _cacheTtlHours = 24;

  /// Maximum number of suggestions kept in the feed.
  static const _maxFeedSize = 30;

  /// Returns the cached feed without touching the network.
  /// Returns an empty list if nothing is cached or the cache is unreadable.
  static Future<List<DiscoverFeedApp>> getCachedFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.safeString(_cacheKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => DiscoverFeedApp.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      talker.warning('Discover feed cache read failed: $e');
      return [];
    }
  }

  /// Fetches a fresh feed if the cache is missing or older than the TTL.
  /// Returns the fresh feed on success, or null when the cache is still
  /// fresh or the refresh failed (callers keep whatever they already have).
  static Future<List<DiscoverFeedApp>?> refreshFeedIfStale() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final cacheTs = prefs.safeInt(_cacheTimestampKey);
      if (cacheTs != null) {
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cacheTs),
        );
        if (age.inHours < _cacheTtlHours &&
            (prefs.safeString(_cacheKey)?.isNotEmpty ?? false)) {
          return null;
        }
      }
    } catch (e) {
      talker.warning('Discover feed cache check failed: $e');
    }

    List<DiscoverFeedApp> feed;
    try {
      final response = await http
          .get(Uri.parse(_feedUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      feed = _parseCatalogHtml(response.body);
    } catch (e) {
      talker.warning('Discover feed fetch failed: $e');
      return null;
    }
    if (feed.isEmpty) return null;

    // Shuffle once at fetch time so the suggestions vary between refreshes
    // (the catalog page itself is alphabetical), then cap the size.
    feed.shuffle(Random());
    if (feed.length > _maxFeedSize) {
      feed = feed.sublist(0, _maxFeedSize);
    }

    try {
      await prefs?.setString(
        _cacheKey,
        jsonEncode(feed.map((e) => e.toJson()).toList()),
      );
      await prefs?.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Cache write failure is non-fatal — still return the fresh feed.
      talker.warning('Discover feed cache write failed: $e');
    }
    return feed;
  }

  /// Extracts apps from the catalog page's `obtainium://app/<json>` links.
  static List<DiscoverFeedApp> _parseCatalogHtml(String html) {
    final byUrl = <String, DiscoverFeedApp>{};
    for (final anchor in parse(html).querySelectorAll('a')) {
      final href = anchor.attributes['href'];
      if (href == null || !href.startsWith(_deepLinkPrefix)) continue;
      try {
        final payload =
            jsonDecode(Uri.decodeComponent(href.substring(_deepLinkPrefix.length)))
                as Map<String, dynamic>;
        final url = payload['url'] as String?;
        final name = (payload['name'] as String?)?.trim() ?? '';
        if (url == null || url.isEmpty || name.isEmpty) continue;

        String description = '';
        final additionalSettings = payload['additionalSettings'];
        if (additionalSettings is String && additionalSettings.isNotEmpty) {
          try {
            final settings =
                jsonDecode(additionalSettings) as Map<String, dynamic>;
            description = (settings['about'] as String?)?.trim() ?? '';
          } catch (_) {
            // Malformed nested settings — keep the app without a description.
          }
        }

        byUrl[url] = DiscoverFeedApp(
          url: url,
          name: name,
          description: description,
          sourceName: _sourceLabelFor(url),
        );
      } catch (_) {
        // Skip malformed deep links instead of failing the whole feed.
      }
    }
    return byUrl.values.toList();
  }

  static String _sourceLabelFor(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('github.com')) return 'GitHub';
    if (host.contains('gitlab.com')) return 'GitLab';
    if (host.contains('f-droid.org')) return 'F-Droid';
    if (host.contains('izzysoft.de')) return 'IzzyOnDroid';
    if (host.contains('codeberg.org')) return 'Codeberg';
    if (host.contains('sourceforge.net')) return 'SourceForge';
    return host.isNotEmpty ? host : 'Web';
  }
}
