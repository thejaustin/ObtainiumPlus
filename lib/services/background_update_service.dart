import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';

import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/services/offline_service.dart';
import 'package:obtainium/utils/logger.dart';

class BackgroundUpdateService {
  BackgroundUpdateService._();

  static Future<void> bgUpdateCheck(
    String taskId,
    Map<String, dynamic>? initialParams,
  ) async {
    talker.debug('BG task started $taskId: ${initialParams.toString()}');
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    await loadTranslations();

    LogsProvider logs = LogsProvider();
    NotificationsProvider notificationsProvider = NotificationsProvider();
    AppsProvider appsProvider = AppsProvider(isBg: true);
    await appsProvider
        .initializationDone; // Ensure directories and apps are loaded
    await notificationsProvider.initialize();

    Map<String, dynamic>? currentParams = initialParams;
    bool isFirstIteration = true;
    List<MapEntry<String, int>> toCheck = [];
    List<App> updates = [];

    while (true) {
      int maxAttempts = 4; // Immediate retries
      int maxRetryWaitSeconds = 5;

      var netResult = await (Connectivity().checkConnectivity());
      if (netResult.contains(ConnectivityResult.none) ||
          netResult.isEmpty ||
          (netResult.contains(ConnectivityResult.vpn) &&
              netResult.length == 1)) {
        logs.add('BG update task: No network.');
        return;
      }

      currentParams ??= {};

      bool firstEverUpdateTask =
          DateTime.fromMillisecondsSinceEpoch(
            0,
          ).compareTo(appsProvider.updateSettings.lastCompletedBGCheckTime) ==
          0;

      // Load Retry Queue and add due items using OfflineService
      final offlineService = OfflineService();
      List<String> dueRetries = offlineService.getDueRetries(
        appsProvider.updateSettings,
      );

      toCheck = <MapEntry<String, int>>[
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
                              : appsProvider
                                    .updateSettings
                                    .lastCompletedBGCheckTime
                        : null,
                    onlyCheckInstalledOrTrackOnlyApps: appsProvider
                        .updateSettings
                        .onlyCheckInstalledOrTrackOnlyApps,
                  ).map((e) => MapEntry(e, 0))
                : <MapEntry<String, int>>[])),
      ];

      // Add due retries if not already in toCheck (only on first iteration)
      if (isFirstIteration) {
        for (var appId in dueRetries) {
          if (!toCheck.any((e) => e.key == appId) &&
              appsProvider.apps.containsKey(appId)) {
            toCheck.add(MapEntry(appId, 0));
            logs.add('BG update task: Including queued retry for $appId');
          }
        }
      }

      toCheck.removeWhere((entry) {
        final app = appsProvider.apps[entry.key]?.app;
        if (app == null) return false;

        if (AppUpdateService.shouldSkipAppUpdate(
          app: app,
          updateSettings: appsProvider.updateSettings,
          netResult: netResult,
        )) {
          logs.add('BG update task: Skipping ${app.id} based on rules');
          return true;
        }
        return false;
      });
      // ------------------------------------------

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
          appsProvider.updateSettings.bgUpdatesOnWiFiOnly &&
          !netResult.contains(ConnectivityResult.wifi) &&
          !netResult.contains(ConnectivityResult.ethernet);

      var chargingRestricted =
          appsProvider.updateSettings.bgUpdatesWhileChargingOnly &&
          (await Battery().batteryState) != BatteryState.charging;

      var scheduleRestricted =
          appsProvider.updateSettings.useUpdateSchedule &&
          !appsProvider.updateSettings.isWithinUpdateSchedule();

      if (isFirstIteration) {
        if (networkRestricted) {
          logs.add('BG update task: Network restriction in effect.');
        }
        if (chargingRestricted) {
          logs.add('BG update task: Charging restriction in effect.');
        }
        if (scheduleRestricted) {
          logs.add('BG update task: Outside scheduled update window.');
        }
      }

      // Skip update if any restriction is active (except for forced retries)
      if (isFirstIteration &&
          (networkRestricted || chargingRestricted || scheduleRestricted) &&
          currentParams['toCheck'] == null &&
          dueRetries.isEmpty) {
        logs.add('BG update task: Skipped due to restrictions.');
        return;
      }

      if (toCheck.isNotEmpty) {
        if (isFirstIteration) {
          var enoughTimePassed =
              appsProvider.updateSettings.updateInterval != 0 &&
              appsProvider.updateSettings.lastCompletedBGCheckTime
                  .add(
                    Duration(
                      minutes: appsProvider.updateSettings.updateInterval,
                    ),
                  )
                  .isBefore(DateTime.now());

          if (!enoughTimePassed &&
              currentParams['toCheck'] == null &&
              dueRetries.isEmpty) {
            talker.debug('BG update task: Too early for another check.');
            return;
          }
        }

        logs.add('BG update task: Started (${toCheck.length}).');

        updates = [];
        List<MapEntry<String, int>> toRetry = [];
        var retryAfterXSeconds = 0;
        MultiAppMultiError? errors;
        MultiAppMultiError toThrow = MultiAppMultiError();
        CheckingUpdatesNotification notif = CheckingUpdatesNotification(() {
          try {
            return plural('apps', toCheck.length);
          } catch (_) {
            return '${toCheck.length} apps';
          }
        }());

        try {
          notificationsProvider.notify(notif, cancelExisting: true);
          updates = await appsProvider.checkUpdates(
            specificIds: toCheck.map((e) => e.key).toList(),
          );

          for (var update in updates) {
            offlineService.clearAppFromRetryQueue(
              update.id,
              appsProvider.updateSettings,
            );
          }
          for (var entry in toCheck) {
            if (!updates.any((u) => u.id == entry.key)) {
              offlineService.clearAppFromRetryQueue(
                entry.key,
                appsProvider.updateSettings,
              );
            }
          }
        } catch (e) {
          if (e is Map) {
            updates = List<App>.from(e['updates'] ?? <App>[]);
            errors = e['errors'] as MultiAppMultiError?;

            for (var entry
                in (errors?.rawErrors.entries ??
                    <MapEntry<String, dynamic>>[])) {
              var key = entry.key;
              var err = entry.value;
              logs.add(
                'BG update task: Got error on checking for $key "${err.toString()}"',
              );

              var toCheckAppMatch = toCheck.where(
                (element) => element.key == key,
              );
              if (toCheckAppMatch.isEmpty) continue;
              var toCheckApp = toCheckAppMatch.first;

              if (toCheckApp.value < maxAttempts) {
                toRetry.add(MapEntry(toCheckApp.key, toCheckApp.value + 1));
                int minRetryIntervalForThisApp = err is RateLimitError
                    ? (err.remainingMinutes * 60)
                    : (15 * 60);
                if (minRetryIntervalForThisApp > maxRetryWaitSeconds) {
                  minRetryIntervalForThisApp = maxRetryWaitSeconds;
                }
                if (minRetryIntervalForThisApp > retryAfterXSeconds) {
                  retryAfterXSeconds = minRetryIntervalForThisApp;
                }
              } else {
                if (err is! RateLimitError) {
                  offlineService.addAppToRetryQueue(
                    key,
                    appsProvider.updateSettings,
                    reason: err.toString(),
                  );
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

        final silentFlags = await Future.wait(
          updates.map((App app) => appsProvider.canInstallSilently(app)),
        );
        List<App> toNotify = [];
        List<App> trackOnlyToNotify = [];
        List<App> exemptToNotify = [];
        for (var i = 0; i < updates.length; i++) {
          if (networkRestricted || chargingRestricted || !silentFlags[i]) {
            if (updates[i].additionalSettings['skipUpdateNotifications'] !=
                true) {
              if (updates[i].additionalSettings['trackOnly'] == true) {
                trackOnlyToNotify.add(updates[i]);
              } else if (updates[i]
                      .additionalSettings['exemptFromBackgroundUpdates'] ==
                  true) {
                exemptToNotify.add(updates[i]);
              } else {
                toNotify.add(updates[i]);
              }
            }
          }
        }

        // Sent as separate notifications so cancelling one type doesn't
        // cancel the others.
        if (toNotify.isNotEmpty) {
          if (appsProvider.plusSettings.plusEnableNotificationDigest) {
            notificationsProvider.notify(UpdateNotification(toNotify));
          } else {
            for (var app in toNotify) {
              notificationsProvider.notify(
                UpdateNotification([app], id: app.id.hashCode),
              );
            }
          }
        }
        if (trackOnlyToNotify.isNotEmpty) {
          notificationsProvider.notify(
            TrackOnlyUpdateNotification(trackOnlyToNotify),
          );
        }
        if (exemptToNotify.isNotEmpty) {
          notificationsProvider.notify(
            TrackOnlyUpdateNotification(exemptToNotify),
          );
        }
        if (toThrow.rawErrors.isNotEmpty) {
          for (var element in toThrow.idsByErrorString.entries) {
            notificationsProvider.notify(
              ErrorCheckingUpdatesNotification(
                (errors ?? toThrow).errorsAppsString(
                  element.key,
                  element.value,
                ),
                id: Random().nextInt(10000),
              ),
            );
          }
        }

        if (toRetry.isNotEmpty) {
          logs.add(
            'BG update task: Will retry in $retryAfterXSeconds seconds.',
          );
          await Future.delayed(Duration(seconds: retryAfterXSeconds));
          currentParams = {
            'toCheck': toRetry
                .map((entry) => {'key': entry.key, 'value': entry.value})
                .toList(),
            'toInstall': toInstall
                .map((entry) => {'key': entry.key, 'value': entry.value})
                .toList(),
          };
          isFirstIteration = false;
          continue; // Loop for retries
        } else {
          currentParams = {
            'toCheck': [],
            'toInstall': toInstall
                .map((entry) => {'key': entry.key, 'value': entry.value})
                .toList(),
          };
          isFirstIteration = false;
          continue; // Loop for installs
        }
      } else {
        // Installation Phase
        logs.add('BG install task: Started (${toInstall.length}).');
        if (toInstall.isEmpty && !networkRestricted && !chargingRestricted) {
          var temp = appsProvider.findExistingUpdates(installedOnly: true);
          final canInstallFlags = await Future.wait(
            temp.map(
              (id) =>
                  appsProvider.canInstallSilently(appsProvider.apps[id]!.app),
            ),
          );
          for (var i = 0; i < temp.length; i++) {
            if (canInstallFlags[i]) toInstall.add(MapEntry(temp[i], 0));
          }
        }
        if (toInstall.isNotEmpty) {
          try {
            await AppDownloadService.downloadAndInstallLatestApps(
              appIds: toInstall.map((e) => e.key).toList(),
              apps: appsProvider.apps,
              settingsProvider: appsProvider.settingsProvider,
              behaviorSettings: appsProvider.behaviorSettings,
              plusSettings: appsProvider.plusSettings,
              updateSettings: appsProvider.updateSettings,
              logs: logs,
              APKDir: appsProvider.APKDir,
              notifyListeners: appsProvider.forceNotifyListeners,
              saveApps: appsProvider.saveApps,
              removeApps: appsProvider.removeApps,
              checkUpdate: appsProvider.checkUpdate,
              confirmAppFileUrl: appsProvider.confirmAppFileUrl,
              canInstallSilently: appsProvider.canInstallSilently,
              waitForUserToReturnToForeground:
                  appsProvider.waitForUserToReturnToForeground,
              notificationsProvider: notificationsProvider,
              forceParallelDownloads: true,
            );
          } catch (e, stack) {
            logs.add('BG install task error: $e');
            talker.handle(e, stack, 'BG install task');
          }
          logs.add('BG install task: Done.');
        }
        break; // Finished both phases
      }
    }
    appsProvider.updateSettings.lastCompletedBGCheckTime = DateTime.now();

    // --- Save status for potential cloud sync ---
    try {
      final status = {
        'timestamp': DateTime.now().toIso8601String(),
        'appsChecked': toCheck.length,
        'updatesFound': updates.length,
        'success': true,
      };
      final file = File(
        '${appsProvider.APKDir.parent.path}/last_update_status.json',
      );
      await file.writeAsString(jsonEncode(status));
    } catch (e) {
      talker.error('Failed to save BG status: $e');
    }
  }
}
