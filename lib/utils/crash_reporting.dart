import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/utils/safe_prefs.dart';

/// Preference key for the opt-in crash reporting switch.
const String crashReportingPrefKey = 'crashReportingEnabled';

/// Crash reports are sent only after the user turns this on (default off).
Future<bool> isCrashReportingEnabled() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.safeBool(crashReportingPrefKey) ?? false;
  } catch (_) {
    return false;
  }
}
