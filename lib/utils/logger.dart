import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:sentry_talker/sentry_talker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Global Talker instance for logging
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    enabled: true,
    useConsoleLogs: !kReleaseMode,
    useHistory: true,
    maxHistoryItems: 1000,
  ),
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(
      enableColors: true,
    ),
  ),
);

/// Helper extension for easier logging
extension TalkerExt on Object {
  void logInfo(String message) => talker.info(message);
  void logWarning(String message) => talker.warning(message);
  void logError(String message, [dynamic error, StackTrace? stack]) =>
      talker.handle(error ?? message, stack, message);
  void logDebug(String message) => talker.debug(message);
}
