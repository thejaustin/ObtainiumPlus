import 'dart:async';
import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
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

  static const int _maxRetries = 4;

  /// Performs a retried check for the Shizuku/ShizukuPlus binder service.
  /// Uses progressive backoff (50ms, 100ms, 150ms, 200ms) for fast (<100ms)
  /// connection when the daemon is alive.
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
        final delayMs = 50 * (i + 1);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    return status;
  }

  /// Measures Shizuku binder round-trip latency in milliseconds.
  /// Returns null if the binder is unavailable.
  static Future<int?> measureBinderLatencyMs() async {
    final sw = Stopwatch()..start();
    try {
      final status = await ShizukuApkInstaller().checkPermission()
          .timeout(const Duration(seconds: 3));
      sw.stop();
      if (status == null ||
          status == 'binder_not_found' ||
          status == 'services_not_found') {
        return null;
      }
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  /// Checks if ShizukuPlus (af.shizuku.plus.api), Dhizuku (bin.xposed.Dhizuku),
  /// or stock Shizuku (moe.shizuku.privileged.api) is installed.
  static Future<String?> getInstalledShizukuPackageId() async {
    try {
      final plus = await AppInstallService.getInstalledInfo(
        AppConstants.shizukuPlusId,
        printErr: false,
      );
      if (plus != null) return AppConstants.shizukuPlusId;
      final dhizuku = await AppInstallService.getInstalledInfo(
        'bin.xposed.Dhizuku',
        printErr: false,
      );
      if (dhizuku != null) return 'bin.xposed.Dhizuku';
      final stock = await AppInstallService.getInstalledInfo(
        'moe.shizuku.privileged.api',
        printErr: false,
      );
      if (stock != null) return 'moe.shizuku.privileged.api';
    } catch (_) {}
    return null;
  }

  /// Returns a friendly label for the active Shizuku provider
  /// ('ShizukuPlus', 'Dhizuku', or 'Shizuku').
  static Future<String> getShizukuProviderLabel() async {
    final pkg = await getInstalledShizukuPackageId();
    if (pkg == AppConstants.shizukuPlusId) return 'ShizukuPlus';
    if (pkg == 'bin.xposed.Dhizuku') return 'Dhizuku';
    return 'Shizuku';
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
    // --- Smart binder pre-check with system fallback ---
    // If the binder is unavailable and shizukuFallbackToSystem is enabled,
    // skip Shizuku entirely and use the session-based stock installer, which
    // still works silently when Obtainium is the installer package on Android 12+.
    final bool fallbackEnabled =
        installOptions['shizukuFallbackToSystem'] != false &&
        (settingsProvider.shizukuFallbackToSystem);
    if (fallbackEnabled) {
      final preCheckStatus = await ShizukuApkInstaller().checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      final binderAlive = preCheckStatus?.startsWith('authorized') == true ||
          preCheckStatus?.startsWith('granted') == true;
      if (!binderAlive) {
        // Binder is down — gracefully fall back to stock session installer
        final code = await AndroidPackageInstaller.installApk(
          apkFilePath: apkFilePaths.join(','),
        );
        return InstallResult.fromPlatformCode(code);
      }
    }

    final fakeInstallSource =
        installOptions['shizukuPretendToBeGooglePlay'] == true
        ? 'com.android.vending'
        : '';
    final uris = apkFilePaths.map((p) => File(p).uri.toString()).toList();

    final completer = Completer<InstallResult>();
    Timer? pollTimer;

    final int? targetVersionCode = installOptions['targetVersionCode'] as int?;
    final String? targetVersionName = installOptions['targetVersionName'] as String?;
    final int? existingVersionCode = installOptions['existingVersionCode'] as int?;
    final String? existingVersionName = installOptions['existingVersionName'] as String?;

    // Start fast concurrent package verification polling (every 350ms)
    // so we detect successful installation the instant the OS completes it,
    // avoiding Shizuku binder callback delays or freezes.
    int pollCount = 0;
    pollTimer = Timer.periodic(const Duration(milliseconds: 350), (t) async {
      pollCount++;
      if (completer.isCompleted) {
        t.cancel();
        return;
      }
      if (pollCount > 200) {
        t.cancel();
        return;
      }
      try {
        final info = await AppInstallService.getInstalledInfo(appId, printErr: false);
        if (info != null) {
          final currentCode = info.versionCode ?? 0;
          bool isSuccess = false;
          if (existingVersionCode == null || existingVersionCode == 0) {
            if (targetVersionCode != null && targetVersionCode > 0) {
              if (currentCode >= targetVersionCode) isSuccess = true;
            } else {
              isSuccess = true;
            }
          } else {
            if (targetVersionCode != null &&
                targetVersionCode > 0 &&
                targetVersionCode > existingVersionCode) {
              if (currentCode >= targetVersionCode) isSuccess = true;
            } else if (targetVersionName != null &&
                targetVersionName.isNotEmpty &&
                targetVersionName != existingVersionName) {
              if (info.versionName == targetVersionName) isSuccess = true;
            } else if (currentCode > existingVersionCode) {
              isSuccess = true;
            }
          }
          if (isSuccess && !completer.isCompleted) {
            t.cancel();
            completer.complete(InstallResult.success());
          }
        }
      } catch (_) {}
    });

    Future<int?> runShizuku() async {
      if (uris.length > 1) {
        return await ShizukuApkInstaller().installAABSplits(
          uris,
          fakeInstallSource,
        );
      } else {
        return await ShizukuApkInstaller().installAPK(
          uris.first,
          fakeInstallSource,
        );
      }
    }

    runShizuku().then((code) {
      if (!completer.isCompleted) {
        completer.complete(InstallResult.fromPlatformCode(code));
      }
    }).catchError((err) {
      if (!completer.isCompleted) {
        completer.complete(InstallResult.error(1));
      }
    });

    final res = await completer.future.timeout(
      const Duration(seconds: 75),
      onTimeout: () => InstallResult.error(1),
    );
    pollTimer.cancel();
    return res;
  }
}
