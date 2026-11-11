/// The payload of an `obtainium://<action>/<data>` deep link.
///
/// Senders (Obtainium's own share redirect, app stores such as ShizuStore,
/// ObtainX) percent-encode the data, e.g. `obtainium://app/%7B%22id%22...`
/// or `obtainium://add/https%3A%2F%2Fgithub.com%2F...`. Dart's [Uri.path]
/// keeps that encoding, so it has to be decoded here. A `?url=` query
/// parameter wins over the path. Malformed escapes leave the data as-is.
String deepLinkData(Uri uri) {
  final query = uri.queryParameters['url'];
  if (query != null) return query;
  if (uri.path.length <= 1) return '';
  final raw = uri.path.substring(1);
  try {
    return Uri.decodeComponent(raw);
  } on ArgumentError {
    return raw;
  }
}
