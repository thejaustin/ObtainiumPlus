import 'dart:async';
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
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_update_service.dart';

class BackgroundUpdateService {
  BackgroundUpdateService._();

  static Future<void> bgUpdateCheck(String taskId, Map<String, dynamic>? params) async {
    print('BG task started $taskId: ${params.toString()}');
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    await loadTranslations();

    LogsProvider logs = LogsProvider();
    NotificationsProvider notificationsProvider = NotificationsProvider();
    AppsProvider appsProvider = AppsProvider(isBg: true);
    await appsProvider.loadApps();

    int maxAttempts = 4; // Immediate retries
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

    // Load Retry Queue and add due items
    var retryQueue = appsProvider.settingsProvider.retryQueue;
    int now = DateTime.now().millisecondsSinceEpoch;
    List<String> dueRetries = [];
    retryQueue.forEach((appId, data) {
      if (data['nextRetry'] <= now) {
        dueRetries.add(appId);
      }
    });

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

    // Add due retries if not already in toCheck
    for (var appId in dueRetries) {
      if (!toCheck.any((e) => e.key == appId) && appsProvider.apps.containsKey(appId)) {
        // Use 0 for immediate attempt count, persistent attempts tracked in retryQueue
        toCheck.add(MapEntry(appId, 0));
        logs.add('BG update task: Including queued retry for $appId');
      }
    }

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

    var scheduleRestricted =
        appsProvider.settingsProvider.useUpdateSchedule &&
        !appsProvider.settingsProvider.isWithinUpdateSchedule();

    if (networkRestricted) {
      logs.add('BG update task: Network restriction in effect.');
    }

    if (chargingRestricted) {
      logs.add('BG update task: Charging restriction in effect.');
    }

    if (scheduleRestricted) {
      logs.add('BG update task: Outside scheduled update window (${appsProvider.settingsProvider.getScheduleDescription()}).');
    }

    // Skip update if any restriction is active (except for forced retries)
    if ((networkRestricted || chargingRestricted || scheduleRestricted) &&
        params['toCheck'] == null && dueRetries.isEmpty) {
      logs.add('BG update task: Skipped due to restrictions.');
      return;
    }

    if (toCheck.isNotEmpty) {
      var enoughTimePassed =
          appsProvider.settingsProvider.updateInterval != 0 &&
          appsProvider.settingsProvider.lastCompletedBGCheckTime
              .add(
                Duration(minutes: appsProvider.settingsProvider.updateInterval),
              )
              .isBefore(DateTime.now());
      
      // Bypass time check if we have forced retries
      if (!enoughTimePassed && params['toCheck'] == null && dueRetries.isEmpty) {
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
        
        // Clear successful updates from retry queue
        var queue = appsProvider.settingsProvider.retryQueue;
        for (var update in updates) {
          if (queue.containsKey(update.id)) {
            queue.remove(update.id);
          }
        }
        // Also clear checked apps that didn't have updates but didn't error
        for (var entry in toCheck) {
          if (!updates.any((u) => u.id == entry.key) && 
              (errors == null || !errors.idsByErrorString.containsKey(entry.key))) {
             if (queue.containsKey(entry.key)) {
               queue.remove(entry.key);
             }
          }
        }
        appsProvider.settingsProvider.retryQueue = queue;

      } catch (e) {
        if (e is Map) {
          updates = e['updates'];
          errors = e['errors'];
          
          // Clear successful/non-error ones from retry queue
          var queue = appsProvider.settingsProvider.retryQueue;
          
          for (var entry in errors!.rawErrors.entries) {
            var key = entry.key;
            var err = entry.value;
                      logs.add(
                        'BG update task: Got error on checking for $key "${err.toString()}"'
                      );
                        var toCheckAppMatch = toCheck.where((element) => element.key == key);
            if (toCheckAppMatch.isEmpty) continue;
            var toCheckApp = toCheckAppMatch.first;
            
            if (toCheckApp.value < maxAttempts) {
              // Immediate retry within this task
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
              // Persistent Retry Logic
              if (err is! RateLimitError) {
                 int currentPersistentAttempts = queue[key]?['attempts'] ?? 0;
                 // Exponential backoff: 15min * 2^attempts
                 int nextBackoffMinutes = (15 * pow(2, min(currentPersistentAttempts, 6))).toInt(); // Cap backoff multiplier
                 int nextRetryTime = DateTime.now().add(Duration(minutes: nextBackoffMinutes)).millisecondsSinceEpoch;
                 
                 queue[key] = {
                   'attempts': currentPersistentAttempts + 1,
                   'nextRetry': nextRetryTime
                 };
                 logs.add('BG update task: Queued $key for persistent retry in $nextBackoffMinutes mins (Persistent Attempt ${currentPersistentAttempts + 1})');
              } else {
                 toThrow.add(key, err, appName: errors?.appIdNames[key]);
              }
            }
          }
          
          // Clean up successes from queue in partial failure case
          for (var update in updates) {
            if (queue.containsKey(update.id)) queue.remove(update.id);
          }
          // And non-errors
          for (var entry in toCheck) {
             if (!updates.any((u) => u.id == entry.key) && 
                 !errors.idsByErrorString.containsKey(entry.key)) {
                if (queue.containsKey(entry.key)) queue.remove(entry.key);
             }
          }
          appsProvider.settingsProvider.retryQueue = queue;

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
        return await BackgroundUpdateService.bgUpdateCheck(taskId, {
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
        return await BackgroundUpdateService.bgUpdateCheck(taskId, {
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
              element.key == 'app.obtainiumplus' || element.key == 'app.obtainiumplus.fdroid',
        );
        if (tempObtArr.isNotEmpty) {
          var obt = tempObtArr.first;
          toInstall = AppDownloadService.moveStrToEnd(toInstall.map((e) => e.key).toList(), obt.key).map((k) => MapEntry(k, 0)).toList(); 
          // Corrected logic for moving map entry
        }
        try {
          await AppDownloadService.downloadAndInstallLatestApps(
            appIds: toInstall.map((e) => e.key).toList(),
            apps: appsProvider.apps,
            settingsProvider: appsProvider.settingsProvider,
            logs: logs,
            APKDir: appsProvider.APKDir,
            notifyListeners: appsProvider.notifyListeners,
            saveApps: appsProvider.saveApps,
            removeApps: appsProvider.removeApps,
            checkUpdate: appsProvider.checkUpdate,
            confirmAppFileUrl: appsProvider.confirmAppFileUrl,
            canInstallSilently: appsProvider.canInstallSilently,
            waitForUserToReturnToForeground: appsProvider.waitForUserToReturnToForeground,
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
}
