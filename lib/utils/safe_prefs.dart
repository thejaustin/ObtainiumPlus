import 'package:shared_preferences/shared_preferences.dart';

/// Type-tolerant SharedPreferences reads.
///
/// A key written as one type but read as another makes the plugin getters
/// throw a TypeError, which can take down whole pages that read settings
/// during build (issue #217). Mismatches come from old app versions
/// changing a key's type, and from Obtainium data import, which restores
/// settings typed by their JSON representation (apps_provider
/// importObtainiumData) — so ANY imported key can arrive with the wrong
/// type. These helpers coerce compatible types and fall back to null
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
    if (value is bool) return value;
    if (value is String && (value == 'true' || value == 'false')) {
      return value == 'true';
    }
    return null;
  }

  String? safeString(String key) {
    final value = get(key);
    return value is String ? value : null;
  }

  List<String>? safeStringList(String key) {
    final value = get(key);
    if (value is List) return value.whereType<String>().toList();
    return null;
  }

  /// Reads an enum stored by index. Returns null when the stored value is
  /// not a valid index into [values] — e.g. the enum lost members between
  /// app versions, or the index came from imported data — so the caller's
  /// `?? fallback` applies instead of `values[i]` throwing a RangeError.
  T? safeEnum<T>(String key, List<T> values) {
    final index = safeInt(key);
    if (index == null || index < 0 || index >= values.length) return null;
    return values[index];
  }
}
