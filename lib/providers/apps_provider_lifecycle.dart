import 'dart:io';
import 'dart:typed_data';

import 'package:obtainium/core/logging/app_logger.dart';

// App icon-cache and version-detection helpers shared by AppsProvider.

/// Whether a cached app icon can be reused instead of re-reading it from the
/// platform.
///
/// An app's icon is packaged in its APK, so it can only change when the app is
/// updated. The cache is therefore only stale when the installed package's
/// [PackageInfo.lastUpdateTime] is newer than the cache file (or when
/// [ignoreCache] forces a refresh), keeping the relatively expensive
/// `getAppIcon` platform call off the hot path.
bool isIconCacheUsable({
  required bool cacheExists,
  required DateTime? cacheModified,
  int? packageLastUpdateTime,
  bool ignoreCache = false,
}) {
  if (ignoreCache || !cacheExists) {
    return false;
  }
  if (packageLastUpdateTime == null || cacheModified == null) {
    return true;
  }
  return cacheModified.millisecondsSinceEpoch >= packageLastUpdateTime;
}

Future<Uint8List?> loadAppIconSafely(
  Future<Uint8List?> Function()? load, {
  Uint8List? fallback,
}) async {
  if (load == null) return fallback;
  try {
    return await load();
  } catch (e) {
    AppLogger.warn('Failed to load app icon: $e', error: e);
    return fallback;
  }
}

Future<Uint8List?> readCachedAppIconSafely(File file) async {
  try {
    return await file.readAsBytes();
  } catch (e) {
    AppLogger.warn('Failed to read cached app icon: $e', error: e);
    return null;
  }
}

Future<void> writeCachedAppIconSafely(File file, Uint8List bytes) async {
  try {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  } catch (e) {
    AppLogger.warn('Failed to write cached app icon: $e', error: e);
  }
}

/// Whether install-status reconciliation should turn version detection off.
///
/// When the user opts into using the app's versionCode as the OS-detected
/// version, the tracked version and the OS value are intentionally different
/// formats; disabling version detection in that mode makes the per-app toggle
/// appear to reset. Leave the user's choice intact in that case.
bool shouldDisableVersionDetection({
  required bool installed,
  required bool versionDetectionIsStandard,
  required bool useVersionCodeAsOSVersion,
  required bool versionDetectionPossible,
}) =>
    installed &&
    versionDetectionIsStandard &&
    !useVersionCodeAsOSVersion &&
    !versionDetectionPossible;

/// Uses [bulk] when it contains [key], otherwise confirms with [lookup].
///
/// The bulk package list can be incomplete (for example when the platform
/// transaction is truncated), so a missing entry alone is not proof that an
/// app was uninstalled. A per-app lookup distinguishes the two cases.
Future<T?> resolveBulkOrLookup<T>(
  String key,
  Map<String, T> bulk, {
  required Future<T?> Function(String key) lookup,
}) async => bulk[key] ?? await lookup(key);

/// Whether load-time reconciliation should clear a recorded installed version.
///
/// A background load must not erase an explicit "Mark as updated" when the
/// package list is temporarily incomplete; the foreground load can confirm an
/// actual uninstall.
bool shouldClearInstalledVersion({
  required bool installedInfoMissing,
  required bool trackOnly,
  required bool isBackground,
  required bool versionDetectionIsStandard,
  required String? installedVersion,
  required String latestVersion,
}) {
  if (!installedInfoMissing || installedVersion == null || trackOnly) {
    return false;
  }
  if (isBackground &&
      !versionDetectionIsStandard &&
      installedVersion == latestVersion) {
    return false;
  }
  return true;
}
