class VersionHistoryEntry {
  final String version;
  final String? changeLog;
  final DateTime? releaseDate;
  final DateTime detectedAt;

  VersionHistoryEntry({
    required this.version,
    this.changeLog,
    this.releaseDate,
    required this.detectedAt,
  });

  factory VersionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return VersionHistoryEntry(
      version: json['version'] as String,
      changeLog: json['changeLog'] as String?,
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(json['releaseDate'] as int),
      detectedAt: DateTime.fromMicrosecondsSinceEpoch(
        json['detectedAt'] as int,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'changeLog': changeLog,
    'releaseDate': releaseDate?.microsecondsSinceEpoch,
    'detectedAt': detectedAt.microsecondsSinceEpoch,
  };
}
