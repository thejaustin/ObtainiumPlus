import 'dart:convert';

/// An `obtainium://` link split into its action (the host) and payload.
class ObtainiumDeepLink {
  const ObtainiumDeepLink(this.action, this.data);

  /// `add`, `app`, `apps`, `refresh`, ... (lower-cased host).
  final String action;

  /// The decoded payload: a source URL for `add`, JSON for `app`/`apps`.
  final String data;
}

/// Everything after `obtainium://<host>/`, taken from the full link text so
/// an unencoded `?` or `#` inside the payload (hand-built catalog links whose
/// JSON holds URLs with query strings) isn't cut off as a query or fragment.
String _rawPayload(Uri uri) {
  final s = uri.toString();
  final schemeEnd = s.indexOf('://');
  if (schemeEnd < 0) return '';
  final slash = s.indexOf('/', schemeEnd + 3);
  if (slash < 0) return '';
  return s.substring(slash + 1);
}

/// Percent-decodes [s], returning it unchanged when it holds a stray `%`
/// that isn't a valid escape (raw JSON can contain a literal `%`).
String _tryDecode(String s) {
  try {
    return Uri.decodeComponent(s);
  } catch (_) {
    return s;
  }
}

bool _isJson(String s) {
  try {
    jsonDecode(s);
    return true;
  } catch (_) {
    return false;
  }
}

/// Parses an `obtainium://` deep link.
///
/// Catalog sites (apps.obtainium.page, ShizuStore and others) emit
/// `obtainium://app/<encodeURIComponent(json)>`. Dart's [Uri.path] stays
/// percent-encoded, so the payload must be decoded before `jsonDecode`.
/// Raw (unencoded) JSON payloads are accepted too.
ObtainiumDeepLink parseObtainiumDeepLink(Uri uri) {
  final action = uri.host.toLowerCase();
  final raw = _rawPayload(uri);
  final queryUrl = uri.queryParameters['url'];
  final emptyPath = uri.path.isEmpty || uri.path == '/';
  if (action == 'app' || action == 'apps') {
    if (emptyPath && queryUrl != null) {
      return ObtainiumDeepLink(action, queryUrl);
    }
    final decoded = _tryDecode(raw);
    // Use the first form that is valid JSON: the decoded full remainder,
    // the raw one (decoding a never-encoded payload can break a literal
    // "%25"), or the decoded path alone (tracking params such as
    // `?utm_source=` appended after an encoded payload).
    final pathOnly = uri.path.length > 1
        ? _tryDecode(uri.path.substring(1))
        : '';
    for (final candidate in [decoded, raw, pathOnly]) {
      if (candidate.isNotEmpty && _isJson(candidate)) {
        return ObtainiumDeepLink(action, candidate);
      }
    }
    return ObtainiumDeepLink(action, decoded);
  }
  if (emptyPath && queryUrl != null) {
    return ObtainiumDeepLink(action, queryUrl);
  }
  if (action == 'add') {
    // `obtainium://add/https%3A%2F%2Fgithub.com%2Fo%2Fr` is decoded; a
    // plain `obtainium://add/https://github.com/o/r?x=y` is kept as-is
    // (with its query) so meaningful escapes like `%26` or `%2F` survive.
    final lower = raw.toLowerCase();
    final encodedScheme =
        lower.startsWith('https%3a') || lower.startsWith('http%3a');
    return ObtainiumDeepLink(action, encodedScheme ? _tryDecode(raw) : raw);
  }
  return ObtainiumDeepLink(
    action,
    queryUrl ?? (uri.path.length > 1 ? uri.path.substring(1) : ''),
  );
}
