import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/custom_errors.dart';

import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/models/app_in_memory.dart';

import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/version_utils.dart';

class AppUpdateService {
  AppUpdateService._();

  static final Map<String, (App, DateTime)> _updateCache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  static void invalidateCache(String appId) {
    _updateCache.remove(appId);
  }

  static bool areVersionsDifferent(
    App app,
    String? installed,
    String latest, {
    bool ignoreOrdering = false,
  }) {
    if (installed == null)
      return false; // Not installed is not "different" for update purposes (usually handled separately)
    if (installed == latest) return false;
    final aggressive =
        app.additionalSettings['aggressiveVersionReconciliation'] == true ||
        AppConstants.plusAppIds.contains(app.id);
    final reconciliation = reconcileVersionDifferences(
      installed,
      latest,
      aggressive: aggressive,
    );
    if (reconciliation != null && reconciliation.key == true) {
      return false; // Reconciled as equal
    }

    // Best-effort downgrade guard: after a sideload/manual install the stored
    // latestVersion can lag behind the OS-reported installedVersion, and
    // offering it as an "update" just makes the installer throw a
    // DowngradeError. Only skip when the ordering is confidently known —
    // unknown (null) must fall through to the old behavior so apps with
    // unusual versioning schemes still get their updates offered.
    if (!ignoreOrdering) {
      final ordering = compareVersionStrings(installed, latest);
      if (ordering != null && ordering > 0) {
        _logDowngradeSuppression(app, installed, latest);
        return false;
      }
    }

    // Set ambiguous flag if they are likely identical but have different strings
    if (isLikelyIdentical(installed, latest)) {
      app.additionalSettings['isAmbiguousUpdate'] = true;
    } else {
      app.additionalSettings.remove('isAmbiguousUpdate');
    }

    return true;
  }

  // Downgrade suppressions already logged this session — areVersionsDifferent
  // runs inside list builders, so log each app/version pair only once.
  static final Set<String> _loggedDowngradeSuppressions = {};

  static void _logDowngradeSuppression(
    App app,
    String installed,
    String latest,
  ) {
    if (!_loggedDowngradeSuppressions.add('${app.id}|$installed|$latest')) {
      return;
    }
    // Guarded zone: logging is best-effort and must never break update
    // checks (LogsProvider needs sqflite, unavailable in unit tests).
    runZonedGuarded(() {
      LogsProvider().add(
        'Not offering $latest as an update for ${app.id}: '
        'installed version $installed appears newer',
        level: LogLevels.warning,
      );
    }, (_, __) {});
  }

  static bool isLikelyIdentical(String v1, String v2) {
    String n1 = normalizeVersion(v1).toLowerCase();
    String n2 = normalizeVersion(v2).toLowerCase();
    if (n1 == n2) return true;

    // Common noise suffixes
    final noise = RegExp(
      r'([-._](release|stable|plus|ose|shizukuplus|fork|latest|final|official))+$',
    );
    String sn1 = n1.replaceFirst(noise, '');
    String sn2 = n2.replaceFirst(noise, '');
    if (sn1 == sn2) return true;

    // Check if one is a version-code-like suffix of the other (e.g. 1.2.3+123 vs 1.2.3)
    final buildMetadata = RegExp(r'\+[0-9]+$');
    if (sn1.replaceFirst(buildMetadata, '') ==
        sn2.replaceFirst(buildMetadata, '')) {
      return true;
    }

    return false;
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
        return areVersionsDifferent(
              currentApp,
              currentApp.installedVersion,
              cachedApp.latestVersion,
            )
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

    return areVersionsDifferent(
          newApp,
          newApp.installedVersion,
          newApp.latestVersion,
        )
        ? newApp
        : null;
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

  static bool shouldSkipAppUpdate({
    required App app,
    required UpdateSettingsProvider updateSettings,
    required List<ConnectivityResult> netResult,
    bool isBackground = false,
  }) {
    // Collect all relevant rule keys for this app
    final List<String> ruleKeys = [];
    for (var cat in app.categories) {
      ruleKeys.add('cat_$cat');
    }
    for (var tag in app.tags) {
      ruleKeys.add('tag_$tag');
    }

    final rules = updateSettings.autoUpdateRules;
    final bool isWifi =
        netResult.contains(ConnectivityResult.wifi) ||
        netResult.contains(ConnectivityResult.ethernet);

    for (var key in ruleKeys) {
      final rule = rules[key];
      if (rule != null) {
        if (rule['disabled'] == true) {
          return true;
        }
        if (rule['wifiOnly'] == true && !isWifi) {
          return true;
        }
      }
    }
    return false;
  }

  static Future<List<App>> checkUpdates({
    required Map<String, AppInMemory> apps,
    required UpdateSettingsProvider updateSettings,
    required Function(String) checkUpdateFn,
    DateTime? ignoreAppsCheckedAfter,
    bool throwErrorsForRetry = false,
    List<String>? specificIds,
    bool gettingUpdates = false,
    Function(bool)? setGettingUpdates,
    bool ignoreCache = false,
    bool isBackground = false,
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
              updateSettings.onlyCheckInstalledOrTrackOnlyApps,
        );
        if (specificIds != null) {
          appIds = appIds.where((aId) => specificIds.contains(aId)).toList();
        }

        // --- Per-app/tag/category rule filtering ---
        final List<ConnectivityResult> netResult = await (Connectivity()
            .checkConnectivity());
        appIds.removeWhere((id) {
          final app = apps[id]?.app;
          if (app == null) return false;
          return shouldSkipAppUpdate(
            app: app,
            updateSettings: updateSettings,
            netResult: netResult,
            isBackground: isBackground,
          );
        });
        // ------------------------------------------

        final int maxConcurrency = 5;
        int index = 0;

        Future<void> worker() async {
          while (index < appIds.length) {
            final appId = appIds[index++];
            App? newApp;
            int retries = 3;
            while (retries >= 0) {
              try {
                newApp = await checkUpdateFn(appId);
                break;
              } catch (e, stackTrace) {
                final isNetworkError =
                    e is SocketException ||
                    e is TimeoutException ||
                    e.toString().toLowerCase().contains('clientexception') ||
                    e.toString().toLowerCase().contains('timeoutexception');
                if (retries > 0 && isNetworkError) {
                  retries--;
                  await Future.delayed(const Duration(seconds: 2));
                  continue;
                }
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
                break;
              }
            }
            if (newApp != null) {
              updates.add(newApp);
            }
          }
        }

        await Future.wait(List.generate(maxConcurrency, (_) => worker()));
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
    obt.additionalSettings['includePrereleases'] =
        settingsProvider.obtainiumReleaseChannel == 'dev';
    obt.additionalSettings['apkFilterRegEx'] = 'fdroid';
    obt.additionalSettings['invertAPKFilter'] = true;
    return checkUpdateFn(obtainiumId, ignoreCache: ignoreCache);
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
      if (areVersionsDifferent(app, app.installedVersion, app.latestVersion) &&
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
