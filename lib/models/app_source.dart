import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart';
import 'package:obtainium/components/generated_form_model.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/host_request_gate.dart';
import 'package:obtainium/utils/min_update_age.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/utils/update_health.dart';

const List<int> minimumUpdateAgeOptions = [0, 1, 2, 3, 5, 7, 14, 30];

class SourceSearchProfile {
  final String id;
  final String name;
  final Map<String, dynamic> querySettings;
  final Map<String, dynamic> appSettings;

  const SourceSearchProfile({
    required this.id,
    required this.name,
    this.querySettings = const {},
    this.appSettings = const {},
  });
}

abstract class AppSource {
  List<String> hosts = [];
  bool hostChanged = false;
  bool hostIdenticalDespiteAnyChange = false;
  late String name;
  bool enforceTrackOnly = false;
  bool changeLogIfAnyIsMarkDown = true;
  bool appIdInferIsOptional = false;
  bool allowSubDomains = false;
  bool naiveStandardVersionDetection = false;
  bool allowOverride = true;
  bool neverAutoSelect = false;
  bool showReleaseDateAsVersionToggle = false;
  bool versionDetectionDisallowed = false;
  List<String> excludeCommonSettingKeys = [];
  bool urlsAlwaysHaveExtension = false;
  bool allowIncludeZips = false;
  bool allowIncludeTarballs = false;
  bool allowInsecureRedirects = false;
  bool changeLogPageIsStandardUrl = false;
  bool inferAppIdFromUrlPath = false;
  bool inferAppIdEvenWhenTrackOnly = false;
  bool suppressStandardVersionExtraction = false;
  List<String> trustedApkHosts = [];
  bool enableHostRequestGate = false;
  int maxConcurrentRequestsPerHost = 2;
  String get sourceIdentifier => runtimeType.toString();

  RegExp? _hostRegex;
  RegExp get hostRegex => _hostRegex ??= RegExp(
    '^${allowSubDomains ? '([^\\.]+\\.)*' : '(www\\.)?'}(${getSourceRegex(hosts)})\$',
  );

  void invalidateHostRegex() {
    _hostRegex = null;
  }

  bool matchesHost(String host) => hostRegex.hasMatch(host);

  AppSource() {
    name = runtimeType.toString();
  }

  final Map<String, ({bool disabled, bool defaultValue})>
  _agnosticSettingSwitchOverrides = {};

  void overrideAdditionalAppSpecificSourceAgnosticSettingSwitch(
    String key, {
    bool disabled = true,
    bool defaultValue = true,
  }) {
    _agnosticSettingSwitchOverrides[key] = (
      disabled: disabled,
      defaultValue: defaultValue,
    );
  }

  String standardizeUrl(String url) {
    url = preStandardizeUrl(url);
    if (!hostChanged) {
      url = sourceSpecificStandardizeURL(url);
    }
    return url;
  }

  Future<Map<String, String>?> getRequestHeaders(
    Map<String, dynamic> additionalSettings,
    String url, {
    bool forAPKDownload = false,
  }) async {
    return null;
  }

  App endOfGetAppChanges(App app) {
    return app;
  }

  App postProcessApp(App app) {
    return app;
  }

  Future<Map<String, dynamic>> buildMergedSettings(
    Map<String, dynamic> additionalSettings,
    SettingsProvider settingsProvider,
  ) async {
    return {
      ...additionalSettings,
      ...(await getSourceConfigValues(additionalSettings, settingsProvider)),
    };
  }

  /// File extensions Obtainium recognizes as installable Android package
  /// containers.
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

  /// Whether [name] (a filename or URL) refers to an APK-type container that
  /// Obtainium can install. Optionally also accept generic zip archives and
  /// tarballs (some sources bundle split APKs that way).
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

  /// A convenience for the common standardize-by-regex pattern: build a regex
  /// from the source's [hosts] plus the given subdomain prefix and path, match
  /// against [url], and return the match or throw [InvalidURLError].
  String standardizeUrlWithRegex(
    String url, {
    required String subdomainPrefix,
    required String pathPattern,
  }) {
    final re = RegExp(
      '^https?://$subdomainPrefix${getSourceRegex(hosts)}$pathPattern',
      caseSensitive: false,
    );
    final match = re.firstMatch(url);
    if (match == null) throw InvalidURLError(name);
    return match.group(0)!;
  }

  Future<Response> sourceRequest(
    String url,
    Map<String, dynamic> additionalSettings, {
    bool followRedirects = true,
    Object? postBody,
  }) async {
    Future<Response> perform() async {
      var sp = SettingsProvider();
      await sp.initializeSettings();
      var sourceConfigSettingValues = await getSourceConfigValues(
        additionalSettings,
        sp,
      );
      Map<String, String>? headers = await getRequestHeaders(
        additionalSettings,
        url,
      );
      return await SourceUtils.httpRequest(
        url,
        method: postBody != null ? 'POST' : 'GET',
        headers: headers,
        body: postBody,
        sourceConfigSettingValues: sourceConfigSettingValues,
        followRedirects: followRedirects,
        allowInsecure:
            additionalSettings['allowInsecure'] == true ||
            additionalSettings['allowInsecureRedirects'] == true ||
            allowInsecureRedirects,
      );
    }

    if (!enableHostRequestGate) {
      return perform();
    }
    final uri = Uri.parse(url);
    final host = uri.host;
    final blockKey = '$host|${_hostGateBucket(uri)}';
    final gate = HostRequestGate.instance;
    final response = await gate.run(
      host,
      blockKey,
      maxConcurrentRequestsPerHost,
      perform,
    );
    gate.observe(blockKey, response.statusCode, response.headers);
    return response;
  }

  static String _hostGateBucket(Uri uri) {
    if (uri.path.contains('/wp-json/')) return 'api';
    if (uri.path.endsWith('/feed/')) return 'feed';
    return 'html';
  }

  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    return url;
  }

  String preStandardizeUrl(String url) {
    url = url.trim();
    if (url.startsWith('www.')) {
      url = 'https://$url';
    } else if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    try {
      var uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        throw UnsupportedURLError();
      }
    } on FormatException {
      throw UnsupportedURLError();
    }
    return url;
  }

  static String stripLastPathSegment(String url) {
    final uri = Uri.parse(url);
    return uri
        .replace(
          pathSegments: uri.pathSegments.sublist(
            0,
            uri.pathSegments.length - 1,
          ),
        )
        .toString();
  }

  static Future<String?> tryInferAppIdFromLastPathSegment(
    String standardUrl, {
    Map<String, dynamic> additionalSettings = const {},
  }) async {
    return Uri.parse(
      standardUrl,
    ).pathSegments.where((s) => s.isNotEmpty).lastOrNull;
  }

  Future<String?> tryInferringAppId(
    String standardUrl, {
    Map<String, dynamic> additionalSettings = const {},
  }) async {
    if (inferAppIdFromUrlPath) {
      return tryInferAppIdFromLastPathSegment(standardUrl);
    }
    return null;
  }

  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  );

  /// Update-check entry point that also receives the app being updated, so
  /// sources can avoid repeat work (e.g. scraping) when nothing changed.
  /// Sources that do not need the previous app just inherit this delegate.
  Future<APKDetails> getLatestAPKDetailsWithContext(
    String standardUrl,
    Map<String, dynamic> additionalSettings, {
    App? currentApp,
  }) {
    return getLatestAPKDetails(standardUrl, additionalSettings);
  }

  /// Optional pre-pass before a batch of update checks, allowing sources to
  /// fetch shared data once (e.g. APKMirror's batched API lookup).
  Future<void> prefetchUpdateInfo(List<App> apps) async {}

  List<List<GeneratedFormItem>> additionalSourceAppSpecificSettingFormItems =
      [];

  static List<GeneratedFormItem> get fallbackToOlderReleasesFormItem => [
    GeneratedFormSwitch(
      'fallbackToOlderReleases',
      label: tr('fallbackToOlderReleases'),
      value: true,
    ),
  ];

  List<List<GeneratedFormItem>> get _versionAppSettingFormItems => [
    [
      GeneratedFormTextField(
        'versionExtractionRegEx',
        label: tr('trimVersionString'),
        required: false,
        additionalValidators: [(value) => SourceUtils.regExValidator(value)],
      ),
    ],
    [
      GeneratedFormTextField(
        'matchGroupToUse',
        label: tr('matchGroupToUseForX', args: [tr('trimVersionString')]),
        required: false,
        hint: r'$0',
      ),
    ],
    [
      GeneratedFormSwitch(
        'versionDetection',
        label: tr('versionDetectionExplanation'),
        value: true,
      ),
    ],
    [
      GeneratedFormSwitch(
        'useVersionCodeAsOSVersion',
        label: tr('useVersionCodeAsOSVersion'),
        value: false,
      ),
    ],
  ];

  List<List<GeneratedFormItem>> get _apkAppSettingFormItems => [
    [
      GeneratedFormTextField(
        'apkFilterRegEx',
        label: tr('filterAPKsByRegEx'),
        required: false,
        additionalValidators: [(value) => SourceUtils.regExValidator(value)],
      ),
    ],
    [
      GeneratedFormSwitch(
        'invertAPKFilter',
        label: '${tr('invertRegEx')} (${tr('filterAPKsByRegEx')})',
        value: false,
      ),
    ],
    [
      GeneratedFormSwitch(
        'autoApkFilterByArch',
        label: tr('autoApkFilterByArch'),
        value: true,
      ),
    ],
  ];

  List<List<GeneratedFormItem>> get _updateAppSettingFormItems => [
    [
      GeneratedFormSlider(
        'minimumUpdateAgeDays',
        [
          const MapEntry('', 'useGlobalDefault'),
          for (final days in minimumUpdateAgeOptions)
            MapEntry(days.toString(), days == 0 ? 'none' : days.toString()),
        ],
        label: tr('minimumUpdateAgeDays'),
        value: '',
        required: false,
      ),
    ],
    [
      GeneratedFormSwitch(
        'exemptFromBackgroundUpdates',
        label: tr('exemptFromBackgroundUpdates'),
      ),
    ],
    [
      GeneratedFormSwitch(
        'skipUpdateNotifications',
        label: tr('skipUpdateNotifications'),
      ),
    ],
    [
      GeneratedFormSwitch(
        'refreshBeforeDownload',
        label: tr('refreshBeforeDownload'),
      ),
    ],
    [
      GeneratedFormSwitch(
        'detectionDateAsReleaseDate',
        label: tr('detectionDateAsReleaseDate'),
      ),
    ],
  ];

  List<List<GeneratedFormItem>> get _appAppSettingFormItems => [
    [GeneratedFormSwitch('trackOnly', label: tr('trackOnly'))],
    [GeneratedFormTextField('appName', label: tr('appName'), required: false)],
    [GeneratedFormTextField('appAuthor', label: tr('author'), required: false)],
    [
      GeneratedFormSwitch(
        'shizukuPretendToBeGooglePlay',
        label: tr('shizukuPretendToBeGooglePlay'),
        value: false,
      ),
    ],
    [
      GeneratedFormSwitch(
        'allowInsecure',
        label: '${tr('allowInsecure')} ${tr('allowInsecureWarning')}',
        value: false,
      ),
    ],
    [GeneratedFormTextField('about', label: tr('about'), required: false)],
    [
      GeneratedFormSwitch(
        'aggressiveVersionReconciliation',
        label: tr('aggressiveVersionReconciliation'),
        tooltip: tr('aggressiveVersionReconciliationTooltip'),
      ),
    ],
    [
      GeneratedFormSwitch(
        'persistentVersionTracking',
        label: tr('persistentVersionTracking'),
        tooltip: tr('persistentVersionTrackingTooltip'),
      ),
    ],
  ];

  List<List<GeneratedFormItem>> _filterExcludedKeys(
    List<List<GeneratedFormItem>> items,
  ) => items
      .map(
        (e) => e
            .where((ee) => !excludeCommonSettingKeys.contains(ee.key))
            .toList(),
      )
      .where((e) => e.isNotEmpty)
      .toList();

  List<List<GeneratedFormItem>> get combinedAppSpecificSettingFormItems {
    var versionItems = cloneFormItems(_versionAppSettingFormItems);

    final versionDetectionIdx = versionItems.indexWhere(
      (row) => row.any((item) => item.key == 'versionDetection'),
    );
    if (showReleaseDateAsVersionToggle &&
        versionDetectionIdx >= 0 &&
        !versionItems.any(
          (row) => row.any((item) => item.key == 'releaseDateAsVersion'),
        )) {
      versionItems.insert(versionDetectionIdx + 1, [
        GeneratedFormSwitch(
          'releaseDateAsVersion',
          label: '${tr('releaseDateAsVersion')} (${tr('pseudoVersion')})',
          value: false,
        ),
      ]);
    }
    versionItems = _filterExcludedKeys(versionItems);

    final apkItems = _filterExcludedKeys(
      cloneFormItems(_apkAppSettingFormItems),
    );
    if (allowIncludeZips) {
      apkItems.addAll([
        [
          GeneratedFormSwitch(
            'includeZips',
            label: tr('includeZips'),
            value: false,
          ),
        ],
        [
          GeneratedFormTextField(
            'zippedApkFilterRegEx',
            label: tr('zippedApkFilterRegEx'),
            required: false,
            additionalValidators: [
              (value) => SourceUtils.regExValidator(value),
            ],
          ),
        ],
      ]);
    }
    if (allowIncludeTarballs) {
      apkItems.addAll([
        [
          GeneratedFormSwitch(
            'includeTarballs',
            label: tr('includeTarballs'),
            value: false,
          ),
        ],
        [
          GeneratedFormTextField(
            'tarballedApkFilterRegEx',
            label: tr('tarballedApkFilterRegEx'),
            required: false,
            additionalValidators: [
              (value) => SourceUtils.regExValidator(value),
            ],
          ),
        ],
      ]);
    }

    final updateItems = _filterExcludedKeys(
      cloneFormItems(_updateAppSettingFormItems),
    );
    final appItems = _filterExcludedKeys(
      cloneFormItems(_appAppSettingFormItems),
    );

    if (versionDetectionDisallowed) {
      for (var item in versionItems.expand((row) => row)) {
        if (item.key == 'versionDetection' ||
            item.key == 'useVersionCodeAsOSVersion') {
          (item as GeneratedFormSwitch).disabled = true;
          item.value = false;
        }
      }
    }

    if (_agnosticSettingSwitchOverrides.isNotEmpty) {
      for (var item in [
        ...versionItems,
        ...apkItems,
        ...updateItems,
        ...appItems,
      ].expand((r) => r)) {
        if (_agnosticSettingSwitchOverrides.containsKey(item.key) &&
            item is GeneratedFormSwitch) {
          final override = _agnosticSettingSwitchOverrides[item.key]!;
          item.disabled = override.disabled;
          item.value = override.defaultValue;
        }
      }
    }

    return [
      ...cloneFormItems(additionalSourceAppSpecificSettingFormItems),
      if (versionItems.isNotEmpty) ...[
        [GeneratedFormHeader(label: tr('sectionVersionDetection'))],
        ...versionItems,
      ],
      if (apkItems.isNotEmpty) ...[
        [GeneratedFormHeader(label: tr('sectionApkSelection'))],
        ...apkItems,
      ],
      if (updateItems.isNotEmpty) ...[
        [GeneratedFormHeader(label: tr('sectionUpdateOptions'))],
        ...updateItems,
      ],
      if (appItems.isNotEmpty) ...[
        [GeneratedFormHeader(label: tr('sectionAppOptions'))],
        ...appItems,
      ],
      [
        GeneratedFormHeader(
          id: updateHealthSectionId,
          label: tr('sectionUpdateHealthDetection'),
        ),
      ],
      ...updateHealthOverrideFormItems(),
    ];
  }

  /// Cached emptiness check for [combinedAppSpecificSettingFormItems], used to
  /// avoid rebuilding the form-item tree just to test isNotEmpty.
  bool? _hasAppSpecificSettingsCache;
  bool get hasAppSpecificSettings => _hasAppSpecificSettingsCache ??=
      combinedAppSpecificSettingFormItems.isNotEmpty;

  /// Flattened, read-only view of [combinedAppSpecificSettingFormItems].
  List<GeneratedFormItem> get flatCombinedFormItemsReadOnly =>
      combinedAppSpecificSettingFormItems.expand((row) => row).toList();

  // Some Sources may have additional settings at the Source level (not specific to Apps) - these use SettingsProvider
  // If the source has been overridden, we expect the user to define one-time values as additional settings - don't use the stored values
  List<GeneratedFormItem> sourceConfigSettingFormItems = [];
  Future<Map<String, String>> getSourceConfigValues(
    Map<String, dynamic> additionalSettings,
    SettingsProvider settingsProvider,
  ) async {
    Map<String, String> results = {};
    for (var e in sourceConfigSettingFormItems) {
      var val = hostChanged && !hostIdenticalDespiteAnyChange
          ? additionalSettings[e.key]
          : additionalSettings[e.key] ??
                settingsProvider.getSettingString(e.key);
      if (val != null) {
        // Switch items (e.g. GitHub's checkRepoRename) yield bools; this map
        // is String-typed, so stringify instead of crashing on the cast.
        results[e.key] = val is String ? val : val.toString();
      }
    }
    return results;
  }

  String? changeLogPageFromStandardUrl(String standardUrl) {
    return changeLogPageIsStandardUrl ? standardUrl : null;
  }

  Future<String?> getSourceNote() async {
    return null;
  }

  Future<String> assetUrlPrefetchModifier(
    String assetUrl,
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    return assetUrl;
  }

  Future<String> generalReqPrefetchModifier(
    String reqUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    return reqUrl;
  }

  bool canSearch = false;
  List<SourceSearchProfile> get searchProfiles => [
    SourceSearchProfile(id: name, name: name),
  ];
  bool includeAdditionalOptsInMainSearch = false;
  List<GeneratedFormItem> searchQuerySettingFormItems = [];
  Future<Map<String, List<String>>> search(
    String query, {
    Map<String, dynamic> querySettings = const {},
  }) {
    throw NotImplementedError();
  }

  Map<String, dynamic> runOnAddAppInputChange(String input) => {};
}

abstract class MassAppUrlSource {
  late String name;
  late List<String> requiredArgs;
  Future<Map<String, List<String>>> getUrlsWithDescriptions(List<String> args);
}
