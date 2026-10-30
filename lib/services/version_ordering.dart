// Decides whether an app's latest version is newer or older than the installed
// one, and records which signal settled it.
//
// Version strings come first. Where they can't be ordered (one side carries a
// label the other lacks, `1.4.0-rc1` vs `1.4.0`, an app switching from date
// versions to semantic ones), the release timeline decides: when each version
// came out, from the app's version history.

import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/version_history_entry.dart';
import 'package:obtainium/utils/version_utils.dart';

/// What settled a [VersionOrdering].
enum VersionOrderBasis {
  /// The full version strings compared cleanly.
  version,

  /// Only the leading numeric cores (`1.2.3` in `1.2.3-gplay`) compared.
  numericCore,

  /// The versions' release (or detection) dates.
  releaseDate,

  /// No signal was confident enough.
  unknown,
}

class VersionOrdering {
  const VersionOrdering(this.order, this.basis);

  /// Negative: latest is newer (an update). Positive: latest is older (a
  /// downgrade). Zero: same release. Null: unknown.
  final int? order;
  final VersionOrderBasis basis;

  static const unknown = VersionOrdering(null, VersionOrderBasis.unknown);

  bool get isDowngrade => order != null && order! > 0;

  @override
  String toString() => 'VersionOrdering($order, ${basis.name})';
}

/// Release dates closer than this don't order two versions: same-day
/// re-tags, mirrors and time zones blur them.
const Duration releaseDateMargin = Duration(hours: 6);

/// Orders [installed] against [latest] for [app]; see the file comment.
VersionOrdering resolveVersionOrdering(
  App app,
  String installed,
  String latest,
) {
  final full = compareVersionStrings(installed, latest);
  if (full != null) {
    // A scheme switch (`2024.10.5` -> `3.2.0`) reads as a downgrade by the
    // numbers; trust the timeline when it says the release is newer.
    if (full > 0 && _schemesDiffer(installed, latest)) {
      final byDate = _compareByReleaseDate(app, installed, latest);
      if (byDate != null && byDate < 0) {
        return VersionOrdering(byDate, VersionOrderBasis.releaseDate);
      }
    }
    if (full != 0) return VersionOrdering(full, VersionOrderBasis.version);
  }
  final core = compareVersionCores(installed, latest);
  if (core != null && core != 0) {
    return VersionOrdering(core, VersionOrderBasis.numericCore);
  }
  final byDate = _compareByReleaseDate(app, installed, latest);
  if (byDate != null) {
    return VersionOrdering(byDate, VersionOrderBasis.releaseDate);
  }
  if (full == 0 || core == 0) {
    return const VersionOrdering(0, VersionOrderBasis.version);
  }
  return VersionOrdering.unknown;
}

bool _schemesDiffer(String a, String b) {
  final ca = RegExp(r'\d+').firstMatch(a)?.group(0);
  final cb = RegExp(r'\d+').firstMatch(b)?.group(0);
  if (ca == null || cb == null) return false;
  return (int.parse(ca) >= 1000) != (int.parse(cb) >= 1000);
}

/// Orders by when each version came out. Both sides must use the same kind of
/// date: real release dates, or (when the source has none) the times
/// Obtainium+ first saw each version in its history.
int? _compareByReleaseDate(App app, String installed, String latest) {
  final history = app.versionHistory;
  if (history.isEmpty) return null;
  final installedEntry = _findEntry(history, installed);
  if (installedEntry == null) return null;
  final latestEntry = _findEntry(history, latest);

  // With detectionDateAsReleaseDate the app's releaseDate is a detection time,
  // not a release date.
  final detectionDates =
      app.additionalSettings['detectionDateAsReleaseDate'] == true;
  final latestRelease = detectionDates
      ? null
      : (app.latestVersion == latest ? app.releaseDate : null) ??
            latestEntry?.releaseDate;
  final installedRelease = detectionDates ? null : installedEntry.releaseDate;

  DateTime? a;
  DateTime? b;
  if (installedRelease != null && latestRelease != null) {
    a = installedRelease;
    b = latestRelease;
  } else if (latestEntry != null &&
      installedRelease == null &&
      latestEntry.releaseDate == null) {
    a = installedEntry.detectedAt;
    b = latestEntry.detectedAt;
  }
  if (a == null || b == null) return null;
  final diff = b.difference(a);
  if (diff.abs() < releaseDateMargin) return null;
  return diff.isNegative ? 1 : -1;
}

/// The history entry for [version]: an exact match, else a normalized one
/// (`v1.2.3` = `1.2.3`), else the single entry with the same numeric core.
/// Ambiguous matches count as none.
VersionHistoryEntry? _findEntry(
  List<VersionHistoryEntry> history,
  String version,
) {
  for (final e in history) {
    if (e.version == version) return e;
  }
  final normalized = normalizeVersion(version.trim());
  final byNormalized = history
      .where((e) => normalizeVersion(e.version.trim()) == normalized)
      .toList();
  if (byNormalized.length == 1) return byNormalized.single;
  if (byNormalized.length > 1) return null;
  final byCore = history
      .where((e) => compareVersionCores(e.version, version) == 0)
      .toList();
  return byCore.length == 1 ? byCore.single : null;
}
