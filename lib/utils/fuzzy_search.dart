import 'dart:math';

/// A lightweight fuzzy matching algorithm combining substring matches and Levenshtein distance.
/// Returns a score between 0.0 and 1.0, where 1.0 is a perfect match.
double fuzzyMatch(String query, String target) {
  if (query.isEmpty) return 1.0;
  if (target.isEmpty) return 0.0;

  final q = query.toLowerCase();
  final t = target.toLowerCase();

  // Exact match
  if (q == t) return 1.0;

  // Exact prefix match
  if (t.startsWith(q)) return 0.9 + (q.length / t.length) * 0.1;

  // Substring match
  if (t.contains(q)) return 0.7 + (q.length / t.length) * 0.2;

  // Levenshtein distance
  int distance = _levenshtein(q, t);
  double maxLength = max(q.length, t.length).toDouble();
  double matchRatio = 1.0 - (distance / maxLength);

  // Apply a penalty for distance to lower the score
  double score = matchRatio * 0.6;

  return score;
}

int _levenshtein(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  List<int> v0 = List<int>.filled(b.length + 1, 0);
  List<int> v1 = List<int>.filled(b.length + 1, 0);

  for (int i = 0; i <= b.length; i++) {
    v0[i] = i;
  }

  for (int i = 0; i < a.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < b.length; j++) {
      int cost = (a[i] == b[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j <= b.length; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[b.length];
}
