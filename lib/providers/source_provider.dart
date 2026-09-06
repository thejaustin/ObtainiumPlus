// Defines App sources and provides functions used to interact with them.
//
// AppSource is an abstract class with a concrete implementation for each source.
// Legacy JSON migration logic lives at the bottom of this file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/models/version_history_entry.dart';
import 'package:obtainium/utils/app_utils.dart' show safeJsonEncode;
import 'package:obtainium/utils/url_validator.dart';
export 'package:obtainium/models/app.dart';
export 'package:obtainium/models/app_source.dart';
export 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/app_sources/apkcombo.dart';
import 'package:obtainium/app_sources/apkmirror.dart';
import 'package:obtainium/app_sources/apkpure.dart';
import 'package:obtainium/app_sources/aptoide.dart';
import 'package:obtainium/app_sources/apk4free.dart';
import 'package:obtainium/app_sources/codeberg.dart';
import 'package:obtainium/app_sources/bitbucket.dart';
import 'package:obtainium/app_sources/gitea.dart';
import '../app_sources/samsung_galaxy_store.dart';
import '../app_sources/xda_developers.dart';
import 'package:obtainium/app_sources/coolapk.dart';
import 'package:obtainium/app_sources/direct_apk_link.dart';
import 'package:obtainium/app_sources/farsroid.dart';
import 'package:obtainium/app_sources/fdroid.dart';
import 'package:obtainium/app_sources/fdroidrepo.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/app_sources/gitlab.dart';
import 'package:obtainium/app_sources/huaweiappgallery.dart';
import 'package:obtainium/app_sources/itchio.dart';
import 'package:obtainium/app_sources/izzyondroid.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/app_sources/jenkins.dart';
import 'package:obtainium/app_sources/liteapks.dart';
import 'package:obtainium/app_sources/neutroncode.dart';
import 'package:obtainium/app_sources/rockmods.dart';
import 'package:obtainium/app_sources/rustore.dart';
import 'package:obtainium/app_sources/sourceforge.dart';
import 'package:obtainium/app_sources/sourcehut.dart';
import 'package:obtainium/app_sources/telegramapp.dart';
import 'package:obtainium/app_sources/tencent.dart';
import 'package:obtainium/app_sources/uptodown.dart';
import 'package:obtainium/app_sources/vivoappstore.dart';
import 'package:obtainium/components/generated_form_model.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/app_sources/githubstars.dart';
import 'package:obtainium/app_sources/githubpersonalrepos.dart';
import 'package:obtainium/app_sources/googleplay.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';

/// Converts a list of [MapEntry] pairs into a 2D list of strings for JSON encoding.
List<List<String>> stringMapListTo2DList(
  List<MapEntry<String, String>> mapList,
) => mapList.map((e) => [e.key, e.value]).toList();

/// Converts a 2D list (decoded from JSON) back into a list of [MapEntry] pairs.
List<MapEntry<String, String>> assumed2DlistToStringMapList(
  List<dynamic> arr,
) => arr.map((e) => MapEntry(e[0] as String, e[1] as String)).toList();

/// Delegates to [HttpService.ensureAbsoluteUrl].
String ensureAbsoluteUrl(String ambiguousUrl, Uri referenceAbsoluteUrl) =>
    HttpService().ensureAbsoluteUrl(ambiguousUrl, referenceAbsoluteUrl);

/// Ensures the URL is well-formed and starts with HTTPS.
String preStandardizeUrl(String url) {
  final firstDotIndex = url.indexOf('.');
  if (!(firstDotIndex >= 0 && firstDotIndex != url.length - 1) &&
      !url.contains('[')) {
    throw UnsupportedURLError();
  }
  if (!url.toLowerCase().startsWith('http://') &&
      !url.toLowerCase().startsWith('https://')) {
    url = 'https://$url';
  }
  final uri = Uri.tryParse(url);
  final trailingSlash =
      ((uri?.path.endsWith('/') ?? false) ||
          ((uri?.path.isEmpty ?? false) && url.endsWith('/'))) &&
      (uri?.queryParameters.isEmpty ?? false);

  // Only normalize duplicate slashes in the scheme/host/path portion; leave the
  // query string and fragment untouched so any slashes they contain (e.g. a URL
  // passed as a query parameter) aren't mangled.
  var splitIndex = url.length;
  final queryStart = url.indexOf('?');
  if (queryStart >= 0 && queryStart < splitIndex) {
    splitIndex = queryStart;
  }
  final fragmentStart = url.indexOf('#');
  if (fragmentStart >= 0 && fragmentStart < splitIndex) {
    splitIndex = fragmentStart;
  }
  var mainPart = url.substring(0, splitIndex);
  final rest = url.substring(splitIndex);
  mainPart = mainPart
      .split('/')
      .where((e) => e.isNotEmpty)
      .join('/')
      .replaceFirst(':/', '://');
  url = mainPart + (trailingSlash ? '/' : '') + rest;
  return url;
}

/// Delegates to [ApkFilterService.getApkUrlsFromUrls].
List<MapEntry<String, String>> getApkUrlsFromUrls(List<String> urls) =>
    ApkFilterService().getApkUrlsFromUrls(urls);

/// Delegates to [ApkFilterService.filterApksByArch].
Future<List<MapEntry<String, String>>> filterApksByArch(
  List<MapEntry<String, String>> apkUrls,
) async {
  final abis = (await DeviceInfoPlugin().androidInfo).supportedAbis;
  return ApkFilterService().filterApksByArch(apkUrls, abis);
}

/// Builds a regex alternation pattern from a list of hostname strings, escaping dots.
String getSourceRegex(List<String> hosts) {
  return '(${hosts.join('|').replaceAll('.', '\\.')})';
}

/// Delegates to [HttpService.createHttpClient].
HttpClient createHttpClient(bool insecure) =>
    HttpService().createHttpClient(insecure);

/// Delegates to [HttpService.sourceRequestStreamResponse].
Future<MapEntry<Uri, MapEntry<HttpClient, HttpClientResponse>>>
sourceRequestStreamResponse(
  String method,
  String url,
  Map<String, String>? requestHeaders,
  Map<String, dynamic> additionalSettings, {
  bool followRedirects = true,
  Object? postBody,
}) => HttpService().sourceRequestStreamResponse(
  method,
  url,
  requestHeaders,
  additionalSettings,
  followRedirects: followRedirects,
  postBody: postBody,
);

/// Delegates to [HttpService.httpClientResponseStreamToFinalResponse].
Future<http.Response> httpClientResponseStreamToFinalResponse(
  HttpClient httpClient,
  String method,
  String url,
  HttpClientResponse response,
) => HttpService().httpClientResponseStreamToFinalResponse(
  httpClient,
  method,
  url,
  response,
);

/// Delegates to [HttpService.getHttpError].
ObtainiumError getObtainiumHttpError(Response res) =>
    HttpService().getHttpError(res);

/// Delegates to [VersionService.regExValidator].
String? regExValidator(String? value) => VersionService().regExValidator(value);

/// Returns true if the app's ID is a temporary placeholder rather than a real
/// package name. Matches [generateTempID]'s sha256-hex prefix and legacy numeric
/// IDs; real package names contain a dot and never match.
bool isTempId(App app) {
  return RegExp(r'^[0-9]+$').hasMatch(app.id) ||
      RegExp(r'^[0-9a-f]{12}$').hasMatch(app.id);
}

/// Delegates to [VersionService.replaceMatchGroupsInString].
String? replaceMatchGroupsInString(
  RegExpMatch match,
  String matchGroupString,
) => VersionService().replaceMatchGroupsInString(match, matchGroupString);

/// Delegates to [VersionService.extractVersion].
String? extractVersion(
  String? versionExtractionRegEx,
  String? matchGroupString,
  String stringToCheck,
) => VersionService().extractVersion(
  versionExtractionRegEx,
  matchGroupString,
  stringToCheck,
);

/// Delegates to [ApkFilterService.filterApks].
List<MapEntry<String, String>> filterApks(
  List<MapEntry<String, String>> apkUrls,
  String? apkFilterRegEx,
  bool? invert,
) => ApkFilterService().filterApks(apkUrls, apkFilterRegEx, invert);

/// Returns true when the app uses pseudo-versioning (track-only or disabled version detection).
bool isVersionPseudo(App app) =>
    app.settings.getBool('trackOnly') ||
    (app.installedVersion != null && !app.settings.getBool('versionDetection'));

class SourceProvider {
  static final SourceProvider _instance = SourceProvider._();
  factory SourceProvider() => _instance;
  SourceProvider._();

  // Builds a fresh set of source instances. Adding a source here makes it
  // available via the service. Kept private so callers go through [sources]
  // (cached) or, when per-call mutation is needed, [_buildSources] directly.
  static List<AppSource> _buildSources() => [
    GooglePlay(),
    GitHub(),
    GitLab(),
    Codeberg(),
    FDroid(),
    FDroidRepo(),
    IzzyOnDroid(),
    SourceHut(),
    APKPure(),
    Aptoide(),
    Uptodown(),
    ItchIO(),
    HuaweiAppGallery(),
    Tencent(),
    VivoAppStore(),
    RuStore(),
    Apk4Free(),
    Farsroid(),
    CoolApk(),
    LiteAPKs(),
    SourceForge(),
    Jenkins(),
    APKMirror(),
    APKCombo(),
    RockMods(),
    TelegramApp(),
    NeutronCode(),
    DirectAPKLink(),
    Gitea(),
    Bitbucket(),
    SamsungGalaxyStore(),
    XdaDevelopers(),
    HTML(), // Must be the last entry — hostless sources are tried in order and HTML is the catch-all fallback
  ];

  /// Cached, read-only source list built lazily by [_buildSources].
  /// Because sources are immutable after construction, the cache is safe.
  static List<AppSource>? _cachedSources;
  List<AppSource> get sources => _cachedSources ??= _buildSources();

  /// Add mass URL source classes here so they are available via the service.
  List<MassAppUrlSource> massUrlSources = [
    GitHubStars(),
    GitHubPersonalRepos(),
  ];

  AppSource getSource(String url, {String? overrideSource}) {
    url = preStandardizeUrl(url);
    if (overrideSource != null) {
      // The override path mutates the chosen source's host config, so build a
      // throwaway instance here rather than touching the shared cache.
      final srcs = _buildSources().where(
        (e) => e.sourceIdentifier == overrideSource,
      );
      if (srcs.isEmpty) {
        throw UnsupportedURLError()..url = url;
      }
      final res = srcs.first;
      final originalHosts = res.hosts;
      final newHost = Uri.parse(url).host;
      res.hosts = [newHost];
      res.hostChanged = true;
      if (originalHosts.contains(newHost)) {
        res.hostIdenticalDespiteAnyChange = true;
      }
      return res;
    }
    // The non-override path is read-only, so reuse the cached source set.
    final allSources = sources;
    AppSource? source;
    for (var s in allSources.where((element) => element.hosts.isNotEmpty)) {
      // A non-match here is expected control flow during source auto-detection,
      // so failures are intentionally not logged (they are just noise).
      try {
        if (RegExp(
          '^${s.allowSubDomains ? '([^\\.]+\\.)*' : '(www\\.)?'}(${getSourceRegex(s.hosts)})\$',
        ).hasMatch(Uri.parse(url).host)) {
          source = s;
          break;
        }
      } catch (e) {
        // Ignore and try the next source.
      }
    }
    if (source == null) {
      for (var s in allSources.where(
        (element) => element.hosts.isEmpty && !element.neverAutoSelect,
      )) {
        // As above, hostless sources are tried in order until one accepts the
        // URL; a rejection is normal and must not be logged as an error.
        try {
          s.sourceSpecificStandardizeURL(url, forSelection: true);
          source = s;
          break;
        } catch (e) {
          // Ignore and try the next source.
        }
      }
    }
    if (source == null) {
      throw UnsupportedURLError()..url = url;
    }
    return source;
  }

  bool ifRequiredAppSpecificSettingsExist(AppSource source) {
    for (var row in source.combinedAppSpecificSettingFormItems) {
      for (var element in row) {
        if (element is GeneratedFormTextField && element.required) {
          return true;
        }
      }
    }
    return false;
  }

  String generateTempID(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) => sha256
      .convert(utf8.encode(standardUrl + additionalSettings.toString()))
      .toString()
      .substring(0, 12);

  Future<String> _resolveAppId(
    AppSource source,
    App? currentApp,
    Map<String, dynamic> additionalSettings,
    bool trackOnly,
    String standardUrl,
    bool inferAppIdIfOptional,
  ) async {
    // generateTempID's sha256-hex output never needs sanitizing, but every other
    // path below returns a value derived from external/attacker-influenced input
    // (a source's inferred id, a user/import-supplied override, or a reused id
    // that predates this fix) — resolve to one raw value, then sanitize the single
    // return, so a future branch added here can't forget the file-safety guarantee.
    String? rawId = currentApp?.id;
    rawId ??= additionalSettings['appId'] as String?;
    if (rawId == null &&
        !trackOnly &&
        (!source.appIdInferIsOptional ||
            (source.appIdInferIsOptional && inferAppIdIfOptional))) {
      rawId = await source.tryInferringAppId(
        standardUrl,
        additionalSettings: additionalSettings,
      );
    }
    if (rawId == null) return generateTempID(standardUrl, additionalSettings);
    return URLValidator.sanitizeAppId(rawId);
  }

  Future<App> getApp(
    AppSource source,
    String url,
    Map<String, dynamic> additionalSettings, {
    App? currentApp,
    bool trackOnlyOverride = false,
    bool sourceIsOverriden = false,
    bool inferAppIdIfOptional = false,
  }) async {
    additionalSettings = Map<String, dynamic>.from(additionalSettings);
    if (trackOnlyOverride || source.enforceTrackOnly) {
      additionalSettings['trackOnly'] = true;
    }
    final trackOnly = additionalSettings['trackOnly'] == true;
    final String standardUrl;
    try {
      standardUrl = source.standardizeUrl(url);
    } on ObtainiumError catch (e) {
      throw e..withUrlContext(url);
    }
    final APKDetails apk;
    try {
      apk = await source.getLatestAPKDetails(standardUrl, additionalSettings);
    } on ObtainiumError catch (e) {
      throw e..withUrlContext(standardUrl);
    }

    if (!source.suppressStandardVersionExtraction) {
      final String? extractedVersion = extractVersion(
        additionalSettings['versionExtractionRegEx'] as String?,
        additionalSettings['matchGroupToUse'] as String?,
        apk.version,
      );
      if (extractedVersion != null) {
        apk.version = extractedVersion;
      }
    }

    if (additionalSettings['releaseDateAsVersion'] == true &&
        apk.releaseDate != null) {
      apk.version = apk.releaseDate!.microsecondsSinceEpoch.toString();
    }
    apk.apkUrls = filterApks(
      apk.apkUrls,
      additionalSettings['apkFilterRegEx'],
      additionalSettings['invertAPKFilter'],
    );
    if (apk.apkUrls.isEmpty && !trackOnly) {
      throw NoAPKError()..url = standardUrl;
    }
    if (additionalSettings['autoApkFilterByArch'] == true) {
      apk.apkUrls = await filterApksByArch(apk.apkUrls);
      if (apk.apkUrls.isEmpty && !trackOnly) {
        throw NoAPKError()..url = standardUrl;
      }
    }
    var name = currentApp != null ? currentApp.name.trim() : '';
    name = name.isNotEmpty ? name : apk.names.name;
    final App finalApp = App(
      await _resolveAppId(
        source,
        currentApp,
        additionalSettings,
        trackOnly,
        standardUrl,
        inferAppIdIfOptional,
      ),
      standardUrl,
      apk.names.author,
      name,
      currentApp?.installedVersion,
      apk.version,
      apk.apkUrls,
      currentApp?.preferredApkIndex ??
          (apk.apkUrls.isNotEmpty ? apk.apkUrls.length - 1 : 0),
      additionalSettings,
      DateTime.now(),
      currentApp?.pinned ?? false,
      categories: currentApp?.categories ?? const [],
      releaseDate: apk.releaseDate,
      changeLog: apk.changeLog,
      overrideSource: sourceIsOverriden
          ? source.sourceIdentifier
          : currentApp?.overrideSource,
      allowIdChange:
          currentApp?.allowIdChange ??
          trackOnly || (source.appIdInferIsOptional && inferAppIdIfOptional),
      otherAssetUrls: apk.allAssetUrls
          .where((a) => apk.apkUrls.indexWhere((p) => a.key == p.key) < 0)
          .toList(),
      versionHistory: _buildVersionHistory(currentApp, apk),
    );
    return source.postProcessApp(finalApp);
  }

  List<VersionHistoryEntry> _buildVersionHistory(
    App? currentApp,
    APKDetails apk,
  ) {
    if (currentApp == null) {
      return [
        VersionHistoryEntry(
          version: apk.version,
          changeLog: apk.changeLog,
          releaseDate: apk.releaseDate,
          detectedAt: DateTime.now(),
        ),
      ];
    }
    if (currentApp.latestVersion != apk.version) {
      final newEntry = VersionHistoryEntry(
        version: apk.version,
        changeLog: apk.changeLog,
        releaseDate: apk.releaseDate,
        detectedAt: DateTime.now(),
      );
      final list = List<VersionHistoryEntry>.from(currentApp.versionHistory)
        ..insert(0, newEntry);
      return list.length > 5 ? list.sublist(0, 5) : list;
    }

    if (currentApp.versionHistory.isEmpty &&
        currentApp.latestVersion.isNotEmpty) {
      return [
        VersionHistoryEntry(
          version: currentApp.latestVersion,
          changeLog: currentApp.changeLog,
          releaseDate: currentApp.releaseDate,
          detectedAt: DateTime.now(),
        ),
      ];
    }

    return currentApp.versionHistory;
  }

  // Returns errors in [results, errors] instead of throwing them
  Future<List<dynamic>> getAppsByURLNaive(
    List<String> urls, {
    Set<String> alreadyAddedUrls = const {},
    AppSource? sourceOverride,
  }) async {
    final List<App> apps = [];
    final Map<String, dynamic> errors = {};
    const concurrency = 4;
    for (var i = 0; i < urls.length; i += concurrency) {
      final end = i + concurrency > urls.length ? urls.length : i + concurrency;
      final batch = urls.sublist(i, end);
      final results = await Future.wait(
        batch.map((url) async {
          try {
            if (alreadyAddedUrls.contains(url)) {
              throw ObtainiumError(tr('appAlreadyAdded'));
            }
            final source = sourceOverride ?? getSource(url);
            return await getApp(
              source,
              url,
              sourceIsOverriden: sourceOverride != null,
              getDefaultValuesFromFormItems(
                source.combinedAppSpecificSettingFormItems,
              ),
            );
          } catch (e) {
            return e;
          }
        }),
      );
      for (var j = 0; j < batch.length; j++) {
        final result = results[j];
        if (result is App) {
          apps.add(result);
        } else {
          errors[batch[j]] = result;
        }
      }
    }
    return [apps, errors];
  }
}

/// Type-safe wrapper around [App.additionalSettings] that eliminates
/// manual casts and null checks when reading per-source configuration values.
///
/// Usage:
/// ```dart
/// if (app.settings.getBool('trackOnly')) { ... }
/// String? regex = app.settings.getStringOrNull('apkFilterRegEx');
/// ```
class TypedSettings {
  final Map<String, dynamic> _raw;

  const TypedSettings(Map<String, dynamic> raw) : _raw = raw;

  bool getBool(String key, {bool defaultValue = false}) {
    final val = _raw[key];
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is String) return val == 'true';
    return defaultValue;
  }

  int? getIntOrNull(String key) {
    final val = _raw[key];
    if (val is int) return val;
    if (val is String) return int.tryParse(val);
    return null;
  }

  String? getStringOrNull(String key) {
    final val = _raw[key];
    if (val == null) return null;
    if (val is String) return val.isNotEmpty ? val : null;
    return val.toString();
  }

  String getString(String key, {String defaultValue = ''}) =>
      getStringOrNull(key) ?? defaultValue;

  @override
  String toString() => _raw.toString();
}

class HttpService {
  static const int maxRedirects = 10;

  HttpClient createHttpClient(bool insecure) {
    final client = HttpClient();
    // dart:io's HttpClient has no connection timeout by default, so a
    // stalled TCP handshake (dead host, silent firewall drop, bad DNS)
    // hangs the request forever with no way to recover — this was the
    // root cause of search/update-check results silently never appearing.
    client.connectionTimeout = const Duration(seconds: 15);
    if (insecure) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }

  String ensureAbsoluteUrl(String ambiguousUrl, Uri referenceAbsoluteUrl) {
    try {
      ambiguousUrl = ambiguousUrl.trim();
      if (Uri.parse(ambiguousUrl).isAbsolute) {
        return ambiguousUrl;
      }
    } on FormatException {
      // Non-parsable URL, fall through to resolve logic below
    }
    return referenceAbsoluteUrl.resolve(ambiguousUrl).toString();
  }

  /// Performs an HTTP request with redirect following, returning the final URL, client, and streamed response.
  Future<MapEntry<Uri, MapEntry<HttpClient, HttpClientResponse>>>
  sourceRequestStreamResponse(
    String method,
    String url,
    Map<String, String>? requestHeaders,
    Map<String, dynamic> additionalSettings, {
    bool followRedirects = true,
    Object? postBody,
  }) async {
    var currentUrl = Uri.parse(url);
    var redirectCount = 0;
    List<Cookie> cookies = [];
    HttpClient? httpClient;
    while (redirectCount < maxRedirects) {
      httpClient = createHttpClient(
        additionalSettings['allowInsecure'] == true,
      );
      final request = await httpClient.openUrl(method, currentUrl);
      if (requestHeaders != null) {
        requestHeaders.forEach((key, value) {
          request.headers.set(key, value);
        });
      }
      request.cookies.addAll(cookies);
      request.followRedirects = false;
      if (postBody != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(postBody));
      }
      // connectionTimeout only bounds the TCP handshake — a server that
      // accepts the connection but never sends a response header would
      // still hang here forever without this.
      final response = await request.close().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ObtainiumError(tr('requestTimedOut')),
      );

      if (followRedirects &&
          (response.statusCode >= 300 && response.statusCode <= 399)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location != null) {
          final nextUrl = Uri.parse(ensureAbsoluteUrl(location, currentUrl));
          if (currentUrl.scheme == 'https' &&
              nextUrl.scheme == 'http' &&
              additionalSettings['allowInsecure'] != true &&
              additionalSettings['allowInsecureRedirects'] != true) {
            httpClient.close();
            throw ObtainiumError(tr('insecureRedirect'));
          }
          if (nextUrl.host != currentUrl.host && headers != null) {
            headers.remove(HttpHeaders.authorizationHeader);
            headers.remove('authorization');
            headers.remove(HttpHeaders.proxyAuthorizationHeader);
          }
          currentUrl = nextUrl;
          redirectCount++;
          cookies = response.cookies;
          httpClient.close();
          httpClient = null;
          continue;
        }
      }

      return MapEntry(currentUrl, MapEntry(httpClient, response));
    }
    httpClient?.close();
    throw ObtainiumError(tr('tooManyRedirects'));
  }

  Future<http.Response> httpClientResponseStreamToFinalResponse(
    HttpClient httpClient,
    String method,
    String url,
    HttpClientResponse response,
  ) async {
    try {
      final bytes = (await response.fold<BytesBuilder>(
        BytesBuilder(),
        (b, d) => b..add(d),
      )).toBytes();

      final headers = <String, String>{};
      response.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      return http.Response.bytes(
        bytes,
        response.statusCode,
        headers: headers,
        request: http.Request(method, Uri.parse(url)),
      );
    } finally {
      httpClient.close();
    }
  }

  ObtainiumError getHttpError(http.Response res) {
    if (res.statusCode == 404) return NoReleasesError();

    final reasonLower = res.reasonPhrase?.toLowerCase() ?? '';
    final bodySample = res.body.length > 1000
        ? res.body.substring(0, 1000).toLowerCase()
        : res.body.toLowerCase();

    final isRateLimit =
        res.statusCode == 429 ||
        res.statusCode == 403 ||
        reasonLower.contains('rate limit') ||
        reasonLower.contains('too many requests') ||
        bodySample.contains('rate limit') ||
        bodySample.contains('too many requests');

    if (isRateLimit) {
      final retryAfter = res.headers['retry-after'];
      final secs = retryAfter != null ? int.tryParse(retryAfter) : null;
      if (secs != null) return RateLimitError((secs / 60).ceil());

      final resetHeader = res.headers['x-ratelimit-reset'];
      if (resetHeader != null) {
        final parsed = int.tryParse(resetHeader);
        if (parsed != null) {
          // x-ratelimit-reset is typically in seconds since epoch
          final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final remainingMinutes = ((parsed - nowSeconds) / 60).ceil().clamp(
            1,
            9999,
          );
          return RateLimitError(remainingMinutes);
        }
      }
      return RateLimitError(30); // Default to conservative 30 minutes
    }

    return ObtainiumError(
      (res.reasonPhrase != null && res.reasonPhrase!.isNotEmpty)
          ? res.reasonPhrase!
          : tr('errorWithHttpStatusCode', args: [res.statusCode.toString()]),
      code: 'HTTP_ERROR',
    );
  }
}

class VersionService {
  static const defaultMatchGroup = '0';

  static final List<String> standardVersionRegExStrings =
      _generateStandardVersionRegExStrings();

  static final List<MapEntry<String, RegExp>> strictStandardVersionRegExes =
      standardVersionRegExStrings
          .map((p) => MapEntry(p, RegExp('^$p\$')))
          .toList();

  static final List<MapEntry<String, RegExp>> looseStandardVersionRegExes =
      standardVersionRegExStrings.map((p) => MapEntry(p, RegExp(p))).toList();

  static List<String> _generateStandardVersionRegExStrings() {
    final basics = [
      '[0-9]+',
      '[0-9]+\\.[0-9]+',
      '[0-9]+\\.[0-9]+\\.[0-9]+',
      '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+',
    ];
    final preSuffixes = ['-', '\\+'];
    final suffixes = [
      'alpha',
      'beta',
      'rc',
      'pre',
      'dev',
      'snapshot',
      'nightly',
      'ose',
      '[0-9]+',
    ];
    final finals = ['\\+[0-9]+', '[0-9]+'];
    final List<String> results = [];
    for (var b in basics) {
      results.add(b);
      for (var p in preSuffixes) {
        for (var s in suffixes) {
          results.add('$b$s');
          results.add('$b$p$s');
          for (var f in finals) {
            results.add('$b$s$f');
            results.add('$b$p$s$f');
          }
        }
      }
    }
    return results.toSet().toList();
  }

  String? regExValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      RegExp(value);
    } catch (e) {
      return tr('invalidRegEx');
    }
    return null;
  }

  /// Replaces `$N` references in a string with the corresponding regex match groups.
  String? replaceMatchGroupsInString(
    RegExpMatch match,
    String matchGroupString,
  ) {
    if (RegExp('^\\d+\$').hasMatch(matchGroupString)) {
      matchGroupString = '\$$matchGroupString';
    }
    final numberRegex = RegExp(r'\$\d+');
    final numbers = numberRegex.allMatches(matchGroupString);
    if (numbers.isEmpty) {
      return null;
    }
    var outputString = matchGroupString;
    for (final numberMatch in numbers) {
      final number = numberMatch.group(0)!;
      final matchGroup = match.group(int.parse(number.substring(1))) ?? '';
      final isEscaped = outputString.contains('\\$number');
      if (!isEscaped) {
        outputString = outputString.replaceAll(number, matchGroup);
      } else {
        outputString = outputString.replaceAll('\\$number', number);
      }
    }
    return outputString;
  }

  /// Applies a version extraction regex to a string and returns the captured match group.
  String? extractVersion(
    String? versionExtractionRegEx,
    String? matchGroupString,
    String stringToCheck,
  ) {
    if (versionExtractionRegEx?.isNotEmpty == true) {
      String? version = stringToCheck;
      final match = RegExp(versionExtractionRegEx!).allMatches(version);
      if (match.isEmpty) {
        throw NoVersionError();
      }
      matchGroupString = matchGroupString?.trim() ?? '';
      if (matchGroupString.isEmpty) {
        matchGroupString = defaultMatchGroup;
      }
      version = replaceMatchGroupsInString(match.last, matchGroupString);
      if (version?.isNotEmpty != true) {
        throw NoVersionError();
      }
      return version!;
    } else {
      return null;
    }
  }

  static final Map<String, Set<String>> _strictFormatCache = {};
  static final Map<String, Set<String>> _looseFormatCache = {};
  static const int _maxFormatCacheSize = 4096;

  Set<String> findStandardFormatsForVersion(String version, bool strict) {
    final cache = strict ? _strictFormatCache : _looseFormatCache;
    final cached = cache[version];
    if (cached != null) return cached;

    final Set<String> results = {};
    final patterns = strict
        ? strictStandardVersionRegExes
        : looseStandardVersionRegExes;
    for (var entry in patterns) {
      if (entry.value.hasMatch(version)) {
        results.add(entry.key);
      }
    }
    if (cache.length >= _maxFormatCacheSize) cache.clear();
    cache[version] = results;
    return results;
  }

  bool doStringsMatchUnderRegEx(String pattern, String value1, String value2) {
    final r = RegExp(pattern);
    final m1 = r.firstMatch(value1);
    final m2 = r.firstMatch(value2);
    return m1 != null && m2 != null
        ? value1.substring(m1.start, m1.end) ==
              value2.substring(m2.start, m2.end)
        : false;
  }
}

class ApkFilterService {
  static const List<String> apkContainerExtensions = [
    '.apk',
    '.xapk',
    '.apkm',
    '.apks',
  ];

  static const List<String> archiveExtensions = ['.zip'];

  static const List<String> tarballExtensions = [
    '.tar.gz',
    '.tgz',
    '.tar.bz2',
    '.tar.xz',
  ];

  static bool isApkOrContainerFile(
    String name, {
    bool includeArchives = false,
    bool includeTarballs = false,
  }) {
    final lower = name.toLowerCase();
    bool endsWithAny(List<String> exts) => exts.any(lower.endsWith);
    return endsWithAny(apkContainerExtensions) ||
        (includeArchives && endsWithAny(archiveExtensions)) ||
        (includeTarballs && endsWithAny(tarballExtensions));
  }

  List<MapEntry<String, String>> getApkUrlsFromUrls(List<String> urls) =>
      urls.map((e) {
        final segments = e.split('/').where((el) => el.trim().isNotEmpty);
        final apkSegs = segments.where((s) => isApkOrContainerFile(s));
        return MapEntry(apkSegs.isNotEmpty ? apkSegs.last : segments.last, e);
      }).toList();

  List<MapEntry<String, String>> filterApks(
    List<MapEntry<String, String>> apkUrls,
    String? apkFilterRegEx,
    bool? invert,
  ) {
    if (apkFilterRegEx?.isNotEmpty == true) {
      final reg = RegExp(apkFilterRegEx!);
      apkUrls = apkUrls.where((element) {
        final hasMatch = reg.hasMatch(element.key);
        return invert == true ? !hasMatch : hasMatch;
      }).toList();
    }
    return apkUrls;
  }

  Future<List<MapEntry<String, String>>> filterApksByArch(
    List<MapEntry<String, String>> apkUrls,
    List<String> abis, {
    bool preferSplits = true,
  }) async {
    if (apkUrls.length > 1) {
      for (var abi in abis) {
        final urls2 = apkUrls
            .where(
              (element) => RegExp(
                '.*$abi.*',
                caseSensitive: false,
              ).hasMatch(element.key),
            )
            .toList();
        if (urls2.isNotEmpty && urls2.length < apkUrls.length) {
          apkUrls = urls2;
          break;
        }
      }
    }
    return apkUrls;
  }
}

Map<String, dynamic> _migrateAppToHTML(
  Map<String, dynamic> json,
  Map<String, dynamic> additionalSettings, {
  required String newUrl,
  Map<String, dynamic>? overrides,
}) {
  json['url'] = newUrl;
  final replacement = getDefaultValuesFromFormItems(
    HTML().combinedAppSpecificSettingFormItems,
  );
  for (var s in replacement.keys) {
    if (additionalSettings.containsKey(s)) {
      replacement[s] = additionalSettings[s];
    }
  }
  if (overrides != null) replacement.addAll(overrides);
  return replacement;
}

/// Migrates old-style `additionalData` array (list of strings) to the
/// newer `additionalSettings` map, keyed by form-item key.
void _migrateAdditionalDataToSettings(
  Map<String, dynamic> json,
  Map<String, dynamic> additionalSettings,
  List<GeneratedFormItem> formItems,
) {
  if (json['additionalData'] == null) return;
  final decoded = jsonDecode(json['additionalData']);
  if (decoded is! List) return;
  final List<String> temp = List<String>.from(decoded);
  temp.asMap().forEach((i, value) {
    if (i < formItems.length) {
      if (formItems[i] is GeneratedFormSwitch) {
        additionalSettings[formItems[i].key] = value == 'true';
      } else {
        additionalSettings[formItems[i].key] = value;
      }
    }
  });
  additionalSettings['trackOnly'] =
      json['trackOnly'] == 'true' || json['trackOnly'] == true;
  additionalSettings['noVersionDetection'] =
      json['noVersionDetection'] == 'true' ||
      json['noVersionDetection'] == true;
}

/// Converts legacy booleans `noVersionDetection` / `releaseDateAsVersion`
/// to the current `versionDetection` string dropdown and back.
void _migrateVersionDetectionFormat(Map<String, dynamic> additionalSettings) {
  if (additionalSettings['noVersionDetection'] == true) {
    additionalSettings['versionDetection'] = 'noVersionDetection';
    if (additionalSettings['releaseDateAsVersion'] == true) {
      additionalSettings['versionDetection'] = 'releaseDateAsVersion';
    }
    additionalSettings.remove('noVersionDetection');
    additionalSettings.remove('releaseDateAsVersion');
  }
  if (additionalSettings['versionDetection'] == 'standardVersionDetection') {
    additionalSettings['versionDetection'] = true;
  } else if (additionalSettings['versionDetection'] == 'noVersionDetection') {
    additionalSettings['versionDetection'] = false;
  } else if (additionalSettings['versionDetection'] == 'releaseDateAsVersion') {
    additionalSettings['versionDetection'] = false;
    additionalSettings['releaseDateAsVersion'] = true;
  }
}

/// Converts legacy `supportFixedAPKURL` bool to `defaultPseudoVersioningMethod`.
void _migratePseudoVersioningMethod(
  Map<String, dynamic> originalAdditionalSettings,
  Map<String, dynamic> additionalSettings,
) {
  if (originalAdditionalSettings['supportFixedAPKURL'] == true) {
    additionalSettings['defaultPseudoVersioningMethod'] = 'partialAPKHash';
  } else if (originalAdditionalSettings['supportFixedAPKURL'] == false) {
    additionalSettings['defaultPseudoVersioningMethod'] = 'APKLinkHash';
  }
}

/// Ensures every known form item's value is coerced to its declared type.
void _coerceAdditionalSettingTypes(
  Map<String, dynamic> additionalSettings,
  List<GeneratedFormItem> formItems,
) {
  for (var item in formItems) {
    if (additionalSettings[item.key] != null) {
      additionalSettings[item.key] = item.ensureType(
        additionalSettings[item.key],
      );
    }
  }
}

/// Normalises `apkUrls` to the current 2D-list JSON format.
void _migrateApkUrlsFormat(Map<String, dynamic> json) {
  if (json['apkUrls'] == null) return;
  final apkUrlJson = jsonDecode(json['apkUrls']);
  List<MapEntry<String, String>> apkUrls;
  try {
    apkUrls = getApkUrlsFromUrls(List<String>.from(apkUrlJson));
  } catch (e) {
    apkUrls = assumed2DlistToStringMapList(List<dynamic>.from(apkUrlJson));
  }
  json['apkUrls'] = jsonEncode(stringMapListTo2DList(apkUrls));
}

/// Applies HTML-source-specific one-time migrations: key renames,
/// intermediate-link format upgrade, and legacy-source → HTML conversions
/// (Steam, Signal, WhatsApp, VLC).
Map<String, dynamic> _migrateHtmlSpecificMigrations(
  Map<String, dynamic> json,
  Map<String, dynamic> originalAdditionalSettings,
  Map<String, dynamic> additionalSettings,
) {
  if (originalAdditionalSettings['sortByFileNamesNotLinks'] != null) {
    additionalSettings['sortByLastLinkSegment'] =
        originalAdditionalSettings['sortByFileNamesNotLinks'];
  }
  if (originalAdditionalSettings['intermediateLinkRegex'] != null &&
      additionalSettings['intermediateLinkRegex']?.isNotEmpty != true) {
    additionalSettings['intermediateLink'] = [
      {
        'customLinkFilterRegex':
            originalAdditionalSettings['intermediateLinkRegex'],
        'filterByLinkText':
            originalAdditionalSettings['intermediateLinkByText'],
      },
    ];
  }
  if ((additionalSettings['intermediateLink']?.length ?? 0) > 0) {
    additionalSettings['intermediateLink'] =
        additionalSettings['intermediateLink'].where((e) {
          return e['customLinkFilterRegex']?.isNotEmpty == true;
        }).toList();
  }

  final legacySteamSourceApps = ['steam', 'steam-chat-app'];
  if (legacySteamSourceApps.contains(additionalSettings['app'] ?? '')) {
    additionalSettings = _migrateAppToHTML(
      json,
      additionalSettings,
      newUrl: '${json['url']}/mobile',
      overrides: {
        'customLinkFilterRegex':
            '/${additionalSettings['app']}-(([0-9]+\\.?){1,})\\.apk',
        'versionExtractionRegEx':
            '/${additionalSettings['app']}-(([0-9]+\\.?){1,})\\.apk',
        'matchGroupToUse': '\$1',
      },
    );
  }
  if (json['url'] == 'https://signal.org' &&
      json['id'] == 'org.thoughtcrime.securesms' &&
      json['author'] == 'Signal' &&
      json['name'] == 'Signal' &&
      json['overrideSource'] == null &&
      additionalSettings['trackOnly'] == false &&
      additionalSettings['versionExtractionRegEx'] == '' &&
      json['lastUpdateCheck'] != null) {
    additionalSettings = _migrateAppToHTML(
      json,
      additionalSettings,
      newUrl: 'https://updates.signal.org/android/latest.json',
      overrides: {'versionExtractionRegEx': r'\d+.\d+.\d+'},
    );
  }
  if (json['url'] == 'https://whatsapp.com' &&
      json['id'] == 'com.whatsapp' &&
      json['author'] == 'Meta' &&
      json['name'] == 'WhatsApp' &&
      json['overrideSource'] == null &&
      additionalSettings['trackOnly'] == false &&
      additionalSettings['versionExtractionRegEx'] == '' &&
      json['lastUpdateCheck'] != null) {
    additionalSettings = _migrateAppToHTML(
      json,
      additionalSettings,
      newUrl: 'https://whatsapp.com/android',
      overrides: {'refreshBeforeDownload': true},
    );
  }
  if (json['url'] == 'https://videolan.org' &&
      json['id'] == 'org.videolan.vlc' &&
      json['author'] == 'VideoLAN' &&
      json['name'] == 'VLC' &&
      json['overrideSource'] == null &&
      additionalSettings['trackOnly'] == false &&
      additionalSettings['versionExtractionRegEx'] == '' &&
      json['lastUpdateCheck'] != null) {
    additionalSettings = _migrateAppToHTML(
      json,
      additionalSettings,
      newUrl: 'https://www.videolan.org/vlc/download-android.html',
      overrides: {
        'refreshBeforeDownload': true,
        'intermediateLink': <Map<String, dynamic>>[
          {
            'customLinkFilterRegex': 'APK',
            'filterByLinkText': true,
            'skipSort': false,
            'reverseSort': false,
            'sortByLastLinkSegment': false,
          },
          {
            'customLinkFilterRegex': r'arm64-v8a\.apk$',
            'filterByLinkText': false,
            'skipSort': false,
            'reverseSort': false,
            'sortByLastLinkSegment': false,
          },
        ],
        'versionExtractionRegEx': '/vlc-android/([^/]+)/',
        'matchGroupToUse': '1',
      },
    );
  }
  return additionalSettings;
}

/// Migrates F-Droid cloudflare URLs to override-source and auto-detects
/// third-party F-Droid repo URLs.
void _migrateFdroidOverrides(Map<String, dynamic> json) {
  final overrideSourceWasUndefined = !json.keys.contains('overrideSource');
  if ((json['url'] as String).startsWith('https://cloudflare.f-droid.org')) {
    json['overrideSource'] = FDroid().sourceIdentifier;
  } else if (overrideSourceWasUndefined) {
    final RegExpMatch? match = RegExp(
      '^https?://.+/fdroid/([^/]+(/|\\?)|[^/]+\$)',
    ).firstMatch(json['url'] as String);
    if (match != null) {
      json['overrideSource'] = FDroidRepo().sourceIdentifier;
    }
  }
}

/// Applies any legacy JSON transformations so the stored [json] matches the
/// current schema. All transformations are idempotent, so they run on every
/// load.
Map<String, dynamic> appJSONCompatibilityModifiers(Map<String, dynamic> json) {
  final source = SourceProvider().getSource(
    json['url'],
    overrideSource: json['overrideSource'],
  );
  final formItems = source.flatCombinedFormItemsReadOnly;
  Map<String, dynamic> additionalSettings = getDefaultValuesFromFormItems([
    formItems,
  ]);
  Map<String, dynamic> originalAdditionalSettings = {};
  if (json['additionalSettings'] != null) {
    originalAdditionalSettings = Map<String, dynamic>.from(
      jsonDecode(json['additionalSettings']),
    );
    additionalSettings.addEntries(originalAdditionalSettings.entries);
  }

  _migrateAdditionalDataToSettings(json, additionalSettings, formItems);
  _migrateVersionDetectionFormat(additionalSettings);
  _migratePseudoVersioningMethod(
    originalAdditionalSettings,
    additionalSettings,
  );
  _coerceAdditionalSettingTypes(additionalSettings, formItems);

  int preferredApkIndex = json['preferredApkIndex'] == null
      ? 0
      : json['preferredApkIndex'] as int;
  if (preferredApkIndex < 0) {
    preferredApkIndex = 0;
  }
  json['preferredApkIndex'] = preferredApkIndex;
  _migrateApkUrlsFormat(json);

  if (additionalSettings['autoApkFilterByArch'] == null) {
    additionalSettings['autoApkFilterByArch'] = false;
  }
  if (additionalSettings['dontSortReleasesList'] == true) {
    additionalSettings['sortMethodChoice'] = 'none';
  }

  if (source is HTML) {
    additionalSettings = _migrateHtmlSpecificMigrations(
      json,
      originalAdditionalSettings,
      additionalSettings,
    );
  }

  json['additionalSettings'] = safeJsonEncode(additionalSettings);
  _migrateFdroidOverrides(json);
  return json;
}
