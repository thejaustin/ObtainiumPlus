class AppNames {
  late String author;
  late String name;

  AppNames(this.author, this.name);
}

class APKDetails {
  late String version;
  late List<MapEntry<String, String>> apkUrls;
  late AppNames names;
  late DateTime? releaseDate;
  late String? changeLog;
  late List<MapEntry<String, String>> allAssetUrls;
  final Map<String, String>? assetSha256s;

  APKDetails(
    this.version,
    this.apkUrls,
    this.names, {
    this.releaseDate,
    this.changeLog,
    this.allAssetUrls = const [],
    this.assetSha256s,
  });
}
