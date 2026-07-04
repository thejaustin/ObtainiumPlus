import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/utils/safe_prefs.dart';

/// Tracks crashes captured by Sentry so the app can prompt the user to
/// follow the corresponding GitHub issue on next launch.
class CrashTracker {
  static const _keyEventId = 'pending_crash_event_id';
  static const _keyTimestamp = 'pending_crash_timestamp';

  /// GitHub Issues URL filtered to Sentry-synced crash issues, newest first.
  static const issueTrackerUrl =
      'https://github.com/thejaustin/ObtainiumPlus/issues?q=is%3Aissue+label%3Asentry-crash+sort%3Acreated-desc';

  /// Returns a GitHub search URL for the specific recorded crash event ID,
  /// or the general issue tracker URL if no event ID is found.
  static Future<String> getSpecificIssueUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final eventId = prefs.getString(_keyEventId);
    if (eventId != null && eventId.isNotEmpty && eventId != 'null') {
      // Searching for the Sentry Event ID in the repo
      return 'https://github.com/thejaustin/ObtainiumPlus/issues?q=is%3Aissue+label%3Asentry-crash+%22Sentry+%23$eventId%22';
    }
    return issueTrackerUrl;
  }

  /// Persists a Sentry event ID so the next app launch can show a follow banner.
  static Future<void> recordCrash(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEventId, eventId);
    await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns true if there is a crash recorded within the last 48 hours.
  static Future<bool> hasPendingCrash() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.safeInt(_keyTimestamp);
    if (timestamp == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    return age.inHours <= 48;
  }

  /// Clears the stored crash record (call after showing the follow banner).
  static Future<void> clearPendingCrash() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEventId);
    await prefs.remove(_keyTimestamp);
  }
}
