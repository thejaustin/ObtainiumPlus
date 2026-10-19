import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/core/logging/app_logger.dart';
import 'package:obtainium/models/typed_settings.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/url_validator.dart';
import 'package:obtainium/models/version_history_entry.dart';

/// Converts a list of [MapEntry] pairs into a 2D list of strings for JSON encoding.
List<List<String>> stringMapListTo2DList(
  List<MapEntry<String, String>> mapList,
) => mapList.map((e) => [e.key, e.value]).toList();

/// Converts a 2D list (decoded from JSON) back into a list of [MapEntry] pairs.
List<MapEntry<String, String>> assumed2DlistToStringMapList(
  List<dynamic> arr,
) => arr.map((e) => MapEntry(e[0] as String, e[1] as String)).toList();

class App {
  late String id;
  late String url;
  late String author;
  late String name;
  String? installedVersion;
  late String latestVersion;
  List<MapEntry<String, String>> apkUrls = [];
  List<MapEntry<String, String>> otherAssetUrls = [];
  late int preferredApkIndex;
  late Map<String, dynamic> additionalSettings;
  late DateTime? lastUpdateCheck;
  bool pinned = false;
  bool disabled = false;
  List<String> categories;
  List<String> tags;
  late DateTime? releaseDate;
  late String? changeLog;
  late String? releaseUrl;
  late String? overrideSource;
  bool allowIdChange = false;
  List<VersionHistoryEntry> versionHistory = [];

  /// If non-null, the app's source has a new canonical URL and a rename is pending.
  String? pendingRepoRenameUrl;

  bool get hasPendingRepoRename =>
      pendingRepoRenameUrl != null && pendingRepoRenameUrl!.isNotEmpty;

  int? apkSizeBytes;
  DateTime? latestVersionChangedAt;
  int consecutiveFailedChecks = 0;
  bool? isArchived;
  int? newerReleasesFilteredOut;
  bool updateHealthEnabled = true;
  String? updateHealthDismissedVersion;

  App(
    this.id,
    this.url,
    this.author,
    this.name,
    this.installedVersion,
    this.latestVersion,
    this.apkUrls,
    this.preferredApkIndex,
    this.additionalSettings,
    this.lastUpdateCheck,
    this.pinned, {
    this.disabled = false,
    this.categories = const [],
    this.tags = const [],
    this.releaseDate,
    this.changeLog,
    this.releaseUrl,
    this.overrideSource,
    this.allowIdChange = false,
    this.otherAssetUrls = const [],
    this.versionHistory = const [],
    this.apkSizeBytes,
    this.latestVersionChangedAt,
    this.consecutiveFailedChecks = 0,
    this.isArchived,
    this.newerReleasesFilteredOut,
    this.updateHealthEnabled = true,
    this.updateHealthDismissedVersion,
  });

  @override
  String toString() {
    return 'ID: $id URL: $url INSTALLED: $installedVersion LATEST: $latestVersion APK: $apkUrls PREFERREDAPK: $preferredApkIndex ADDITIONALSETTINGS: ${additionalSettings.toString()} LASTCHECK: ${lastUpdateCheck.toString()} PINNED $pinned';
  }

  String? get overrideName {
    final n = settings.getStringOrNull('appName');
    return n != null && n.trim().isNotEmpty ? n : null;
  }

  String get finalName => overrideName ?? name;

  String? get overrideAuthor {
    final a = settings.getStringOrNull('appAuthor');
    return a != null && a.trim().isNotEmpty ? a : null;
  }

  String get finalAuthor => overrideAuthor ?? author;

  /// Type-safe accessor for [additionalSettings].
  TypedSettings get settings => TypedSettings(additionalSettings);

  static const Object _sentinel = Object();

  App copyWith({
    String? id,
    String? url,
    String? author,
    String? name,
    Object? installedVersion = _sentinel,
    String? latestVersion,
    List<MapEntry<String, String>>? apkUrls,
    List<MapEntry<String, String>>? otherAssetUrls,
    int? preferredApkIndex,
    Map<String, dynamic>? additionalSettings,
    Object? lastUpdateCheck = _sentinel,
    bool? pinned,
    bool? disabled,
    List<String>? categories,
    List<String>? tags,
    Object? releaseDate = _sentinel,
    Object? changeLog = _sentinel,
    Object? releaseUrl = _sentinel,
    Object? overrideSource = _sentinel,
    bool? allowIdChange,
    List<VersionHistoryEntry>? versionHistory,
    Object? pendingRepoRenameUrl = _sentinel,
    Object? apkSizeBytes = _sentinel,
    Object? latestVersionChangedAt = _sentinel,
    int? consecutiveFailedChecks,
    Object? isArchived = _sentinel,
    Object? newerReleasesFilteredOut = _sentinel,
    bool? updateHealthEnabled,
    Object? updateHealthDismissedVersion = _sentinel,
  }) {
    return App(
        id ?? this.id,
        url ?? this.url,
        author ?? this.author,
        name ?? this.name,
        installedVersion == _sentinel
            ? this.installedVersion
            : installedVersion as String?,
        latestVersion ?? this.latestVersion,
        apkUrls ?? List<MapEntry<String, String>>.from(this.apkUrls),
        preferredApkIndex ?? this.preferredApkIndex,
        additionalSettings ??
            Map<String, dynamic>.from(this.additionalSettings),
        lastUpdateCheck == _sentinel
            ? this.lastUpdateCheck
            : lastUpdateCheck as DateTime?,
        pinned ?? this.pinned,
        disabled: disabled ?? this.disabled,
        categories: categories ?? List<String>.from(this.categories),
        tags: tags ?? List<String>.from(this.tags),
        releaseDate: releaseDate == _sentinel
            ? this.releaseDate
            : releaseDate as DateTime?,
        changeLog: changeLog == _sentinel
            ? this.changeLog
            : changeLog as String?,
        releaseUrl: releaseUrl == _sentinel
            ? this.releaseUrl
            : releaseUrl as String?,
        overrideSource: overrideSource == _sentinel
            ? this.overrideSource
            : overrideSource as String?,
        allowIdChange: allowIdChange ?? this.allowIdChange,
        otherAssetUrls:
            otherAssetUrls ??
            List<MapEntry<String, String>>.from(this.otherAssetUrls),
        versionHistory: versionHistory ?? List.from(this.versionHistory),
        apkSizeBytes: apkSizeBytes == _sentinel
            ? this.apkSizeBytes
            : apkSizeBytes as int?,
        latestVersionChangedAt: latestVersionChangedAt == _sentinel
            ? this.latestVersionChangedAt
            : latestVersionChangedAt as DateTime?,
        consecutiveFailedChecks:
            consecutiveFailedChecks ?? this.consecutiveFailedChecks,
        isArchived: isArchived == _sentinel
            ? this.isArchived
            : isArchived as bool?,
        newerReleasesFilteredOut: newerReleasesFilteredOut == _sentinel
            ? this.newerReleasesFilteredOut
            : newerReleasesFilteredOut as int?,
        updateHealthEnabled: updateHealthEnabled ?? this.updateHealthEnabled,
        updateHealthDismissedVersion: updateHealthDismissedVersion == _sentinel
            ? this.updateHealthDismissedVersion
            : updateHealthDismissedVersion as String?,
      )
      ..pendingRepoRenameUrl = (pendingRepoRenameUrl == _sentinel
          ? this.pendingRepoRenameUrl
          : pendingRepoRenameUrl as String?);
  }

  App deepCopy() => App(
    id,
    url,
    author,
    name,
    installedVersion,
    latestVersion,
    apkUrls,
    preferredApkIndex,
    Map.from(additionalSettings),
    lastUpdateCheck,
    pinned,
    disabled: disabled,
    categories: List<String>.from(categories),
    tags: List<String>.from(tags),
    changeLog: changeLog,
    releaseDate: releaseDate,
    releaseUrl: releaseUrl,
    overrideSource: overrideSource,
    allowIdChange: allowIdChange,
    otherAssetUrls: List.from(otherAssetUrls),
    versionHistory: List.from(versionHistory),
    apkSizeBytes: apkSizeBytes,
    latestVersionChangedAt: latestVersionChangedAt,
    consecutiveFailedChecks: consecutiveFailedChecks,
    isArchived: isArchived,
    newerReleasesFilteredOut: newerReleasesFilteredOut,
    updateHealthEnabled: updateHealthEnabled,
    updateHealthDismissedVersion: updateHealthDismissedVersion,
  )..pendingRepoRenameUrl = pendingRepoRenameUrl;

  factory App.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> Function(Map<String, dynamic>)? migrator,
  }) {
    if (migrator != null) {
      json = migrator(json);
    }
    try {
      return App(
        URLValidator.sanitizeAppId(json['id'] as String),
        json['url'] as String,
        json['author'] as String,
        json['name'] as String,
        json['installedVersion'] == null
            ? null
            : json['installedVersion'] as String,
        (json['latestVersion'] ?? tr('unknown')) as String,
        assumed2DlistToStringMapList(
          safeJsonDecode(json['apkUrls'], [
                ["placeholder", "placeholder"],
              ])
              as List<dynamic>,
        ),
        (json['preferredApkIndex'] ?? -1) as int,
        safeJsonDecode(json['additionalSettings'], <String, dynamic>{})
            as Map<String, dynamic>,
        json['lastUpdateCheck'] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(json['lastUpdateCheck']),
        json['pinned'] ?? false,
        disabled: json['disabled'] ?? false,
        categories: json['categories'] != null
            ? (json['categories'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toList()
            : json['category'] != null
            ? [json['category'] as String]
            : [],
        tags: json['tags'] != null
            ? (json['tags'] as List<dynamic>).map((e) => e.toString()).toList()
            : [],
        releaseDate: json['releaseDate'] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(json['releaseDate']),
        changeLog: json['changeLog'] == null
            ? null
            : json['changeLog'] as String,
        releaseUrl: json['releaseUrl'] as String?,
        overrideSource: json['overrideSource'],
        allowIdChange: json['allowIdChange'] ?? false,
        otherAssetUrls: assumed2DlistToStringMapList(
          safeJsonDecode(json['otherAssetUrls'], <dynamic>[]) as List<dynamic>,
        ),
        versionHistory: json['versionHistory'] != null
            ? (json['versionHistory'] as List<dynamic>)
                  .map(
                    (e) =>
                        VersionHistoryEntry.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : [],
        apkSizeBytes: json['apkSizeBytes'] as int?,
        latestVersionChangedAt: json['latestVersionChangedAt'] == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(
                json['latestVersionChangedAt'] as int,
              ),
        consecutiveFailedChecks: (json['consecutiveFailedChecks'] as int?) ?? 0,
        isArchived: json['isArchived'] as bool?,
        newerReleasesFilteredOut: json['newerReleasesFilteredOut'] as int?,
        updateHealthEnabled: (json['updateHealthEnabled'] as bool?) ?? true,
        updateHealthDismissedVersion:
            json['updateHealthDismissedVersion'] as String?,
      )..pendingRepoRenameUrl = json['pendingRepoRenameUrl'] as String?;
    } on TypeError catch (e) {
      AppLogger.error(
        e,
        stackTrace: e.stackTrace,
        message: 'Type mismatch in App.fromJson',
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'author': author,
    'name': name,
    'installedVersion': installedVersion,
    'latestVersion': latestVersion,
    'apkUrls': safeJsonEncode(stringMapListTo2DList(apkUrls)),
    'otherAssetUrls': safeJsonEncode(stringMapListTo2DList(otherAssetUrls)),
    'preferredApkIndex': preferredApkIndex,
    'additionalSettings': safeJsonEncode(additionalSettings),
    'lastUpdateCheck': lastUpdateCheck?.microsecondsSinceEpoch,
    'pinned': pinned,
    'disabled': disabled,
    'categories': categories,
    'tags': tags,
    'releaseDate': releaseDate?.microsecondsSinceEpoch,
    'changeLog': changeLog,
    'releaseUrl': releaseUrl,
    'overrideSource': overrideSource,
    'allowIdChange': allowIdChange,
    'pendingRepoRenameUrl': pendingRepoRenameUrl,
    'versionHistory': versionHistory.map((e) => e.toJson()).toList(),
    'apkSizeBytes': apkSizeBytes,
    'latestVersionChangedAt': latestVersionChangedAt?.microsecondsSinceEpoch,
    'consecutiveFailedChecks': consecutiveFailedChecks,
    'isArchived': isArchived,
    'newerReleasesFilteredOut': newerReleasesFilteredOut,
    'updateHealthEnabled': updateHealthEnabled,
    'updateHealthDismissedVersion': updateHealthDismissedVersion,
  };
}

/// Returns true if the app's ID is a temporary placeholder rather than a real
/// package name.
bool isTempId(App app) {
  return RegExp(r'^[0-9]+$').hasMatch(app.id) ||
      RegExp(r'^[0-9a-f]{12}$').hasMatch(app.id);
}

/// Returns true when the app uses pseudo-versioning (track-only or disabled version detection).
bool isVersionPseudo(App app) =>
    app.settings.getBool('trackOnly') ||
    (app.installedVersion != null && !app.settings.getBool('versionDetection'));
