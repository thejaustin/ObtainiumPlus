import 'package:shared_preferences/shared_preferences.dart';

/// Type-tolerant SharedPreferences reads.
///
/// A key written as one type by an old app version and read as another
/// after an upgrade makes the plugin getters throw a TypeError, which can
/// take down whole pages that read settings during build (issue #217).
/// These helpers coerce compatible numeric types and fall back to null
/// (so callers' `?? default` kicks in) instead of throwing.
extension SafePrefs on SharedPreferences {
  double? safeDouble(String key) {
    final value = get(key);
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  int? safeInt(String key) {
    final value = get(key);
    if (value is int) return value;
    if (value is double) return value.round();
    return null;
  }

  bool? safeBool(String key) {
    final value = get(key);
    return value is bool ? value : null;
  }
}
