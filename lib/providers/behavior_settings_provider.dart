import 'package:obtainium/utils/safe_prefs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart' as saf;
import 'package:obtainium/models/settings_enums.dart';

class BehaviorSettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;

  Future<void> initializeSettings(SharedPreferences p) async {
    prefs = p;
    AppHaptics.enabled = enableHapticFeedback;
    notifyListeners();
  }

  bool get useShizuku {
    return prefs?.getBool('useShizuku') ?? false;
  }

  set useShizuku(bool useShizuku) {
    prefs?.setBool('useShizuku', useShizuku);
    notifyListeners();
  }

  Future<bool> getInstallPermission({bool enforce = false}) async {
    while (!(await Permission.requestInstallPackages.isGranted)) {
      talker.info(tr('pleaseAllowInstallPerm'));
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

  bool get removeOnExternalUninstall {
    return prefs?.getBool('removeOnExternalUninstall') ?? false;
  }

  set removeOnExternalUninstall(bool show) {
    prefs?.setBool('removeOnExternalUninstall', show);
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

  int get exportSettings {
    try {
      return prefs?.safeInt('exportSettings') ?? 1;
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
    return prefs?.getBool('parallelDownloads') ?? true;
  }

  set parallelDownloads(bool val) {
    prefs?.setBool('parallelDownloads', val);
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

  double get animationSpeedMultiplier {
    return prefs?.safeDouble('animationSpeedMultiplier') ?? 1.0;
  }

  set animationSpeedMultiplier(double multiplier) {
    prefs?.setDouble('animationSpeedMultiplier', multiplier);
    notifyListeners();
  }

  bool get highlightTouchTargets {
    return prefs?.getBool('highlightTouchTargets') ?? false;
  }

  set highlightTouchTargets(bool val) {
    prefs?.setBool('highlightTouchTargets', val);
    notifyListeners();
  }

  bool get enableHapticFeedback {
    return prefs?.getBool('enableHapticFeedback') ?? true;
  }

  set enableHapticFeedback(bool enabled) {
    prefs?.setBool('enableHapticFeedback', enabled);
    AppHaptics.enabled = enabled;
    notifyListeners();
  }

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

  AppSwipeAction get swipeRightAction =>
      AppSwipeAction.values[prefs?.safeInt('swipeRightAction') ??
          AppSwipeAction.update.index];
  set swipeRightAction(AppSwipeAction val) {
    prefs?.setInt('swipeRightAction', val.index);
    notifyListeners();
  }

  AppSwipeAction get swipeLeftAction =>
      AppSwipeAction.values[prefs?.safeInt('swipeLeftAction') ??
          AppSwipeAction.togglePin.index];
  set swipeLeftAction(AppSwipeAction val) {
    prefs?.setInt('swipeLeftAction', val.index);
    notifyListeners();
  }

  /// Preferred update source: 'direct', 'play_store', 'aurora'
  String get preferredUpdateSource {
    final val = prefs?.getString('preferredUpdateSource') ?? 'direct';
    // Migrate deprecated 'github' and 'apkpure' values to 'direct'.
    if (val == 'github' || val == 'apkpure') {
      prefs?.setString('preferredUpdateSource', 'direct');
      return 'direct';
    }
    return val;
  }

  set preferredUpdateSource(String val) {
    prefs?.setString('preferredUpdateSource', val);
    notifyListeners();
  }

  /// Allow third-party sources for updates
  bool get allowThirdPartySources {
    return prefs?.getBool('allowThirdPartySources') ?? true;
  }

  set allowThirdPartySources(bool val) {
    prefs?.setBool('allowThirdPartySources', val);
    notifyListeners();
  }

  /// Use app links for Google Play Store
  bool get usePlayStoreAppLinks {
    return prefs?.getBool('usePlayStoreAppLinks') ?? true;
  }

  set usePlayStoreAppLinks(bool val) {
    prefs?.setBool('usePlayStoreAppLinks', val);
    notifyListeners();
  }
}
