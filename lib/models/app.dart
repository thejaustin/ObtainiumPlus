import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/providers/source_provider.dart' show TypedSettings;
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/models/version_history_entry.dart';

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
  List<String> categories;
  List<String> tags; // NEW: Tags for cross-category organization
  late DateTime? releaseDate;
  late String? changeLog;
  late String? overrideSource;
  bool allowIdChange = false;
  List<VersionHistoryEntry> versionHistory = [];

  /// If non-null, the app's source has a new canonical URL and a rename is pending.
  String? pendingRepoRenameUrl;

  bool get hasPendingRepoRename => pendingRepoRenameUrl != null;

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
    this.categories = const [],
    this.tags = const [], // NEW: Default empty tags
    this.releaseDate,
    this.changeLog,
    this.overrideSource,
    this.allowIdChange = false,
    this.otherAssetUrls = const [],
    this.versionHistory = const [],
  });

  @override
  String toString() {
    return 'ID: $id URL: $url INSTALLED: $installedVersion LATEST: $latestVersion APK: $apkUrls PREFERREDAPK: $preferredApkIndex ADDITIONALSETTINGS: ${additionalSettings.toString()} LASTCHECK: ${lastUpdateCheck.toString()} PINNED $pinned';
  }

  String? get overrideName =>
      additionalSettings['appName']?.toString().trim().isNotEmpty == true
      ? additionalSettings['appName']
      : null;

  String get finalName {
    return overrideName ?? name;
  }

  String? get overrideAuthor =>
      additionalSettings['appAuthor']?.toString().trim().isNotEmpty == true
      ? additionalSettings['appAuthor']
      : null;

  String get finalAuthor {
    return overrideAuthor ?? author;
  }

  /// Type-safe accessor for [additionalSettings].
  TypedSettings get settings => TypedSettings(additionalSettings);

  static const Object _sentinel = Object();

  /// Returns a copy of this [App] with the given fields replaced. Pass an
  /// explicit `null` for a nullable field (e.g. `installedVersion: null`) to
  /// clear it; omit the argument to keep the current value.
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
    List<String>? categories,
    List<String>? tags,
    Object? releaseDate = _sentinel,
    Object? changeLog = _sentinel,
    Object? overrideSource = _sentinel,
    bool? allowIdChange,
    List<VersionHistoryEntry>? versionHistory,
    Object? pendingRepoRenameUrl = _sentinel,
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
        categories: categories ?? List<String>.from(this.categories),
        tags: tags ?? List<String>.from(this.tags),
        releaseDate: releaseDate == _sentinel
            ? this.releaseDate
            : releaseDate as DateTime?,
        changeLog: changeLog == _sentinel
            ? this.changeLog
            : changeLog as String?,
        overrideSource: overrideSource == _sentinel
            ? this.overrideSource
            : overrideSource as String?,
        allowIdChange: allowIdChange ?? this.allowIdChange,
        otherAssetUrls:
            otherAssetUrls ??
            List<MapEntry<String, String>>.from(this.otherAssetUrls),
        versionHistory: versionHistory ?? List.from(this.versionHistory),
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
    categories: List<String>.from(categories),
    tags: List<String>.from(tags), // NEW: Deep copy tags
    changeLog: changeLog,
    releaseDate: releaseDate,
    overrideSource: overrideSource,
    allowIdChange: allowIdChange,
    otherAssetUrls: List.from(otherAssetUrls),
    versionHistory: List.from(versionHistory),
  );

  factory App.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic> Function(Map<String, dynamic>)? migrator,
  }) {
    if (migrator != null) {
      json = migrator(json);
    }
    return App(
      json['id'] as String,
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
      categories: json['categories'] != null
          ? (json['categories'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
          : json['category'] != null
          ? [json['category'] as String]
          : [],
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>).map((e) => e.toString()).toList()
          : [], // NEW: Load tags from JSON
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(json['releaseDate']),
      changeLog: json['changeLog'] == null ? null : json['changeLog'] as String,
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
    );
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
    'categories': categories,
    'tags': tags, // NEW: Save tags to JSON
    'releaseDate': releaseDate?.microsecondsSinceEpoch,
    'changeLog': changeLog,
    'overrideSource': overrideSource,
    'allowIdChange': allowIdChange,
    'versionHistory': versionHistory.map((e) => e.toJson()).toList(),
  };
}
