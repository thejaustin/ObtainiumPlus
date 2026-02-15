// Exposes functions used to save/load app settings

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

import 'package:obtainium/models/settings_enums.dart';

String obtainiumTempId = 'thejaustin_obtainiumplus_${GitHub().hosts[0]}';
String obtainiumId = 'app.obtainiumplus';
String obtainiumUrl = 'https://github.com/thejaustin/ObtainiumPlus';
Color obtainiumThemeColor = const Color(0xFF6438B5);

enum ThemeSettings { system, light, dark }

class SettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;
  String? defaultAppDir;
  bool justStarted = true;

  final UpdateSettingsProvider updateSettings = UpdateSettingsProvider();
  final ViewSettingsProvider viewSettings = ViewSettingsProvider();
  final BehaviorSettingsProvider behaviorSettings = BehaviorSettingsProvider();

  String sourceUrl = 'https://github.com/thejaustin/ObtainiumPlus';

  // Not done in constructor as we want to be able to await it
  Future<void> initializeSettings() async {
    prefs = await SharedPreferences.getInstance();
    defaultAppDir = (await AppFileService.getAppStorageDir()).path;
    
    await updateSettings.initializeSettings(prefs!);
    await viewSettings.initializeSettings(prefs!);
    await behaviorSettings.initializeSettings(prefs!);

    notifyListeners();
  }

  bool get useSystemFont {
    return prefs?.getBool('useSystemFont') ?? false;
  }

  set useSystemFont(bool useSystemFont) {
    prefs?.setBool('useSystemFont', useSystemFont);
    notifyListeners();
  }

  AppBarStyle getAppBarStyleForPage(String? pageId) {
    if (pageId != null) {
        int? styleIndex = prefs?.getInt('appBarStyle_$pageId');
        if (styleIndex != null && styleIndex >= 0 && styleIndex < AppBarStyle.values.length) {
            return AppBarStyle.values[styleIndex];
        }
    }
    return AppBarStyle.large;
  }

  ThemeSettings get theme {
    return ThemeSettings.values[prefs?.getInt('theme') ??
        ThemeSettings.system.index];
  }

  set theme(ThemeSettings t) {
    prefs?.setInt('theme', t.index);
    notifyListeners();
  }

  DynamicSchemeVariant get themeVariant {
    return DynamicSchemeVariant.values[prefs?.getInt('themeVariant') ??
        DynamicSchemeVariant.expressive.index];
  }

  set themeVariant(DynamicSchemeVariant t) {
    prefs?.setInt('themeVariant', t.index);
    notifyListeners();
  }

  Color get themeColor {
    int? colorCode = prefs?.getInt('themeColor');
    return (colorCode != null) ? Color(colorCode) : obtainiumThemeColor;
  }

  set themeColor(Color themeColor) {
    prefs?.setInt('themeColor', themeColor.value);
    notifyListeners();
  }

  bool get useMaterialYou {
    return prefs?.getBool('useMaterialYou') ?? false;
  }

  set useMaterialYou(bool useMaterialYou) {
    prefs?.setBool('useMaterialYou', useMaterialYou);
    notifyListeners();
  }

  bool get matchSystemMaterialStyle {
    return prefs?.getBool('matchSystemMaterialStyle') ?? false;
  }

  set matchSystemMaterialStyle(bool matchSystemMaterialStyle) {
    prefs?.setBool('matchSystemMaterialStyle', matchSystemMaterialStyle);
    notifyListeners();
  }

  bool get useBlackTheme {
    return prefs?.getBool('useBlackTheme') ?? false;
  }

  set useBlackTheme(bool useBlackTheme) {
    prefs?.setBool('useBlackTheme', useBlackTheme);
    notifyListeners();
  }

  bool checkAndFlipFirstRun() {
    bool result = prefs?.getBool('firstRun') ?? true;
    if (result) {
      prefs?.setBool('firstRun', false);
    }
    return result;
  }

  bool get welcomeShown {
    return prefs?.getBool('welcomeShown') ?? false;
  }

  set welcomeShown(bool welcomeShown) {
    prefs?.setBool('welcomeShown', welcomeShown);
    notifyListeners();
  }

  bool get googleVerificationWarningShown {
    return prefs?.getBool('googleVerificationWarningShown') ?? false;
  }

  set googleVerificationWarningShown(bool googleVerificationWarningShown) {
    prefs?.setBool(
      'googleVerificationWarningShown',
      googleVerificationWarningShown,
    );
    notifyListeners();
  }

  bool get xiaomiSetupShown {
    return prefs?.getBool('xiaomiSetupShown') ?? false;
  }

  set xiaomiSetupShown(bool value) {
    prefs?.setBool('xiaomiSetupShown', value);
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
    return prefs?.getBool('hideTrackOnlyWarning') ?? false;
  }

  set hideTrackOnlyWarning(bool show) {
    prefs?.setBool('hideTrackOnlyWarning', show);
    notifyListeners();
  }

  bool get hideAPKOriginWarning {
    return prefs?.getBool('hideAPKOriginWarning') ?? false;
  }

  set hideAPKOriginWarning(bool show) {
    prefs?.setBool('hideAPKOriginWarning', show);
    notifyListeners();
  }

  String? getSettingString(String settingId) {
    String? str = prefs?.getString(settingId);
    return str?.isNotEmpty == true ? str : null;
  }

  void setSettingString(String settingId, String value) {
    prefs?.setString(settingId, value);
    notifyListeners();
  }

  bool? getSettingBool(String settingId) {
    return prefs?.getBool(settingId) ?? false;
  }

  void setSettingBool(String settingId, bool value) {
    prefs?.setBool(settingId, value);
    notifyListeners();
  }

  Locale? get forcedLocale {
    var flSegs = prefs?.getString('forcedLocale')?.split('-');
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
    return prefs?.getBool('showDebugOpts') ?? false;
  }

  set showDebugOpts(bool val) {
    prefs?.setBool('showDebugOpts', val);
    notifyListeners();
  }

  bool get highlightTouchTargets {
    return prefs?.getBool('highlightTouchTargets') ?? false;
  }

  set highlightTouchTargets(bool val) {
    prefs?.setBool('highlightTouchTargets', val);
    notifyListeners();
  }

  bool get onlyCheckInstalledOrTrackOnlyApps {
    return prefs?.getBool('onlyCheckInstalledOrTrackOnlyApps') ?? false;
  }

  set onlyCheckInstalledOrTrackOnlyApps(bool val) {
    prefs?.setBool('onlyCheckInstalledOrTrackOnlyApps', val);
    notifyListeners();
  }

  List<String> get searchDeselected {
    return prefs?.getStringList('searchDeselected') ?? [];
  }

  set searchDeselected(List<String> list) {
    prefs?.setStringList('searchDeselected', list);
    notifyListeners();
  }

  // App icon cache expiration setting
  int get appIconCacheDays {
    return prefs?.getInt('appIconCacheDays') ?? 30;
  }

  set appIconCacheDays(int days) {
    prefs?.setInt('appIconCacheDays', days);
    notifyListeners();
  }

  // Number of apps to preload setting
  int get appsToPreload {
    return prefs?.getInt('appsToPreload') ?? 50;
  }

  set appsToPreload(int count) {
    prefs?.setInt('appsToPreload', count);
    notifyListeners();
  }

  // Predictive feature: Track most commonly used sort method
  String get mostUsedSortMethod {
    return prefs?.getString('mostUsedSortMethod') ?? 'default';
  }

  void setMostUsedSortMethod(String method) {
    prefs?.setString('mostUsedSortMethod', method);
  }

  // Predictive feature: Track user's preferred update interval
  int get preferredUpdateInterval {
    return prefs?.getInt('preferredUpdateInterval') ?? 0; // Default to manual
  }

  void setPreferredUpdateInterval(int interval) {
    prefs?.setInt('preferredUpdateInterval', interval);
  }

  // Retry Queue persistence
  Map<String, Map<String, dynamic>> get retryQueue {
    var str = prefs?.getString('retryQueue');
    if (str == null) return {};
    try {
      return Map<String, Map<String, dynamic>>.from(
        jsonDecode(str).map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)))
      );
    } catch (e) {
      return {};
    }
  }

  set retryQueue(Map<String, Map<String, dynamic>> queue) {
    prefs?.setString('retryQueue', jsonEncode(queue));
    notifyListeners();
  }

  // Offline Queue persistence
  List<String> get offlineQueue {
    return prefs?.getStringList('offlineQueue') ?? [];
  }

  set offlineQueue(List<String> queue) {
    prefs?.setStringList('offlineQueue', queue);
    notifyListeners();
  }

  bool get enableDeepLogging {
    return prefs?.getBool('enableDeepLogging') ?? false;
  }

  set enableDeepLogging(bool val) {
    prefs?.setBool('enableDeepLogging', val);
    notifyListeners();
  }

  // Obtainium+ Features
  bool get enableAllPlusFeatures => prefs?.getBool('enableAllPlusFeatures') ?? true;
  set enableAllPlusFeatures(bool val) {
    prefs?.setBool('enableAllPlusFeatures', val);
    notifyListeners();
  }

  bool get plusEnableGridView => prefs?.getBool('plusEnableGridView') ?? true;
  set plusEnableGridView(bool val) {
    prefs?.setBool('plusEnableGridView', val);
    notifyListeners();
  }

  bool get plusEnableQuickFilters => prefs?.getBool('plusEnableQuickFilters') ?? true;
  set plusEnableQuickFilters(bool val) {
    prefs?.setBool('plusEnableQuickFilters', val);
    notifyListeners();
  }

  bool get plusEnableDiscover => prefs?.getBool('plusEnableDiscover') ?? true;
  set plusEnableDiscover(bool val) {
    prefs?.setBool('plusEnableDiscover', val);
    notifyListeners();
  }

  bool get plusEnableIconCaching => prefs?.getBool('plusEnableIconCaching') ?? true;
  set plusEnableIconCaching(bool val) {
    prefs?.setBool('plusEnableIconCaching', val);
    notifyListeners();
  }

  bool get plusEnableAdvancedSorting => prefs?.getBool('plusEnableAdvancedSorting') ?? true;
  set plusEnableAdvancedSorting(bool val) {
    prefs?.setBool('plusEnableAdvancedSorting', val);
    notifyListeners();
  }

  bool get plusEnableSwipeActions => prefs?.getBool('plusEnableSwipeActions') ?? true;
  set plusEnableSwipeActions(bool val) {
    prefs?.setBool('plusEnableSwipeActions', val);
    notifyListeners();
  }

  bool get plusEnableCategoryReorder => prefs?.getBool('plusEnableCategoryReorder') ?? true;
  set plusEnableCategoryReorder(bool val) {
    prefs?.setBool('plusEnableCategoryReorder', val);
    notifyListeners();
  }

  bool get plusEnableUpdateSchedule => prefs?.getBool('plusEnableUpdateSchedule') ?? true;
  set plusEnableUpdateSchedule(bool val) {
    prefs?.setBool('plusEnableUpdateSchedule', val);
    notifyListeners();
  }

  bool get plusEnableEnhancedAnimations => prefs?.getBool('plusEnableEnhancedAnimations') ?? true;
  set plusEnableEnhancedAnimations(bool val) {
    prefs?.setBool('plusEnableEnhancedAnimations', val);
    notifyListeners();
  }

  bool get plusEnableUICustomization => prefs?.getBool('plusEnableUICustomization') ?? true;
  set plusEnableUICustomization(bool val) {
    prefs?.setBool('plusEnableUICustomization', val);
    notifyListeners();
  }

  bool get plusEnableHapticFeedback => prefs?.getBool('plusEnableHapticFeedback') ?? true;
  set plusEnableHapticFeedback(bool val) {
    prefs?.setBool('plusEnableHapticFeedback', val);
    notifyListeners();
  }

  bool get plusEnableModernSettings => prefs?.getBool('plusEnableModernSettings') ?? true;
  set plusEnableModernSettings(bool val) {
    prefs?.setBool('plusEnableModernSettings', val);
    notifyListeners();
  }

  bool get plusEnableModernAppPage => prefs?.getBool('plusEnableModernAppPage') ?? true;
  set plusEnableModernAppPage(bool val) {
    prefs?.setBool('plusEnableModernAppPage', val);
    notifyListeners();
  }

  bool get plusEnableResponsiveAppLayout => prefs?.getBool('plusEnableResponsiveAppLayout') ?? true;
  set plusEnableResponsiveAppLayout(bool val) {
    prefs?.setBool('plusEnableResponsiveAppLayout', val);
    notifyListeners();
  }

  bool get enableContextualTips => prefs?.getBool('enableContextualTips') ?? true;
  set enableContextualTips(bool val) {
    prefs?.setBool('enableContextualTips', val);
    notifyListeners();
  }
}
}
