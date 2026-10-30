import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/version_service.dart' show isAppUpdateable;

/// Stamps when [newApp]'s latest version changed. With the
/// `detectionDateAsReleaseDate` setting on, that time also stands in for the
/// release date when the source gives none (direct APK links, most HTML pages).
App recordLatestVersionChange(App currentApp, App newApp, {DateTime? now}) {
  final versionChanged = newApp.latestVersion != currentApp.latestVersion;
  final firstObservation = currentApp.latestVersionChangedAt == null;
  final changedAt = versionChanged || firstObservation
      ? (now ?? DateTime.now())
      : currentApp.latestVersionChangedAt;
  // Only date a version by when it was found if it actually appeared while
  // tracked (or was already dated that way): the first check after adding an
  // app, or turning the setting on, must not invent a release date.
  final useDetectionDate =
      newApp.releaseDate == null &&
      newApp.additionalSettings['detectionDateAsReleaseDate'] == true &&
      (versionChanged || currentApp.releaseDate != null);
  return newApp.copyWith(
    latestVersionChangedAt: changedAt,
    releaseDate: useDetectionDate ? changedAt : newApp.releaseDate,
  );
}

/// Update checking and pending-update bookkeeping for [AppsProvider].
extension AppsProviderUpdates on AppsProvider {
  /// Fetches the latest [App] metadata from its source WITHOUT persisting it.
  /// Returns null if the app is missing or has a pending repo rename.
  ///
  /// Keeping fetch and save separate lets [checkUpdates] batch many checks into
  /// a few [saveApps] calls instead of saving (and triggering a full UI
  /// rebuild) once per app.
  ///
  /// Disabled apps are skipped unless [includeDisabled] (single-app refreshes,
  /// e.g. before a manual download, still need fresh metadata).
  Future<App?> fetchUpdate(String appId, {bool includeDisabled = false}) async {
    final App? currentApp = apps[appId]?.app;
    // Pause update checks until the user resolves a pending repo rename.
    if (currentApp == null ||
        (currentApp.disabled && !includeDisabled) ||
        currentApp.hasPendingRepoRename) {
      return null;
    }
    final SourceProvider sourceProvider = SourceProvider();
    App newApp = await sourceProvider.getApp(
      sourceProvider.getSource(
        currentApp.url,
        overrideSource: currentApp.overrideSource,
      ),
      currentApp.url,
      currentApp.additionalSettings,
      currentApp: currentApp,
    );
    // newApp is fresh from getApp() so direct mutation is safe and avoids a
    // copyWith() call that copies all list fields just to change one integer.
    if (currentApp.preferredApkIndex < newApp.apkUrls.length) {
      newApp.preferredApkIndex = currentApp.preferredApkIndex;
    } else if (newApp.apkUrls.isNotEmpty) {
      newApp.preferredApkIndex = 0;
    }
    return recordLatestVersionChange(
      currentApp,
      newApp.copyWith(consecutiveFailedChecks: 0),
    );
  }

  /// Fetches [appId] with a short retry for transient TLS handshake failures.
  ///
  /// Concurrent TLS handshakes to the same host can fail on certain
  /// devices/networks. Retry up to 2 times with staggered random delays to
  /// avoid all retries colliding. Any error that is not a handshake failure
  /// (including one raised by a retry) propagates to the caller so it can take
  /// the normal per-app error path instead of aborting the whole batch.
  Future<App?> fetchUpdateWithHandshakeRetry(
    String appId, {
    bool includeDisabled = false,
  }) async {
    try {
      return await fetchUpdate(appId, includeDisabled: includeDisabled);
    } on HandshakeException {
      const maxRetries = 2;
      final rng = Random();
      for (var attempt = 0; attempt < maxRetries; attempt++) {
        await Future.delayed(Duration(milliseconds: 250 + rng.nextInt(501)));
        try {
          return await fetchUpdate(appId, includeDisabled: includeDisabled);
        } on HandshakeException {
          if (attempt == maxRetries - 1) rethrow;
        }
      }
      return null;
    }
  }

  /// Finds app IDs whose installed version differs from the latest version, with optional filtering.
  List<String> findAppIdsWithPendingUpdates({
    bool installedOnly = false,
    bool nonInstalledOnly = false,
  }) {
    final List<String> updateAppIds = [];
    for (final appId in apps.keys) {
      final app = apps[appId]!.app;
      if (app.disabled) continue;
      final installed = app.installedVersion;
      if (installedOnly) {
        if (installed == null) continue;
      } else if (nonInstalledOnly) {
        if (installed == null) updateAppIds.add(app.id);
        continue;
      }
      if (installed == null ||
          (_installedVersionDiffers(app, installed) &&
              isAppUpdateable(app, settingsProvider))) {
        updateAppIds.add(app.id);
      }
    }
    return updateAppIds;
  }

  /// Whether [installed] differs from the app's latest version, either
  /// directly or after extracting the app's `versionExtractionRegEx` portion.
  bool _installedVersionDiffers(App app, String installed) {
    final regex =
        (app.additionalSettings['versionExtractionRegEx'] as String?) ?? '';
    return regex.isEmpty
        ? installed != app.latestVersion
        : !doStringsMatchUnderRegEx(regex, installed, app.latestVersion);
  }
}
