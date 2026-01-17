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
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_utils.dart';

class AppUpdateService {
  AppUpdateService._();

  static Future<App?> checkUpdate(String appId, Map<String, AppInMemory> apps, Function(List<App>) saveApps) async {
    if (!apps.containsKey(appId)) {
      throw ObtainiumError(tr('appNotFound'));
    }
    App currentApp = apps[appId]!.app;
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
    await saveApps([newApp]);
    return newApp.latestVersion != currentApp.latestVersion ? newApp : null;
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
            } catch (e) {
              if ((e is RateLimitError || e is SocketException) &&
                  throwErrorsForRetry) {
                rethrow;
              }
              errors.add(appId, e, appName: apps[appId]?.name);
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

  static List<String> findExistingUpdates(
    Map<String, AppInMemory> apps, {
    bool installedOnly = false,
    bool nonInstalledOnly = false,
  }) {
    List<String> updateAppIds = [];
    List<String> appIds = apps.keys.toList();
    for (int i = 0; i < appIds.length; i++) {
      App? app = apps[appIds[i]]!.app;
      if (app.installedVersion != app.latestVersion &&
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

Future<void> bgUpdateCheck(String taskId, Map<String, dynamic>? params) async {
  print('BG task started $taskId: ${params.toString()}');
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await loadTranslations();

  LogsProvider logs = LogsProvider();
  NotificationsProvider notificationsProvider = NotificationsProvider();
  AppsProvider appsProvider = AppsProvider(isBg: true);
  await appsProvider.loadApps();

  int maxAttempts = 4;
  int maxRetryWaitSeconds = 5;

  var netResult = await (Connectivity().checkConnectivity());
  if (netResult.contains(ConnectivityResult.none) ||
      netResult.isEmpty ||
      (netResult.contains(ConnectivityResult.vpn) && netResult.length == 1)) {
    logs.add('BG update task: No network.');
    return;
  }

  params ??= {};

  bool firstEverUpdateTask =
      DateTime.fromMillisecondsSinceEpoch(
        0,
      ).compareTo(appsProvider.settingsProvider.lastCompletedBGCheckTime) ==
      0;

  List<MapEntry<String, int>> toCheck = <MapEntry<String, int>>[
    ...(params['toCheck']
            ?.map(
              (entry) => MapEntry<String, int>(
                entry['key'] as String,
                entry['value'] as int,
              ),
            )
            .toList() ??
        AppUpdateService.getAppsSortedByUpdateCheckTime(
              appsProvider.apps,
              ignoreAppsCheckedAfter: params['toCheck'] == null
                  ? firstEverUpdateTask
                        ? null
                        : appsProvider.settingsProvider.lastCompletedBGCheckTime
                  : null,
              onlyCheckInstalledOrTrackOnlyApps:
                  appsProvider
                      .settingsProvider
                      .onlyCheckInstalledOrTrackOnlyApps,
            )
            .map((e) => MapEntry(e, 0))),
  ];
  List<MapEntry<String, int>> toInstall = <MapEntry<String, int>>[
    ...(params['toInstall']
            ?.map(
              (entry) => MapEntry<String, int>(
                entry['key'] as String,
                entry['value'] as int,
              ),
            )
            .toList() ??
        (<List<MapEntry<String, int>>>[])),
  ];

  var networkRestricted =
      appsProvider.settingsProvider.bgUpdatesOnWiFiOnly &&
      !netResult.contains(ConnectivityResult.wifi) &&
      !netResult.contains(ConnectivityResult.ethernet);

  var chargingRestricted =
      appsProvider.settingsProvider.bgUpdatesWhileChargingOnly &&
      (await Battery().batteryState) != BatteryState.charging;

  if (networkRestricted) {
    logs.add('BG update task: Network restriction in effect.');
  }

  if (chargingRestricted) {
    logs.add('BG update task: Charging restriction in effect.');
  }

  if (toCheck.isNotEmpty) {
    var enoughTimePassed =
        appsProvider.settingsProvider.updateInterval != 0 &&
        appsProvider.settingsProvider.lastCompletedBGCheckTime
            .add(
              Duration(minutes: appsProvider.settingsProvider.updateInterval),
            )
            .isBefore(DateTime.now());
    if (!enoughTimePassed) {
      print(
        'BG update task: Too early for another check (last check was ${appsProvider.settingsProvider.lastCompletedBGCheckTime.toIso8601String()}, interval is ${appsProvider.settingsProvider.updateInterval}).',
      );
      return;
    }

    logs.add('BG update task: Started (${toCheck.length}).');

    List<App> updates = [];
    List<App> toNotify = [];
    List<MapEntry<String, int>> toRetry = [];
    var retryAfterXSeconds = 0;
    MultiAppMultiError? errors;
    MultiAppMultiError toThrow = MultiAppMultiError();
    CheckingUpdatesNotification notif = CheckingUpdatesNotification(
      plural('apps', toCheck.length),
    );

    try {
      notificationsProvider.notify(notif, cancelExisting: true);
      updates = await appsProvider.checkUpdates(
        specificIds: toCheck.map((e) => e.key).toList(),
        sp: appsProvider.settingsProvider,
      );
    } catch (e) {
      if (e is Map) {
        updates = e['updates'];
        errors = e['errors'];
        for (var entry in errors!.rawErrors.entries) {
          var key = entry.key;
          var err = entry.value;
          logs.add(
            'BG update task: Got error on checking for $key \'${err.toString()}\''
          );

          var toCheckAppMatch = toCheck.where((element) => element.key == key);
          if (toCheckAppMatch.isEmpty) continue;
          var toCheckApp = toCheckAppMatch.first;
          if (toCheckApp.value < maxAttempts) {
            toRetry.add(MapEntry(toCheckApp.key, toCheckApp.value + 1));
            int minRetryIntervalForThisApp = err is RateLimitError
                ? (err.remainingMinutes * 60)
                : e is ClientException
                ? (15 * 60)
                : (toCheckApp.value + 1);
            if (minRetryIntervalForThisApp > maxRetryWaitSeconds) {
              minRetryIntervalForThisApp = maxRetryWaitSeconds;
            }
            if (minRetryIntervalForThisApp > retryAfterXSeconds) {
              retryAfterXSeconds = minRetryIntervalForThisApp;
            }
          } else {
            if (err is! RateLimitError) {
              toThrow.add(key, err, appName: errors?.appIdNames[key]);
            }
          }
        }
      } else {
        logs.add('Fatal error in BG update task: ${e.toString()}');
        rethrow;
      }
    } finally {
      notificationsProvider.cancel(notif.id);
    }

    for (var i = 0; i < updates.length; i++) {
      var canInstallSilently = await appsProvider.canInstallSilently(
        updates[i],
      );
      if (networkRestricted || chargingRestricted || !canInstallSilently) {
        if (updates[i].additionalSettings['skipUpdateNotifications'] != true) {
          logs.add(
            'BG update task notifying for ${updates[i].id} (networkRestricted $networkRestricted, chargingRestricted: $chargingRestricted, canInstallSilently: $canInstallSilently).',
          );
          toNotify.add(updates[i]);
        }
      }
    }

    if (toNotify.isNotEmpty) {
      notificationsProvider.notify(UpdateNotification(toNotify));
    }

    if (toThrow.rawErrors.isNotEmpty) {
      for (var element in toThrow.idsByErrorString.entries) {
        notificationsProvider.notify(
          ErrorCheckingUpdatesNotification(
            errors!.errorsAppsString(element.key, element.value),
            id: Random().nextInt(10000),
          ),
        );
      }
    }
    logs.add('BG update task: Done checking for updates.');
    if (toRetry.isNotEmpty) {
      logs.add(
        'BG update task $taskId: Will retry in $retryAfterXSeconds seconds (${toRetry.length} to retry, ${toInstall.length} to install).',
      );
      return await bgUpdateCheck(taskId, {
        'toCheck': toRetry
            .map((entry) => {'key': entry.key, 'value': entry.value})
            .toList(),
        'toInstall': toInstall
            .map((entry) => {'key': entry.key, 'value': entry.value})
            .toList(),
      });
    } else {
      logs.add(
        'BG update task: Done checking for updates (${toRetry.length} to retry, ${toInstall.length} to install).',
      );
      return await bgUpdateCheck(taskId, {
        'toCheck': [],
        'toInstall': toInstall
            .map((entry) => {'key': entry.key, 'value': entry.value})
            .toList(),
      });
    }
  } else {
    logs.add('BG install task: Started (${toInstall.length}).');
    if (toInstall.isEmpty && !networkRestricted && !chargingRestricted) {
      var temp = appsProvider.findExistingUpdates(installedOnly: true);
      for (var i = 0; i < temp.length; i++) {
        if (await appsProvider.canInstallSilently(
          appsProvider.apps[temp[i]]!.app,
        )) {
          toInstall.add(MapEntry(temp[i], 0));
        }
      }
    }
    if (toInstall.isNotEmpty) {
      var tempObtArr = toInstall.where(
        (element) =>
            element.key == 'dev.imranr.obtainium' || element.key == 'dev.imranr.obtainium.fdroid',
      );
      if (tempObtArr.isNotEmpty) {
        var obt = tempObtArr.first;
        toInstall = moveStrToEndMapEntryWithCount(toInstall, obt);
      }
      try {
        await appsProvider.downloadAndInstallLatestApps(
          toInstall.map((e) => e.key).toList(),
          null,
          notificationsProvider: notificationsProvider,
          forceParallelDownloads: true,
        );
      } catch (e) {
        if (e is MultiAppMultiError) {
          e.idsByErrorString.forEach((key, value) {
            notificationsProvider.notify(
              ErrorCheckingUpdatesNotification(e.errorsAppsString(key, value)),
            );
          });
        } else {
          logs.add('Fatal error in BG install task: ${e.toString()}');
          rethrow;
        }
      }
      logs.add('BG install task: Done installing updates.');
    }
  }
  appsProvider.settingsProvider.lastCompletedBGCheckTime = DateTime.now();
}
