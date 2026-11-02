/// Represents a recorded installation or update event for an application.
class InstallHistoryEntry {
  final String version;
  final String? previousVersion;
  final DateTime timestamp;
  final String? installerMethod;
  final int? versionCode;

  const InstallHistoryEntry({
    required this.version,
    this.previousVersion,
    required this.timestamp,
    this.installerMethod,
    this.versionCode,
  });

  factory InstallHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    DateTime parsedTime;
    if (rawTimestamp is num) {
      final val = rawTimestamp.toInt();
      // Values > 10^14 are microsecond timestamps, smaller are milliseconds
      parsedTime = val > 100000000000000
          ? DateTime.fromMicrosecondsSinceEpoch(val)
          : DateTime.fromMillisecondsSinceEpoch(val);
    } else {
      parsedTime = DateTime.now();
    }

    return InstallHistoryEntry(
      version: json['version'] as String? ?? '',
      previousVersion: json['previousVersion'] as String?,
      timestamp: parsedTime,
      installerMethod: json['installerMethod'] as String?,
      versionCode: (json['versionCode'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'previousVersion': previousVersion,
    'timestamp': timestamp.microsecondsSinceEpoch,
    'installerMethod': installerMethod,
    'versionCode': versionCode,
  };
}
