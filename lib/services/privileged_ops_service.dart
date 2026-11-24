import 'package:flutter/services.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/core/logging/app_logger.dart';

/// Backends to try, in order, for a [PrivilegedBackend] preference. An empty
/// list means "use the plain Android path". Pure so the policy is testable.
List<String> privilegedCandidates(PrivilegedBackend pref) => switch (pref) {
  PrivilegedBackend.system => const [],
  PrivilegedBackend.auto => const ['shizuku', 'root'],
  PrivilegedBackend.shizuku => const ['shizuku'],
  PrivilegedBackend.root => const ['root'],
};

/// Default backend per operation. Uninstall stays on the system dialog (it is
/// destructive); the battery exemption only affects this app, so it is auto.
PrivilegedBackend privilegedDefault(PrivilegedOp op) =>
    op == PrivilegedOp.batteryWhitelist
    ? PrivilegedBackend.auto
    : PrivilegedBackend.system;

/// Runs system operations through Shizuku or root, as the user chose. The
/// native side only accepts a fixed allowlist of operations, so no shell text
/// ever crosses this channel.
class PrivilegedOps {
  PrivilegedOps._();

  static const MethodChannel _channel = MethodChannel(
    'dev.thejaustin.obtainiumplus/native',
  );

  /// Test hook: replaces the native call. Returns the result map.
  static Future<Map<Object?, Object?>?> Function(
    String op,
    String pkg,
    String backend,
  )?
  invokeOverride;

  /// Tries each backend allowed by [pref] for [op] on [pkg]. Returns true as
  /// soon as one succeeds; false means the caller should use the system path.
  static Future<bool> run(
    PrivilegedOp op,
    String pkg,
    PrivilegedBackend pref,
  ) async {
    for (final backend in privilegedCandidates(pref)) {
      try {
        final res = invokeOverride != null
            ? await invokeOverride!(op.name, pkg, backend)
            : await _channel
                  .invokeMapMethod<Object?, Object?>('runPrivilegedOp', {
                    'op': op.name,
                    'package': pkg,
                    'backend': backend,
                  })
                  .timeout(const Duration(seconds: 20));
        if (res?['ok'] == true) return true;
        AppLogger.debug(
          'PrivilegedOps ${op.name} via $backend: ${res?['status']}',
        );
      } catch (e) {
        AppLogger.debug('PrivilegedOps ${op.name} via $backend failed: $e');
      }
    }
    return false;
  }

  /// This app's own package id (debug and F-Droid builds add a suffix).
  static Future<String?> ownPackageId() async {
    try {
      return await _channel.invokeMethod<String>('getPackageName');
    } catch (_) {
      return null;
    }
  }
}
