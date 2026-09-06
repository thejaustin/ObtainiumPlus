import 'dart:math';

List<String> generateStandardVersionRegExStrings() {
  var basics = [
    '[0-9]+',
    '[0-9]+\\.[0-9]+',
    '[0-9]+\\.[0-9]+\\.[0-9]+',
    '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+',
  ];
  var prefixes = ['[vV]?', '[pP]?', 'dev-', 'stable-'];
  var preSuffixes = ['-', '\\.r', '\\.', '_'];
  var suffixes = [
    'alpha',
    'beta',
    'ose',
    '[0-9]+',
    '[pP][0-9]+',
    '[rR][cC][0-9]+',
    '[rR][0-9]+',
    '[vV][0-9]+',
    'shizukuplus',
    'fork',
    'plus',
  ];
  var finals = ['\\+[0-9]+', '[0-9]+', '-shizukuplus', '-plus', '-fork'];
  List<String> results = [];
  for (var b in basics) {
    for (var pre in prefixes) {
      results.add('$pre$b');
      for (var f in finals) {
        results.add('$pre$b$f');
        for (var p in preSuffixes) {
          results.add('$pre$b$p$f');
        }
      }
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

List<String> standardVersionRegExStrings =
    generateStandardVersionRegExStrings();

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
  String comparisonVersion, {
  bool aggressive = false,
}) {
  if (aggressive) {
    if (templateVersion == comparisonVersion) {
      return MapEntry(true, comparisonVersion);
    }
    if (normalizeVersion(templateVersion) ==
        normalizeVersion(comparisonVersion)) {
      return MapEntry(true, comparisonVersion);
    }
  }
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
    if (doStringsMatchUnderRegEx(pattern, comparisonVersion, templateVersion)) {
      return MapEntry(true, comparisonVersion);
    }
  }
  return MapEntry(false, templateVersion);
}

final RegExp _versionOrderingTokenRegExp = RegExp('[0-9]+|[^0-9]+');

// Splits a version into numeric (int) and non-numeric (String) run tokens
// after normalization. Returns null if the string contains no number at all
// or a digit run too long to be a real version component.
List<Object>? _versionOrderingTokens(String version) {
  var v = normalizeVersion(version.trim()).toLowerCase();
  List<Object> tokens = [];
  bool hasNumber = false;
  for (var match in _versionOrderingTokenRegExp.allMatches(v)) {
    var part = match.group(0)!;
    if (part.codeUnitAt(0) >= 0x30 && part.codeUnitAt(0) <= 0x39) {
      var n = int.tryParse(part);
      if (n == null) {
        return null;
      }
      tokens.add(n);
      hasNumber = true;
    } else {
      tokens.add(part);
    }
  }
  if (!hasNumber) {
    return null;
  }
  return tokens;
}

// Drops trailing '.0' segments ('1.4.0' -> '1.4') but only down to
// [targetLength] — stripping unconditionally would turn same-length pairs
// like '1.10.0' vs '1.9.5' into a bogus structural mismatch.
void _stripTrailingZeroSegments(List<Object> tokens, int targetLength) {
  while (tokens.length > targetLength &&
      tokens.length >= 2 &&
      tokens.last == 0 &&
      tokens[tokens.length - 2] == '.') {
    tokens.removeRange(tokens.length - 2, tokens.length);
  }
}

bool _isPureDotSeparatedNumeric(List<Object> tokens) {
  for (int i = 0; i < tokens.length; i++) {
    if (i.isEven && tokens[i] is! int) return false;
    if (i.isOdd && tokens[i] != '.') return false;
  }
  return true;
}

void _padTrailingZeroSegments(List<Object> tokens, int targetLength) {
  if (!_isPureDotSeparatedNumeric(tokens)) return;
  while (tokens.length < targetLength) {
    tokens.add('.');
    tokens.add(0);
  }
}

// Best-effort semantic ordering of two version strings.
// Returns a negative number if version1 is older than version2, zero if they
// are semantically equal, a positive number if version1 is newer, or null
// when the strings don't share a comparable shape — callers must treat null
// as "unknown" and keep their pre-existing behavior.
// Deliberately conservative: numeric segments compare numerically
// ('1.4.3' < '1.4.10', '1.4.3-p36' < '1.4.3-p41') but any structural
// difference in the non-numeric parts (dates vs semver, differing suffixes,
// hashes, extra segments beyond trailing zeros) yields null so genuine
// updates for oddly-versioned apps are never suppressed.
int? compareVersionStrings(String version1, String version2) {
  var tokens1 = _versionOrderingTokens(version1);
  var tokens2 = _versionOrderingTokens(version2);
  if (tokens1 == null || tokens2 == null) {
    return null;
  }
  if (tokens1.length != tokens2.length) {
    _stripTrailingZeroSegments(tokens1, tokens2.length);
    _stripTrailingZeroSegments(tokens2, tokens1.length);
    if (tokens1.length != tokens2.length &&
        _isPureDotSeparatedNumeric(tokens1) &&
        _isPureDotSeparatedNumeric(tokens2)) {
      if (tokens1.length < tokens2.length) {
        _padTrailingZeroSegments(tokens1, tokens2.length);
      } else {
        _padTrailingZeroSegments(tokens2, tokens1.length);
      }
    }
    if (tokens1.length != tokens2.length) {
      final minLen = min(tokens1.length, tokens2.length);
      bool prefixMatches = true;
      for (int i = 0; i < minLen; i++) {
        if (tokens1[i] != tokens2[i]) {
          prefixMatches = false;
          break;
        }
      }
      if (prefixMatches) {
        // SemVer 2.0.0: stable release has higher precedence than a pre-release
        // sharing the same major.minor.patch (e.g. 1.0.0 > 1.0.0-rc1)
        final longer = tokens1.length > tokens2.length ? tokens1 : tokens2;
        final extraFirst = longer[minLen].toString().toLowerCase();
        if (extraFirst.startsWith('-') ||
            extraFirst.startsWith('rc') ||
            extraFirst.startsWith('beta') ||
            extraFirst.startsWith('alpha') ||
            extraFirst.startsWith('preview') ||
            extraFirst.startsWith('pre')) {
          return tokens1.length > tokens2.length ? -1 : 1;
        }
      }
      return null;
    }
  }
  int result = 0;
  for (var i = 0; i < tokens1.length; i++) {
    var t1 = tokens1[i];
    var t2 = tokens2[i];
    if (t1 is int && t2 is int) {
      if (result == 0 && t1 != t2) {
        result = t1 < t2 ? -1 : 1;
      }
    } else if (t1 != t2) {
      // Keep scanning the whole skeleton even after a numeric difference —
      // any non-numeric mismatch means the pair is not confidently orderable
      return null;
    }
  }
  return result;
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
