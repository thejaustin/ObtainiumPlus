import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/core/logging/app_log_db.dart';
import 'package:obtainium/pages/logs.dart';
import 'package:obtainium/providers/logs_provider.dart' hide AppLogger;

void main() {
  test('both log stores show together, oldest first', () {
    final install = Log('Installing "x"', LogLevel.info)
      ..timestamp = DateTime(2026, 10, 24, 10, 0, 1);
    final bgError = Log('BG update task timed out.', LogLevel.error)
      ..timestamp = DateTime(2026, 10, 24, 9);
    final merged = mergeLogStores(
      [
        LogEntry(
          message: 'Update check for x',
          level: AppLogLevel.debug,
          timestamp: DateTime(2026, 10, 24, 10),
        ),
      ],
      [install, bgError],
    );
    expect(merged.map((e) => e.message), [
      'BG update task timed out.',
      'Update check for x',
      'Installing "x"',
    ]);
    expect(merged.first.level, AppLogLevel.error);
  });
}
