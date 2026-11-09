import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:obtainium/core/logging/app_logger.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/release_note.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/release_notes_utils.dart';
import 'package:obtainium/utils/version_normalization.dart';

class _CacheEntry {
  final DateTime fetchedAt;
  final Future<List<ReleaseNote>> notes;
  _CacheEntry(this.fetchedAt, this.notes);
}

/// Fetches per-version release notes from the forge an app is tracked from.
///
/// Only called when the user opens the version history (never during update
/// checks). Results are cached in memory per app URL for [cacheTtl]; failures
/// (including rate limits) yield an empty list, which callers treat as
/// "fall back to the locally recorded history", and are not cached.
class ReleaseNotesService {
  ReleaseNotesService._();
  static final ReleaseNotesService instance = ReleaseNotesService._();

  static const Duration cacheTtl = Duration(minutes: 15);

  /// Replaces the network fetch in tests.
  @visibleForTesting
  static Future<List<ReleaseNote>> Function(App app, int limit)? fetchOverride;

  /// Clock used for cache expiry; replaceable in tests.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  final Map<String, _CacheEntry> _cache = {};

  @visibleForTesting
  void clearCache() => _cache.clear();

  Future<List<ReleaseNote>> fetch(App app, {int limit = 20}) {
    final key = '${app.overrideSource ?? ''}|${app.url}';
    final now = clock();
    final cached = _cache[key];
    if (cached != null && now.difference(cached.fetchedAt) < cacheTtl) {
      return cached.notes;
    }
    final future = _fetchUncached(app, limit).then(
      dedupe,
      onError: (Object e) {
        if (e is RateLimitError) {
          AppLogger.info(
            'Release notes for ${app.url} skipped: rate limited '
            '(${e.remainingMinutes} min)',
          );
        } else {
          AppLogger.info('Release notes fetch failed for ${app.url}: $e');
        }
        _cache.remove(key); // let a later expand retry
        return const <ReleaseNote>[];
      },
    );
    _cache[key] = _CacheEntry(now, future);
    return future;
  }

  Future<List<ReleaseNote>> _fetchUncached(App app, int limit) async {
    final override = fetchOverride;
    if (override != null) return override(app, limit);
    final source = SourceProvider().getSource(
      app.url,
      overrideSource: app.overrideSource,
    );
    if (!source.supportsReleaseNotes) return const [];
    final notes = await source.getReleaseNotes(
      app.url,
      app.additionalSettings,
      limit: limit,
    );
    final sp = SettingsProvider();
    await sp.initializeSettings();
    return applyAppReleaseSettings(
      notes,
      app.additionalSettings,
      extractVersion: source.suppressStandardVersionExtraction
          ? null
          : (tag) => extractVersionWithGlobalDefault(
              app.additionalSettings,
              sp,
              tag,
              allowGlobalDefault: !source.excludeCommonSettingKeys.contains(
                'versionExtractionRegEx',
              ),
            ),
    );
  }

  /// Applies the app's own release settings to fetched notes, the same way
  /// update checks do: the release-title filter (with its invert option)
  /// drops other apps' releases in shared repos, and version extraction
  /// turns tags into the versions the app tracks, so the Latest/Installed
  /// badges match.
  @visibleForTesting
  static List<ReleaseNote> applyAppReleaseSettings(
    List<ReleaseNote> notes,
    Map<String, dynamic> settings, {
    String? Function(String tag)? extractVersion,
  }) {
    final pattern = settings['filterReleaseTitlesByRegEx'];
    RegExp? titleRegex;
    if (pattern is String && pattern.isNotEmpty) {
      try {
        titleRegex = RegExp(pattern);
      } catch (_) {}
    }
    final invert = settings['invertReleaseTitlesFilter'] == true;
    final out = <ReleaseNote>[];
    for (final n in notes) {
      if (titleRegex != null) {
        final hit =
            titleRegex.hasMatch(n.title ?? '') || titleRegex.hasMatch(n.version);
        if (hit == invert) continue;
      }
      String? extracted;
      try {
        extracted = extractVersion?.call(n.version);
      } catch (_) {
        // A per-app regex that doesn't match this tag throws; keep the tag.
      }
      out.add(
        extracted != null && extracted.isNotEmpty
            ? n.copyWith(version: extracted)
            : n,
      );
    }
    return out;
  }

  /// Blanks the body of any entry whose notes are the same as the next-older
  /// entry's (projects that re-post the previous notes). The version row is
  /// kept so every published version still shows; empty bodies are never
  /// treated as duplicates. [notes] must be newest first.
  static List<ReleaseNote> dedupe(List<ReleaseNote> notes) {
    final normalized = notes.map((n) => normalizeReleaseNotes(n.body)).toList();
    return [
      for (var i = 0; i < notes.length; i++)
        if (normalized[i].isNotEmpty &&
            i + 1 < notes.length &&
            normalized[i] == normalized[i + 1])
          notes[i].copyWith(body: '')
        else
          notes[i],
    ];
  }

  /// Whether release [tag] names [version] (e.g. `v1.7.3-p15` and
  /// `1.7.3-p15`), ignoring cosmetic packaging differences.
  static bool tagMatchesVersion(String tag, String? version) {
    if (version == null || version.trim().isEmpty) return false;
    return tag.trim() == version.trim() ||
        versionsAreCosmeticallyEqual(tag, version);
  }

  /// Whether [tag] is the release of the installed build [installed], which
  /// may carry extra packaging words (`1.6.15-debug`) the tag does not.
  static bool tagMatchesInstalled(String tag, String? installed) {
    if (installed == null || installed.trim().isEmpty) return false;
    return tag.trim() == installed.trim() ||
        installedMatchesRemote(installed: installed, remote: tag);
  }

  /// The note for [version], if any.
  static ReleaseNote? findForVersion(List<ReleaseNote> notes, String version) {
    for (final n in notes) {
      if (tagMatchesVersion(n.version, version)) return n;
    }
    return null;
  }
}
