import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// File-based crash logger — Flutter equivalent of hexodus's CrashHandler.kt.
///
/// Writes the most recent crash to `latest_crash.log` in the app's documents
/// directory so it survives the process death and can be retrieved on the next
/// launch for debugging or user-facing bug reports.
class CrashFileHandler {
  static const _crashLogFile = 'latest_crash.log';

  static Future<File> _getCrashFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_crashLogFile');
  }

  /// Persist crash details to disk. This method is deliberately fire-and-forget
  /// safe — it never throws.
  static Future<void> writeCrashLog({
    required String errorType,
    required String message,
    required String stackTrace,
    String? sentryEventId,
  }) async {
    try {
      final file = await _getCrashFile();

      var deviceLine = 'Device: (unknown)';
      var versionLine = 'Android: (unknown)';
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        deviceLine = 'Device: ${info.manufacturer} ${info.model}';
        versionLine =
            'Android: ${info.version.release} (SDK ${info.version.sdkInt})';
      } catch (_) {}

      final report = [
        '--- Obtainium+ Crash Report ---',
        'Timestamp: ${DateTime.now().toIso8601String()}',
        deviceLine,
        versionLine,
        'Error Type: $errorType',
        'Sentry Event ID: ${sentryEventId ?? 'N/A'}',
        '',
        'Message:',
        message,
        '',
        'Stack Trace:',
        stackTrace,
        '------------------------------',
      ].join('\n');

      await file.writeAsString(report);
    } catch (_) {
      // Never let crash-logging itself cause a crash.
    }
  }

  /// Returns the contents of the last crash log, or null if none exists.
  static Future<String?> getCrashLog() async {
    try {
      final file = await _getCrashFile();
      if (!file.existsSync()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Deletes the stored crash log (call after the user has been informed).
  static Future<void> clearCrashLog() async {
    try {
      final file = await _getCrashFile();
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
