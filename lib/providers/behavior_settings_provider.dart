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
    return prefs?.safeBool('useShizuku') ?? false;
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
    return prefs?.safeBool('removeOnExternalUninstall') ?? false;
  }

  set removeOnExternalUninstall(bool show) {
    prefs?.setBool('removeOnExternalUninstall', show);
    notifyListeners();
  }

  bool get disablePageTransitions {
    return prefs?.safeBool('disablePageTransitions') ?? false;
  }

  set disablePageTransitions(bool show) {
    prefs?.setBool('disablePageTransitions', show);
    notifyListeners();
  }

  bool get reversePageTransitions {
    return prefs?.safeBool('reversePageTransitions') ?? false;
  }

  set reversePageTransitions(bool show) {
    prefs?.setBool('reversePageTransitions', show);
    notifyListeners();
  }

  Future<Uri?> getExportDir() async {
    var uriString = prefs?.safeString('exportDir');
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
    return prefs?.safeBool('autoExportOnChanges') ?? false;
  }

  set autoExportOnChanges(bool val) {
    prefs?.setBool('autoExportOnChanges', val);
    notifyListeners();
  }

  int get exportSettings {
    try {
      return prefs?.safeInt('exportSettings') ?? 1;
    } catch (e) {
      var val = prefs?.safeBool('exportSettings') == true ? 1 : 0;
      prefs?.setInt('exportSettings', val);
      return val;
    }
  }

  set exportSettings(int val) {
    prefs?.setInt('exportSettings', val > 2 || val < 0 ? 1 : val);
    notifyListeners();
  }

  bool get parallelDownloads {
    return prefs?.safeBool('parallelDownloads') ?? true;
  }

  set parallelDownloads(bool val) {
    prefs?.setBool('parallelDownloads', val);
    notifyListeners();
  }

  bool get beforeNewInstallsShareToAppVerifier {
    return prefs?.safeBool('beforeNewInstallsShareToAppVerifier') ?? true;
  }

  set beforeNewInstallsShareToAppVerifier(bool val) {
    prefs?.setBool('beforeNewInstallsShareToAppVerifier', val);
    notifyListeners();
  }

  bool get shizukuPretendToBeGooglePlay {
    return prefs?.safeBool('shizukuPretendToBeGooglePlay') ?? false;
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
    return prefs?.safeBool('highlightTouchTargets') ?? false;
  }

  set highlightTouchTargets(bool val) {
    prefs?.setBool('highlightTouchTargets', val);
    notifyListeners();
  }

  bool get enableHapticFeedback {
    return prefs?.safeBool('enableHapticFeedback') ?? true;
  }

  set enableHapticFeedback(bool enabled) {
    prefs?.setBool('enableHapticFeedback', enabled);
    AppHaptics.enabled = enabled;
    notifyListeners();
  }

  bool get enableSwipeGestures {
    return prefs?.safeBool('enableSwipeGestures') ?? true;
  }

  set enableSwipeGestures(bool enabled) {
    prefs?.setBool('enableSwipeGestures', enabled);
    notifyListeners();
  }

  bool get enableUndoForAppRemoval {
    return prefs?.safeBool('enableUndoForAppRemoval') ?? true;
  }

  set enableUndoForAppRemoval(bool enabled) {
    prefs?.setBool('enableUndoForAppRemoval', enabled);
    notifyListeners();
  }

  AppSwipeAction get swipeRightAction =>
      prefs?.safeEnum('swipeRightAction', AppSwipeAction.values) ??
      AppSwipeAction.update;
  set swipeRightAction(AppSwipeAction val) {
    prefs?.setInt('swipeRightAction', val.index);
    notifyListeners();
  }

  AppSwipeAction get swipeLeftAction =>
      prefs?.safeEnum('swipeLeftAction', AppSwipeAction.values) ??
      AppSwipeAction.togglePin;
  set swipeLeftAction(AppSwipeAction val) {
    prefs?.setInt('swipeLeftAction', val.index);
    notifyListeners();
  }

  /// Preferred update source: 'direct', 'play_store', 'aurora'
  String get preferredUpdateSource {
    final val = prefs?.safeString('preferredUpdateSource') ?? 'direct';
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
    return prefs?.safeBool('allowThirdPartySources') ?? true;
  }

  set allowThirdPartySources(bool val) {
    prefs?.setBool('allowThirdPartySources', val);
    notifyListeners();
  }

  /// Use app links for Google Play Store
  bool get usePlayStoreAppLinks {
    return prefs?.safeBool('usePlayStoreAppLinks') ?? true;
  }

  set usePlayStoreAppLinks(bool val) {
    prefs?.setBool('usePlayStoreAppLinks', val);
    notifyListeners();
  }
}
