import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart';
import 'package:obtainium/components/generated_form_model.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/source_utils.dart';

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
  bool suppressStandardVersionExtraction = false;
  String get sourceIdentifier => runtimeType.toString();

  AppSource() {
    name = runtimeType.toString();
  }

  void overrideAdditionalAppSpecificSourceAgnosticSettingSwitch(
    String key, {
    bool disabled = true,
    bool defaultValue = true,
  }) {
    additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly =
        additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly.map(
          (e) {
            return e.map((e2) {
              if (e2.key == key) {
                var item = e2 as GeneratedFormSwitch;
                item.disabled = disabled;
                item.value = defaultValue;
              }
              return e2;
            }).toList();
          },
        ).toList();
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
      allowInsecure: additionalSettings['allowInsecure'] == true ||
          additionalSettings['allowInsecureRedirects'] == true ||
          allowInsecureRedirects,
    );
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

  List<List<GeneratedFormItem>> additionalSourceAppSpecificSettingFormItems =
      [];

  static List<GeneratedFormItem> get fallbackToOlderReleasesFormItem => [
    GeneratedFormSwitch(
      'fallbackToOlderReleases',
      label: tr('fallbackToOlderReleases'),
      value: true,
    ),
  ];

  // Some additional data may be needed for Apps regardless of Source
  List<List<GeneratedFormItem>>
  additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly = [
    [GeneratedFormSwitch('trackOnly', label: tr('trackOnly'))],
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
        hint: '\$0',
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
    [
      GeneratedFormTextField(
        'apkFilterRegEx',
        label: tr('filterAPKsByRegEx'),
        required: false,
        additionalValidators: [
          (value) {
            return SourceUtils.regExValidator(value);
          },
        ],
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
    [GeneratedFormTextField('about', label: tr('about'), required: false)],
    [
      GeneratedFormSwitch(
        'refreshBeforeDownload',
        label: tr('refreshBeforeDownload'),
      ),
    ],
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

  // Previous 2 variables combined into one at runtime for convenient usage + additional processing
  List<List<GeneratedFormItem>> get combinedAppSpecificSettingFormItems {
    if (showReleaseDateAsVersionToggle == true) {
      if (additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly
              .indexWhere(
                (List<GeneratedFormItem> e) =>
                    e.indexWhere(
                      (GeneratedFormItem i) => i.key == 'releaseDateAsVersion',
                    ) >=
                    0,
              ) <
          0) {
        additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly
            .insert(
              additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly
                      .indexWhere(
                        (List<GeneratedFormItem> e) =>
                            e.indexWhere(
                              (GeneratedFormItem i) =>
                                  i.key == 'versionDetection',
                            ) >=
                            0,
                      ) +
                  1,
              [
                GeneratedFormSwitch(
                  'releaseDateAsVersion',
                  label:
                      '${tr('releaseDateAsVersion')} (${tr('pseudoVersion')})',
                  value: false,
                ),
              ],
            );
      }
    }
    additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly =
        additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly
            .map(
              (e) => e
                  .where((ee) => !excludeCommonSettingKeys.contains(ee.key))
                  .toList(),
            )
            .where((e) => e.isNotEmpty)
            .toList();

    var moreConditionalItems = [];
    if (allowIncludeZips) {
      moreConditionalItems.addAll([
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
              (value) {
                return SourceUtils.regExValidator(value);
              },
            ],
          ),
        ],
      ]);
    }

    if (allowIncludeTarballs) {
      moreConditionalItems.addAll([
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
              (value) {
                return SourceUtils.regExValidator(value);
              },
            ],
          ),
        ],
      ]);
    }

    if (versionDetectionDisallowed) {
      overrideAdditionalAppSpecificSourceAgnosticSettingSwitch(
        'versionDetection',
        disabled: true,
        defaultValue: false,
      );
      overrideAdditionalAppSpecificSourceAgnosticSettingSwitch(
        'useVersionCodeAsOSVersion',
        disabled: true,
        defaultValue: false,
      );
    }
    return [
      ...additionalSourceAppSpecificSettingFormItems,
      ...additionalAppSpecificSourceAgnosticSettingFormItemsNeverUseDirectly,
      ...moreConditionalItems,
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
