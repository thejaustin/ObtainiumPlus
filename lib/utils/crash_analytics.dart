import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/utils/crash_tracker.dart';

/// Tracks crash analytics and provides insights for debugging
class CrashAnalytics {
  static const _keyCrashCount = 'crash_count';
  static const _keyLastCrashTime = 'last_crash_timestamp';
  static const _keyCrashTypes = 'crash_types';

  /// Record a crash for analytics
  static Future<void> recordCrash({
    required String errorType,
    required String errorMessage,
    String? eventId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Increment crash count
    final currentCount = prefs.safeInt(_keyCrashCount) ?? 0;
    await prefs.setInt(_keyCrashCount, currentCount + 1);

    // Record timestamp
    await prefs.setInt(
      _keyLastCrashTime,
      DateTime.now().millisecondsSinceEpoch,
    );

    // Track crash types
    final crashTypes = prefs.safeStringList(_keyCrashTypes) ?? [];
    if (!crashTypes.contains(errorType)) {
      crashTypes.add(errorType);
      await prefs.setStringList(_keyCrashTypes, crashTypes);
    }

    // Log to Sentry if event ID provided
    if (eventId != null) {
      await CrashTracker.recordCrash(eventId);
    }
  }

  /// Get crash statistics
  static Future<CrashStats> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return CrashStats(
      totalCrashes: prefs.safeInt(_keyCrashCount) ?? 0,
      lastCrashTime: prefs.safeInt(_keyLastCrashTime) != null
          ? DateTime.fromMillisecondsSinceEpoch(
              prefs.safeInt(_keyLastCrashTime)!,
            )
          : null,
      crashTypes: prefs.safeStringList(_keyCrashTypes) ?? [],
    );
  }

  /// Reset crash statistics (call after successful session)
  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCrashCount);
    await prefs.remove(_keyLastCrashTime);
    await prefs.remove(_keyCrashTypes);
  }

  /// Check if app is in crash loop (>3 crashes in 10 minutes)
  static Future<bool> isInCrashLoop() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCrash = prefs.safeInt(_keyLastCrashTime);
    if (lastCrash == null) return false;

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastCrash),
    );

    if (age.inMinutes > 10) return false;

    final count = prefs.safeInt(_keyCrashCount) ?? 0;
    return count >= 3;
  }
}

/// Crash statistics data class
class CrashStats {
  final int totalCrashes;
  final DateTime? lastCrashTime;
  final List<String> crashTypes;

  CrashStats({
    required this.totalCrashes,
    this.lastCrashTime,
    this.crashTypes = const [],
  });

  String get summary {
    if (totalCrashes == 0) return 'No crashes recorded';

    final types = crashTypes.isEmpty ? '' : ' (${crashTypes.join(', ')})';
    return '$totalCrashes crash(es)$types';
  }
}
