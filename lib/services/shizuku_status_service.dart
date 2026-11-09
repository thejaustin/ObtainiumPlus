import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/services/adb_port_prober.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

/// What the Shizuku/Dhizuku backend is doing right now, as seen by the
/// installer. Every screen that shows a Shizuku status reads this.
enum ShizukuServiceState {
  /// No Shizuku+, Shizuku or Dhizuku package installed.
  notInstalled,

  /// A provider is installed but its binder never answered.
  notRunning,

  /// The binder answered but this app is not authorized.
  permissionNeeded,

  /// The binder answered and the app may use it to install.
  active,
}

@immutable
class ShizukuStatusSnapshot {
  final ShizukuServiceState state;

  /// Exact package id of the installed provider (Shizuku+ preferred).
  final String? packageId;

  /// Raw plugin result (`granted_adb`, `services_not_found`, ...).
  final String? rawStatus;

  /// Round-trip of the probe that answered, when the binder answered.
  final int? latencyMs;

  /// Open ADB loopback port found while the binder was down.
  final int? activeLoopbackPort;

  final DateTime checkedAt;

  const ShizukuStatusSnapshot({
    required this.state,
    required this.checkedAt,
    this.packageId,
    this.rawStatus,
    this.latencyMs,
    this.activeLoopbackPort,
  });

  bool get isInstalled => state != ShizukuServiceState.notInstalled;
  bool get isActive => state == ShizukuServiceState.active;

  /// The binder answered at all (granted or not).
  bool get isBinderAlive =>
      state == ShizukuServiceState.active ||
      state == ShizukuServiceState.permissionNeeded;

  bool get isPlus => packageId == AppConstants.shizukuPlusId;
  bool get isDhizuku => packageId == AppConstants.dhizukuId;

  /// Dhizuku grants as device owner, not through a Shizuku binder.
  bool get isDhizukuGrant => rawStatus == 'granted_owner';

  /// User-facing provider name (never the package-style spelling).
  String get providerLabel {
    if (isDhizukuGrant || isDhizuku) return 'Dhizuku';
    if (isPlus) return 'Shizuku+';
    return 'Shizuku';
  }

  /// Bridges to the older info type the status card renders.
  ShizukuProviderInfo toProviderInfo() => ShizukuProviderInfo(
    packageId: packageId,
    providerLabel: providerLabel,
    isInstalled: isInstalled,
    isRunning: isBinderAlive,
    binderLatencyMs: latencyMs,
    activeLoopbackPort: activeLoopbackPort,
  );
}

/// Single source of truth for the Shizuku status shown in settings, the
/// installer picker and Service Doctor.
///
/// The plugin asks Shizuku for its binder asynchronously on first use, so
/// the first `checkPermission` of a process answers `services_not_found`
/// even while the server is running. Each screen used to make one unretried
/// probe of its own, so the screen that probed first (the installer picker)
/// showed "not running" while a later one (Service Doctor) showed "active".
/// This service applies the user's backend, retries past that warm-up, and
/// shares the answer through [status].
class ShizukuStatusService {
  ShizukuStatusService._();

  static ShizukuStatusService instance = ShizukuStatusService._();

  /// Fresh instance; for tests.
  @visibleForTesting
  static void resetForTest() => instance = ShizukuStatusService._();

  final ValueNotifier<ShizukuStatusSnapshot?> status = ValueNotifier(null);

  /// Replaces the installed-provider lookup; for tests.
  @visibleForTesting
  static Future<String?> Function()? installedPackageOverride;

  Future<ShizukuStatusSnapshot>? _inFlight;

  static const _retryDelaysMs = [50, 100, 150, 200, 300];
  static const _probeTimeout = Duration(seconds: 4);

  /// Re-probes unless a probe is already running, in which case its result
  /// is shared. [backendMode] is the `shizukuInstallerMode` setting
  /// (`auto`, `shizuku` or `dhizuku`).
  Future<ShizukuStatusSnapshot> refresh({String backendMode = 'auto'}) {
    return _inFlight ??= _probe(backendMode).whenComplete(() {
      _inFlight = null;
    });
  }

  /// [refresh] with the backend the user picked in settings.
  Future<ShizukuStatusSnapshot> refreshFrom(BuildContext context) {
    var mode = 'auto';
    try {
      mode = context.read<BehaviorSettingsProvider>().shizukuInstallerMode;
    } catch (_) {}
    return refresh(backendMode: mode);
  }

  Future<ShizukuStatusSnapshot> _probe(String backendMode) async {
    final pkg = await (installedPackageOverride ?? _installedProviderPackage)();
    if (pkg == null) {
      return _publish(
        ShizukuStatusSnapshot(
          state: ShizukuServiceState.notInstalled,
          checkedAt: DateTime.now(),
        ),
      );
    }

    try {
      await ShizukuApkInstaller().setInstallerMode(
        ShizukuInstaller.modeForSetting(backendMode),
      );
    } catch (_) {}

    String? raw;
    int? latency;
    var timedOut = false;
    for (var i = 0; i <= _retryDelaysMs.length; i++) {
      final sw = Stopwatch()..start();
      try {
        // A first-time Shizuku permission request blocks until the user
        // answers, so a passive refresh must not wait on it forever.
        raw = await ShizukuApkInstaller().checkPermission().timeout(
          _probeTimeout,
        );
      } on TimeoutException {
        // The binder answered with a permission prompt that is still open.
        // Retrying would stack more prompts; the service is running.
        timedOut = true;
        raw = null;
        break;
      } catch (_) {
        raw = null;
      }
      sw.stop();
      if (raw != null &&
          raw != 'services_not_found' &&
          raw != 'binder_not_found') {
        latency = sw.elapsedMilliseconds;
        break;
      }
      if (i < _retryDelaysMs.length) {
        await Future<void>.delayed(Duration(milliseconds: _retryDelaysMs[i]));
      }
    }

    final ShizukuServiceState state;
    if (raw != null &&
        (raw.startsWith('granted') || raw.startsWith('authorized'))) {
      state = ShizukuServiceState.active;
    } else if (timedOut ||
        raw == 'denied' ||
        raw == 'old_shizuku' ||
        raw == 'old_android_with_adb') {
      state = ShizukuServiceState.permissionNeeded;
    } else {
      state = ShizukuServiceState.notRunning;
    }

    int? port;
    if (state == ShizukuServiceState.notRunning) {
      try {
        port = await AdbPortProber.findActiveLoopbackPort();
      } catch (_) {}
    }

    return _publish(
      ShizukuStatusSnapshot(
        state: state,
        packageId: pkg,
        rawStatus: raw,
        latencyMs: latency,
        activeLoopbackPort: port,
        checkedAt: DateTime.now(),
      ),
    );
  }

  ShizukuStatusSnapshot _publish(ShizukuStatusSnapshot snap) {
    status.value = snap;
    return snap;
  }

  /// Exact-match lookup: `getInstalledInfo` falls back to package aliases,
  /// so asking for Shizuku+ can return stock Shizuku's info. Only trust the
  /// answer when the returned package is the one asked for.
  // One lookup shared with the install paths, so screens and installs can't
  // name different providers.
  static Future<String?> _installedProviderPackage() =>
      ShizukuInstaller.getInstalledShizukuPackageId();
}
