import 'dart:core';

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

Set<String> findStandardFormatsForVersion(String version, bool strict) {
  Set<String> results = {};
  for (var pattern in generateStandardVersionRegExStrings()) {
    try {
      if (RegExp('${strict ? '^' : ''}$pattern${strict ? '\$' : ''}').hasMatch(version)) {
        results.add(pattern);
      }
    } catch (_) {}
  }
  return results;
}

void main() {
  var v1 = findStandardFormatsForVersion("v13.6.0.r2013", false);
  var v2 = findStandardFormatsForVersion("v1.4.3-p15", false);
  print("v13.6.0.r2013 formats count: ${v1.length}");
  print("v1.4.3-p15 formats count: ${v2.length}");
}
