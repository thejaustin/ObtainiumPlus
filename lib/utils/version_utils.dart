import 'package:obtainium/utils/app_constants.dart';

List<String> generateStandardVersionRegExStrings() {
  var basics = [
    '[0-9]+',
    '[0-9]+\\.[0-9]+',
    '[0-9]+\\.[0-9]+\\.[0-9]+',
    '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+',
  ];
  var prefixes = ['[vV]?', '[pP]?'];
  var preSuffixes = ['-', '\\+'];
  var suffixes = ['alpha', 'beta', 'ose', '[0-9]+'];
  var finals = ['\\+[0-9]+', '[0-9]+'];
  List<String> results = [];
  for (var b in basics) {
    for (var pre in prefixes) {
      results.add('$pre$b');
      for (var p in preSuffixes) {
        for (var s in suffixes) {
          results.add('$pre$b$s');
          results.add('$pre$b$p$s');
          for (var f in finals) {
            results.add('$pre$b$s$f');
            results.add('$pre$b$p$s$f');
          }
        }
      }
    }
  }
  return results;
}

List<String> standardVersionRegExStrings = generateStandardVersionRegExStrings();

Set<String> findStandardFormatsForVersion(String version, bool strict) {
  // If !strict, even a substring match is valid
  Set<String> results = {};
  for (var pattern in standardVersionRegExStrings) {
    try {
      if (RegExp(
        '${strict ? '^' : ''}$pattern${strict ? '\$' : ''}',
      ).hasMatch(version)) {
        results.add(pattern);
      }
    } catch (_) {
      // Skip patterns that fail to compile (e.g. adjacent quantifiers from
      // certain basic+suffix+final combinations). Fixes OBTAINIUMPLUS-1.
    }
  }
  return results;
}

MapEntry<bool, String>? reconcileVersionDifferences(
  String templateVersion,
  String comparisonVersion,
) {
  // Returns null if the versions don't share a common standard format
  // Returns <true, comparisonVersion> if they share a common format and are equal
  // Returns <false, templateVersion> if they share a common format but are not equal
  // templateVersion must fully match a standard format, while comparisonVersion can have a substring match
  var templateVersionFormats = findStandardFormatsForVersion(
    templateVersion,
    true,
  );
  var comparisonVersionFormats = findStandardFormatsForVersion(
    comparisonVersion,
    true,
  );
  if (comparisonVersionFormats.isEmpty) {
    comparisonVersionFormats = findStandardFormatsForVersion(
      comparisonVersion,
      false,
    );
  }
  var commonStandardFormats = templateVersionFormats.intersection(
    comparisonVersionFormats,
  );
  if (commonStandardFormats.isEmpty) {
    return null;
  }
  for (String pattern in commonStandardFormats) {
    if (doStringsMatchUnderRegEx(
      pattern,
      comparisonVersion,
      templateVersion,
    )) {
      return MapEntry(true, comparisonVersion);
    }
  }
  return MapEntry(false, templateVersion);
}

String normalizeVersion(String version) {
  // Remove leading 'v' or 'p' (case-insensitive) followed by a digit
  // e.g. v1.2.3 -> 1.2.3, p100 -> 100
  var vPrefixed = RegExp(r'^[vV](?=[0-9])');
  var pPrefixed = RegExp(r'^[pP](?=[0-9])');
  return version.replaceFirst(vPrefixed, '').replaceFirst(pPrefixed, '');
}

bool doStringsMatchUnderRegEx(String pattern, String value1, String value2) {
  var r = RegExp(pattern);
  var m1 = r.firstMatch(value1);
  var m2 = r.firstMatch(value2);
  if (m1 != null && m2 != null) {
    var v1 = value1.substring(m1.start, m1.end);
    var v2 = value2.substring(m2.start, m2.end);
    if (v1 == v2) return true;
    // Try normalized matching
    return normalizeVersion(v1) == normalizeVersion(v2);
  }
  return false;
}
