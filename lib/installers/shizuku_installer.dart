import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/installers/installer.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

/// Installs via the Shizuku/Dhizuku/Sui binder API for elevated installs with
/// no user-facing permission dialog. Supports silent installs.
class ShizukuInstaller extends Installer {
  ShizukuInstaller(super.settingsProvider);

  @override
  String get modeKey => 'shizuku';

  @override
  Future<bool> canInstallSilently(App app) async => true;

  static const int _maxRetries = 3;
  static const Duration _retryInterval = Duration(milliseconds: 200);

  /// Performs a retried check for the Shizuku/ShizukuPlus binder service.
  /// When an app starts up or runs in the background, the binder listener
  /// may take a few hundred milliseconds to attach. Retrying prevents spurious
  /// 'binder_not_found' / 'services_not_found' false-negatives.
  Future<String?> checkPermissionWithRetry({int retries = _maxRetries}) async {
    String? status;
    for (int i = 0; i <= retries; i++) {
      try {
        status = await ShizukuApkInstaller().checkPermission();
        if (status != null &&
            status != 'services_not_found' &&
            status != 'binder_not_found') {
          return status;
        }
      } catch (_) {
        // Ignore transient error and retry
      }
      if (i < retries) {
        await Future.delayed(_retryInterval);
      }
    }
    return status;
  }

  /// Checks if either ShizukuPlus (af.shizuku.plus.api) or stock Shizuku
  /// (moe.shizuku.privileged.api) is installed.
  static Future<String?> getInstalledShizukuPackageId() async {
    try {
      final plus = await AppInstallService.getInstalledInfo(
        AppConstants.shizukuPlusId,
        printErr: false,
      );
      if (plus != null) return AppConstants.shizukuPlusId;
      final stock = await AppInstallService.getInstalledInfo(
        'moe.shizuku.privileged.api',
        printErr: false,
      );
      if (stock != null) return 'moe.shizuku.privileged.api';
    } catch (_) {}
    return null;
  }

  /// Launches whichever Shizuku manager is installed (prioritizing ShizukuPlus).
  static Future<void> openShizukuManager() async {
    final pkg = await getInstalledShizukuPackageId();
    if (pkg != null) {
      await AppInstallService.openApp(pkg);
    }
  }

  @override
  Future<bool> checkPermission() async {
    final status = await checkPermissionWithRetry();
    return status?.startsWith('granted') == true ||
        status?.startsWith('authorized') == true;
  }

  @override
  Future<void> ensurePermission() async {
    final status = await checkPermissionWithRetry();
    if (status?.startsWith('granted') == true ||
        status?.startsWith('authorized') == true) {
      return;
    }
    final pkg = await getInstalledShizukuPackageId();
    if (pkg == null) {
      throw ObtainiumError(tr('shizukuNotInstalled'));
    }
    final isPlus = pkg == AppConstants.shizukuPlusId;
    switch (status) {
      case 'services_not_found':
      case 'binder_not_found':
      case null:
        throw ObtainiumError(
          isPlus
              ? tr('shizukuPlusServiceStopped')
              : tr('shizukuBinderNotFound'),
        );
      case 'old_shizuku':
        throw ObtainiumError(tr('shizukuOld'));
      case 'old_android_with_adb':
        throw ObtainiumError(tr('shizukuOldAndroidWithADB'));
      case 'denied':
        throw ObtainiumError(tr('shizukuPermissionDenied'));
      default:
        throw ObtainiumError(tr('shizukuBinderNotFound'));
    }
  }

  @override
  Future<InstallResult> installApk(
    List<String> apkFilePaths, {
    required String appId,
    Map<String, dynamic> installOptions = const {},
  }) async {
    final fakeInstallSource =
        installOptions['shizukuPretendToBeGooglePlay'] == true
        ? 'com.android.vending'
        : '';
    final uris = apkFilePaths.map((p) => File(p).uri.toString()).toList();
    int? code;
    if (uris.length > 1) {
      code = await ShizukuApkInstaller().installAABSplits(
        uris,
        fakeInstallSource,
      );
    } else {
      code = await ShizukuApkInstaller().installAPK(
        uris.first,
        fakeInstallSource,
      );
    }
    return InstallResult.fromPlatformCode(code);
  }
}
