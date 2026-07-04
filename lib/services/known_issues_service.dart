import 'dart:convert';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A single entry from `known_issues.json`.
class KnownIssue {
  final String id;
  final String title;
  final String description;

  /// 'critical' | 'warning'
  final String severity;

  /// Exact versionName strings this issue affects (e.g. "1.2.9-p81").
  final List<String> affectedVersions;

  /// Inclusive build-number range (versionCode). Both are optional.
  final int? minBuild;
  final int? maxBuild;

  final String githubIssueUrl;

  /// Human-readable version in which the fix ships, shown as a hint.
  final String? fixedInVersion;

  /// When true, a skippable "update recommended" dialog is shown instead of
  /// the non-dismissible CriticalIssueDialog.  The user can skip (with an
  /// optional "don't show again" toggle) or tap "Update Now".
  final bool forceUpdate;

  const KnownIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.affectedVersions,
    this.minBuild,
    this.maxBuild,
    required this.githubIssueUrl,
    this.fixedInVersion,
    this.forceUpdate = false,
  });

  factory KnownIssue.fromJson(Map<String, dynamic> json) => KnownIssue(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    severity: (json['severity'] as String?) ?? 'warning',
    affectedVersions:
        (json['affectedVersions'] as List<dynamic>?)?.cast<String>() ?? [],
    minBuild:
        (json['affectedBuildRange'] as Map<String, dynamic>?)?['min'] as int?,
    maxBuild:
        (json['affectedBuildRange'] as Map<String, dynamic>?)?['max'] as int?,
    githubIssueUrl: json['githubIssueUrl'] as String,
    fixedInVersion: json['fixedInVersion'] as String?,
    forceUpdate: (json['forceUpdate'] as bool?) ?? false,
  );

  bool affects(String versionName, int buildNumber) {
    if (affectedVersions.isNotEmpty) {
      return affectedVersions.contains(versionName);
    }
    if (minBuild != null || maxBuild != null) {
      final aboveMin = minBuild == null || buildNumber >= minBuild!;
      final belowMax = maxBuild == null || buildNumber <= maxBuild!;
      return aboveMin && belowMax;
    }
    return false;
  }
}

class KnownIssuesService {
  static const _issuesUrl =
      'https://raw.githubusercontent.com/thejaustin/ObtainiumPlus/main/known_issues.json';
  static const _cacheKey = 'known_issues_cache';
  static const _cacheTimestampKey = 'known_issues_cache_ts';
  static const _dismissedKey = 'dismissed_known_issue_ids';

  /// Cache TTL: re-fetch at most once every 6 hours.
  static const _cacheTtlHours = 6;

  /// Returns issues that affect [versionName]/[buildNumber] and haven't been
  /// dismissed by the user.  Returns an empty list on any network/parse error.
  static Future<List<KnownIssue>> getActiveIssues(
    String versionName,
    int buildNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = await _fetchWithCache(prefs);
    if (cachedJson == null) return [];

    List<KnownIssue> issues;
    try {
      final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
      issues = (decoded['issues'] as List<dynamic>)
          .map((e) => KnownIssue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }

    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    return issues
        .where(
          (i) =>
              i.affects(versionName, buildNumber) && !dismissed.contains(i.id),
        )
        .toList();
  }

  /// Marks an issue as dismissed so it won't be shown again on this device.
  static Future<void> dismissIssue(String issueId) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = List<String>.from(
      prefs.getStringList(_dismissedKey) ?? [],
    );
    if (!dismissed.contains(issueId)) {
      dismissed.add(issueId);
      await prefs.setStringList(_dismissedKey, dismissed);
    }
  }

  static Future<String?> _fetchWithCache(SharedPreferences prefs) async {
    final cacheTs = prefs.safeInt(_cacheTimestampKey);
    if (cacheTs != null) {
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTs),
      );
      if (age.inHours < _cacheTtlHours) {
        return prefs.getString(_cacheKey);
      }
    }

    try {
      final response = await http
          .get(Uri.parse(_issuesUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await prefs.setString(_cacheKey, response.body);
        await prefs.setInt(
          _cacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        return response.body;
      }
    } catch (_) {
      // Network unavailable — fall back to stale cache
    }
    return prefs.getString(_cacheKey);
  }
}
