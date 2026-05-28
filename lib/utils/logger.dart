import 'package:flutter/foundation.dart';

class TalkerHistoryEntry {
  final String title;
  final String message;
  final DateTime timestamp;
  TalkerHistoryEntry(this.title, this.message) : timestamp = DateTime.now();
}

class Talker {
  final List<TalkerHistoryEntry> history = [];

  void info(String message) {
    if (kDebugMode) print('[INFO] $message');
    _add('INFO', message);
  }

  void warning(String message) {
    if (kDebugMode) print('[WARNING] $message');
    _add('WARNING', message);
  }

  void error(String message) {
    if (kDebugMode) print('[ERROR] $message');
    _add('ERROR', message);
  }

  void debug(String message) {
    if (kDebugMode) print('[DEBUG] $message');
    _add('DEBUG', message);
  }

  void handle(dynamic error, [StackTrace? stackTrace, String? message]) {
    final msg = '${message ?? ""}: $error${stackTrace != null ? "\n$stackTrace" : ""}';
    if (kDebugMode) print('[EXCEPTION] $msg');
    _add('EXCEPTION', msg);
  }

  void _add(String title, String message) {
    if (history.length >= 1000) {
      history.removeAt(0);
    }
    history.add(TalkerHistoryEntry(title, message));
  }

  void clear() {
    history.clear();
  }
}

final talker = Talker();

/// Helper extension for easier logging
extension TalkerExt on Object {
  void logInfo(String message) => talker.info(message);
  void logWarning(String message) => talker.warning(message);
  void logError(String message, [dynamic error, StackTrace? stack]) =>
      talker.handle(error ?? message, stack, message);
  void logDebug(String message) => talker.debug(message);
}
