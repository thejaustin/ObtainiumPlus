import 'dart:async';
import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/installers/installer.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/adb_port_prober.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/shizuku_telemetry_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

/// Comprehensive snapshot of the active Shizuku service and provider on device.
class ShizukuProviderInfo {
  final String? packageId;
  final String providerLabel;
  final bool isInstalled;
  final bool isRunning;
  final int? binderLatencyMs;
  final int? activeLoopbackPort;

  const ShizukuProviderInfo({
    this.packageId,
    required this.providerLabel,
    required this.isInstalled,
    required this.isRunning,
    this.binderLatencyMs,
    this.activeLoopbackPort,
  });

  bool get isPlus => packageId == AppConstants.shizukuPlusId;
  bool get hasActiveLoopback => activeLoopbackPort != null;
}

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
        ShizukuTelemetryService.instance.log(
          action: 'measureLatency',
          durationMs: sw.elapsedMilliseconds,
          status: 'stopped',
          details: 'Binder unavailable ($status)',
        );
        return null;
      }
      final latency = sw.elapsedMilliseconds;
      ShizukuTelemetryService.instance.log(
        action: 'measureLatency',
        durationMs: latency,
        latencyMs: latency,
        status: 'success',
        details: 'Binder response in ${latency}ms',
      );
      return latency;
    } catch (e) {
      sw.stop();
      ShizukuTelemetryService.instance.log(
        action: 'measureLatency',
        durationMs: sw.elapsedMilliseconds,
        status: 'error',
        details: '$e',
      );
      return null;
    }
  }

  /// Fast pre-flight check to determine if the Shizuku daemon is actively responding.
  static Future<bool> isServiceReady() async {
    try {
      final status = await ShizukuApkInstaller()
          .checkPermission()
          .timeout(const Duration(milliseconds: 750));
      return status?.startsWith('authorized') == true ||
          status?.startsWith('granted') == true;
    } catch (_) {
      return false;
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

  /// Returns a rich diagnostic snapshot of the Shizuku provider and service.
  static Future<ShizukuProviderInfo> getDetailedProviderInfo() async {
    final pkg = await getInstalledShizukuPackageId();
    final isInstalled = pkg != null;
    bool isRunning = false;
    int? latency;
    int? activePort;

    if (isInstalled) {
      latency = await measureBinderLatencyMs();
      isRunning = latency != null;
      if (!isRunning) {
        // Probe local ADB loopback to see if port 5555 is open
        activePort = await AdbPortProber.findActiveLoopbackPort();
      }
    }

    String label = 'Shizuku';
    if (pkg == AppConstants.shizukuPlusId) {
      label = 'ShizukuPlus';
    } else if (pkg == 'bin.xposed.Dhizuku') {
      label = 'Dhizuku';
    }

    return ShizukuProviderInfo(
      packageId: pkg,
      providerLabel: label,
      isInstalled: isInstalled,
      isRunning: isRunning,
      binderLatencyMs: latency,
      activeLoopbackPort: activePort,
    );
  }

  /// Returns true if the status code indicates installation was blocked by
  /// Samsung Auto Blocker or enterprise Device Policy.
  static bool isBlockedByAutoBlocker(int code) => code == -21 || code == 21;

  /// Translates raw Android PackageInstaller status codes into actionable diagnostic messages.
  static String getDiagnosticMessageForErrorCode(int code) {
    switch (code) {
      case -21:
      case 21:
        return 'Installation blocked by system policy (e.g. Samsung One UI Auto Blocker). Disable Auto Blocker or exempt ObtainiumPlus.';
      case -1:
      case 1:
        return 'Signature conflict or downgrade disallowed. An existing version with conflicting keys is installed.';
      case -2:
      case 2:
        return 'Package parsing error. The APK file may be corrupted, truncated, or incomplete.';
      case -3:
      case 3:
        return 'Insufficient device storage. Free up internal storage to proceed.';
      case -7:
      case 7:
        return 'Incompatible device architecture (ABI) or minimum SDK requirement not met.';
      case -4:
      case 4:
        return 'Package installer session became invalid or expired.';
      default:
        return 'Package installation failed with status code $code.';
    }
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
    final stopwatch = Stopwatch()..start();
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
        stopwatch.stop();
        final res = InstallResult.fromPlatformCode(code);
        ShizukuTelemetryService.instance.log(
          action: 'systemFallback',
          targetPackage: appId,
          durationMs: stopwatch.elapsedMilliseconds,
          status: res.isSuccess ? 'success' : 'error',
          details: 'Shizuku daemon suspended; fell back to stock installer (code $code)',
        );
        return res;
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
    stopwatch.stop();

    // Log telemetry for this install
    final actionName = uris.length > 1 ? 'installAABSplits' : 'installAPK';
    final statusStr = res.isSuccess
        ? 'success'
        : (isBlockedByAutoBlocker(res.errorCode ?? 0)
            ? 'blocked'
            : (res.isCancelled ? 'cancelled' : 'error'));
    final detailsMsg = res.isSuccess
        ? 'Successfully committed via Shizuku binder'
        : (res.errorCode != null
            ? getDiagnosticMessageForErrorCode(res.errorCode!)
            : 'Outcome: ${res.outcome}');

    ShizukuTelemetryService.instance.log(
      action: actionName,
      targetPackage: appId,
      durationMs: stopwatch.elapsedMilliseconds,
      status: statusStr,
      details: detailsMsg,
    );

    return res;
  }
}
