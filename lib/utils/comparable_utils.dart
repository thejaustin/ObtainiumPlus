int compareAlphaNumeric(String a, String b) {
  final RegExp alphaNumeric = RegExp(r'(\d+)|(\D+)');
  final Iterable<RegExpMatch> matchesA = alphaNumeric.allMatches(a);
  final Iterable<RegExpMatch> matchesB = alphaNumeric.allMatches(b);

  final List<String> partsA = matchesA.map((m) => m.group(0)!).toList();
  final List<String> partsB = matchesB.map((m) => m.group(0)!).toList();

  final int length = partsA.length < partsB.length
      ? partsA.length
      : partsB.length;

  for (int i = 0; i < length; i++) {
    final String partA = partsA[i];
    final String partB = partsB[i];

    final int? numA = int.tryParse(partA);
    final int? numB = int.tryParse(partB);

    if (numA != null && numB != null) {
      if (numA != numB) return numA.compareTo(numB);
    } else {
      final int res = partA.toLowerCase().compareTo(partB.toLowerCase());
      if (res != 0) return res;
    }
  }

  if (partsA.length != partsB.length) {
    if (partsA.length > length) {
      String extraA = partsA[length].toLowerCase();
      if (extraA.contains('alpha') || extraA.contains('beta') || extraA.contains('rc') || extraA.contains('pre')) {
        return -1; // A is a prerelease, so it's older than base B
      }
      return 1;
    } else {
      String extraB = partsB[length].toLowerCase();
      if (extraB.contains('alpha') || extraB.contains('beta') || extraB.contains('rc') || extraB.contains('pre')) {
        return 1; // B is a prerelease, so A (base) is newer
      }
      return -1;
    }
  }
  return 0;
}
