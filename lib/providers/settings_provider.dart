// Exposes functions used to save/load app settings

import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/utils/locale_constants.dart' show supportedLocales;
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_config_provider.dart';
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
  final PlusSettingsProvider plusSettings = PlusSettingsProvider();
  final SourceConfigProvider sourceConfig = SourceConfigProvider();

  String sourceUrl = 'https://github.com/thejaustin/ObtainiumPlus';

  Completer<void>? _initCompleter;

  // Not done in constructor as we want to be able to await it
  Future<void> initializeSettings() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();

    prefs = await SharedPreferences.getInstance();
    defaultAppDir = (await AppFileService.getAppStorageDir()).path;

    await updateSettings.initializeSettings(prefs!);
    await viewSettings.initializeSettings(prefs!);
    await behaviorSettings.initializeSettings(prefs!);
    await plusSettings.initializeSettings(prefs!);
    await sourceConfig.initializeSettings(prefs!);

    notifyListeners();
    _initCompleter!.complete();
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

  String? getSettingString(String settingId) => sourceConfig.getSettingString(settingId);

  void setSettingString(String settingId, String value) {
    sourceConfig.setSettingString(settingId, value);
    notifyListeners();
  }

  bool getSettingBool(String settingId) => sourceConfig.getSettingBool(settingId);

  void setSettingBool(String settingId, bool value) {
    sourceConfig.setSettingBool(settingId, value);
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

  // Obtainium+ Features (Delegated to PlusSettingsProvider)
  bool get enableAllPlusFeatures => plusSettings.enableAllPlusFeatures;
  set enableAllPlusFeatures(bool val) {
    plusSettings.enableAllPlusFeatures = val;
    notifyListeners();
  }

  bool get plusEnableGridView => plusSettings.plusEnableGridView;
  set plusEnableGridView(bool val) {
    plusSettings.plusEnableGridView = val;
    notifyListeners();
  }

  bool get plusEnableQuickFilters => plusSettings.plusEnableQuickFilters;
  set plusEnableQuickFilters(bool val) {
    plusSettings.plusEnableQuickFilters = val;
    notifyListeners();
  }

  bool get plusEnableDiscover => plusSettings.plusEnableDiscover;
  set plusEnableDiscover(bool val) {
    plusSettings.plusEnableDiscover = val;
    notifyListeners();
  }

  bool get plusEnableIconCaching => plusSettings.plusEnableIconCaching;
  set plusEnableIconCaching(bool val) {
    plusSettings.plusEnableIconCaching = val;
    notifyListeners();
  }

  bool get plusEnableAdvancedSorting => plusSettings.plusEnableAdvancedSorting;
  set plusEnableAdvancedSorting(bool val) {
    plusSettings.plusEnableAdvancedSorting = val;
    notifyListeners();
  }

  bool get plusEnableSwipeActions => plusSettings.plusEnableSwipeActions;
  set plusEnableSwipeActions(bool val) {
    plusSettings.plusEnableSwipeActions = val;
    notifyListeners();
  }

  bool get plusEnableCategoryReorder => plusSettings.plusEnableCategoryReorder;
  set plusEnableCategoryReorder(bool val) {
    plusSettings.plusEnableCategoryReorder = val;
    notifyListeners();
  }

  bool get plusEnableUpdateSchedule => plusSettings.plusEnableUpdateSchedule;
  set plusEnableUpdateSchedule(bool val) {
    plusSettings.plusEnableUpdateSchedule = val;
    notifyListeners();
  }

  bool get plusEnableEnhancedAnimations => plusSettings.plusEnableEnhancedAnimations;
  set plusEnableEnhancedAnimations(bool val) {
    plusSettings.plusEnableEnhancedAnimations = val;
    notifyListeners();
  }

  bool get plusEnableMaterialExpressive => plusSettings.plusEnableMaterialExpressive;
  set plusEnableMaterialExpressive(bool val) {
    plusSettings.plusEnableMaterialExpressive = val;
    notifyListeners();
  }

  bool get plusEnableUICustomization => plusSettings.plusEnableUICustomization;
  set plusEnableUICustomization(bool val) {
    plusSettings.plusEnableUICustomization = val;
    notifyListeners();
  }

  bool get plusEnableExperimentalCustomization => plusSettings.plusEnableExperimentalCustomization;
  set plusEnableExperimentalCustomization(bool val) {
    plusSettings.plusEnableExperimentalCustomization = val;
    notifyListeners();
  }

  bool get plusEnableHapticFeedback => plusSettings.plusEnableHapticFeedback;
  set plusEnableHapticFeedback(bool val) {
    plusSettings.plusEnableHapticFeedback = val;
    notifyListeners();
  }

  bool get plusEnableGlassmorphism => plusSettings.plusEnableGlassmorphism;
  set plusEnableGlassmorphism(bool val) {
    plusSettings.plusEnableGlassmorphism = val;
    notifyListeners();
  }

  bool get plusEnablePopupSlider => plusSettings.plusEnablePopupSlider;
  set plusEnablePopupSlider(bool val) {
    plusSettings.plusEnablePopupSlider = val;
    notifyListeners();
  }

  bool get plusEnableModernSettings => plusSettings.plusEnableModernSettings;
  set plusEnableModernSettings(bool val) {
    plusSettings.plusEnableModernSettings = val;
    notifyListeners();
  }

  bool get plusEnableModernAppPage => plusSettings.plusEnableModernAppPage;
  set plusEnableModernAppPage(bool val) {
    plusSettings.plusEnableModernAppPage = val;
    notifyListeners();
  }

  bool get plusEnableModernAddAppPage => plusSettings.plusEnableModernAddAppPage;
  set plusEnableModernAddAppPage(bool val) {
    plusSettings.plusEnableModernAddAppPage = val;
    notifyListeners();
  }

  bool get plusEnableModernAppListTile => plusSettings.plusEnableModernAppListTile;
  set plusEnableModernAppListTile(bool val) {
    plusSettings.plusEnableModernAppListTile = val;
    notifyListeners();
  }

  bool get plusEnableResponsiveAppLayout => plusSettings.plusEnableResponsiveAppLayout;
  set plusEnableResponsiveAppLayout(bool val) {
    plusSettings.plusEnableResponsiveAppLayout = val;
    notifyListeners();
  }

  bool get plusEnableSystemUpdateScanner => plusSettings.plusEnableSystemUpdateScanner;
  set plusEnableSystemUpdateScanner(bool val) {
    plusSettings.plusEnableSystemUpdateScanner = val;
    notifyListeners();
  }

  bool get plusDeveloperMode => plusSettings.plusDeveloperMode;
  set plusDeveloperMode(bool val) {
    plusSettings.plusDeveloperMode = val;
    notifyListeners();
  }

  bool get plusShowLegacyUIComparison => plusSettings.plusShowLegacyUIComparison;
  set plusShowLegacyUIComparison(bool val) {
    plusSettings.plusShowLegacyUIComparison = val;
    notifyListeners();
  }

  bool get enableContextualTips => prefs?.getBool('enableContextualTips') ?? true;
  set enableContextualTips(bool val) {
    prefs?.setBool('enableContextualTips', val);
    notifyListeners();
  }

  // ======================================================================
  // Forwarding getters/setters to sub-providers
  // These allow consumers to keep using settingsProvider.X syntax
  // ======================================================================

  // --- UpdateSettingsProvider ---
  int get updateInterval => updateSettings.updateInterval;
  set updateInterval(int val) {
    updateSettings.updateInterval = val;
    notifyListeners();
  }

  double get updateIntervalSliderVal => updateSettings.updateIntervalSliderVal;
  set updateIntervalSliderVal(double val) {
    updateSettings.updateIntervalSliderVal = val;
    notifyListeners();
  }

  String get updateIntervalLabel => updateSettings.updateIntervalLabel;
  List<int> get updateIntervalNodes => updateSettings.updateIntervalNodes;

  bool get checkOnStart => updateSettings.checkOnStart;
  set checkOnStart(bool val) {
    updateSettings.checkOnStart = val;
    notifyListeners();
  }

  bool get checkUpdateOnDetailPage => updateSettings.checkUpdateOnDetailPage;
  set checkUpdateOnDetailPage(bool val) {
    updateSettings.checkUpdateOnDetailPage = val;
    notifyListeners();
  }

  bool get enableBackgroundUpdates => updateSettings.enableBackgroundUpdates;
  set enableBackgroundUpdates(bool val) {
    updateSettings.enableBackgroundUpdates = val;
    notifyListeners();
  }

  bool get bgUpdatesOnWiFiOnly => updateSettings.bgUpdatesOnWiFiOnly;
  set bgUpdatesOnWiFiOnly(bool val) {
    updateSettings.bgUpdatesOnWiFiOnly = val;
    notifyListeners();
  }

  bool get bgUpdatesWhileChargingOnly => updateSettings.bgUpdatesWhileChargingOnly;
  set bgUpdatesWhileChargingOnly(bool val) {
    updateSettings.bgUpdatesWhileChargingOnly = val;
    notifyListeners();
  }

  bool get useUpdateSchedule => updateSettings.useUpdateSchedule;
  set useUpdateSchedule(bool val) {
    updateSettings.useUpdateSchedule = val;
    notifyListeners();
  }

  int get updateScheduleStartHour => updateSettings.updateScheduleStartHour;
  set updateScheduleStartHour(int val) {
    updateSettings.updateScheduleStartHour = val;
    notifyListeners();
  }

  int get updateScheduleEndHour => updateSettings.updateScheduleEndHour;
  set updateScheduleEndHour(int val) {
    updateSettings.updateScheduleEndHour = val;
    notifyListeners();
  }

  List<int> get updateScheduleDays => updateSettings.updateScheduleDays;
  set updateScheduleDays(List<int> val) {
    updateSettings.updateScheduleDays = val;
    notifyListeners();
  }

  bool isWithinUpdateSchedule() => updateSettings.isWithinUpdateSchedule();
  String getScheduleDescription() => updateSettings.getScheduleDescription();

  DateTime get lastCompletedBGCheckTime => updateSettings.lastCompletedBGCheckTime;
  set lastCompletedBGCheckTime(DateTime val) {
    updateSettings.lastCompletedBGCheckTime = val;
    notifyListeners();
  }

  bool get useFGService => updateSettings.useFGService;
  set useFGService(bool val) {
    updateSettings.useFGService = val;
    notifyListeners();
  }

  String get obtainiumReleaseChannel => updateSettings.obtainiumReleaseChannel;
  set obtainiumReleaseChannel(String val) {
    updateSettings.obtainiumReleaseChannel = val;
    notifyListeners();
  }

  void processIntervalSliderValue(double val, {bool notify = true}) {
    updateSettings.processIntervalSliderValue(val, notify: notify);
    notifyListeners();
  }

  // --- ViewSettingsProvider ---
  List<String> get bottomTabs => viewSettings.bottomTabs;
  set bottomTabs(List<String> val) {
    viewSettings.bottomTabs = val;
    notifyListeners();
  }

  SortColumnSettings get sortColumn => viewSettings.sortColumn;
  set sortColumn(SortColumnSettings val) {
    viewSettings.sortColumn = val;
    notifyListeners();
  }

  SortOrderSettings get sortOrder => viewSettings.sortOrder;
  set sortOrder(SortOrderSettings val) {
    viewSettings.sortOrder = val;
    notifyListeners();
  }

  bool get showAppWebpage => viewSettings.showAppWebpage;
  set showAppWebpage(bool val) {
    viewSettings.showAppWebpage = val;
    notifyListeners();
  }

  bool get pinUpdates => viewSettings.pinUpdates;
  set pinUpdates(bool val) {
      viewSettings.pinUpdates = val;
      notifyListeners();
    }

  bool get buryNonInstalled => viewSettings.buryNonInstalled;
  set buryNonInstalled(bool val) {
      viewSettings.buryNonInstalled = val;
      notifyListeners();
    }

  bool get groupByCategory => viewSettings.groupByCategory;
  set groupByCategory(bool val) {
      viewSettings.groupByCategory = val;
      notifyListeners();
    }

  bool get categoriesCollapsedByDefault => viewSettings.categoriesCollapsedByDefault;
  set categoriesCollapsedByDefault(bool val) {
      viewSettings.categoriesCollapsedByDefault = val;
      notifyListeners();
    }

  Map<String, int> get categories => viewSettings.categories;
  void setCategories(Map<String, int> cats, {AppsProvider? appsProvider}) {
    viewSettings.setCategories(cats, appsProvider: appsProvider);
    notifyListeners();
  }

  List<String> get categoryOrder => viewSettings.categoryOrder;
  set categoryOrder(List<String> val) {
      viewSettings.categoryOrder = val;
      notifyListeners();
    }

  AppSortMethod get appSortMethod => viewSettings.appSortMethod;
  set appSortMethod(AppSortMethod val) {
      viewSettings.appSortMethod = val;
      notifyListeners();
    }

  ViewMode get globalViewMode => viewSettings.globalViewMode;
  set globalViewMode(ViewMode val) {
      viewSettings.globalViewMode = val;
      notifyListeners();
    }

  int get gridColumnCount => viewSettings.gridColumnCount;
  set gridColumnCount(int val) {
      viewSettings.gridColumnCount = val;
      notifyListeners();
    }

  bool get displayShowAppCount => viewSettings.displayShowAppCount;
  set displayShowAppCount(bool val) {
      viewSettings.displayShowAppCount = val;
      notifyListeners();
    }

  bool get displayShowFilterChips => viewSettings.displayShowFilterChips;
  set displayShowFilterChips(bool val) {
      viewSettings.displayShowFilterChips = val;
      notifyListeners();
    }

  bool get displayShowAuthor => viewSettings.displayShowAuthor;
  set displayShowAuthor(bool val) {
      viewSettings.displayShowAuthor = val;
      notifyListeners();
    }

  bool get displayShowVersion => viewSettings.displayShowVersion;
  set displayShowVersion(bool val) {
      viewSettings.displayShowVersion = val;
      notifyListeners();
    }

  bool get displayShowDate => viewSettings.displayShowDate;
  set displayShowDate(bool val) {
      viewSettings.displayShowDate = val;
      notifyListeners();
    }

  CategoryIconPosition get categoryIconPosition => viewSettings.categoryIconPosition;
  set categoryIconPosition(CategoryIconPosition val) {
      viewSettings.categoryIconPosition = val;
      notifyListeners();
    }

  int get categoryIconCount => viewSettings.categoryIconCount;
  set categoryIconCount(int val) {
      viewSettings.categoryIconCount = val;
      notifyListeners();
    }

  AppListDensity get appListDensity => viewSettings.appListDensity;
  set appListDensity(AppListDensity val) {
      viewSettings.appListDensity = val;
      notifyListeners();
    }

  GridCategoryMode get gridCategoryMode => viewSettings.gridCategoryMode;
  set gridCategoryMode(GridCategoryMode val) {
      viewSettings.gridCategoryMode = val;
      notifyListeners();
    }

  NavigationDestinationLabelBehavior get navigationLabelBehavior => viewSettings.navigationLabelBehavior;
  set navigationLabelBehavior(NavigationDestinationLabelBehavior val) {
      viewSettings.navigationLabelBehavior = val;
      notifyListeners();
    }

  // --- BehaviorSettingsProvider ---
  bool get useShizuku => behaviorSettings.useShizuku;
  set useShizuku(bool val) {
      behaviorSettings.useShizuku = val;
      notifyListeners();
    }

  Future<bool> getInstallPermission({bool enforce = false}) =>
      behaviorSettings.getInstallPermission(enforce: enforce);

  bool get removeOnExternalUninstall => behaviorSettings.removeOnExternalUninstall;
  set removeOnExternalUninstall(bool val) {
      behaviorSettings.removeOnExternalUninstall = val;
      notifyListeners();
    }

  bool get disablePageTransitions => behaviorSettings.disablePageTransitions;
  set disablePageTransitions(bool val) {
      behaviorSettings.disablePageTransitions = val;
      notifyListeners();
    }

  bool get reversePageTransitions => behaviorSettings.reversePageTransitions;
  set reversePageTransitions(bool val) {
      behaviorSettings.reversePageTransitions = val;
      notifyListeners();
    }

  Future<Uri?> getExportDir() => behaviorSettings.getExportDir();
  Future<void> pickExportDir({bool remove = false}) async {
    await behaviorSettings.pickExportDir(remove: remove);
    notifyListeners();
  }

  bool get autoExportOnChanges => behaviorSettings.autoExportOnChanges;
  set autoExportOnChanges(bool val) {
      behaviorSettings.autoExportOnChanges = val;
      notifyListeners();
    }

  int get exportSettings => behaviorSettings.exportSettings;
  set exportSettings(int val) {
      behaviorSettings.exportSettings = val;
      notifyListeners();
    }

  bool get parallelDownloads => behaviorSettings.parallelDownloads;
  set parallelDownloads(bool val) {
      behaviorSettings.parallelDownloads = val;
      notifyListeners();
    }

  bool get beforeNewInstallsShareToAppVerifier => behaviorSettings.beforeNewInstallsShareToAppVerifier;
  set beforeNewInstallsShareToAppVerifier(bool val) {
      behaviorSettings.beforeNewInstallsShareToAppVerifier = val;
      notifyListeners();
    }

  bool get shizukuPretendToBeGooglePlay => behaviorSettings.shizukuPretendToBeGooglePlay;
  set shizukuPretendToBeGooglePlay(bool val) {
      behaviorSettings.shizukuPretendToBeGooglePlay = val;
      notifyListeners();
    }

  double get animationSpeedMultiplier => behaviorSettings.animationSpeedMultiplier;
  set animationSpeedMultiplier(double val) {
      behaviorSettings.animationSpeedMultiplier = val;
      notifyListeners();
    }

  bool get enableHapticFeedback => behaviorSettings.enableHapticFeedback;
  set enableHapticFeedback(bool val) {
      behaviorSettings.enableHapticFeedback = val;
      notifyListeners();
    }

  bool get enableSwipeGestures => behaviorSettings.enableSwipeGestures;
  set enableSwipeGestures(bool val) {
      behaviorSettings.enableSwipeGestures = val;
      notifyListeners();
    }

  bool get enableUndoForAppRemoval => behaviorSettings.enableUndoForAppRemoval;
  set enableUndoForAppRemoval(bool val) {
      behaviorSettings.enableUndoForAppRemoval = val;
      notifyListeners();
    }

  AppSwipeAction get swipeRightAction => behaviorSettings.swipeRightAction;
  set swipeRightAction(AppSwipeAction val) {
      behaviorSettings.swipeRightAction = val;
      notifyListeners();
    }

  AppSwipeAction get swipeLeftAction => behaviorSettings.swipeLeftAction;
  set swipeLeftAction(AppSwipeAction val) {
      behaviorSettings.swipeLeftAction = val;
      notifyListeners();
    }
}
