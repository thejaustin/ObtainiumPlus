// Exposes functions used to save/load app settings

import 'dart:convert';

import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/utils/logger.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

String obtainiumTempId = 'imranr98_obtainium_github.com';
String obtainiumId = 'dev.thejaustin.obtainiumplus';
String obtainiumUrl = 'https://github.com/thejaustin/ObtainiumPlus';
Color obtainiumThemeColor = const Color(0xFF6438B5);

String lowerCaseUnlessLang(String str, String lang) =>
    currentLanguageCode == lang ? str : str.toLowerCase();

// Handles 2 and 3-segment BCP-47 tags (e.g. "zh-Hant-TW"); a naive split
// on '-' with only 2 segments taken would misparse the country code as the
// script subtag and cause forcedLocale to silently fail to match on relaunch.
Locale? tryParseLocale(String? localeString) {
  if (localeString == null) return null;
  final split = localeString.split('-');
  if (split.length == 3) {
    return Locale.fromSubtags(
      languageCode: split[0],
      scriptCode: split[1],
      countryCode: split[2],
    );
  }
  if (split.length == 2) {
    return Locale(split[0], split[1]);
  }
  if (split.isNotEmpty) {
    return Locale(split[0]);
  }
  return null;
}

enum ActionBannerMode { all, updatesOnly, none }

class SettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final Map<String, String> _secureCache = {};
  static const List<String> _secureKeys = ['github-creds', 'gitlab-creds'];

  String? defaultAppDir;
  bool justStarted = true;
  bool isTV = false;

  T? _get<T>(String key) {
    final value = prefs?.get(key);
    if (value is T) return value;
    return null;
  }

  bool? _getBool(String key) => _get<bool>(key);
  int? _getInt(String key) => _get<int>(key);
  double? _getDouble(String key) => _get<double>(key);
  String? _getString(String key) => _get<String>(key);

  final String sourceUrl = obtainiumUrl;

  /// Platform properties that are stable for the process lifetime but expensive
  /// to fetch (platform channel round-trips). Cached across all provider instances.
  static String? _cachedDefaultAppDir;
  static bool? _cachedIsTV;

  Future<void> initializeSettings() async {
    prefs = await SharedPreferences.getInstance();

    // Migrate existing plaintext keys to secure storage and cache them
    try {
      for (final key in _secureKeys) {
        if (prefs!.containsKey(key)) {
          final plaintextVal = prefs!.getString(key);
          if (plaintextVal != null && plaintextVal.isNotEmpty) {
            await secureStorage.write(key: key, value: plaintextVal);
            _secureCache[key] = plaintextVal;
          }
          await prefs!.remove(key); // Clear plaintext
        } else {
          final secureVal = await secureStorage.read(key: key);
          if (secureVal != null) {
            _secureCache[key] = secureVal;
          }
        }
      }
    } catch (e) {
      talker.warning('Could not initialize secure storage: $e');
    }

    // Neither platform lookup is worth failing all of settings init over —
    // both have sane fallbacks (defaultAppDir stays null, isTV stays false)
    try {
      defaultAppDir = (await getAppStorageDir()).path;
    } catch (e) {
      talker.warning('Could not determine app storage dir: $e');
    }
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      isTV =
          info.systemFeatures.contains('android.hardware.type.television') ||
          info.systemFeatures.contains('android.software.leanback');
    } catch (e) {
      isTV = false;
    }
    notifyListeners();
  }

  void notifyPlusSettingsChanged() {
    notifyListeners();
  }

  bool checkAndFlipFirstRun() {
    bool result = prefs?.safeBool('firstRun') ?? true;
    if (result) {
      prefs?.setBool('firstRun', false);
    }
    return result;
  }

  bool get welcomeShown {
    return prefs?.safeBool('welcomeShown') ?? false;
  }

  set welcomeShown(bool welcomeShown) {
    prefs?.setBool('welcomeShown', welcomeShown);
    notifyListeners();
  }

  bool get googleVerificationWarningShown {
    return prefs?.safeBool('googleVerificationWarningShown') ?? false;
  }

  set googleVerificationWarningShown(bool googleVerificationWarningShown) {
    prefs?.setBool(
      'googleVerificationWarningShown',
      googleVerificationWarningShown,
    );
    notifyListeners();
  }

  bool checkJustStarted() {
    if (justStarted) {
      justStarted = false;
      return true;
    }
    return false;
  }

  bool get hideTrackOnlyWarning {
    return prefs?.safeBool('hideTrackOnlyWarning') ?? false;
  }

  set hideTrackOnlyWarning(bool show) {
    prefs?.setBool('hideTrackOnlyWarning', show);
    notifyListeners();
  }

  bool get hideAPKOriginWarning {
    return prefs?.safeBool('hideAPKOriginWarning') ?? false;
  }

  set hideAPKOriginWarning(bool show) {
    prefs?.setBool('hideAPKOriginWarning', show);
    notifyListeners();
  }

  String? getSettingString(String settingId) {
    if (_secureKeys.contains(settingId)) {
      String? str = _secureCache[settingId];
      return str?.isNotEmpty == true ? str : null;
    }
    String? str = prefs?.safeString(settingId);
    return str?.isNotEmpty == true ? str : null;
  }

  void setSettingString(String settingId, String value) {
    if (_secureKeys.contains(settingId)) {
      _secureCache[settingId] = value;
      secureStorage.write(key: settingId, value: value).catchError((e) {
        talker.warning('Could not write secure setting $settingId: $e');
      });
    } else {
      prefs?.setString(settingId, value);
    }
    notifyListeners();
  }

  bool? getSettingBool(String settingId) {
    return prefs?.safeBool(settingId) ?? false;
  }

  void setSettingBool(String settingId, bool value) {
    prefs?.setBool(settingId, value);
    notifyListeners();
  }

  Locale? get forcedLocale {
    final fl = tryParseLocale(_getString('forcedLocale'));
    final set =
        supportedLocales.where((element) => element.key == fl).isNotEmpty
        ? fl
        : null;
    return set;
  }

  set forcedLocale(Locale? fl) {
    if (fl == null) {
      prefs?.remove('forcedLocale');
    } else if (supportedLocales
        .where((element) => element.key == fl)
        .isNotEmpty) {
      prefs?.setString('forcedLocale', fl.toLanguageTag());
    }
    notifyListeners();
  }

  bool setEqual(Set<String> a, Set<String> b) =>
      a.length == b.length && a.union(b).length == a.length;

  void resetLocaleSafe(BuildContext context) {
    if (context.supportedLocales.any(
      (l) => l.languageCode == context.deviceLocale.languageCode,
    )) {
      context.resetLocale();
    } else {
      context.setLocale(context.fallbackLocale!);
      context.deleteSaveLocale();
    }
  }

  bool get showDebugOpts {
    return prefs?.safeBool('showDebugOpts') ?? false;
  }

  set showDebugOpts(bool val) {
    prefs?.setBool('showDebugOpts', val);
    notifyListeners();
  }

  bool get showAppDowngradeError {
    return _getBool('showAppDowngradeError') ?? true;
  }

  set showAppDowngradeError(bool show) {
    prefs?.setBool('showAppDowngradeError', show);
    notifyListeners();
  }

  bool get showBatteryOptimizationPrompt {
    return prefs?.getBool('showBatteryOptimizationPrompt') ?? true;
  }

  set showBatteryOptimizationPrompt(bool show) {
    prefs?.setBool('showBatteryOptimizationPrompt', show);
    notifyListeners();
  }

  bool get includePrereleasesByDefault {
    return _getBool('includePrereleasesByDefault') ?? false;
  }

  set includePrereleasesByDefault(bool val) {
    prefs?.setBool('includePrereleasesByDefault', val);
    notifyListeners();
  }

  List<String> get searchDeselected {
    return prefs?.safeStringList('searchDeselected') ??
        SourceProvider().sources.map((s) => s.name).toList();
  }

  set searchDeselected(List<String> list) {
    prefs?.setStringList('searchDeselected', list);
    notifyListeners();
  }

  ActionBannerMode get actionBannerMode {
    final stored = prefs?.safeString('actionBannerMode');
    if (stored != null &&
        ActionBannerMode.values.any((m) => m.name == stored)) {
      return ActionBannerMode.values.byName(stored);
    }
    final legacyBool = prefs?.safeBool('showActionBannerForUpdateOnly');
    if (legacyBool != null) {
      return legacyBool ? ActionBannerMode.updatesOnly : ActionBannerMode.all;
    }
    return ActionBannerMode.updatesOnly;
  }

  set actionBannerMode(ActionBannerMode mode) {
    prefs?.setString('actionBannerMode', mode.name);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Forwarding getters for settings that moved to dedicated providers.
  // Files still referencing these via SettingsProvider continue to compile.
  // ---------------------------------------------------------------------------

  // --- BehaviorSettingsProvider forwards ---
  @Deprecated('Use BehaviorSettingsProvider.useShizuku')
  bool get useShizuku => prefs?.safeBool('useShizuku') ?? false;
  bool get removeOnExternalUninstall =>
      prefs?.safeBool('removeOnExternalUninstall') ?? false;
  bool get disablePageTransitions =>
      prefs?.safeBool('disablePageTransitions') ?? false;
  bool get reversePageTransitions =>
      prefs?.safeBool('reversePageTransitions') ?? false;
  bool get autoExportOnChanges =>
      prefs?.safeBool('autoExportOnChanges') ?? false;
  set autoExportOnChanges(bool val) {
    prefs?.setBool('autoExportOnChanges', val);
    notifyListeners();
  }

  String get installerMode =>
      prefs?.safeString('installMethod') ??
      (prefs?.safeBool('useShizuku') ?? false
          ? InstallerMode.shizuku.name
          : InstallerMode.system.name);
  String? get externalInstallerPackage {
    final str = prefs?.safeString('externalInstallerPackage');
    return str?.isNotEmpty == true ? str : null;
  }

  String? get externalInstallerComponent {
    final str = prefs?.safeString('externalInstallerComponent');
    return str?.isNotEmpty == true ? str : null;
  }

  // --- ViewSettingsProvider forwards ---
  // Mirrors ViewSettingsProvider.categories against the same prefs key.
  Map<String, int> get categories {
    try {
      return Map<String, int>.from(
        jsonDecode(prefs?.safeString('categories') ?? '{}'),
      );
    } catch (e) {
      return {};
    }
  }

  bool get highlightTouchTargets =>
      prefs?.safeBool('highlightTouchTargets') ?? false;
  set highlightTouchTargets(bool val) {
    prefs?.setBool('highlightTouchTargets', val);
    notifyListeners();
  }

  int get exportSettings => prefs?.safeInt('exportSettings') ?? 1;
  bool get parallelDownloads => prefs?.safeBool('parallelDownloads') ?? true;
  bool get shizukuPretendToBeGooglePlay =>
      prefs?.safeBool('shizukuPretendToBeGooglePlay') ?? false;
  double get animationSpeedMultiplier =>
      prefs?.safeDouble('animationSpeedMultiplier') ?? 1.0;
  bool get enableContextualTips =>
      prefs?.safeBool('enableContextualTips') ?? true;
  set enableContextualTips(bool val) {
    prefs?.setBool('enableContextualTips', val);
    notifyListeners();
  }

  bool get enableDeepLogging => prefs?.safeBool('enableDeepLogging') ?? false;
  set enableDeepLogging(bool val) {
    prefs?.setBool('enableDeepLogging', val);
    notifyListeners();
  }

  // preferredUpdateSource is in BehaviorSettingsProvider
  String get preferredUpdateSource {
    final val = prefs?.safeString('preferredUpdateSource') ?? 'direct';
    if (val == 'github' || val == 'apkpure') return 'direct';
    return val;
  }

  set preferredUpdateSource(String val) {
    prefs?.setString('preferredUpdateSource', val);
    notifyListeners();
  }

  // updateSettings shortcut (not a provider, just a string)
  String get updateSettings => prefs?.safeString('updateSettings') ?? '';

  // --- UpdateSettingsProvider forwards ---
  @Deprecated('Use UpdateSettingsProvider.onlyCheckInstalledOrTrackOnlyApps')
  bool get onlyCheckInstalledOrTrackOnlyApps =>
      prefs?.safeBool('onlyCheckInstalledOrTrackOnlyApps') ?? false;
  String get obtainiumReleaseChannel =>
      prefs?.safeString('obtainiumReleaseChannel') ?? 'stable';
  String get autoUpdateRules => prefs?.safeString('autoUpdateRules') ?? '';

  // --- PlusSettingsProvider forwards ---
  @Deprecated('Use PlusSettingsProvider.plusEnableGlassmorphism')
  bool get plusEnableGlassmorphism =>
      prefs?.safeBool('plusEnableGlassmorphism') ?? true;
  bool get plusEnablePopupSlider =>
      prefs?.safeBool('plusEnablePopupSlider') ?? true;
  bool get plusEnableExpressiveProgress =>
      prefs?.safeBool('plusEnableExpressiveProgress') ?? true;
  bool get plusEnableSmartRetries =>
      prefs?.safeBool('plusEnableSmartRetries') ?? true;
  bool get plusEnableAdvancedSorting =>
      prefs?.safeBool('plusEnableAdvancedSorting') ?? true;
  bool get plusEnableUserPreapproval =>
      prefs?.safeBool('plusEnableUserPreapproval') ?? true;
  bool get plusDeveloperMode => prefs?.safeBool('plusDeveloperMode') ?? false;
  bool get plusEnableSystemUpdateScanner =>
      prefs?.safeBool('plusEnableSystemUpdateScanner') ?? false;
  bool get plusTopUILayout => prefs?.safeBool('plusTopUILayout') ?? false;
  bool get plusShowDashboardSearch =>
      prefs?.safeBool('plusShowDashboardSearch') ?? true;
  bool get plusShowFloatingSearch =>
      prefs?.safeBool('plusShowFloatingSearch') ?? true;
  bool get plusFabShowSearch => prefs?.safeBool('plusFabShowSearch') ?? true;
  bool get plusFabShowAddByUrl =>
      prefs?.safeBool('plusFabShowAddByUrl') ?? true;
  bool get plusFabShowGithubStarred =>
      prefs?.safeBool('plusFabShowGithubStarred') ?? true;
  bool get plusFabShowGithubPersonalRepos =>
      prefs?.safeBool('plusFabShowGithubPersonalRepos') ?? true;
  bool get plusFabShowImportInstalled =>
      prefs?.safeBool('plusFabShowImportInstalled') ?? true;
  double get plusGlobalCornerRadius =>
      (prefs?.safeDouble('plusGlobalCornerRadius') ?? 20.0).clamp(0.0, 40.0);
  double get plusHomeCornerRadius =>
      (prefs?.safeDouble('plusHomeCornerRadius') ?? 20.0).clamp(0.0, 40.0);
  double get plusSettingsCornerRadius =>
      (prefs?.safeDouble('plusSettingsCornerRadius') ?? 16.0).clamp(0.0, 40.0);
  bool get plusOverrideIndividualCornerRadius =>
      prefs?.safeBool('plusOverrideIndividualCornerRadius') ?? false;
  bool get plusEnableNotificationDigest =>
      prefs?.safeBool('plusEnableNotificationDigest') ?? false;
  // plusSettings is accessed as a provider — return a reference to self
  // so code like `settings.plusSettings.someField` doesn't blow up at runtime.
  // For compile-time, the property just needs to exist with a valid type.
  SettingsProvider get plusSettings => this;

  // Forwarding methods for callers that still reference SettingsProvider
  // for things that moved to BehaviorSettingsProvider. Mirrors
  // BehaviorSettingsProvider's implementation against the same prefs keys.
  Future<Uri?> getExportDir() async {
    final uriString = prefs?.safeString('exportDir');
    if (uriString == null) return null;
    Uri? uri = Uri.parse(uriString);
    if (!(await saf.canRead(uri) ?? false) ||
        !(await saf.canWrite(uri) ?? false)) {
      uri = null;
      await prefs?.remove('exportDir');
      notifyListeners();
    }
    return uri;
  }

  // Stub for app bar style — returns AppBarStyle.
  AppBarStyle getAppBarStyleForPage(String page) {
    final index = prefs?.safeInt('appBarStyle_$page') ?? 0;
    // Stored index can be stale after enum changes (#217 corruption class)
    if (index < 0 || index >= AppBarStyle.values.length) {
      return AppBarStyle.values[0];
    }
    return AppBarStyle.values[index];
  }

  void setAppBarStyleForPage(String page, AppBarStyle style) {
    prefs?.setInt('appBarStyle_$page', style.index);
    notifyListeners();
  }

  // Stub for install permission (moved to BehaviorSettingsProvider).
  Future<bool> getInstallPermission({bool enforce = false}) async => true;

  Future<void> pickExportDir({bool remove = false}) async {
    final existingSAFPerms = (await saf.persistedUriPermissions()) ?? [];
    final currentOneWayDataSyncDir = await getExportDir();
    Uri? newOneWayDataSyncDir;
    if (!remove) {
      try {
        newOneWayDataSyncDir = (await saf.openDocumentTree());
      } catch (_) {
        throw ObtainiumError(tr('noFilePickerAvailable'));
      }
    }
    if (currentOneWayDataSyncDir?.path != newOneWayDataSyncDir?.path) {
      if (newOneWayDataSyncDir == null) {
        await prefs?.remove('exportDir');
      } else {
        await prefs?.setString('exportDir', newOneWayDataSyncDir.toString());
      }
      notifyListeners();
    }
    for (var e in existingSAFPerms) {
      await saf.releasePersistableUriPermission(e.uri);
    }
  }

  bool get enableBackgroundUpdates =>
      prefs?.safeBool('enableBackgroundUpdates') ?? true;

  int get updateCheckConcurrencyLimit =>
      prefs?.safeInt('updateCheckConcurrencyLimit') ?? 3;
  set updateCheckConcurrencyLimit(int val) {
    prefs?.setInt('updateCheckConcurrencyLimit', val);
    notifyListeners();
  }

  int get updateDownloadConcurrencyLimit =>
      prefs?.safeInt('updateDownloadConcurrencyLimit') ?? 2;
  set updateDownloadConcurrencyLimit(int val) {
    prefs?.setInt('updateDownloadConcurrencyLimit', val);
    notifyListeners();
  }
}
