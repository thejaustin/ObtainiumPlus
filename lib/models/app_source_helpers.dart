const Object _sentinel = Object();

class AppNames {
  late String author;
  late String name;

  AppNames(this.author, this.name);

  AppNames copyWith({String? author, String? name}) {
    return AppNames(author ?? this.author, name ?? this.name);
  }
}

class APKDetails {
  late String version;
  late List<MapEntry<String, String>> apkUrls;
  late AppNames names;
  late DateTime? releaseDate;
  late String? changeLog;
  late String? releaseUrl;
  late List<MapEntry<String, String>> allAssetUrls;
  final Map<String, String>? assetSha256s;
  final String? appId;
  final int? apkSizeBytes;
  final bool? isArchived;
  final int? newerReleasesFilteredOut;

  APKDetails(
    this.version,
    this.apkUrls,
    this.names, {
    this.releaseDate,
    this.changeLog,
    this.releaseUrl,
    this.allAssetUrls = const [],
    this.assetSha256s,
    this.appId,
    this.apkSizeBytes,
    this.isArchived,
    this.newerReleasesFilteredOut,
  });

  APKDetails copyWith({
    String? version,
    List<MapEntry<String, String>>? apkUrls,
    AppNames? names,
    Object? releaseDate = _sentinel,
    Object? changeLog = _sentinel,
    Object? releaseUrl = _sentinel,
    List<MapEntry<String, String>>? allAssetUrls,
    Map<String, String>? assetSha256s,
    Object? appId = _sentinel,
    Object? apkSizeBytes = _sentinel,
    Object? isArchived = _sentinel,
    Object? newerReleasesFilteredOut = _sentinel,
  }) {
    return APKDetails(
      version ?? this.version,
      apkUrls ?? this.apkUrls,
      names ?? this.names,
      releaseDate: releaseDate == _sentinel
          ? this.releaseDate
          : releaseDate as DateTime?,
      changeLog: changeLog == _sentinel ? this.changeLog : changeLog as String?,
      releaseUrl: releaseUrl == _sentinel
          ? this.releaseUrl
          : releaseUrl as String?,
      allAssetUrls: allAssetUrls ?? this.allAssetUrls,
      assetSha256s: assetSha256s ?? this.assetSha256s,
      appId: appId == _sentinel ? this.appId : appId as String?,
      apkSizeBytes: apkSizeBytes == _sentinel
          ? this.apkSizeBytes
          : apkSizeBytes as int?,
      isArchived: isArchived == _sentinel
          ? this.isArchived
          : isArchived as bool?,
      newerReleasesFilteredOut: newerReleasesFilteredOut == _sentinel
          ? this.newerReleasesFilteredOut
          : newerReleasesFilteredOut as int?,
    );
  }
}
