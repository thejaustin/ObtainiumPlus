import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/custom_errors.dart';

import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/models/app_in_memory.dart';

import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/services/version_ordering.dart';
import 'package:obtainium/utils/version_utils.dart';

class AppUpdateService {
  AppUpdateService._();

  static final Map<String, (App, DateTime)> _updateCache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  static void invalidateCache(String appId) {
    _updateCache.remove(appId);
  }

  /// Whether a check that turned [previous] into [fetched] found an update
  /// worth reporting (notification, auto-install, "updates found"). For an
  /// installed app the new latest version must also pass the downgrade guard,
  /// so an older release re-surfacing isn't announced or installed.
  static bool isNewlyFoundUpdate(App previous, App fetched) {
    if (fetched.latestVersion == previous.latestVersion) return false;
    final installed = fetched.installedVersion;
    if (installed == null || fetched.additionalSettings['trackOnly'] == true) {
      return true;
    }
    return areVersionsDifferent(fetched, installed, fetched.latestVersion);
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
      // Version strings first, then numeric cores, then the release
      // timeline; see resolveVersionOrdering.
      final ordering = resolveVersionOrdering(app, installed, latest);
      if (ordering.isDowngrade) {
        _logDowngradeSuppression(app, installed, latest, ordering.basis);
        return false;
      }
    }

    // Set ambiguous flag if they are likely identical but have different
    // strings. Only write on a change: this runs inside list builders.
    if (isLikelyIdentical(installed, latest)) {
      if (app.additionalSettings['isAmbiguousUpdate'] != true) {
        app.additionalSettings['isAmbiguousUpdate'] = true;
      }
    } else if (app.additionalSettings.containsKey('isAmbiguousUpdate')) {
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
    VersionOrderBasis basis,
  ) {
    if (!_loggedDowngradeSuppressions.add('${app.id}|$installed|$latest')) {
      return;
    }
    // Guarded zone: logging is best-effort and must never break update
    // checks (LogsProvider needs sqflite, unavailable in unit tests).
    runZonedGuarded(() {
      LogsProvider().add(
        'Not offering $latest as an update for ${app.id}: '
        'installed version $installed appears newer (by ${basis.name})',
        level: LogLevel.warning,
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
    Set<String> excludedCategories = const {},
  }) {
    List<String> appIds = apps.values
        .where((app) => !app.app.disabled)
        .where(
          (app) =>
              excludedCategories.isEmpty ||
              !app.app.categories.any(excludedCategories.contains),
        )
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
    PlusSettingsProvider? plusSettings,
    bool isBackground = false,
  }) {
    // If auto update rules are disabled via Plus settings, never skip
    if (plusSettings != null && !plusSettings.plusEnableAutoUpdateRules) {
      return false;
    }
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
    Set<String> excludedCategories = const {},
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
          excludedCategories: excludedCategories,
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
                  final attempt = 3 - retries;
                  final baseMs = [1000, 2000, 4000][attempt];
                  final jitterMs = (Random().nextDouble() * baseMs * 0.5)
                      .round();
                  retries--;
                  await Future.delayed(
                    Duration(milliseconds: baseMs + jitterMs),
                  );
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
    bool includeAmbiguous = true,
  }) {
    List<String> updateAppIds = [];
    List<String> appIds = apps.keys.toList();
    for (int i = 0; i < appIds.length; i++) {
      App? app = apps[appIds[i]]?.app;
      // Disabled apps stay in the library but are never offered or installed.
      if (app == null || app.disabled) continue;
      bool isCandidate = false;
      if (app.installedVersion == null) {
        if (!installedOnly &&
            app.additionalSettings['trackOnly'] != true &&
            app.latestVersion.isNotEmpty) {
          isCandidate = true;
        }
      } else if (!nonInstalledOnly) {
        if (areVersionsDifferent(
          app,
          app.installedVersion,
          app.latestVersion,
        )) {
          if (includeAmbiguous ||
              app.additionalSettings['isAmbiguousUpdate'] != true) {
            isCandidate = true;
          }
        }
      }
      if (isCandidate) {
        updateAppIds.add(app.id);
      }
    }
    return updateAppIds;
  }

  /// Single-pass variant: returns installed-apps-with-pending-updates as a
  /// [Set] (for O(1) lookup) and not-yet-installed apps as a [List], avoiding
  /// two separate O(n) passes over the apps map.
  static ({Set<String> updates, List<String> newInstalls})
  findAllPendingUpdates(Map<String, AppInMemory> apps) {
    final updates = <String>{};
    final newInstalls = <String>[];
    for (final entry in apps.values) {
      final app = entry.app;
      if (app.disabled) continue;
      if (app.installedVersion == null) {
        if (app.additionalSettings['trackOnly'] != true &&
            app.latestVersion.isNotEmpty) {
          newInstalls.add(app.id);
        }
      } else if (areVersionsDifferent(
        app,
        app.installedVersion,
        app.latestVersion,
      )) {
        updates.add(app.id);
      }
    }
    return (updates: updates, newInstalls: newInstalls);
  }
}
