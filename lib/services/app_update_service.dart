import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:http/http.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_utils.dart';

import 'package:obtainium/utils/version_utils.dart';

class AppUpdateService {
  AppUpdateService._();

  static final Map<String, (App, DateTime)> _updateCache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  static bool _areVersionsDifferent(String? installed, String latest) {
    if (installed == null) return true;
    if (installed == latest) return false;
    final reconciliation = reconcileVersionDifferences(installed, latest);
    if (reconciliation != null && reconciliation.key == true) {
      return false; // Reconciled as equal
    }
    return true;
  }

  static Future<App?> checkUpdate(
    String appId,
    Map<String, AppInMemory> apps,
    Function(List<App>) saveApps, {
    bool ignoreCache = false,
  }) async {
    if (!apps.containsKey(appId)) {
      throw ObtainiumError(tr('appNotFound'));
    }
    App currentApp = apps[appId]!.app;

    if (!ignoreCache && _updateCache.containsKey(appId)) {
      var (cachedApp, timestamp) = _updateCache[appId]!;
      if (DateTime.now().difference(timestamp) < _cacheTtl) {
        return _areVersionsDifferent(currentApp.installedVersion, cachedApp.latestVersion)
            ? cachedApp
            : null;
      }
    }

    SourceProvider sourceProvider = SourceProvider();
    App newApp = await sourceProvider.getApp(
      sourceProvider.getSource(
        currentApp.url,
        overrideSource: currentApp.overrideSource,
      ),
      currentApp.url,
      currentApp.additionalSettings,
      currentApp: currentApp,
    );
    if (currentApp.preferredApkIndex < newApp.apkUrls.length) {
      newApp.preferredApkIndex = currentApp.preferredApkIndex;
    }
    // Ensure releaseDate is preserved from the source
    if (newApp.releaseDate == null && currentApp.releaseDate != null) {
      newApp.releaseDate = currentApp.releaseDate;
    }
    await saveApps([newApp]);

    // Update cache
    _updateCache[appId] = (newApp, DateTime.now());

    return _areVersionsDifferent(newApp.installedVersion, newApp.latestVersion) ? newApp : null;
  }

  static List<String> getAppsSortedByUpdateCheckTime(
    Map<String, AppInMemory> apps, {
    DateTime? ignoreAppsCheckedAfter,
    bool onlyCheckInstalledOrTrackOnlyApps = false,
  }) {
    List<String> appIds = apps.values
        .where(
          (app) =>
              app.app.lastUpdateCheck == null ||
              ignoreAppsCheckedAfter == null ||
              app.app.lastUpdateCheck!.isBefore(ignoreAppsCheckedAfter),
        )
        .where((app) {
          if (!onlyCheckInstalledOrTrackOnlyApps) {
            return true;
          } else {
            return app.app.installedVersion != null ||
                app.app.additionalSettings['trackOnly'] == true;
          }
        })
        .map((e) => e.app.id)
        .toList();
    appIds.sort(
      (a, b) =>
          (apps[a]!.app.lastUpdateCheck ??
                  DateTime.fromMicrosecondsSinceEpoch(0))
              .compareTo(
                apps[b]!.app.lastUpdateCheck ??
                    DateTime.fromMicrosecondsSinceEpoch(0),
              ),
    );
    return appIds;
  }

  static Future<List<App>> checkUpdates({
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required Function(String) checkUpdateFn,
    DateTime? ignoreAppsCheckedAfter,
    bool throwErrorsForRetry = false,
    List<String>? specificIds,
    bool gettingUpdates = false,
    Function(bool)? setGettingUpdates,
    bool ignoreCache = false,
  }) async {
    List<App> updates = [];
    MultiAppMultiError errors = MultiAppMultiError();
    if (!gettingUpdates) {
      setGettingUpdates?.call(true);
      try {
        List<String> appIds = getAppsSortedByUpdateCheckTime(
          apps,
          ignoreAppsCheckedAfter: ignoreAppsCheckedAfter,
          onlyCheckInstalledOrTrackOnlyApps:
              settingsProvider.onlyCheckInstalledOrTrackOnlyApps,
        );
        if (specificIds != null) {
          appIds = appIds.where((aId) => specificIds.contains(aId)).toList();
        }
        await Future.wait(
          appIds.map((appId) async {
            App? newApp;
            try {
              newApp = await checkUpdateFn(appId);
            } catch (e, stackTrace) {
              if ((e is RateLimitError || e is SocketException) &&
                  throwErrorsForRetry) {
                rethrow;
              }
              if (e is IDChangedError) {
                e.appId = appId;
              }
              if (e is DowngradeError && e.appId == null) {
                e.appId = appId;
              }
              if (e is InvalidURLError && e.appId == null) e.appId = appId;
              if (e is NoReleasesError && e.appId == null) e.appId = appId;
              if (e is NoAPKError && e.appId == null) e.appId = appId;
              if (e is NoVersionError && e.appId == null) e.appId = appId;
              // Safely get app name with null check
              final appName = apps[appId]?.name;
              errors.add(appId, e, appName: appName, stackTrace: stackTrace);
            }
            if (newApp != null) {
              updates.add(newApp);
            }
          }),
          eagerError: true,
        );
      } finally {
        setGettingUpdates?.call(false);
      }
    }
    if (errors.idsByErrorString.isNotEmpty) {
      var res = <String, dynamic>{};
      res['errors'] = errors;
      res['updates'] = updates;
      throw res;
    }
    return updates;
  }

  static Future<App?> checkObtainiumUpdate({
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required Future<App?> Function(String, {bool ignoreCache}) checkUpdateFn,
    bool ignoreCache = false,
  }) async {
    if (apps[obtainiumId] == null) return null;
    App obt = apps[obtainiumId]!.app;
    // Apply release channel setting
    obt.additionalSettings['includePrereleases'] = settingsProvider.obtainiumReleaseChannel == 'dev';
    obt.additionalSettings['apkFilterRegEx'] = 'fdroid';
    obt.additionalSettings['invertAPKFilter'] = true;
    return checkUpdateFn(obtainiumId);
  }

  static List<String> findExistingUpdates(
    Map<String, AppInMemory> apps, {
    bool installedOnly = false,
    bool nonInstalledOnly = false,
  }) {
    List<String> updateAppIds = [];
    List<String> appIds = apps.keys.toList();
    for (int i = 0; i < appIds.length; i++) {
      App? app = apps[appIds[i]]!.app;
      if (_areVersionsDifferent(app.installedVersion, app.latestVersion) &&
          (!installedOnly || !nonInstalledOnly)) {
        if ((app.installedVersion == null &&
                (nonInstalledOnly || !installedOnly) ||
            (app.installedVersion != null &&
                (installedOnly || !nonInstalledOnly)))) {
          updateAppIds.add(app.id);
        }
      }
    }
    return updateAppIds;
  }
}
