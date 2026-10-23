// Exposes functions used to save/load app settings

import 'dart:async';
import 'dart:convert';

import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/utils/logger.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/core/logging/app_logger.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/document_tree_bridge.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:shared_storage/shared_storage.dart' as saf;

const String kDownloadsExportDir = 'tv-downloads:';
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

enum GroupByMode { none, category, source }

enum ActionBannerMode { all, updatesOnly, none }

/// What background work may run when a guard condition (not on Wi-Fi, not
/// charging) is unmet. When the condition is met the mode is irrelevant.
enum BgGuardMode { nothing, checksOnly, checksAndUpdates }

class SettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;
  SettingsProvider([this.prefs]);
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  static final Map<String, String> _secureCache = {};
  static bool _secureCacheLoaded = false;

  /// Credential settings kept in secure storage instead of plain prefs.
  static const List<String> secureKeys = [
    'github-creds',
    'gitlab-creds',
    'forgejo-creds',
  ];

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

  Future<void> _loadSecureSettings() async {
    try {
      await Future.wait(
        secureKeys.map((key) async {
          if (prefs!.containsKey(key)) {
            final plaintextVal = prefs!.getString(key);
            if (plaintextVal != null && plaintextVal.isNotEmpty) {
              await secureStorage.write(key: key, value: plaintextVal);
              _secureCache[key] = plaintextVal;
            }
            await prefs!.remove(key); // Clear plaintext
          } else if (!_secureCacheLoaded) {
            final secureVal = await secureStorage.read(key: key);
            if (secureVal != null) {
              _secureCache[key] = secureVal;
            }
          }
        }),
      );
      _secureCacheLoaded = true;
    } catch (e) {
      talker.warning('Could not initialize secure storage: $e');
    }
  }

  Future<void> initializeSettings([
    SharedPreferences? existingPrefs,
    bool deferSecureStorage = false,
  ]) async {
    prefs = existingPrefs ?? prefs ?? await SharedPreferences.getInstance();

    final secureFuture = _loadSecureSettings();
    if (deferSecureStorage) {
      unawaited(secureFuture);
    }

    // Neither platform lookup is worth failing all of settings init over —
    // both have sane fallbacks (defaultAppDir stays null, isTV stays false)
    await Future.wait([
      if (!deferSecureStorage) secureFuture,
      () async {
        if (_cachedDefaultAppDir != null) {
          defaultAppDir = _cachedDefaultAppDir;
          return;
        }
        try {
          _cachedDefaultAppDir = (await AppFileService.getAppStorageDir()).path;
          defaultAppDir = _cachedDefaultAppDir;
        } catch (e) {
          talker.warning('Could not determine app storage dir: $e');
        }
      }(),
      () async {
        if (_cachedIsTV != null) {
          isTV = _cachedIsTV!;
          return;
        }
        try {
          final info = await DeviceInfoPlugin().androidInfo;
          _cachedIsTV =
              info.systemFeatures.contains(
                'android.hardware.type.television',
              ) ||
              info.systemFeatures.contains('android.software.leanback');
          isTV = _cachedIsTV!;
        } catch (e) {
          isTV = false;
        }
      }(),
    ]);
    _migrateLegacyExportSetting();
    _normalizeInstallPreference();
    _migrateGroupBySetting();
    notifyListeners();
  }

  void _migrateLegacyExportSetting() {
    if (_getInt('exportSettings') != null) return;
    final legacyBool = _getBool('exportSettings');
    if (legacyBool != null) {
      prefs?.setInt('exportSettings', legacyBool ? 1 : 0);
    }
  }

  void _migrateGroupBySetting() {
    if (_getString('groupBy') != null) return;
    final legacy = _getBool('groupByCategory');
    if (legacy != null) {
      prefs?.setString(
        'groupBy',
        legacy ? GroupByMode.category.name : GroupByMode.none.name,
      );
      unawaited(prefs?.remove('groupByCategory') ?? Future.value());
    }
  }

  void _normalizeInstallPreference() {
    if (_getString('installMethod') != null) return;
    final shizukuFlag = _getBool('useShizuku');
    if (shizukuFlag != null) {
      prefs?.setString(
        'installMethod',
        shizukuFlag ? InstallerMode.shizuku.name : InstallerMode.system.name,
      );
      unawaited(prefs?.remove('useShizuku') ?? Future.value());
    }
  }

  bool get useSystemFont {
    return _getBool('useSystemFont') ?? false;
  }

  set useSystemFont(bool useSystemFont) {
    prefs?.setBool('useSystemFont', useSystemFont);
    notifyListeners();
  }

  String get installerMode {
    final stored = _getString('installMethod');
    if (stored != null && InstallerMode.values.any((m) => m.name == stored)) {
      return stored;
    }
    return InstallerMode.system.name;
  }

  set installerMode(String mode) {
    final resolved = InstallerMode.values.any((m) => m.name == mode)
        ? mode
        : InstallerMode.system.name;
    prefs?.setString('installMethod', resolved);
    notifyListeners();
  }

  String get shizukuInstallerMode {
    final stored = _getString('shizukuInstallerMode');
    return stored == 'shizuku' || stored == 'dhizuku' ? stored! : 'auto';
  }

  set shizukuInstallerMode(String mode) {
    prefs?.setString(
      'shizukuInstallerMode',
      mode == 'shizuku' || mode == 'dhizuku' ? mode : 'auto',
    );
    notifyListeners();
  }

  bool get useShizuku => installerMode == InstallerMode.shizuku.name;

  set useShizuku(bool useShizuku) {
    installerMode = useShizuku
        ? InstallerMode.shizuku.name
        : InstallerMode.system.name;
  }

  String? get externalInstallerPackage =>
      getSettingString('externalInstallerPackage');

  set externalInstallerPackage(String? val) {
    if (val == null || val.isEmpty) {
      prefs?.remove('externalInstallerPackage');
    } else {
      prefs?.setString('externalInstallerPackage', val);
    }
    notifyListeners();
  }

  String? get externalInstallerComponent =>
      getSettingString('externalInstallerComponent');

  set externalInstallerComponent(String? val) {
    if (val == null || val.isEmpty) {
      prefs?.remove('externalInstallerComponent');
    } else {
      prefs?.setString('externalInstallerComponent', val);
    }
    notifyListeners();
  }

  ThemeSettings get theme {
    final stored = _getInt('theme');
    if (stored != null && stored >= 0 && stored < ThemeSettings.values.length) {
      return ThemeSettings.values[stored];
    }
    return ThemeSettings.system;
  }

  set theme(ThemeSettings t) {
    prefs?.setInt('theme', t.index);
    notifyListeners();
  }

  Color get themeColor {
    final int? colorCode = _getInt('themeColor');
    return (colorCode != null) ? Color(colorCode) : obtainiumThemeColor;
  }

  set themeColor(Color themeColor) {
    prefs?.setInt('themeColor', themeColor.toARGB32());
    notifyListeners();
  }

  ColourSchemeMode get colourSchemeMode {
    final stored = _getInt('colourSchemeMode');
    if (stored != null &&
        stored >= 0 &&
        stored < ColourSchemeMode.values.length) {
      return ColourSchemeMode.values[stored];
    }
    return (_getBool('useMaterialYou') ?? false)
        ? ColourSchemeMode.materialYou
        : ColourSchemeMode.standard;
  }

  set colourSchemeMode(ColourSchemeMode mode) {
    prefs?.setInt('colourSchemeMode', mode.index);
    prefs?.setBool('useMaterialYou', mode == ColourSchemeMode.materialYou);
    notifyListeners();
  }

  bool get useBlackTheme {
    return _getBool('useBlackTheme') ?? false;
  }

  set useBlackTheme(bool useBlackTheme) {
    prefs?.setBool('useBlackTheme', useBlackTheme);
    notifyListeners();
  }

  int get updateInterval {
    final stored = _getInt('updateInterval') ?? 360;
    return stored < 0 ? 0 : stored;
  }

  set updateInterval(int min) {
    prefs?.setInt('updateInterval', min);
    notifyListeners();
  }

  double get updateIntervalSliderVal {
    final stored = _getDouble('updateIntervalSliderVal') ?? 6.0;
    if (stored.isNaN || stored.isInfinite || stored < 0) return 6.0;
    return stored;
  }

  set updateIntervalSliderVal(double val) {
    prefs?.setDouble('updateIntervalSliderVal', val);
    notifyListeners();
  }

  bool get checkOnStart {
    return _getBool('checkOnStart') ?? false;
  }

  set checkOnStart(bool checkOnStart) {
    prefs?.setBool('checkOnStart', checkOnStart);
    notifyListeners();
  }

  SortColumnSettings get sortColumn {
    final stored = _getInt('sortColumn');
    if (stored != null &&
        stored >= 0 &&
        stored < SortColumnSettings.values.length) {
      return SortColumnSettings.values[stored];
    }
    return SortColumnSettings.nameAuthor;
  }

  set sortColumn(SortColumnSettings s) {
    prefs?.setInt('sortColumn', s.index);
    notifyListeners();
  }

  SortOrderSettings get sortOrder {
    final stored = _getInt('sortOrder');
    if (stored != null &&
        stored >= 0 &&
        stored < SortOrderSettings.values.length) {
      return SortOrderSettings.values[stored];
    }
    return SortOrderSettings.ascending;
  }

  set sortOrder(SortOrderSettings s) {
    prefs?.setInt('sortOrder', s.index);
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
    if (secureKeys.contains(settingId)) {
      String? str = _secureCache[settingId];
      return str?.isNotEmpty == true ? str : null;
    }
    String? str = prefs?.safeString(settingId);
    return str?.isNotEmpty == true ? str : null;
  }

  void setSettingString(String settingId, String value) {
    if (secureKeys.contains(settingId)) {
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

  String? _categoriesRaw;
  Map<String, int>? _categoriesCache;

  Map<String, int> get categories {
    final raw = _getString('categories') ?? '{}';
    if (raw != _categoriesRaw || _categoriesCache == null) {
      _categoriesRaw = raw;
      try {
        _categoriesCache = Map<String, int>.from(jsonDecode(raw));
      } catch (e) {
        AppLogger.error(e, message: 'Corrupted categories data, resetting');
        _categoriesCache = <String, int>{};
      }
    }
    return _categoriesCache!;
  }

  void setCategories(Map<String, int> cats) {
    prefs?.setString('categories', safeJsonEncode(cats));
    // Deleted/renamed categories must not leave stale exclusions behind.
    final excluded = categoriesExcludedFromChecks
        .where(cats.containsKey)
        .toSet();
    prefs?.setString(
      'categoriesExcludedFromChecks',
      jsonEncode(excluded.toList()),
    );
    notifyListeners();
  }

  /// Categories whose apps are skipped by automatic update checks (#3375).
  Set<String> get categoriesExcludedFromChecks {
    final raw = _getString('categoriesExcludedFromChecks');
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      AppLogger.error(
        e,
        message: 'Corrupted category exclusion data, resetting',
      );
    }
    return <String>{};
  }

  set categoriesExcludedFromChecks(Set<String> categories) {
    prefs?.setString(
      'categoriesExcludedFromChecks',
      jsonEncode(categories.toList()),
    );
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

  bool get hideDowngrades {
    return _getBool('hideDowngrades') ?? true;
  }

  set hideDowngrades(bool hide) {
    prefs?.setBool('hideDowngrades', hide);
    notifyListeners();
  }

  bool get tactileFeedbackEnabled {
    return _getBool('tactileFeedbackEnabled') ?? true;
  }

  set tactileFeedbackEnabled(bool val) {
    prefs?.setBool('tactileFeedbackEnabled', val);
    notifyListeners();
  }

  bool get showBatteryOptimizationPrompt {
    return prefs?.safeBool('showBatteryOptimizationPrompt') ?? true;
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

  bool get removeOnExternalUninstall {
    return _getBool('removeOnExternalUninstall') ?? false;
  }

  set removeOnExternalUninstall(bool value) {
    prefs?.setBool('removeOnExternalUninstall', value);
    notifyListeners();
  }

  bool get checkUpdateOnDetailPage {
    return _getBool('checkUpdateOnDetailPage') ?? false;
  }

  set checkUpdateOnDetailPage(bool value) {
    prefs?.setBool('checkUpdateOnDetailPage', value);
    notifyListeners();
  }

  bool get allowAddingAppsWithoutCheck {
    return _getBool('allowAddingAppsWithoutCheck') ?? false;
  }

  set allowAddingAppsWithoutCheck(bool value) {
    prefs?.setBool('allowAddingAppsWithoutCheck', value);
    notifyListeners();
  }

  bool get enableBackgroundUpdates {
    return _getBool('enableBackgroundUpdates') ?? true;
  }

  set enableBackgroundUpdates(bool val) {
    prefs?.setBool('enableBackgroundUpdates', val);
    notifyListeners();
  }

  bool get enableCertificatePinning {
    return _getBool('enableCertificatePinning') ?? false;
  }

  set enableCertificatePinning(bool enableCertificatePinning) {
    prefs?.setBool('enableCertificatePinning', enableCertificatePinning);
    notifyListeners();
  }

  bool get bgUpdatesOnWiFiOnly {
    return _getBool('bgUpdatesOnWiFiOnly') ?? false;
  }

  set bgUpdatesOnWiFiOnly(bool val) {
    prefs?.setBool('bgUpdatesOnWiFiOnly', val);
    notifyListeners();
  }

  bool get bgUpdatesWhileChargingOnly {
    return _getBool('bgUpdatesWhileChargingOnly') ?? false;
  }

  set bgUpdatesWhileChargingOnly(bool val) {
    prefs?.setBool('bgUpdatesWhileChargingOnly', val);
    notifyListeners();
  }

  bool get highlightTouchTargets {
    return _getBool('highlightTouchTargets') ?? false;
  }

  set highlightTouchTargets(bool val) {
    prefs?.setBool('highlightTouchTargets', val);
    notifyListeners();
  }

  bool get disableSwipeActions {
    return _getBool('disableSwipeActions') ?? false;
  }

  set disableSwipeActions(bool val) {
    prefs?.setBool('disableSwipeActions', val);
    notifyListeners();
  }

  bool get alwaysUsePhoneLayout {
    return _getBool('alwaysUsePhoneLayout') ?? false;
  }

  set alwaysUsePhoneLayout(bool val) {
    prefs?.setBool('alwaysUsePhoneLayout', val);
    notifyListeners();
  }

  BgGuardMode _bgGuardMode(String key, String legacyKey) {
    final stored = _getString(key);
    if (stored != null && BgGuardMode.values.any((m) => m.name == stored)) {
      return BgGuardMode.values.byName(stored);
    }
    final legacy = _getBool(legacyKey);
    if (legacy != null) {
      return legacy ? BgGuardMode.checksOnly : BgGuardMode.checksAndUpdates;
    }
    return BgGuardMode.checksAndUpdates;
  }

  void _setBgGuardMode(String key, BgGuardMode mode) {
    prefs?.setString(key, mode.name);
    notifyListeners();
  }

  BgGuardMode get bgGuardOnWiFi =>
      _bgGuardMode('bgGuardOnWiFi', 'bgUpdatesOnWiFiOnly');

  set bgGuardOnWiFi(BgGuardMode mode) => _setBgGuardMode('bgGuardOnWiFi', mode);

  BgGuardMode get bgGuardWhileCharging =>
      _bgGuardMode('bgGuardWhileCharging', 'bgUpdatesWhileChargingOnly');

  set bgGuardWhileCharging(BgGuardMode mode) =>
      _setBgGuardMode('bgGuardWhileCharging', mode);

  Future<Uri?> getExportDir() async {
    final uriString = _getString('exportDir');
    if (uriString == null) {
      return null;
    }
    if (uriString == kDownloadsExportDir) {
      return Uri.parse(uriString);
    }
    final uri = Uri.parse(uriString);
    // The directory may be temporarily unreadable (e.g. a WebDAV mount not
    // yet available right after a reboot). Keep the stored URI so it can be
    // retried later, and only clear it via pickExportDir.
    try {
      if (!(await saf.canRead(uri) ?? false) ||
          !(await saf.canWrite(uri) ?? false)) {
        return null;
      }
    } catch (e) {
      // A revoked grant or unavailable provider can throw from the platform
      // channel; treat it as "not currently available" rather than crashing.
      AppLogger.error(e, message: 'Failed to check export directory access');
      return null;
    }
    return uri;
  }

  /// Switches exports to the MediaStore-backed `Downloads/Obtainium/` folder
  /// for devices without a document-tree picker.
  Future<void> useDownloadsExportDir() async {
    await prefs?.setString('exportDir', kDownloadsExportDir);
    notifyListeners();
  }

  Future<void> pickExportDir() async {
    final existingSAFPerms = (await saf.persistedUriPermissions()) ?? [];
    final currentOneWayDataSyncDir = await getExportDir();
    final Uri? newOneWayDataSyncDir;
    try {
      newOneWayDataSyncDir = await DocumentTreeBridge.instance
          .pickDocumentTree();
    } catch (e) {
      AppLogger.error(e, message: 'Failed to open document tree');
      throw ObtainiumError(tr('noFilePickerAvailable'));
    }
    if (newOneWayDataSyncDir == null) {
      return;
    }
    if (currentOneWayDataSyncDir?.path != newOneWayDataSyncDir.path) {
      unawaited(prefs?.setString('exportDir', newOneWayDataSyncDir.toString()));
      notifyListeners();
    }
    for (var e in existingSAFPerms) {
      if (e.uri != newOneWayDataSyncDir) {
        try {
          await saf.releasePersistableUriPermission(e.uri);
        } catch (err) {
          // The grant may have already been revoked (e.g. by the OS after an
          // app update); releasing it is best-effort cleanup only.
          AppLogger.error(
            err,
            message: 'Failed to release stale URI permission',
          );
        }
      }
    }
  }

  bool get autoExportOnChanges {
    return _getBool('autoExportOnChanges') ?? false;
  }

  set autoExportOnChanges(bool val) {
    prefs?.setBool('autoExportOnChanges', val);
    notifyListeners();
  }

  String? get autoExportFileName => getSettingString('autoExportFileName');

  set autoExportFileName(String? val) {
    final cleaned = val?.replaceAll(RegExp(r'[/\\:*?"<>|]'), '').trim();
    if (cleaned == null || cleaned.isEmpty) {
      prefs?.remove('autoExportFileName');
    } else {
      prefs?.setString('autoExportFileName', cleaned);
    }
    notifyListeners();
  }

  String? get globalApkFilterRegEx => getSettingString('globalApkFilterRegEx');

  set globalApkFilterRegEx(String? val) {
    final cleaned = val?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      prefs?.remove('globalApkFilterRegEx');
    } else {
      prefs?.setString('globalApkFilterRegEx', cleaned);
    }
    notifyListeners();
  }

  bool get onlyCheckInstalledOrTrackOnlyApps {
    return _getBool('onlyCheckInstalledOrTrackOnlyApps') ?? false;
  }

  set onlyCheckInstalledOrTrackOnlyApps(bool val) {
    prefs?.setBool('onlyCheckInstalledOrTrackOnlyApps', val);
    notifyListeners();
  }

  bool get collapseGroupsOnStartup {
    return _getBool('collapseGroupsOnStartup') ?? false;
  }

  set collapseGroupsOnStartup(bool val) {
    prefs?.setBool('collapseGroupsOnStartup', val);
    notifyListeners();
  }

  bool get skipBulkUpdateConfirmation {
    return _getBool('skipBulkUpdateConfirmation') ?? false;
  }

  set skipBulkUpdateConfirmation(bool val) {
    prefs?.setBool('skipBulkUpdateConfirmation', val);
    notifyListeners();
  }

  int get minimumUpdateAgeDays {
    return _getInt('minimumUpdateAgeDays') ?? 0;
  }

  set minimumUpdateAgeDays(int val) {
    prefs?.setInt('minimumUpdateAgeDays', val < 0 ? 0 : val);
    notifyListeners();
  }

  int get updateHealthStaleReleaseDays {
    return _getInt('updateHealthStaleReleaseDays') ?? 180;
  }

  set updateHealthStaleReleaseDays(int val) {
    prefs?.setInt('updateHealthStaleReleaseDays', val < 0 ? 0 : val);
    notifyListeners();
  }

  int get updateHealthStaleVersionDays {
    return _getInt('updateHealthStaleVersionDays') ?? 180;
  }

  set updateHealthStaleVersionDays(int val) {
    prefs?.setInt('updateHealthStaleVersionDays', val < 0 ? 0 : val);
    notifyListeners();
  }

  int get updateHealthFailedChecksCount {
    return _getInt('updateHealthFailedChecksCount') ?? 5;
  }

  set updateHealthFailedChecksCount(int val) {
    prefs?.setInt('updateHealthFailedChecksCount', val < 0 ? 0 : val);
    notifyListeners();
  }

  bool get updateHealthArchivedEnabled {
    return _getBool('updateHealthArchivedEnabled') ?? true;
  }

  set updateHealthArchivedEnabled(bool val) {
    prefs?.setBool('updateHealthArchivedEnabled', val);
    notifyListeners();
  }

  int get updateHealthFilteredReleasesCount {
    return _getInt('updateHealthFilteredReleasesCount') ?? 5;
  }

  set updateHealthFilteredReleasesCount(int val) {
    prefs?.setInt('updateHealthFilteredReleasesCount', val < 0 ? 0 : val);
    notifyListeners();
  }

  bool get showUpdateHealthIndicator {
    return _getBool('showUpdateHealthIndicator') ?? true;
  }

  set showUpdateHealthIndicator(bool val) {
    prefs?.setBool('showUpdateHealthIndicator', val);
    notifyListeners();
  }

  int get exportSettings {
    return _getInt('exportSettings') ?? 1;
  }

  set exportSettings(int val) {
    prefs?.setInt('exportSettings', val > 2 || val < 0 ? 1 : val);
    notifyListeners();
  }

  bool get exportInstalledOnly {
    return _getBool('exportInstalledOnly') ?? false;
  }

  set exportInstalledOnly(bool val) {
    prefs?.setBool('exportInstalledOnly', val);
    notifyListeners();
  }

  bool get parallelDownloads {
    return _getBool('parallelDownloads') ?? true;
  }

  set parallelDownloads(bool val) {
    prefs?.setBool('parallelDownloads', val);
    notifyListeners();
  }

  AppListDensity get appListDensity {
    final stored = _getString('appListDensity');
    if (stored != null && AppListDensity.values.any((d) => d.name == stored)) {
      return AppListDensity.values.byName(stored);
    }
    return AppListDensity.comfortable;
  }

  set appListDensity(AppListDensity val) {
    prefs?.setString('appListDensity', val.name);
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

  /// Warn (and require confirmation) when a downloaded APK's signing
  /// certificate differs from the installed app's certificate. User-provided
  /// expected hashes are enforced regardless of this setting.
  bool get verifySigningCertHashes {
    return _getBool('verifySigningCertHashes') ?? true;
  }

  set verifySigningCertHashes(bool val) {
    prefs?.setBool('verifySigningCertHashes', val);
    notifyListeners();
  }

  bool get shizukuPretendToBeGooglePlay {
    return _getBool('shizukuPretendToBeGooglePlay') ?? false;
  }

  set shizukuPretendToBeGooglePlay(bool val) {
    prefs?.setBool('shizukuPretendToBeGooglePlay', val);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Fork-only: Plus feature settings and forwarding getters.
  // ---------------------------------------------------------------------------

  void notifyPlusSettingsChanged() {
    notifyListeners();
  }

  bool get disablePageTransitions =>
      prefs?.safeBool('disablePageTransitions') ?? false;
  bool get reversePageTransitions =>
      prefs?.safeBool('reversePageTransitions') ?? false;

  String? get externalInstallerComponentForward {
    final str = prefs?.safeString('externalInstallerComponent');
    return str?.isNotEmpty == true ? str : null;
  }

  bool get shizukuFallbackToSystem =>
      prefs?.safeBool('shizukuFallbackToSystem') ?? true;
  set shizukuFallbackToSystem(bool val) {
    prefs?.setBool('shizukuFallbackToSystem', val);
    notifyListeners();
  }

  double get animationSpeedMultiplier =>
      prefs?.safeDouble('animationSpeedMultiplier') ?? 1.0;
  bool get enableContextualTips =>
      prefs?.safeBool('enableContextualTips') ?? false;
  set enableContextualTips(bool val) {
    prefs?.setBool('enableContextualTips', val);
    notifyListeners();
  }

  List<String> get dismissedTips =>
      prefs?.safeStringList('dismissedTips') ?? const [];
  void dismissTip(String id) {
    if (dismissedTips.contains(id)) return;
    prefs?.setStringList('dismissedTips', [...dismissedTips, id]);
    notifyListeners();
  }

  /// Brings back every dismissed tip, e.g. when tips are switched back on.
  void resetTips() {
    prefs?.remove('dismissedTips');
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

  int get updateCheckConcurrencyLimit =>
      (prefs?.safeInt('updateCheckConcurrencyLimit') ?? 3).clamp(1, 16);
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
