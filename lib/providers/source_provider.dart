// Provides functions used to interact with App sources
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/app_sources/apkmirror.dart';
import 'package:obtainium/app_sources/apkpure.dart';
import 'package:obtainium/app_sources/aptoide.dart';
import 'package:obtainium/app_sources/codeberg.dart';
import 'package:obtainium/app_sources/coolapk.dart';
import 'package:obtainium/app_sources/directAPKLink.dart';
import 'package:obtainium/app_sources/farsroid.dart';
import 'package:obtainium/app_sources/fdroid.dart';
import 'package:obtainium/app_sources/fdroidrepo.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/app_sources/gitlab.dart';
import 'package:obtainium/app_sources/googleplay.dart';
import 'package:obtainium/app_sources/huaweiappgallery.dart';
import 'package:obtainium/app_sources/izzyondroid.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/app_sources/jenkins.dart';
import 'package:obtainium/app_sources/liteapks.dart';
import 'package:obtainium/app_sources/moddroid.dart';
import 'package:obtainium/app_sources/neutroncode.dart';
import 'package:obtainium/app_sources/rustore.dart';
import 'package:obtainium/app_sources/sourceforge.dart';
import 'package:obtainium/app_sources/sourcehut.dart';
import 'package:obtainium/app_sources/telegramapp.dart';
import 'package:obtainium/app_sources/tencent.dart';
import 'package:obtainium/app_sources/uptodown.dart';
import 'package:obtainium/app_sources/vivoappstore.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/mass_app_sources/githubstars.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:obtainium/utils/source_utils.dart';

export 'package:obtainium/models/app.dart';

// App JSON schema has changed multiple times over the many versions of Obtainium
Map<String, dynamic> appJSONCompatibilityModifiers(Map<String, dynamic> json) {
  var source = SourceProvider().getSource(
    json['url'],
    overrideSource: json['overrideSource'],
  );
  var formItems = source.combinedAppSpecificSettingFormItems.reduce(
    (value, element) => [...value, ...element],
  );
  Map<String, dynamic> additionalSettings = getDefaultValuesFromFormItems([
    formItems,
  ]);
  Map<String, dynamic> originalAdditionalSettings = {};
  if (json['additionalSettings'] != null) {
    var decoded = safeJsonDecode(json['additionalSettings'], <String, dynamic>{});
    if (decoded is Map) {
      originalAdditionalSettings = Map<String, dynamic>.from(decoded);
      additionalSettings.addEntries(originalAdditionalSettings.entries);
    }
  }

  _migrateV1Settings(json, additionalSettings, formItems);
  _migrateVersionDetection(additionalSettings);
  _migratePseudoVersioning(originalAdditionalSettings, additionalSettings);

  // Ensure additionalSettings are correctly typed
  for (var item in formItems) {
    if (additionalSettings[item.key] != null) {
      additionalSettings[item.key] = item.ensureType(
        additionalSettings[item.key],
      );
    }
  }

  json['preferredApkIndex'] = _getValidPreferredApkIndex(json);
  json['apkUrls'] = _getStandardizedApkUrls(json);

  if (additionalSettings['autoApkFilterByArch'] == null) {
    additionalSettings['autoApkFilterByArch'] = false;
  }
  if (additionalSettings['dontSortReleasesList'] == true) {
    additionalSettings['sortMethodChoice'] = 'none';
  }

  if (source.runtimeType == HTML().runtimeType) {
    _migrateHtmlSourceSettings(additionalSettings, originalAdditionalSettings, json);
  }

  json['additionalSettings'] = jsonEncode(additionalSettings);

  _migrateFDroidSource(json);

  return json;
}

void _migrateV1Settings(Map<String, dynamic> json, Map<String, dynamic> additionalSettings, List<GeneratedFormItem> formItems) {
  if (json['additionalData'] != null) {
    var decoded = safeJsonDecode(json['additionalData'], <dynamic>[]);
    if (decoded is! List) return;
    List<String> temp = List<String>.from(decoded);
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
        json['noVersionDetection'] == 'true' || json['trackOnly'] == true;
  }
}

void _migrateVersionDetection(Map<String, dynamic> additionalSettings) {
  if (additionalSettings['noVersionDetection'] == true) {
    additionalSettings['versionDetection'] = 'noVersionDetection';
    if (additionalSettings['releaseDateAsVersion'] == true) {
      additionalSettings['versionDetection'] = 'releaseDateAsVersion';
      additionalSettings.remove('releaseDateAsVersion');
    }
    if (additionalSettings['noVersionDetection'] != null) {
      additionalSettings.remove('noVersionDetection');
    }
    if (additionalSettings['releaseDateAsVersion'] != null) {
      additionalSettings.remove('releaseDateAsVersion');
    }
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

void _migratePseudoVersioning(Map<String, dynamic> originalSettings, Map<String, dynamic> additionalSettings) {
  if (originalSettings['supportFixedAPKURL'] == true) {
    additionalSettings['defaultPseudoVersioningMethod'] = 'partialAPKHash';
  } else if (originalSettings['supportFixedAPKURL'] == false) {
    additionalSettings['defaultPseudoVersioningMethod'] = 'APKLinkHash';
  }
}

int _getValidPreferredApkIndex(Map<String, dynamic> json) {
  int preferredApkIndex = json['preferredApkIndex'] == null
      ? 0
      : json['preferredApkIndex'] as int;
  return preferredApkIndex < 0 ? 0 : preferredApkIndex;
}

String _getStandardizedApkUrls(Map<String, dynamic> json) {
  List<MapEntry<String, String>> apkUrls = [];
  if (json['apkUrls'] != null) {
    var apkUrlJson = safeJsonDecode(json['apkUrls'], <dynamic>[]);
    if (apkUrlJson is! List) return '[]';
    try {
      apkUrls = getApkUrlsFromUrls(List<String>.from(apkUrlJson));
    } catch (e) {
      apkUrls = assumed2DlistToStringMapList(List<dynamic>.from(apkUrlJson));
    }
    return jsonEncode(stringMapListTo2DList(apkUrls));
  }
  return '[]';
}

void _migrateHtmlSourceSettings(Map<String, dynamic> additionalSettings, Map<String, dynamic> originalAdditionalSettings, Map<String, dynamic> json) {
  if (originalAdditionalSettings['sortByFileNamesNotLinks'] != null) {
    additionalSettings['sortByLastLinkSegment'] = originalAdditionalSettings['sortByFileNamesNotLinks'];
  }
  if (originalAdditionalSettings['intermediateLinkRegex'] != null && additionalSettings['intermediateLinkRegex']?.isNotEmpty != true) {
    additionalSettings['intermediateLink'] = [
      {
        'customLinkFilterRegex': originalAdditionalSettings['intermediateLinkRegex'],
        'filterByLinkText': originalAdditionalSettings['intermediateLinkByText'],
      },
    ];
  }
  if ((additionalSettings['intermediateLink']?.length ?? 0) > 0) {
    additionalSettings['intermediateLink'] =
        additionalSettings['intermediateLink'].where((e) {
          return e['customLinkFilterRegex']?.isNotEmpty == true;
        }).toList();
  }

  _migrateLegacyHtmlApps(additionalSettings, json);
}

void _migrateLegacyHtmlApps(Map<String, dynamic> additionalSettings, Map<String, dynamic> json) {
  var legacySteamSourceApps = ['steam', 'steam-chat-app'];
  if (legacySteamSourceApps.contains(additionalSettings['app'] ?? '')) {
    json['url'] = '${json['url']}/mobile';
    var replacementAdditionalSettings = getDefaultValuesFromFormItems(HTML().combinedAppSpecificSettingFormItems);
    for (var s in replacementAdditionalSettings.keys) {
      if (additionalSettings.containsKey(s)) {
        replacementAdditionalSettings[s] = additionalSettings[s];
      }
    }
    replacementAdditionalSettings['customLinkFilterRegex'] = '/${additionalSettings['app']}-(([0-9]+\.?){1,})\.apk';
    replacementAdditionalSettings['versionExtractionRegEx'] = replacementAdditionalSettings['customLinkFilterRegex'];
    replacementAdditionalSettings['matchGroupToUse'] = '\$1';
    additionalSettings.clear();
    additionalSettings.addAll(replacementAdditionalSettings);
  }
  // Signal, WhatsApp, VLC migrations
  const legacyApps = {
    'org.thoughtcrime.securesms': {
      'url': 'https://updates.signal.org/android/latest.json',
      'settings': {'versionExtractionRegEx': '\\d+.\\d+.\\d+'}
    },
    'com.whatsapp': {
      'url': 'https://whatsapp.com/android',
      'settings': {'refreshBeforeDownload': true}
    },
    'org.videolan.vlc': {
      'url': 'https://www.videolan.org/vlc/download-android.html',
      'settings': {
        'refreshBeforeDownload': true,
        'intermediateLink': [
          {'customLinkFilterRegex': 'APK', 'filterByLinkText': true, 'skipSort': false, 'reverseSort': false, 'sortByLastLinkSegment': false},
          {'customLinkFilterRegex': 'arm64-v8a\\.apk\$', 'filterByLinkText': false, 'skipSort': false, 'reverseSort': false, 'sortByLastLinkSegment': false},
        ],
        'versionExtractionRegEx': '/vlc-android/([^/]+)/',
        'matchGroupToUse': "1"
      }
    }
  };

  if (legacyApps.containsKey(json['id']) && json['overrideSource'] == null && (json['lastUpdateCheck'] != null)) {
    var appConfig = legacyApps[json['id']]!;
    json['url'] = appConfig['url'];
    var replacementAdditionalSettings = getDefaultValuesFromFormItems(HTML().combinedAppSpecificSettingFormItems);
    replacementAdditionalSettings.addAll(appConfig['settings'] as Map<String, dynamic>);
    additionalSettings.clear();
    additionalSettings.addAll(replacementAdditionalSettings);
  }
}

void _migrateFDroidSource(Map<String, dynamic> json) {
  var overrideSourceWasUndefined = !json.keys.contains('overrideSource');
  if ((json['url'] as String).startsWith('https://cloudflare.f-droid.org')) {
    json['overrideSource'] = FDroid().runtimeType.toString();
  } else if (overrideSourceWasUndefined) {
    RegExpMatch? match = RegExp(r'^https?://.+/fdroid/([^/]+(/|\?)|[^/]+)').firstMatch(json['url'] as String);
    if (match != null) {
      json['overrideSource'] = FDroidRepo().runtimeType.toString();
    }
  }
}

class SourceProvider {
  // PERFORMANCE: Cache sources to avoid re-instantiating ~24 classes on every access
  static final List<AppSource> _cachedSources = [
    GitHub(),
    GitLab(),
    Codeberg(),
    FDroid(),
    FDroidRepo(),
    IzzyOnDroid(),
    SourceHut(),
    APKPure(),
    GooglePlay(),
    Aptoide(),
    Uptodown(),
    HuaweiAppGallery(),
    Tencent(),
    CoolApk(),
    LiteAPKs(),
    Moddroid(),
    VivoAppStore(),
    Jenkins(),
    APKMirror(),
    RuStore(),
    Farsroid(),
    TelegramApp(),
    NeutronCode(),
    DirectAPKLink(),
    HTML(), // This should ALWAYS be the last option as they are tried in order
  ];

  List<AppSource> get sources => _cachedSources;

  // Add more mass url source classes here so they are available via the service
  List<MassAppUrlSource> massUrlSources = [GitHubStars()];

  AppSource getSource(String url, {String? overrideSource}) {
    url = GitHub().preStandardizeUrl(url); // Any AppSource can provide this
    if (overrideSource != null) {
      var srcs = sources.where(
        (e) => e.runtimeType.toString() == overrideSource,
      );
      if (srcs.isEmpty) {
        throw UnsupportedURLError();
      }
      var res = srcs.first;
      var originalHosts = res.hosts;
      var newHost = Uri.parse(url).host;
      res.hosts = [newHost];
      res.hostChanged = true;
      if (originalHosts.contains(newHost)) {
        res.hostIdenticalDespiteAnyChange = true;
      }
      return res;
    }
    AppSource? source;
    for (var s in sources.where((element) => element.hosts.isNotEmpty)) {
      try {
        if (RegExp(
          '^${s.allowSubDomains ? r'([^\.]+\.)*' : r'(www\.)?'}(${getSourceRegex(s.hosts)})'
        ).hasMatch(Uri.parse(url).host)) {
          source = s;
          break;
        }
      } catch (e) {
        // Ignore
      }
    }
    if (source == null) {
      for (var s in sources.where(
        (element) => element.hosts.isEmpty && !element.neverAutoSelect,
      )) {
        try {
          s.sourceSpecificStandardizeURL(url, forSelection: true);
          source = s;
          break;
        } catch (e) {
          //
        }
      }
    }
    if (source == null) {
      // Log failed URL for debugging and potential new source requests
      CrashAnalytics.recordCrash(
        errorType: 'UnsupportedURLError',
        errorMessage: 'Unsupported URL: $url',
      );
      
      // Get list of supported sources for suggestions
      final supportedSources = sources
          .where((s) => s.hosts.isNotEmpty)
          .map((s) => s.name)
          .toList();
      
      throw UnsupportedURLError(
        suggestedSources: supportedSources.take(8).toList(),
        failedUrl: url,
      );
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
  ) => (standardUrl + additionalSettings.toString()).hashCode.toString();

  Future<AppSource?> findSourceForPackage(String appId) async {
    // 1. Try Google Play (via mirror) as it's the most common
    // We check if it exists on the mirror first
    try {
      final GooglePlay gp = GooglePlay();
      final url = gp.standardizeUrl('https://play.google.com/store/apps/details?id=$appId');
      // Verify it exists by trying to get details
      await gp.getLatestAPKDetails(url, {'autoApkFilterByArch': true});
      return gp;
    } catch (e) {
      // Not on Play Store or mirror failed
    }

    // 2. Try F-Droid (Common for FOSS)
    try {
      final FDroid fd = FDroid();
      // F-Droid usually has a predictable API for package names
      await fd.getLatestAPKDetails('https://f-droid.org/en/packages/$appId', {});
      return fd;
    } catch (e) {
      // Not on F-Droid
    }

    return null;
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
    if (trackOnlyOverride || source.enforceTrackOnly) {
      additionalSettings['trackOnly'] = true;
    }
    var trackOnly = additionalSettings['trackOnly'] == true;
    String standardUrl = source.standardizeUrl(url);
    APKDetails apk = await source.getLatestAPKDetails(
      standardUrl,
      additionalSettings,
    );

    if (source.runtimeType !=
            HTML().runtimeType && // Some sources do it separately
        source.runtimeType != SourceForge().runtimeType) {
      String? extractedVersion = SourceUtils.extractVersion(
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
    apk.apkUrls = SourceUtils.filterApks(
      apk.apkUrls,
      additionalSettings['apkFilterRegEx'],
      additionalSettings['invertAPKFilter'],
    );
    if (apk.apkUrls.isEmpty && !trackOnly) {
      throw NoAPKError();
    }
    if (additionalSettings['autoApkFilterByArch'] == true) {
      apk.apkUrls = await filterApksByArch(apk.apkUrls);
    }
    var name = currentApp != null ? currentApp.name.trim() : '';
    name = name.isNotEmpty ? name : apk.names.name;
    App finalApp = App(
      currentApp?.id ??
          ((additionalSettings['appId'] != null)
              ? additionalSettings['appId']
              : null) ??
          (!trackOnly &&
                  (!source.appIdInferIsOptional ||
                      (source.appIdInferIsOptional && inferAppIdIfOptional))
              ? await source.tryInferringAppId(
                  standardUrl,
                  additionalSettings: additionalSettings,
                )
              : null) ??
          generateTempID(standardUrl, additionalSettings),
      standardUrl,
      apk.names.author,
      name,
      currentApp?.installedVersion,
      apk.version,
      apk.apkUrls,
      apk.apkUrls.length - 1 >= 0 ? apk.apkUrls.length - 1 : 0,
      additionalSettings,
      DateTime.now(),
      currentApp?.pinned ?? false,
      categories: currentApp?.categories ?? const [],
      releaseDate: apk.releaseDate,
      changeLog: apk.changeLog,
      overrideSource: sourceIsOverriden
          ? source.runtimeType.toString()
          : currentApp?.overrideSource,
      allowIdChange:
          currentApp?.allowIdChange ??
          trackOnly ||
              (source.appIdInferIsOptional &&
                  inferAppIdIfOptional), // Optional ID inferring may be incorrect - allow correction on first install
      otherAssetUrls: apk.allAssetUrls
          .where((a) => apk.apkUrls.indexWhere((p) => a.key == p.key) < 0)
          .toList(),
    );
    return source.endOfGetAppChanges(finalApp);
  }

  // Returns errors in [results, errors] instead of throwing them
  Future<List<dynamic>> getAppsByURLNaive(
    List<String> urls, {
    List<String> alreadyAddedUrls = const [],
    AppSource? sourceOverride,
  }) async {
    List<App> apps = [];
    Map<String, dynamic> errors = {};
    for (var url in urls) {
      try {
        if (alreadyAddedUrls.contains(url)) {
          throw ObtainiumError(tr('appAlreadyAdded'));
        }
        var source = sourceOverride ?? getSource(url);
        apps.add(
          await getApp(
            source,
            url,
            sourceIsOverriden: sourceOverride != null,
            getDefaultValuesFromFormItems(
              source.combinedAppSpecificSettingFormItems,
            ),
          ),
        );
      } catch (e) {
        errors.addAll(<String, dynamic>{url: e});
      }
    }
    return [apps, errors];
  }
}
