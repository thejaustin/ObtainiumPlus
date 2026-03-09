import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/utils/source_utils.dart';

import 'package:obtainium/utils/version_utils.dart';

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
                item.defaultValue = defaultValue;
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
      allowInsecure: additionalSettings['allowInsecure'] == true,
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

  Future<String?> tryInferringAppId(
    String standardUrl, {
    Map<String, dynamic> additionalSettings = const {},
  }) async {
    return null;
  }

  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  );

  List<List<GeneratedFormItem>> additionalSourceAppSpecificSettingFormItems =
      [];

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
        label: tr('matchGroupToUseForX', args: [tr('trimVersionString')])
        ,
        required: false,
        hint: '\$0',
      ),
    ],
    [
      GeneratedFormSwitch(
        'versionDetection',
        label: tr('versionDetectionExplanation'),
        defaultValue: true,
      ),
    ],
    [
      GeneratedFormSwitch(
        'useVersionCodeAsOSVersion',
        label: tr('useVersionCodeAsOSVersion'),
        defaultValue: false,
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
        defaultValue: false,
      ),
    ],
    [
      GeneratedFormSwitch(
        'autoApkFilterByArch',
        label: tr('autoApkFilterByArch'),
        defaultValue: true,
      ),
    ],
    [GeneratedFormTextField('appName', label: tr('appName'), required: false)],
    [GeneratedFormTextField('appAuthor', label: tr('author'), required: false)],
    [
      GeneratedFormSwitch(
        'shizukuPretendToBeGooglePlay',
        label: tr('shizukuPretendToBeGooglePlay'),
        defaultValue: false,
      ),
    ],
    [
      GeneratedFormSwitch(
        'allowInsecure',
        label: '${tr('allowInsecure')} ${tr('allowInsecureWarning')}',
        defaultValue: false,
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
              )
          < 0) {
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
                  defaultValue: false,
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
            defaultValue: false,
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
        results[e.key] = val;
      }
    }
    return results;
  }

  String? changeLogPageFromStandardUrl(String standardUrl) {
    return null;
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

  void runOnAddAppInputChange(String input) {}
}

abstract class MassAppUrlSource {
  late String name;
  late List<String> requiredArgs;
  Future<Map<String, List<String>>> getUrlsWithDescriptions(List<String> args);
}
