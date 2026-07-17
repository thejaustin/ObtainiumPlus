// Exposes functions used to save/load app settings

import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/utils/logger.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/settings_enums.dart';

String obtainiumTempId = 'imranr98_obtainium_${GitHub().hosts[0]}';
String obtainiumId = 'dev.thejaustin.obtainiumplus';
String obtainiumUrl = 'https://github.com/thejaustin/ObtainiumPlus';
Color obtainiumThemeColor = const Color(0xFF6438B5);

class SettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;
  String? defaultAppDir;
  bool justStarted = true;
  bool isTV = false;

  String sourceUrl = 'https://github.com/ImranR98/Obtainium';

  // Not done in constructor as we want to be able to await it
  Future<void> initializeSettings() async {
    prefs = await SharedPreferences.getInstance();
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
    String? str = prefs?.safeString(settingId);
    return str?.isNotEmpty == true ? str : null;
  }

  void setSettingString(String settingId, String value) {
    prefs?.setString(settingId, value);
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
    var flSegs = prefs?.safeString('forcedLocale')?.split('-');
    var fl = flSegs != null && flSegs.isNotEmpty
        ? Locale(flSegs[0], flSegs.length > 1 ? flSegs[1] : null)
        : null;
    var set = supportedLocales.where((element) => element.key == fl).isNotEmpty
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
    if (context.supportedLocales.contains(context.deviceLocale)) {
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

  List<String> get searchDeselected {
    return prefs?.safeStringList('searchDeselected') ??
        SourceProvider().sources.map((s) => s.name).toList();
  }

  set searchDeselected(List<String> list) {
    prefs?.setStringList('searchDeselected', list);
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

  // Forwarding method stubs for callers that still reference SettingsProvider
  // for things that moved to BehaviorSettingsProvider.
  Future<Uri?> getExportDir() async => null;

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

  // Stub for export dir picker (moved to BehaviorSettingsProvider).
  Future<void> pickExportDir({bool remove = false}) async {}

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
