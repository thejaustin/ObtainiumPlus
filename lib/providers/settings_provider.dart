// Exposes functions used to save/load app settings

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

String obtainiumTempId = 'imranr98_obtainium_${GitHub().hosts[0]}';
String obtainiumId = 'dev.imranr.obtainium';
String obtainiumUrl = 'https://github.com/ImranR98/Obtainium';
Color obtainiumThemeColor = const Color(0xFF6438B5);

enum ThemeSettings { system, light, dark }

enum SortColumnSettings { added, nameAuthor, authorName, releaseDate, lastUpdated, source, installDate, lastCheckDate }

enum SortOrderSettings { ascending, descending }

enum AppSortMethod { latestUpdates, nameAZ, nameZA, recentlyAdded, installStatus, defaultSort }

enum CategoryIconPosition { leading, trailing, below, disabled }

enum ViewMode { list, grid }

enum GridCategoryMode { sections, disabled, folders }

enum AppSwipeAction { none, update, togglePin, share, launch, delete }

enum AppListDensity { comfortable, compact }

class SettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;
  String? defaultAppDir;
  bool justStarted = true;

  String sourceUrl = 'https://github.com/ImranR98/Obtainium';

  List<int> updateIntervalNodes = [
    15,
    30,
    60,
    120,
    180,
    360,
    720,
    1440,
    4320,
    10080,
    20160,
    43200,
  ];
  late SplineInterpolation updateIntervalInterpolator;
  String updateIntervalLabel = '';

  // Not done in constructor as we want to be able to await it
  Future<void> initializeSettings() async {
    prefs = await SharedPreferences.getInstance();
    defaultAppDir = (await AppFileService.getAppStorageDir()).path;
    initUpdateIntervalInterpolator();
    // Initialize label based on current slider value
    processIntervalSliderValue(updateIntervalSliderVal, notify: false);
    notifyListeners();
  }

  void initUpdateIntervalInterpolator() {
    List<InterpolationNode> nodes = [];
    for (final (index, element) in updateIntervalNodes.indexed) {
      nodes.add(
        InterpolationNode(x: index.toDouble() + 1, y: element.toDouble()),
      );
    }
    updateIntervalInterpolator = SplineInterpolation(nodes: nodes);
  }

  void processIntervalSliderValue(double val, {bool notify = true}) {
    if (val < 0.5) {
      updateInterval = 0;
      updateIntervalLabel = tr('neverManualOnly');
      if (notify) notifyListeners();
      return;
    }
    int valInterpolated = 0;
    if (val < 1) {
      valInterpolated = 15;
    } else {
      valInterpolated = updateIntervalInterpolator.compute(val).round();
    }
    if (valInterpolated < 60) {
      updateInterval = valInterpolated;
      updateIntervalLabel = plural('minute', valInterpolated);
    } else if (valInterpolated < 8 * 60) {
      int valRounded = (valInterpolated / 15).floor() * 15;
      updateInterval = valRounded;
      updateIntervalLabel = plural('hour', valRounded ~/ 60);
      int mins = valRounded % 60;
      if (mins != 0) updateIntervalLabel += " ${plural('minute', mins)}";
    } else if (valInterpolated < 24 * 60) {
      int valRounded = (valInterpolated / 30).floor() * 30;
      updateInterval = valRounded;
      updateIntervalLabel = plural('hour', valRounded / 60);
    } else if (valInterpolated < 7 * 24 * 60) {
      int valRounded = (valInterpolated / (12 * 60)).floor() * 12 * 60;
      updateInterval = valRounded;
      updateIntervalLabel = plural('day', valRounded / (24 * 60));
    } else {
      int valRounded = (valInterpolated / (24 * 60)).floor() * 24 * 60;
      updateInterval = valRounded;
      updateIntervalLabel = plural('day', valRounded ~/ (24 * 60));
    }
    if (notify) notifyListeners();
  }

  bool get useSystemFont {
    return prefs?.getBool('useSystemFont') ?? false;
  }

  set useSystemFont(bool useSystemFont) {
    prefs?.setBool('useSystemFont', useSystemFont);
    notifyListeners();
  }

  bool get useShizuku {
    return prefs?.getBool('useShizuku') ?? false;
  }

  set useShizuku(bool useShizuku) {
    prefs?.setBool('useShizuku', useShizuku);
    notifyListeners();
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

  int get updateInterval {
    return prefs?.getInt('updateInterval') ?? 360;
  }

  set updateInterval(int min) {
    prefs?.setInt('updateInterval', min);
    notifyListeners();
  }

  double get updateIntervalSliderVal {
    return prefs?.getDouble('updateIntervalSliderVal') ?? 6.0;
  }

  set updateIntervalSliderVal(double val) {
    prefs?.setDouble('updateIntervalSliderVal', val);
    notifyListeners();
  }

  bool get checkOnStart {
    return prefs?.getBool('checkOnStart') ?? false;
  }

  set checkOnStart(bool checkOnStart) {
    prefs?.setBool('checkOnStart', checkOnStart);
    notifyListeners();
  }

  SortColumnSettings get sortColumn {
    return SortColumnSettings.values[prefs?.getInt('sortColumn') ??
        SortColumnSettings.nameAuthor.index];
  }

  set sortColumn(SortColumnSettings s) {
    prefs?.setInt('sortColumn', s.index);
    notifyListeners();
  }

  SortOrderSettings get sortOrder {
    return SortOrderSettings.values[prefs?.getInt('sortOrder') ??
        SortOrderSettings.ascending.index];
  }

  set sortOrder(SortOrderSettings s) {
    prefs?.setInt('sortOrder', s.index);
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

  Future<bool> getInstallPermission({bool enforce = false}) async {
    while (!(await Permission.requestInstallPackages.isGranted)) {
      // Explicit request as InstallPlugin request sometimes bugged
      Fluttertoast.showToast(
        msg: tr('pleaseAllowInstallPerm'),
        toastLength: Toast.LENGTH_LONG,
      );
      if ((await Permission.requestInstallPackages.request()) ==
          PermissionStatus.granted) {
        return true;
      }
      if (!enforce) {
        return false;
      }
    }
    return true;
  }

  bool get showAppWebpage {
    return prefs?.getBool('showAppWebpage') ?? false;
  }

  set showAppWebpage(bool show) {
    prefs?.setBool('showAppWebpage', show);
    notifyListeners();
  }

  bool get pinUpdates {
    return prefs?.getBool('pinUpdates') ?? true;
  }

  set pinUpdates(bool show) {
    prefs?.setBool('pinUpdates', show);
    notifyListeners();
  }

  bool get buryNonInstalled {
    return prefs?.getBool('buryNonInstalled') ?? false;
  }

  set buryNonInstalled(bool show) {
    prefs?.setBool('buryNonInstalled', show);
    notifyListeners();
  }

  bool get groupByCategory {
    return prefs?.getBool('groupByCategory') ?? false;
  }

  set groupByCategory(bool show) {
    prefs?.setBool('groupByCategory', show);
    notifyListeners();
  }

  bool get categoriesCollapsedByDefault {
    return prefs?.getBool('categoriesCollapsedByDefault') ?? false;
  }

  set categoriesCollapsedByDefault(bool collapsed) {
    prefs?.setBool('categoriesCollapsedByDefault', collapsed);
    notifyListeners();
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

  Map<String, int> get categories {
    try {
      return Map<String, int>.from(jsonDecode(prefs?.getString('categories') ?? '{}'));
    } catch (e) {
      return {};
    }
  }

  void setCategories(Map<String, int> cats, {AppsProvider? appsProvider}) {
    if (appsProvider != null) {
      List<App> changedApps = appsProvider
          .getAppValues(deepCopy: false)
          .map((a) {
            var n1 = a.app.categories.length;
            a.app.categories.removeWhere((c) => !cats.keys.contains(c));
            return n1 > a.app.categories.length ? a.app : null;
          })
          .where((element) => element != null)
          .map((e) => e as App)
          .toList();
      if (changedApps.isNotEmpty) {
        appsProvider.saveApps(changedApps);
      }
    }
    prefs?.setString('categories', jsonEncode(cats));
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

  bool get removeOnExternalUninstall {
    return prefs?.getBool('removeOnExternalUninstall') ?? false;
  }

  set removeOnExternalUninstall(bool show) {
    prefs?.setBool('removeOnExternalUninstall', show);
    notifyListeners();
  }

  bool get checkUpdateOnDetailPage {
    return prefs?.getBool('checkUpdateOnDetailPage') ?? true;
  }

  set checkUpdateOnDetailPage(bool show) {
    prefs?.setBool('checkUpdateOnDetailPage', show);
    notifyListeners();
  }

  bool get disablePageTransitions {
    return prefs?.getBool('disablePageTransitions') ?? false;
  }

  set disablePageTransitions(bool show) {
    prefs?.setBool('disablePageTransitions', show);
    notifyListeners();
  }

  bool get reversePageTransitions {
    return prefs?.getBool('reversePageTransitions') ?? false;
  }

  set reversePageTransitions(bool show) {
    prefs?.setBool('reversePageTransitions', show);
    notifyListeners();
  }

  bool get enableBackgroundUpdates {
    return prefs?.getBool('enableBackgroundUpdates') ?? true;
  }

  set enableBackgroundUpdates(bool val) {
    prefs?.setBool('enableBackgroundUpdates', val);
    notifyListeners();
  }

  bool get bgUpdatesOnWiFiOnly {
    return prefs?.getBool('bgUpdatesOnWiFiOnly') ?? false;
  }

  set bgUpdatesOnWiFiOnly(bool val) {
    prefs?.setBool('bgUpdatesOnWiFiOnly', val);
    notifyListeners();
  }

  bool get bgUpdatesWhileChargingOnly {
    return prefs?.getBool('bgUpdatesWhileChargingOnly') ?? false;
  }

  set bgUpdatesWhileChargingOnly(bool val) {
    prefs?.setBool('bgUpdatesWhileChargingOnly', val);
    notifyListeners();
  }

  DateTime get lastCompletedBGCheckTime {
    int? temp = prefs?.getInt('lastCompletedBGCheckTime');
    return temp != null
        ? DateTime.fromMillisecondsSinceEpoch(temp)
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  set lastCompletedBGCheckTime(DateTime val) {
    prefs?.setInt('lastCompletedBGCheckTime', val.millisecondsSinceEpoch);
    notifyListeners();
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

  Future<Uri?> getExportDir() async {
    var uriString = prefs?.getString('exportDir');
    if (uriString != null) {
      Uri? uri = Uri.parse(uriString);
      if (!(await saf.canRead(uri) ?? false) ||
          !(await saf.canWrite(uri) ?? false)) {
        uri = null;
        prefs?.remove('exportDir');
        notifyListeners();
      }
      return uri;
    } else {
      return null;
    }
  }

  Future<void> pickExportDir({bool remove = false}) async {
    var existingSAFPerms = (await saf.persistedUriPermissions()) ?? [];
    var currentOneWayDataSyncDir = await getExportDir();
    Uri? newOneWayDataSyncDir;
    if (!remove) {
      newOneWayDataSyncDir = (await saf.openDocumentTree());
    }
    if (currentOneWayDataSyncDir?.path != newOneWayDataSyncDir?.path) {
      if (newOneWayDataSyncDir == null) {
        prefs?.remove('exportDir');
      } else {
        prefs?.setString('exportDir', newOneWayDataSyncDir.toString());
      }
      notifyListeners();
    }
    for (var e in existingSAFPerms) {
      await saf.releasePersistableUriPermission(e.uri);
    }
  }

  bool get autoExportOnChanges {
    return prefs?.getBool('autoExportOnChanges') ?? false;
  }

  set autoExportOnChanges(bool val) {
    prefs?.setBool('autoExportOnChanges', val);
    notifyListeners();
  }

  bool get onlyCheckInstalledOrTrackOnlyApps {
    return prefs?.getBool('onlyCheckInstalledOrTrackOnlyApps') ?? false;
  }

  set onlyCheckInstalledOrTrackOnlyApps(bool val) {
    prefs?.setBool('onlyCheckInstalledOrTrackOnlyApps', val);
    notifyListeners();
  }

  int get exportSettings {
    try {
      return prefs?.getInt('exportSettings') ??
          1; // 0 for no, 1 for yes but no secrets, 2 for everything
    } catch (e) {
      var val = prefs?.getBool('exportSettings') == true ? 1 : 0;
      prefs?.setInt('exportSettings', val);
      return val;
    }
  }

  set exportSettings(int val) {
    prefs?.setInt('exportSettings', val > 2 || val < 0 ? 1 : val);
    notifyListeners();
  }

  bool get parallelDownloads {
    return prefs?.getBool('parallelDownloads') ?? false;
  }

  set parallelDownloads(bool val) {
    prefs?.setBool('parallelDownloads', val);
    notifyListeners();
  }

  List<String> get searchDeselected {
    return prefs?.getStringList('searchDeselected') ?? [];
  }

  set searchDeselected(List<String> list) {
    prefs?.setStringList('searchDeselected', list);
    notifyListeners();
  }

  bool get beforeNewInstallsShareToAppVerifier {
    return prefs?.getBool('beforeNewInstallsShareToAppVerifier') ?? true;
  }

  set beforeNewInstallsShareToAppVerifier(bool val) {
    prefs?.setBool('beforeNewInstallsShareToAppVerifier', val);
    notifyListeners();
  }

  bool get shizukuPretendToBeGooglePlay {
    return prefs?.getBool('shizukuPretendToBeGooglePlay') ?? false;
  }

  set shizukuPretendToBeGooglePlay(bool val) {
    prefs?.setBool('shizukuPretendToBeGooglePlay', val);
    notifyListeners();
  }

  bool get useFGService {
    return prefs?.getBool('useFGService') ?? false;
  }

  set useFGService(bool val) {
    prefs?.setBool('useFGService', val);
    notifyListeners();
  }

  List<String> get categoryOrder {
    return prefs?.getStringList('categoryOrder') ?? [];
  }

  set categoryOrder(List<String> order) {
    prefs?.setStringList('categoryOrder', order);
    notifyListeners();
  }

  // Animation speed control setting
  double get animationSpeedMultiplier {
    return prefs?.getDouble('animationSpeedMultiplier') ?? 1.0;
  }

  set animationSpeedMultiplier(double multiplier) {
    prefs?.setDouble('animationSpeedMultiplier', multiplier);
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

  // Enable haptic feedback setting
  bool get enableHapticFeedback {
    return prefs?.getBool('enableHapticFeedback') ?? true;
  }

  set enableHapticFeedback(bool enabled) {
    prefs?.setBool('enableHapticFeedback', enabled);
    notifyListeners();
  }

  AppSortMethod get appSortMethod {
    // Smart default: if user has many apps, default to name sorting for easier scanning
    // Otherwise, default to most recent updates
    int defaultIndex = AppSortMethod.defaultSort.index;

    // Try to get app count from preferences to determine smart default
    int appCount = prefs?.getInt('trackedAppCount') ?? 0;
    if (appCount > 20) {
      // For many apps, name sorting is easier to scan
      defaultIndex = AppSortMethod.nameAZ.index;
    } else if (appCount > 0) {
      // For fewer apps, show latest updates first
      defaultIndex = AppSortMethod.latestUpdates.index;
    }

    return AppSortMethod.values[prefs?.getInt('appSortMethod') ?? defaultIndex];
  }

  set appSortMethod(AppSortMethod method) {
    prefs?.setInt('appSortMethod', method.index);
    notifyListeners();
  }

  void setAppSortMethod(AppSortMethod method) {
    appSortMethod = method;
  }

  // Category Icon Preview Settings
  CategoryIconPosition get categoryIconPosition {
    return CategoryIconPosition.values[prefs?.getInt('categoryIconPosition') ??
        CategoryIconPosition.disabled.index];
  }

  set categoryIconPosition(CategoryIconPosition pos) {
    prefs?.setInt('categoryIconPosition', pos.index);
    notifyListeners();
  }

  int get categoryIconCount {
    return prefs?.getInt('categoryIconCount') ?? 0;
  }

  set categoryIconCount(int count) {
    prefs?.setInt('categoryIconCount', count.clamp(0, 20));
    notifyListeners();
  }

  // Grid View Settings
  ViewMode get globalViewMode {
    return ViewMode.values[prefs?.getInt('globalViewMode') ??
        ViewMode.list.index];
  }

  set globalViewMode(ViewMode mode) {
    prefs?.setInt('globalViewMode', mode.index);
    notifyListeners();
  }

  Map<String, int> get categoryViewModeOverrides {
    try {
      return Map<String, int>.from(
          jsonDecode(prefs?.getString('categoryViewModeOverrides') ?? '{}'));
    } catch (e) {
      return {};
    }
  }

  set categoryViewModeOverrides(Map<String, int> overrides) {
    prefs?.setString('categoryViewModeOverrides', jsonEncode(overrides));
    notifyListeners();
  }

  ViewMode? getCategoryViewMode(String categoryName) {
    int? override = categoryViewModeOverrides[categoryName];
    return override != null ? ViewMode.values[override] : null;
  }

  void setCategoryViewMode(String categoryName, ViewMode? mode) {
    var overrides = categoryViewModeOverrides;
    if (mode == null) {
      overrides.remove(categoryName);
    } else {
      overrides[categoryName] = mode.index;
    }
    categoryViewModeOverrides = overrides;
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

  // Settings for new features
  bool get enableSwipeGestures {
    return prefs?.getBool('enableSwipeGestures') ?? true;
  }

  set enableSwipeGestures(bool enabled) {
    prefs?.setBool('enableSwipeGestures', enabled);
    notifyListeners();
  }

  bool get enableUndoForAppRemoval {
    return prefs?.getBool('enableUndoForAppRemoval') ?? true;
  }

  set enableUndoForAppRemoval(bool enabled) {
    prefs?.setBool('enableUndoForAppRemoval', enabled);
    notifyListeners();
  }

  bool get enableHelpTooltips {
    return prefs?.getBool('enableHelpTooltips') ?? true;
  }

  set enableHelpTooltips(bool enabled) {
    prefs?.setBool('enableHelpTooltips', enabled);
    notifyListeners();
  }

  bool get enableContextualTips {
    return prefs?.getBool('enableContextualTips') ?? true;
  }

  set enableContextualTips(bool enabled) {
    prefs?.setBool('enableContextualTips', enabled);
    notifyListeners();
  }

  GridCategoryMode get gridCategoryMode {
    return GridCategoryMode.values[prefs?.getInt('gridCategoryMode') ??
        GridCategoryMode.sections.index];
  }

  set gridCategoryMode(GridCategoryMode mode) {
    prefs?.setInt('gridCategoryMode', mode.index);
    notifyListeners();
  }

  int get gridColumnCount {
    return prefs?.getInt('gridColumnCount') ?? 0;
  }

  set gridColumnCount(int count) {
    prefs?.setInt('gridColumnCount', count.clamp(0, 6));
    notifyListeners();
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

  bool get enableDeepLogging {
    return prefs?.getBool('enableDeepLogging') ?? false;
  }

  set enableDeepLogging(bool val) {
    prefs?.setBool('enableDeepLogging', val);
    notifyListeners();
  }

  NavigationDestinationLabelBehavior get navigationLabelBehavior {
    return NavigationDestinationLabelBehavior.values[prefs?.getInt('navigationLabelBehavior') ??
        NavigationDestinationLabelBehavior.alwaysShow.index];
  }

  set navigationLabelBehavior(NavigationDestinationLabelBehavior behavior) {
    prefs?.setInt('navigationLabelBehavior', behavior.index);
    notifyListeners();
  }

  // App Tile Display Settings
  bool get displayShowAuthor => prefs?.getBool('displayShowAuthor') ?? true;
  set displayShowAuthor(bool val) {
    prefs?.setBool('displayShowAuthor', val);
    notifyListeners();
  }

  bool get displayShowVersion => prefs?.getBool('displayShowVersion') ?? true;
  set displayShowVersion(bool val) {
    prefs?.setBool('displayShowVersion', val);
    notifyListeners();
  }

  bool get displayShowDate => prefs?.getBool('displayShowDate') ?? true;
  set displayShowDate(bool val) {
    prefs?.setBool('displayShowDate', val);
    notifyListeners();
  }

  // App List Header Settings
  bool get displayShowFilterChips => prefs?.getBool('displayShowFilterChips') ?? true;
  set displayShowFilterChips(bool val) {
    prefs?.setBool('displayShowFilterChips', val);
    notifyListeners();
  }

  bool get displayShowAppCount => prefs?.getBool('displayShowAppCount') ?? true;
  set displayShowAppCount(bool val) {
    prefs?.setBool('displayShowAppCount', val);
    notifyListeners();
  }

  // Swipe Actions
  AppSwipeAction get swipeRightAction =>
      AppSwipeAction.values[prefs?.getInt('swipeRightAction') ??
          AppSwipeAction.none.index];
  set swipeRightAction(AppSwipeAction action) {
    prefs?.setInt('swipeRightAction', action.index);
    notifyListeners();
  }

  AppSwipeAction get swipeLeftAction =>
      AppSwipeAction.values[prefs?.getInt('swipeLeftAction') ??
          AppSwipeAction.none.index];
  set swipeLeftAction(AppSwipeAction action) {
    prefs?.setInt('swipeLeftAction', action.index);
    notifyListeners();
  }

  // List Density
  AppListDensity get appListDensity =>
      AppListDensity.values[prefs?.getInt('appListDensity') ??
          AppListDensity.comfortable.index];
  set appListDensity(AppListDensity density) {
    prefs?.setInt('appListDensity', density.index);
    notifyListeners();
  }

  List<String> get bottomTabs {
    return prefs?.getStringList('bottomTabs') ?? ['apps', 'add'];
  }

  set bottomTabs(List<String> tabs) {
    prefs?.setStringList('bottomTabs', tabs);
    notifyListeners();
  }
}
