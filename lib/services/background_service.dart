import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/services/background_update_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/logger.dart';

class BackgroundService {
  BackgroundService._();

  static final BackgroundService _instance = BackgroundService._();
  factory BackgroundService() => _instance;

  @pragma('vm:entry-point')
  static Future<void> backgroundFetchHeadlessTask(HeadlessTask task) async {
    String taskId = task.taskId;
    bool isTimeout = task.timeout;
    if (isTimeout) {
      talker.warning('BG update task timed out.');
      try {
        BackgroundFetch.finish(taskId);
      } catch (e) {
        talker.warning('BackgroundFetch.finish failed: $e');
      }
      return;
    }
    await BackgroundUpdateService.bgUpdateCheck(taskId, null);
    try {
      BackgroundFetch.finish(taskId);
    } catch (e) {
      talker.warning('BackgroundFetch.finish failed: $e');
    }
  }

  @pragma('vm:entry-point')
  static void startCallback() {
    FlutterForegroundTask.setTaskHandler(MyTaskHandler());
  }

  static void initForegroundService() {
    if (!FlutterForegroundTask.isInitialized) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'bg_update',
          channelName: tr('foregroundService'),
          channelDescription: tr('foregroundService'),
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(
            AppConstants.defaultUpdateIntervalMs,
          ),
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    }
  }

  static Future<ServiceRequestResult?> startForegroundService(
    bool restart,
  ) async {
    try {
      initForegroundService();
      if (await FlutterForegroundTask.isRunningService) {
        if (restart) {
          return await FlutterForegroundTask.restartService();
        }
      } else {
        return await FlutterForegroundTask.startService(
          serviceTypes: [ForegroundServiceTypes.specialUse],
          serviceId: AppConstants.foregroundServiceId,
          notificationTitle: tr('foregroundService'),
          notificationText: tr('fgServiceNotice'),
          notificationIcon: NotificationIcon(
            metaDataName: 'app.obtainiumplus.service.NOTIFICATION_ICON',
          ),
          callback: startCallback,
        );
      }
    } catch (e) {
      talker.warning('startForegroundService failed: $e');
    }
    return null;
  }

  static Future<ServiceRequestResult?> stopForegroundService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        return await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      talker.warning('stopForegroundService failed: $e');
    }
    return null;
  }
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    talker.debug('onStart(starter: ${starter.name})');
    BackgroundUpdateService.bgUpdateCheck('bg_check', null);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    BackgroundUpdateService.bgUpdateCheck('bg_check', null).catchError((e) {
      talker.warning('onRepeatEvent bgUpdateCheck failed: $e');
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    talker.debug('Foreground service onDestroy(isTimeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {}
}
