import 'dart:async';
import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/installers/installer.dart';
import 'package:obtainium/installers/install_landed.dart';
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

/// How many times to re-check a transiently unavailable Shizuku/Dhizuku binder
/// before reporting that the service is not running.
const int _permissionCheckAttempts = 4;

/// Delay between transient binder availability checks.
const Duration _permissionCheckRetryDelay = Duration(milliseconds: 500);

/// Installs via the Shizuku/Dhizuku/Sui binder API for elevated installs with
/// no user-facing permission dialog. Supports silent installs.
class ShizukuInstaller extends Installer {
  ShizukuInstaller(super.settingsProvider);

  /// Maps the `shizukuInstallerMode` setting to the plugin's backend mode.
  static InstallerMode modeForSetting(String setting) => switch (setting) {
    'shizuku' => InstallerMode.shizuku,
    'dhizuku' => InstallerMode.dhizuku,
    _ => InstallerMode.auto,
  };

  Future<void> _applyBackend() => ShizukuApkInstaller().setInstallerMode(
    modeForSetting(settingsProvider.shizukuInstallerMode),
  );

  @override
  String get modeKey => 'shizuku';

  @override
  Future<bool> canInstallSilently(App app) async => true;

  static const int _maxRetries = 4;

  /// Performs a retried check for the Shizuku/ShizukuPlus binder service.
  /// Uses progressive backoff (50ms, 100ms, 150ms, 200ms) for fast (<100ms)
  /// connection when the daemon is alive.
  Future<String?> checkPermissionWithRetry({int retries = _maxRetries}) async {
    // The background engine starts with a fresh plugin; check against the
    // backend the user chose (Shizuku or Dhizuku), not the default.
    try {
      await _applyBackend();
    } catch (_) {}
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
      final status = await ShizukuApkInstaller().checkPermission().timeout(
        const Duration(seconds: 3),
      );
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
      final status = await ShizukuApkInstaller().checkPermission().timeout(
        const Duration(milliseconds: 750),
      );
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
  static const int unknownInstallerErrorCode = -1000;

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
      case unknownInstallerErrorCode:
        return 'Unexpected installer error.';
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
    await _applyBackend();
    return (await ShizukuApkInstaller().checkPermission())?.startsWith(
          'granted',
        ) ??
        false;
  }

  @override
  Future<void> ensurePermission() async {
    String? result;
    for (var attempt = 0; attempt < _permissionCheckAttempts; attempt++) {
      await _applyBackend();
      result = await ShizukuApkInstaller().checkPermission();
      if (result != 'services_not_found' ||
          attempt == _permissionCheckAttempts - 1) {
        break;
      }
      await Future<void>.delayed(_permissionCheckRetryDelay);
    }
    switch (result) {
      case 'granted_owner':
      case 'granted_root':
      case 'granted_adb':
        break;
      case 'services_not_found':
        throw ObtainiumError(tr('shizukuBinderNotFound'));
      case 'old_shizuku':
        throw ObtainiumError(tr('shizukuOld'));
      case 'old_android_with_adb':
        throw ObtainiumError(tr('shizukuOldAndroidWithADB'));
      case 'denied':
        throw ObtainiumError(tr('cancelled'));
      default:
        throw ObtainiumError(tr('cancelled'));
    }
  }

  /// Shizuku providers host the binder we install through, so installing one
  /// restarts it mid-install.
  static const Set<String> providerPackages = {
    AppConstants.shizukuPlusId,
    AppConstants.shizukuStockId,
    AppConstants.dhizukuId,
  };

  /// Neither the Shizuku result nor package polling confirmed the install in
  /// time. Distinct from PackageInstaller codes so callers don't start a
  /// second install while this one may still finish.
  static const int confirmationTimeoutCode = -1001;

  @override
  Future<InstallResult> installApk(
    List<String> apkFilePaths, {
    required String appId,
    Map<String, dynamic> installOptions = const {},
  }) async {
    await _applyBackend();
    final stopwatch = Stopwatch()..start();
    // A suspended daemon would only fail later; report it up front so the
    // caller can use the system installer (if the fallback setting allows).
    // Retried: a just-started binder often misses the first ping.
    final preCheckStatus = await checkPermissionWithRetry();
    final binderAlive =
        preCheckStatus?.startsWith('authorized') == true ||
        preCheckStatus?.startsWith('granted') == true;
    if (!binderAlive) {
      ShizukuTelemetryService.instance.log(
        action: 'binderUnavailable',
        targetPackage: appId,
        durationMs: stopwatch.elapsedMilliseconds,
        status: 'stopped',
        details: 'Shizuku not ready ($preCheckStatus)',
      );
      throw ShizukuUnavailableError(preCheckStatus);
    }

    final fakeInstallSource =
        installOptions['shizukuPretendToBeGooglePlay'] == true
        ? 'com.android.vending'
        : '';
    final uris = apkFilePaths.map((p) => File(p).uri.toString()).toList();

    final completer = Completer<InstallResult>();

    final int? targetVersionCode = installOptions['targetVersionCode'] as int?;
    final String? targetVersionName =
        installOptions['targetVersionName'] as String?;
    final int? existingVersionCode =
        installOptions['existingVersionCode'] as int?;
    final String? existingVersionName =
        installOptions['existingVersionName'] as String?;
    final bool wasInstalled =
        installOptions['wasInstalled'] as bool? ??
        (existingVersionCode != null || existingVersionName != null);
    final int? existingUpdateTime =
        installOptions['existingUpdateTime'] as int?;

    Future<bool> landed() async {
      final info = await AppInstallService.getInstalledInfo(
        appId,
        printErr: false,
      );
      return info != null &&
          hasInstallLanded(
            wasInstalled: wasInstalled,
            existingCode: existingVersionCode,
            existingName: existingVersionName,
            existingUpdateTime: existingUpdateTime,
            targetCode: targetVersionCode,
            targetName: targetVersionName,
            currentCode: info.versionCode,
            currentName: info.versionName,
            currentUpdateTime: info.lastUpdateTime,
          );
    }

    // Concurrent package-verification polling.
    // Adaptive interval: 350ms for the first 10s, then every ~3rd tick (~1050ms)
    // to reduce package manager pressure during longer installs.
    int pollTick = 0;
    final pollTimer = Timer.periodic(const Duration(milliseconds: 350), (
      t,
    ) async {
      pollTick++;
      if (completer.isCompleted) {
        t.cancel();
        return;
      }
      if (stopwatch.elapsedMilliseconds > 10000 && pollTick % 3 != 0) return;
      try {
        if (await landed() && !completer.isCompleted) {
          t.cancel();
          completer.complete(InstallResult.success());
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

    // A binder error doesn't mean the install failed: updating a Shizuku
    // provider restarts the binder mid-install. Let polling look a little
    // longer before reporting failure (and triggering a fallback install).
    final graceAfterError = providerPackages.contains(appId)
        ? const Duration(seconds: 15)
        : const Duration(seconds: 3);
    Timer? graceTimer;

    // Fire Shizuku install with a 30s binder-hang guard. A hung binder callback
    // is the primary cause of the indefinite spinner — detect it early, log it,
    // and let polling continue detecting success in the background.
    runShizuku()
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            ShizukuTelemetryService.instance.log(
              action: 'binderHang',
              targetPackage: appId,
              durationMs: stopwatch.elapsedMilliseconds,
              status: 'hang',
              details: 'Shizuku callback silent for 30s; polling continues',
            );
            return null; // Don't resolve completer — polling or overall timeout handles it
          },
        )
        .then((code) {
          if (code != null && !completer.isCompleted) {
            completer.complete(InstallResult.fromPlatformCode(code));
          }
        })
        .catchError((Object err) {
          graceTimer = Timer(graceAfterError, () {
            if (!completer.isCompleted) {
              // Not a PackageInstaller status: use a distinct unknown code.
              completer.complete(
                InstallResult.error(unknownInstallerErrorCode),
              );
            }
          });
        });

    // 90s ceiling: 30s binder hang detection + 60s polling window after.
    // One last look before giving up, since polling slows down near the end.
    final res = await completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () async => await landed().catchError((Object _) => false)
          ? InstallResult.success()
          : InstallResult.error(confirmationTimeoutCode),
    );
    pollTimer.cancel();
    graceTimer?.cancel();
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
        : (res.errorCode == confirmationTimeoutCode
              ? 'No confirmation from Shizuku or the package manager in 90s'
              : res.errorCode != null
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

/// The Shizuku/Dhizuku binder isn't running or permission isn't granted.
class ShizukuUnavailableError implements Exception {
  final String? status;
  const ShizukuUnavailableError(this.status);

  @override
  String toString() => 'Shizuku unavailable ($status)';
}
