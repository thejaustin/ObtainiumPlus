import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/version_service.dart' show isAppUpdateable;
import 'package:obtainium/utils/min_update_age.dart';

/// Stamps when [newApp]'s latest version changed. With the
/// `detectionDateAsReleaseDate` setting on, that time also stands in for the
/// release date when the source gives none (direct APK links, most HTML pages).
App recordLatestVersionChange(App currentApp, App newApp, {DateTime? now}) {
  final changedAt =
      newApp.latestVersion != currentApp.latestVersion ||
          currentApp.latestVersionChangedAt == null
      ? (now ?? DateTime.now())
      : currentApp.latestVersionChangedAt;
  return newApp.copyWith(
    latestVersionChangedAt: changedAt,
    releaseDate:
        newApp.releaseDate == null &&
            newApp.additionalSettings['detectionDateAsReleaseDate'] == true
        ? changedAt
        : newApp.releaseDate,
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
  Future<App?> fetchUpdate(String appId) async {
    final App? currentApp = apps[appId]?.app;
    // Pause update checks until the user resolves a pending repo rename.
    if (currentApp == null ||
        currentApp.disabled ||
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
  Future<App?> fetchUpdateWithHandshakeRetry(String appId) async {
    try {
      return await fetchUpdate(appId);
    } on HandshakeException {
      const maxRetries = 2;
      final rng = Random();
      for (var attempt = 0; attempt < maxRetries; attempt++) {
        await Future.delayed(Duration(milliseconds: 250 + rng.nextInt(501)));
        try {
          return await fetchUpdate(appId);
        } on HandshakeException {
          if (attempt == maxRetries - 1) rethrow;
        }
      }
      return null;
    }
  }

  /// Returns true when [newApp]'s release is newer than the configured
  /// minimum update age and should therefore be suppressed.
  Future<bool> _isReleaseYoungerThanMinAge(App currentApp, App newApp) async {
    if (newApp.latestVersion == currentApp.latestVersion) {
      return false;
    }
    final minAgeDays = await effectiveMinUpdateAgeDays(
      currentApp.additionalSettings,
      settingsProvider: settingsProvider,
    );
    return isReleaseTooYoung(newApp.releaseDate, minAgeDays);
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
