import 'package:flutter/foundation.dart';

/// Single log entry for Shizuku IPC calls, modeled after ShizukuPlus ActivityLogManager.
class ShizukuLogEntry {
  final DateTime timestamp;
  final String action;
  final String? targetPackage;
  final int durationMs;
  final int? latencyMs;
  final String status;
  final String? details;

  const ShizukuLogEntry({
    required this.timestamp,
    required this.action,
    this.targetPackage,
    required this.durationMs,
    this.latencyMs,
    required this.status,
    this.details,
  });

  bool get isSuccess => status == 'success';
  bool get isBlocked => status == 'blocked';
  bool get isError => status == 'error' || status == 'denied';

  String toFormattedString() {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
    final pkg = targetPackage != null ? ' [$targetPackage]' : '';
    final lat = latencyMs != null ? ' (latency: ${latencyMs}ms)' : '';
    final dur = ' ${durationMs}ms';
    final det = details != null ? ' - $details' : '';
    return '[$timeStr] $action$pkg: $status$dur$lat$det';
  }
}

/// In-memory rolling activity log for Shizuku/ShizukuPlus IPC operations.
class ShizukuTelemetryService extends ChangeNotifier {
  static final ShizukuTelemetryService instance = ShizukuTelemetryService._();
  ShizukuTelemetryService._();

  static const int maxEntries = 50;
  final List<ShizukuLogEntry> _entries = [];

  List<ShizukuLogEntry> get entries => List.unmodifiable(_entries);

  /// Records a Shizuku IPC operation.
  void log({
    required String action,
    String? targetPackage,
    int durationMs = 0,
    int? latencyMs,
    required String status,
    String? details,
  }) {
    final entry = ShizukuLogEntry(
      timestamp: DateTime.now(),
      action: action,
      targetPackage: targetPackage,
      durationMs: durationMs,
      latencyMs: latencyMs,
      status: status,
      details: details,
    );

    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
    notifyListeners();
  }

  /// Clears all recorded entries.
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Generates a plain-text report of all recent activity log entries for export/debugging.
  String exportPlainText() {
    if (_entries.isEmpty) {
      return 'No Shizuku activity recorded yet.';
    }
    final sb = StringBuffer();
    sb.writeln('=== ObtainiumPlus Shizuku Activity Log ===');
    sb.writeln('Generated: ${DateTime.now().toIso8601String()}');
    sb.writeln('Total entries: ${_entries.length}');
    sb.writeln('------------------------------------------');
    for (final e in _entries) {
      sb.writeln(e.toFormattedString());
    }
    return sb.toString();
  }
}
