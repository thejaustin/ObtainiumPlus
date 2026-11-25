import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A GitHub user who contributed to a repository.
class Contributor {
  final String login;
  final int contributions;

  const Contributor(this.login, this.contributions);

  String get profileUrl => 'https://github.com/$login';
}

/// Contributor lists for the credits sheet, from the GitHub API.
///
/// Cached for a day (the unauthenticated quota is 60 requests an hour) and
/// the last copy is served when offline.
class ContributorsService {
  static const forkRepo = 'thejaustin/ObtainiumPlus';
  static const upstreamRepo = 'ImranR98/Obtainium';
  static const _ttl = Duration(hours: 24);

  /// Accounts that are the AI pair-programmer's git identity: credited as a
  /// line of text instead of a person.
  static const _aiAccounts = {'claude'};

  /// Test hook: returns the raw response body for a repo.
  static Future<String> Function(String repo)? debugFetch;

  static bool _isBot(String login, String? type) =>
      type == 'Bot' ||
      login.endsWith('[bot]') ||
      RegExp(r'[-_]bot$', caseSensitive: false).hasMatch(login) ||
      RegExp(r'[a-z]Bot$').hasMatch(login) ||
      _aiAccounts.contains(login.toLowerCase());

  /// Parses the API body into people, most contributions first, bots out.
  static List<Contributor> parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) return [];
    final out = <Contributor>[];
    for (final e in decoded) {
      if (e is! Map) continue;
      final login = e['login'];
      final n = e['contributions'];
      if (login is! String || n is! int) continue;
      if (_isBot(login, e['type'] as String?)) continue;
      out.add(Contributor(login, n));
    }
    out.sort((a, b) => b.contributions.compareTo(a.contributions));
    return out;
  }

  /// Work done in the fork itself: its counts minus the same person's count
  /// upstream, since the fork's history includes all of upstream's.
  static List<Contributor> forkOnly(
    List<Contributor> fork,
    List<Contributor> upstream,
  ) {
    final up = {for (final c in upstream) c.login: c.contributions};
    final out = [
      for (final c in fork)
        if (c.contributions - (up[c.login] ?? 0) > 0)
          Contributor(c.login, c.contributions - (up[c.login] ?? 0)),
    ];
    out.sort((a, b) => b.contributions.compareTo(a.contributions));
    return out;
  }

  static Future<List<Contributor>> _load(String repo) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'contributors_cache_$repo';
    final tsKey = '${key}_ts';
    final cached = prefs.safeString(key);
    final ts = prefs.safeInt(tsKey);
    if (cached != null &&
        ts != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <
            _ttl) {
      return parse(cached);
    }
    try {
      final body =
          await (debugFetch?.call(repo) ??
              http
                  .get(
                    Uri.parse(
                      'https://api.github.com/repos/$repo/contributors?per_page=100',
                    ),
                    headers: {'Accept': 'application/vnd.github+json'},
                  )
                  .timeout(const Duration(seconds: 10))
                  .then((r) {
                    if (r.statusCode != 200) {
                      throw Exception('GitHub returned ${r.statusCode}');
                    }
                    return r.body;
                  }));
      final parsed = parse(body);
      await prefs.setString(key, body);
      await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
      return parsed;
    } catch (_) {
      if (cached != null) return parse(cached);
      rethrow;
    }
  }

  /// (Obtainium+ contributors, upstream Obtainium contributors).
  static Future<(List<Contributor>, List<Contributor>)> loadBoth() async {
    final results = await Future.wait([_load(forkRepo), _load(upstreamRepo)]);
    return (forkOnly(results[0], results[1]), results[1]);
  }
}
