import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/utils/app_utils.dart';

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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'author': author,
    'name': name,
    'installedVersion': installedVersion,
    'latestVersion': latestVersion,
    'apkUrls': jsonEncode(stringMapListTo2DList(apkUrls)),
    'otherAssetUrls': jsonEncode(stringMapListTo2DList(otherAssetUrls)),
    'preferredApkIndex': preferredApkIndex,
    'additionalSettings': jsonEncode(additionalSettings),
    'lastUpdateCheck': lastUpdateCheck?.microsecondsSinceEpoch,
    'pinned': pinned,
    'categories': categories,
    'tags': tags, // NEW: Save tags to JSON
    'releaseDate': releaseDate?.microsecondsSinceEpoch,
    'changeLog': changeLog,
    'overrideSource': overrideSource,
    'allowIdChange': allowIdChange,
  };
}
