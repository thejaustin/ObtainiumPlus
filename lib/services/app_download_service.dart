import 'dart:async';
import 'dart:io';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/app_sources/directAPKLink.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/downloaded_artifact.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:flutter/foundation.dart' as foundation; // Alias to avoid conflict

import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/services/app_crud_service.dart';

class AppDownloadService {
  AppDownloadService._();

  static final pm = AndroidPackageManager();

  // Helper for moving string to end of list
  static List<String> moveStrToEnd(List<String> list, String str, {String? strB}) {
    int indA = list.indexOf(str);
    int indB = strB != null ? list.indexOf(strB) : -1;
    if (indA != -1) {
      list.add(list.removeAt(indA));
    }
    if (indB != -1) {
      list.add(list.removeAt(indB));
    }
    return list;
  }

  static Future<File> _handleAPKIDChange({
    required App app,
    required PackageInfo newInfo,
    required File downloadedFile,
    required String downloadUrl,
    required Map<String, AppInMemory> apps,
    required Future<void> Function(List<String>) removeApps,
    required Future<void> Function(List<App>, {bool onlyIfExists}) saveApps,
  }) async {
    var isTempIdBool = SourceUtils.isTempId(app);
    if (app.id != newInfo.packageName) {
      if (apps[app.id] != null && !isTempIdBool && !app.allowIdChange) {
        throw IDChangedError(newInfo.packageName!);
      }
      var idChangeWasAllowed = app.allowIdChange;
      app.allowIdChange = false;
      var originalAppId = app.id;
      app.id = newInfo.packageName!;
      downloadedFile = downloadedFile.renameSync(
        '${downloadedFile.parent.path}/${app.id}-${downloadUrl.hashCode}.${downloadedFile.path.split('.').last}',
      );
      if (apps[originalAppId] != null) {
        await removeApps([originalAppId]);
        await saveApps([
          app,
        ], onlyIfExists: !isTempIdBool && !idChangeWasAllowed);
      }
    }
    return downloadedFile;
  }

  static Future<List<String>> downloadAndInstallLatestApps({
    required List<String> appIds,
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required LogsProvider logs,
    required Directory APKDir,
    required Function() notifyListeners,
    required Future<void> Function(List<App>, {bool onlyIfExists}) saveApps,
    required Future<void> Function(List<String>) removeApps,
    required Function(String, {bool ignoreCache}) checkUpdate,
    required Future<MapEntry<String, String>?> Function(App, BuildContext?, bool, {bool evenIfSingleChoice}) confirmAppFileUrl,
    required Future<bool> Function(App) canInstallSilently,
    required Future<void> Function(BuildContext) waitForUserToReturnToForeground,
    BuildContext? context,
    NotificationsProvider? notificationsProvider,
    bool forceParallelDownloads = false,
    bool useExisting = true,
  }) async {
    notificationsProvider =
        notificationsProvider ?? context?.read<NotificationsProvider>();
    
    var preparationResult = await _prepareAppsForInstall(
      appIds: appIds,
      apps: apps,
      saveApps: (apps) => saveApps(apps, onlyIfExists: true),
      checkUpdate: checkUpdate,
      confirmAppFileUrl: confirmAppFileUrl,
      canInstallSilently: canInstallSilently,
      context: context,
    );
    
    List<String> appsToInstall = preparationResult['appsToInstall'] as List<String>;

    MultiAppMultiError errors = MultiAppMultiError();
    List<String> installedIds = [];

    appsToInstall = moveStrToEnd(
      appsToInstall,
      'app.obtainiumplus',
      strB: 'imranr98_obtainium_github.com',
    );
    appsToInstall = moveStrToEnd(appsToInstall, 'app.obtainiumplus.fdroid');

    List<Map<String, dynamic>> downloadResults = [];
    if (forceParallelDownloads || !settingsProvider.parallelDownloads) {
      for (var id in appsToInstall) {
        downloadResults.add(await _downloadAppWrapper(
          id: id,
          apps: apps,
          settingsProvider: settingsProvider,
          logs: logs,
          APKDir: APKDir,
          notifyListeners: notifyListeners,
          canInstallSilently: canInstallSilently,
          waitForUserToReturnToForeground: waitForUserToReturnToForeground,
          removeApps: removeApps,
          saveApps: saveApps,
          errors: errors,
          context: context,
          notificationsProvider: notificationsProvider,
          useExisting: useExisting,
        ));
      }
    } else {
      downloadResults = await Future.wait(
        appsToInstall.map((id) => _downloadAppWrapper(
          id: id,
          apps: apps,
          settingsProvider: settingsProvider,
          logs: logs,
          APKDir: APKDir,
          notifyListeners: notifyListeners,
          canInstallSilently: canInstallSilently,
          waitForUserToReturnToForeground: waitForUserToReturnToForeground,
          removeApps: removeApps,
          saveApps: saveApps,
          errors: errors,
          context: context,
          notificationsProvider: notificationsProvider,
          useExisting: useExisting,
          skipInstalls: true,
        )),
      );
    }
    for (var res in downloadResults) {
      if (!errors.appIdNames.containsKey(res['id'])) {
        try {
          var installed = await _installApp(
            id: res['id'] as String,
            willBeSilent: res['willBeSilent'] as bool,
            downloadedFile: res['downloadedFile'] as DownloadedApk?,
            downloadedDir: res['downloadedDir'] as DownloadedDir?,
            apps: apps,
            settingsProvider: settingsProvider,
            logs: logs,
            notifyListeners: notifyListeners,
            notificationsProvider: notificationsProvider,
            context: context,
          );
          if (installed) installedIds.add(res['id'] as String);
        } catch (e) {
          var id = res['id'] as String;
          errors.add(id, e, appName: apps[id]?.name);
        }
      }
    }

    if (errors.idsByErrorString.isNotEmpty) {
      throw errors;
    }

    return installedIds;
  }

  static Future<Map<String, dynamic>> downloadApp({
    required App app,
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required LogsProvider logs,
    required Directory APKDir,
    required Function() notifyListeners,
    required Future<void> Function(List<String>) removeApps,
    required Future<void> Function(List<App>, {bool onlyIfExists}) saveApps,
    BuildContext? context,
    NotificationsProvider? notificationsProvider,
    bool useExisting = true,
  }) async {
    var notifId = DownloadNotification(app.finalName, 0).id;
    if (apps[app.id] != null) {
      apps[app.id]!.downloadProgress = 0;
      notifyListeners();
    }
    try {
      AppSource source = SourceProvider().getSource(
        app.url,
        overrideSource: app.overrideSource,
      );
      var additionalSettingsPlusSourceConfig = {
        ...app.additionalSettings,
        ...(await source.getSourceConfigValues(
          app.additionalSettings,
          settingsProvider,
        )),
      };
      String downloadUrl = await source.assetUrlPrefetchModifier(
        await source.generalReqPrefetchModifier(
          app.apkUrls[app.preferredApkIndex].value,
          additionalSettingsPlusSourceConfig,
        ),
        app.url,
        additionalSettingsPlusSourceConfig,
      );
      
      logs.logEvent('DownloadStarted', {
        'appId': app.id,
        'url': downloadUrl,
        'source': source.name,
      });

      var notif = DownloadNotification(app.finalName, 100);
      notificationsProvider?.cancel(notif.id);
      int? prevProg;
      var fileNameNoExt = '${app.id}-${downloadUrl.hashCode}';
      if (source.urlsAlwaysHaveExtension) {
        fileNameNoExt =
            '$fileNameNoExt.${app.apkUrls[app.preferredApkIndex].key.split('.').last}';
      }
      var headers = await source.getRequestHeaders(
        app.additionalSettings,
        downloadUrl,
        forAPKDownload: true,
      );
      var downloadedFile = await AppFileService.downloadFileWithRetry(
        downloadUrl,
        fileNameNoExt,
        source.urlsAlwaysHaveExtension,
        headers: headers,
        (double? progress) {
          int? prog = progress?.ceil();
          if (apps[app.id] != null) {
            apps[app.id]!.downloadProgress = progress;
            notifyListeners();
          }
          notif = DownloadNotification(app.finalName, prog ?? 100);
          if (prog != null && prevProg != prog) {
            notificationsProvider?.notify(notif);
          }
          prevProg = prog;
        },
        APKDir.path,
        useExisting: useExisting,
        allowInsecure: app.additionalSettings['allowInsecure'] == true,
        logs: logs,
      );
      
      logs.logEvent('DownloadCompleted', {
        'appId': app.id,
        'path': downloadedFile.path,
        'size': await downloadedFile.length(),
      });

      if (apps[app.id] != null) {
        apps[app.id]!.downloadProgress = -1;
        notifyListeners();
        notif = DownloadNotification(app.finalName, -1);
        notificationsProvider?.notify(notif);
      }
      PackageInfo? newInfo;
      var isAPK = downloadedFile.path.toLowerCase().endsWith('.apk');
      var isXAPK = downloadedFile.path.toLowerCase().endsWith('.xapk');
      Directory? apkDir;
      if (isAPK) {
        try {
          newInfo = await pm.getPackageArchiveInfo(
            archiveFilePath: downloadedFile.path,
          );
        } catch (e) {
          talker.error('Error getting package archive info: ${e.toString()}');
        }
      } else {
        var res = await _processDownloadedArchive(
          downloadedFile,
          app.id,
          app.additionalSettings['zippedApkFilterRegEx'],
        );
        newInfo = res['newInfo'];
        apkDir = res['apkDir'];
      }
      
      if (newInfo == null) {
        downloadedFile.delete();
        throw ObtainiumError('Could not get ID from APK');
      }

      downloadedFile = await _handleAPKIDChange(
        app: app,
        newInfo: newInfo,
        downloadedFile: downloadedFile,
        downloadUrl: downloadUrl,
        apps: apps,
        removeApps: removeApps,
        saveApps: saveApps,
      );

      for (var file in downloadedFile.parent.listSync()) {
        var fn = file.path.split('/').last;
        if (fn.startsWith('${app.id}-') &&
            FileSystemEntity.isFileSync(file.path) &&
            file.path != downloadedFile.path) {
          file.delete(recursive: true);
        }
      }

      return {
        'newInfo': newInfo,
        'downloadedFile': downloadedFile,
        'downloadUrl': downloadUrl,
        'isAPK': isAPK,
        'apkDir': apkDir,
        'isXAPK': isXAPK,
      };
    } finally {
      notificationsProvider?.cancel(notifId);
      if (apps[app.id] != null) {
        apps[app.id]!.downloadProgress = null;
        notifyListeners();
      }
    }
  }

  static Future<List<String>> downloadAppAssets({
    required List<String> appIds,
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required LogsProvider logs,
    required Function() notifyListeners,
    required Future<MapEntry<String, String>?> Function(App, BuildContext?, bool, {bool evenIfSingleChoice}) confirmAppFileUrl,
    required Function(String, {bool ignoreCache}) checkUpdate,
    required BuildContext context,
    bool forceParallelDownloads = false,
  }) async {
    NotificationsProvider notificationsProvider = context.read<NotificationsProvider>();
    List<MapEntry<MapEntry<String, String>, App>> filesToDownload = [];
    for (var id in appIds) {
      if (apps[id] == null) {
        throw ObtainiumError(tr('appNotFound'));
      }
      MapEntry<String, String>? fileUrl;
      var refreshBeforeDownload =
          apps[id]!.app.additionalSettings['refreshBeforeDownload'] == true ||
          apps[id]!.app.apkUrls.isNotEmpty &&
              apps[id]!.app.apkUrls.first.value == 'placeholder';
      if (refreshBeforeDownload) {
        await checkUpdate(apps[id]!.app.id, ignoreCache: true);
      }
      if (apps[id]!.app.apkUrls.isNotEmpty ||
          apps[id]!.app.otherAssetUrls.isNotEmpty) {
        MapEntry<String, String>? tempFileUrl = await confirmAppFileUrl(
          apps[id]!.app,
          context,
          true,
          evenIfSingleChoice: true,
        );
        if (tempFileUrl != null) {
          var s = SourceProvider().getSource(
            apps[id]!.app.url,
            overrideSource: apps[id]!.app.overrideSource,
          );
          var additionalSettingsPlusSourceConfig = {
            ...apps[id]!.app.additionalSettings,
            ...(await s.getSourceConfigValues(
              apps[id]!.app.additionalSettings,
              settingsProvider,
            )),
          };
          fileUrl = MapEntry(
            tempFileUrl.key,
            await s.assetUrlPrefetchModifier(
              await s.generalReqPrefetchModifier(
                tempFileUrl.value,
                additionalSettingsPlusSourceConfig,
              ),
              apps[id]!.app.url,
              additionalSettingsPlusSourceConfig,
            ),
          );
        }
      }
      if (fileUrl != null) {
        filesToDownload.add(MapEntry(fileUrl, apps[id]!.app));
      }
    }

    MultiAppMultiError errors = MultiAppMultiError();
    List<String> downloadedIds = [];

    Future<void> downloadFn(MapEntry<String, String> fileUrl, App app) async {
      try {
        String downloadPath = '${await AppInstallService.getStorageRootPath()}/Download';
        await AppFileService.downloadFile(
          fileUrl.value,
          fileUrl.key,
          true,
          (double? progress) {
            notificationsProvider.notify(
              DownloadNotification(fileUrl.key, progress?.ceil() ?? 0),
            );
          },
          downloadPath,
          headers: await SourceProvider()
              .getSource(app.url, overrideSource: app.overrideSource)
              .getRequestHeaders(
                app.additionalSettings,
                fileUrl.value,
                forAPKDownload: fileUrl.key.endsWith('.apk') ? true : false,
              ),
          useExisting: false,
          allowInsecure: app.additionalSettings['allowInsecure'] == true,
          logs: logs,
        );
        notificationsProvider.notify(
          DownloadedNotification(fileUrl.key, fileUrl.value),
        );
      } catch (e) {
        errors.add(fileUrl.key, e);
      } finally {
        notificationsProvider.cancel(DownloadNotification(fileUrl.key, 0).id);
      }
    }

    if (forceParallelDownloads || !settingsProvider.parallelDownloads) {
      for (var urlWithApp in filesToDownload) {
        await downloadFn(urlWithApp.key, urlWithApp.value);
      }
    } else {
      await Future.wait(
        filesToDownload.map(
          (urlWithApp) => downloadFn(urlWithApp.key, urlWithApp.value),
        ),
      );
    }
    if (errors.idsByErrorString.isNotEmpty) {
      throw errors;
    }
    return downloadedIds;
  }

  static Future<Map<String, dynamic>> _prepareAppsForInstall({
    required List<String> appIds,
    required Map<String, AppInMemory> apps,
    required Function(List<App>) saveApps,
    required Function(String, {bool ignoreCache}) checkUpdate,
    required Future<MapEntry<String, String>?> Function(App, BuildContext?, bool, {bool evenIfSingleChoice}) confirmAppFileUrl,
    required Future<bool> Function(App) canInstallSilently,
    BuildContext? context,
  }) async {
    List<String> appsToInstall = [];
    List<String> trackOnlyAppsToUpdate = [];
    for (var id in appIds) {
      if (apps[id] == null) {
        throw ObtainiumError(tr('appNotFound'));
      }
      MapEntry<String, String>? apkUrl;
      var trackOnly = apps[id]!.app.additionalSettings['trackOnly'] == true;
      var refreshBeforeDownload =
          apps[id]!.app.additionalSettings['refreshBeforeDownload'] == true ||
          apps[id]!.app.apkUrls.isNotEmpty &&
              apps[id]!.app.apkUrls.first.value == 'placeholder';
      if (refreshBeforeDownload) {
        await checkUpdate(apps[id]!.app.id, ignoreCache: true);
      }
      if (!trackOnly) {
        apkUrl = await confirmAppFileUrl(apps[id]!.app, context, false);
      }
      if (apkUrl != null) {
        int urlInd = apps[id]!.app.apkUrls
            .map((e) => e.value)
            .toList()
            .indexOf(apkUrl.value);
        if (urlInd >= 0 && urlInd != apps[id]!.app.preferredApkIndex) {
          apps[id]!.app.preferredApkIndex = urlInd;
          await saveApps([apps[id]!.app]);
        }
        if (context != null || await canInstallSilently(apps[id]!.app)) {
          appsToInstall.add(id);
        }
      }
      if (trackOnly) {
        trackOnlyAppsToUpdate.add(id);
      }
    }
    await saveApps(
      trackOnlyAppsToUpdate.map((e) {
        var a = apps[e]!.app;
        a.installedVersion = a.latestVersion;
        return a;
      }).toList(),
    );
    return {
      'appsToInstall': appsToInstall,
    };
  }

  static Future<Map<String, dynamic>> _processDownloadedArchive(
    File downloadedFile,
    String appId,
    String? zippedApkFilterRegEx,
  ) async {
    String apkDirPath = '${downloadedFile.path}-dir';
    await AppFileService.unzipFile(downloadedFile.path, apkDirPath);
    var apkDir = Directory(apkDirPath);
    var apks = apkDir
        .listSync()
        .where((e) => e.path.toLowerCase().endsWith('.apk'))
        .toList();

    FileSystemEntity? temp;
    apks.removeWhere((element) {
      bool res = element.uri.pathSegments.last.startsWith(appId);
      if (res) {
        temp = element;
      }
      return res;
    });
    if (temp != null) {
      apks = [temp!, ...apks];
    }

    if (zippedApkFilterRegEx?.isNotEmpty == true) {
      var reg = RegExp(zippedApkFilterRegEx!);
      apks.removeWhere((apk) {
        var shouldDelete = !reg.hasMatch(apk.uri.pathSegments.last);
        if (shouldDelete) {
          apk.delete();
        }
        return shouldDelete;
      });
    }

    if (apks.isEmpty) {
      throw NoAPKError();
    }

    PackageInfo? newInfo;
    for (var i = 0; i < apks.length; i++) {
      try {
        newInfo = await pm.getPackageArchiveInfo(
          archiveFilePath: apks[i].path,
        );
        if (newInfo != null) {
          break;
        }
      } catch (e) {
        if (i == apks.length - 1) {
          rethrow;
        }
      }
    }
    return {'newInfo': newInfo, 'apkDir': apkDir};
  }

  static Future<void> _checkInstallPermissions(
    SettingsProvider settingsProvider,
    bool willBeSilent,
  ) async {
    if (!settingsProvider.useShizuku) {
      if (!(await settingsProvider.getInstallPermission(enforce: false))) {
        throw ObtainiumError(tr('cancelled'));
      }
    } else {
      var shizukuPermission = await ShizukuApkInstaller.checkPermission();
      switch (shizukuPermission) {
        case 'binder_not_found':
          throw ObtainiumError(tr('shizukuBinderNotFound'));
        case 'old_shizuku':
          throw ObtainiumError(tr('shizukuOld'));
        case 'old_android_with_adb':
          throw ObtainiumError(tr('shizukuOldAndroidWithADB'));
        case 'denied':
        case null:
          throw ObtainiumError(tr('cancelled'));
        default:
          // In case of unknown response, treat as cancelled/denied
          throw ObtainiumError(tr('cancelled'));
      }
    }
  }

  static Future<bool> _installApp({
    required String id,
    required bool willBeSilent,
    required DownloadedApk? downloadedFile,
    required DownloadedDir? downloadedDir,
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required LogsProvider logs,
    required Function() notifyListeners,
    NotificationsProvider? notificationsProvider,
    BuildContext? context,
  }) async {
    apps[id]?.downloadProgress = -1;
    notifyListeners();
    try {
      bool sayInstalled = true;
      var contextIfNewInstall = apps[id]?.installedInfo == null ? context : null;
      bool needBGWorkaround = willBeSilent && context == null && !settingsProvider.useShizuku;
      bool shizukuPretendToBeGooglePlay = settingsProvider.shizukuPretendToBeGooglePlay ||
          apps[id]!.app.additionalSettings['shizukuPretendToBeGooglePlay'] == true;

      logs.logEvent('InstallStarted', {
        'appId': id,
        'shizuku': settingsProvider.useShizuku,
        'bgWorkaround': needBGWorkaround,
      });

      if (downloadedFile != null) {
        sayInstalled = await AppInstallService.installApk(
          downloadedFile,
          contextIfNewInstall,
          settingsProvider,
          logs,
          apps,
          needsBGWorkaround: needBGWorkaround,
          shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
        );
      } else if (downloadedDir != null) {
        sayInstalled = await AppInstallService.installApkDir(
          downloadedDir,
          contextIfNewInstall,
          settingsProvider,
          logs,
          apps,
          needsBGWorkaround: needBGWorkaround,
          shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
        );
      }
      if (willBeSilent && context == null) {
        if (!settingsProvider.useShizuku) {
          notificationsProvider?.notify(
            SilentUpdateAttemptNotification([apps[id]!.app], id: id.hashCode),
          );
        } else {
          notificationsProvider?.notify(
            SilentUpdateNotification([apps[id]!.app], sayInstalled, id: id.hashCode),
          );
        }
      }
      if (sayInstalled) {
        notificationsProvider?.cancel(UpdateNotification([]).id);
      }
      logs.logEvent('InstallCompleted', {'appId': id, 'success': sayInstalled});
      return sayInstalled;
    } finally {
      apps[id]?.downloadProgress = null;
      notifyListeners();
    }
  }

  static Future<Map<String, dynamic>> _downloadAppWrapper({
    required String id,
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required LogsProvider logs,
    required Directory APKDir,
    required Function() notifyListeners,
    required Future<bool> Function(App) canInstallSilently,
    required Future<void> Function(BuildContext) waitForUserToReturnToForeground,
    required Future<void> Function(List<String>) removeApps,
    required Future<void> Function(List<App>, {bool onlyIfExists}) saveApps,
    required MultiAppMultiError errors,
    BuildContext? context,
    NotificationsProvider? notificationsProvider,
    bool useExisting = true,
    bool skipInstalls = false,
  }) async {
    bool willBeSilent = false;
    DownloadedApk? downloadedFile;
    DownloadedDir? downloadedDir;
    try {
      if (apps[id] == null) {
        throw ObtainiumError(tr('appNotFound'));
      }
      var downloadedArtifact =
          await downloadApp(
            app: apps[id]!.app,
            apps: apps,
            settingsProvider: settingsProvider,
            logs: logs,
            APKDir: APKDir,
            notifyListeners: notifyListeners,
            removeApps: removeApps,
            saveApps: saveApps,
            context: context,
            notificationsProvider: notificationsProvider,
            useExisting: useExisting,
          );
      if (downloadedArtifact['isAPK'] == true) {
        downloadedFile = DownloadedApk(id, downloadedArtifact['downloadedFile'] as File);
      } else {
        downloadedDir = DownloadedDir(id, downloadedArtifact['downloadedFile'] as File, downloadedArtifact['apkDir'] as Directory, downloadedArtifact['isXAPK'] ? DownloadedDirType.XAPK : DownloadedDirType.ZIP);
      }

      willBeSilent = await canInstallSilently(apps[id]!.app);
      await _checkInstallPermissions(settingsProvider, willBeSilent);
      
      if (!willBeSilent && context != null && !settingsProvider.useShizuku) {
        await waitForUserToReturnToForeground(context);
      }
    } catch (e) {
      errors.add(id, e, appName: apps[id]?.name);
    }
    return {
      'id': id,
      'willBeSilent': willBeSilent,
      'downloadedFile': downloadedFile,
      'downloadedDir': downloadedDir,
    };
  }
}

