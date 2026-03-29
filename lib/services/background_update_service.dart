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
import 'package:obtainium/services/offline_service.dart';

class BackgroundUpdateService {
  BackgroundUpdateService._();

  static Future<void> bgUpdateCheck(String taskId, Map<String, dynamic>? initialParams) async {
    talker.debug('BG task started $taskId: ${initialParams.toString()}');
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    await loadTranslations();

    LogsProvider logs = LogsProvider();
    NotificationsProvider notificationsProvider = NotificationsProvider();
    AppsProvider appsProvider = AppsProvider(isBg: true);
    await appsProvider.initializationDone; // Ensure directories and apps are loaded

    Map<String, dynamic>? currentParams = initialParams;
    bool isFirstIteration = true;

    while (true) {
      int maxAttempts = 4; // Immediate retries
      int maxRetryWaitSeconds = 5;

      var netResult = await (Connectivity().checkConnectivity());
      if (netResult.contains(ConnectivityResult.none) ||
          netResult.isEmpty ||
          (netResult.contains(ConnectivityResult.vpn) && netResult.length == 1)) {
        logs.add('BG update task: No network.');
        return;
      }

      currentParams ??= {};

      bool firstEverUpdateTask =
          DateTime.fromMillisecondsSinceEpoch(0).compareTo(appsProvider.settingsProvider.lastCompletedBGCheckTime) == 0;

      // Load Retry Queue and add due items using OfflineService
      final offlineService = OfflineService();
      List<String> dueRetries = offlineService.getDueRetries(appsProvider.settingsProvider);

      List<MapEntry<String, int>> toCheck = <MapEntry<String, int>>[
        ...(currentParams['toCheck']
                ?.map(
                  (entry) => MapEntry<String, int>(
                    entry['key'] as String,
                    entry['value'] as int,
                  ),
                )
                .toList() ??
            (isFirstIteration
                ? AppUpdateService.getAppsSortedByUpdateCheckTime(
                      appsProvider.apps,
                      ignoreAppsCheckedAfter: currentParams['toCheck'] == null
                          ? firstEverUpdateTask
                                ? null
                                : appsProvider.settingsProvider.lastCompletedBGCheckTime
                          : null,
                      onlyCheckInstalledOrTrackOnlyApps:
                          appsProvider.settingsProvider.onlyCheckInstalledOrTrackOnlyApps,
                    ).map((e) => MapEntry(e, 0))
                : <MapEntry<String, int>>[])),
      ];

      // Add due retries if not already in toCheck (only on first iteration)
      if (isFirstIteration) {
        for (var appId in dueRetries) {
          if (!toCheck.any((e) => e.key == appId) && appsProvider.apps.containsKey(appId)) {
            toCheck.add(MapEntry(appId, 0));
            logs.add('BG update task: Including queued retry for $appId');
          }
        }
      }

      List<MapEntry<String, int>> toInstall = <MapEntry<String, int>>[
        ...(currentParams['toInstall']
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

      if (isFirstIteration) {
        if (networkRestricted) logs.add('BG update task: Network restriction in effect.');
        if (chargingRestricted) logs.add('BG update task: Charging restriction in effect.');
        if (scheduleRestricted) logs.add('BG update task: Outside scheduled update window.');
      }

      // Skip update if any restriction is active (except for forced retries)
      if (isFirstIteration && (networkRestricted || chargingRestricted || scheduleRestricted) &&
          currentParams['toCheck'] == null && dueRetries.isEmpty) {
        logs.add('BG update task: Skipped due to restrictions.');
        return;
      }

      if (toCheck.isNotEmpty) {
        if (isFirstIteration) {
          var enoughTimePassed =
              appsProvider.settingsProvider.updateInterval != 0 &&
              appsProvider.settingsProvider.lastCompletedBGCheckTime
                  .add(Duration(minutes: appsProvider.settingsProvider.updateInterval))
                  .isBefore(DateTime.now());
          
          if (!enoughTimePassed && currentParams['toCheck'] == null && dueRetries.isEmpty) {
            talker.debug('BG update task: Too early for another check.');
            return;
          }
        }

        logs.add('BG update task: Started (${toCheck.length}).');

        List<App> updates = [];
        List<MapEntry<String, int>> toRetry = [];
        var retryAfterXSeconds = 0;
        MultiAppMultiError? errors;
        MultiAppMultiError toThrow = MultiAppMultiError();
        CheckingUpdatesNotification notif = CheckingUpdatesNotification(
          () { try { return plural('apps', toCheck.length); } catch (_) { return '${toCheck.length} apps'; } }(),
        );

        try {
          notificationsProvider.notify(notif, cancelExisting: true);
          updates = await appsProvider.checkUpdates(
            specificIds: toCheck.map((e) => e.key).toList(),
            sp: appsProvider.settingsProvider,
          );
          
          for (var update in updates) {
            offlineService.clearAppFromRetryQueue(update.id, appsProvider.settingsProvider);
          }
          for (var entry in toCheck) {
            if (!updates.any((u) => u.id == entry.key) && 
                (errors == null || !errors.idsByErrorString.containsKey(entry.key))) {
               offlineService.clearAppFromRetryQueue(entry.key, appsProvider.settingsProvider);
            }
          }
        } catch (e) {
          if (e is Map) {
            updates = e['updates'] ?? [];
            errors = e['errors'];
            
            for (var entry in errors!.rawErrors.entries) {
              var key = entry.key;
              var err = entry.value;
              logs.add('BG update task: Got error on checking for $key "${err.toString()}"');
              
              var toCheckAppMatch = toCheck.where((element) => element.key == key);
              if (toCheckAppMatch.isEmpty) continue;
              var toCheckApp = toCheckAppMatch.first;
              
              if (toCheckApp.value < maxAttempts) {
                toRetry.add(MapEntry(toCheckApp.key, toCheckApp.value + 1));
                int minRetryIntervalForThisApp = err is RateLimitError
                    ? (err.remainingMinutes * 60)
                    : (15 * 60);
                if (minRetryIntervalForThisApp > maxRetryWaitSeconds) minRetryIntervalForThisApp = maxRetryWaitSeconds;
                if (minRetryIntervalForThisApp > retryAfterXSeconds) retryAfterXSeconds = minRetryIntervalForThisApp;
              } else {
                if (err is! RateLimitError) {
                   offlineService.addAppToRetryQueue(key, appsProvider.settingsProvider, reason: err.toString());
                   logs.add('BG update task: Queued $key for persistent retry');
                } else {
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

        List<App> toNotify = [];
        for (var i = 0; i < updates.length; i++) {
          var canInstallSilently = await appsProvider.canInstallSilently(updates[i]);
          if (networkRestricted || chargingRestricted || !canInstallSilently) {
            if (updates[i].additionalSettings['skipUpdateNotifications'] != true) {
              toNotify.add(updates[i]);
            }
          }
        }

        if (toNotify.isNotEmpty) notificationsProvider.notify(UpdateNotification(toNotify));
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

        if (toRetry.isNotEmpty) {
          logs.add('BG update task: Will retry in $retryAfterXSeconds seconds.');
          await Future.delayed(Duration(seconds: retryAfterXSeconds));
          currentParams = {
            'toCheck': toRetry.map((entry) => {'key': entry.key, 'value': entry.value}).toList(),
            'toInstall': toInstall.map((entry) => {'key': entry.key, 'value': entry.value}).toList(),
          };
          isFirstIteration = false;
          continue; // Loop for retries
        } else {
          currentParams = {
            'toCheck': [],
            'toInstall': toInstall.map((entry) => {'key': entry.key, 'value': entry.value}).toList(),
          };
          isFirstIteration = false;
          continue; // Loop for installs
        }
      } else {
        // Installation Phase
        logs.add('BG install task: Started (${toInstall.length}).');
        if (toInstall.isEmpty && !networkRestricted && !chargingRestricted) {
          var temp = appsProvider.findExistingUpdates(installedOnly: true);
          for (var i = 0; i < temp.length; i++) {
            if (await appsProvider.canInstallSilently(appsProvider.apps[temp[i]]!.app)) {
              toInstall.add(MapEntry(temp[i], 0));
            }
          }
        }
        if (toInstall.isNotEmpty) {
          try {
            await AppDownloadService.downloadAndInstallLatestApps(
              appIds: toInstall.map((e) => e.key).toList(),
              apps: appsProvider.apps,
              settingsProvider: appsProvider.settingsProvider,
              logs: logs,
              APKDir: appsProvider.APKDir!,
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
             // Handle or log errors
          }
          logs.add('BG install task: Done.');
        }
        break; // Finished both phases
      }
    }
    appsProvider.settingsProvider.lastCompletedBGCheckTime = DateTime.now();
  }
}
