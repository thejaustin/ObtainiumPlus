import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/downloaded_artifact.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

class AppDownloadService {
  AppDownloadService._();

  static final pm = AndroidPackageManager();

  // Helper for moving string to end of list
  static List<String> _moveStrToEnd(List<String> list, String str, {String? strB}) {
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

  static Future<List<String>> downloadAndInstallLatestApps({
    required List<String> appIds,
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required LogsProvider logs,
    required Directory APKDir,
    required Function() notifyListeners,
    required Function(List<App>) saveApps,
    required Function(String, {bool ignoreCache}) checkUpdate,
    required Future<MapEntry<String, String>?> Function(App, BuildContext?, bool) confirmAppFileUrl,
    required Future<bool> Function(App) canInstallSilently,
    required Future<void> Function(BuildContext) waitForUserToReturnToForeground,
    BuildContext? context,
    NotificationsProvider? notificationsProvider,
    bool forceParallelDownloads = false,
    bool useExisting = true,
  }) async {
    notificationsProvider =
        notificationsProvider ?? context?.read<NotificationsProvider>();
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
    saveApps(
      trackOnlyAppsToUpdate.map((e) {
        var a = apps[e]!.app;
        a.installedVersion = a.latestVersion;
        return a;
      }).toList(),
    );

    MultiAppMultiError errors = MultiAppMultiError();
    List<String> installedIds = [];

    // Prioritize Obtainium updates last
    appsToInstall = _moveStrToEnd(
      appsToInstall,
      'dev.imranr.obtainium',
      strB: 'imranr98_obtainium_github.com',
    );
    appsToInstall = _moveStrToEnd(appsToInstall, 'dev.imranr.obtainium.fdroid');

    Future<void> installFn(
      String id,
      bool willBeSilent,
      DownloadedApk? downloadedFile,
      DownloadedDir? downloadedDir,
    ) async {
      apps[id]?.downloadProgress = -1;
      notifyListeners();
      try {
        bool sayInstalled = true;
        var contextIfNewInstall = apps[id]?.installedInfo == null ? context : null;
        bool needBGWorkaround = willBeSilent && context == null && !settingsProvider.useShizuku;
        bool shizukuPretendToBeGooglePlay = settingsProvider.shizukuPretendToBeGooglePlay ||
            apps[id]!.app.additionalSettings['shizukuPretendToBeGooglePlay'] == true;
        
        if (downloadedFile != null) {
          if (needBGWorkaround) {
            await AppInstallService.installApk(
              downloadedFile,
              contextIfNewInstall,
              settingsProvider,
              logs,
              apps,
              needsBGWorkaround: true,
              shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
            );
          } else {
            sayInstalled = await AppInstallService.installApk(
              downloadedFile,
              contextIfNewInstall,
              settingsProvider,
              logs,
              apps,
              shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
            );
          }
        } else if (downloadedDir != null) {
          if (needBGWorkaround) {
            await AppInstallService.installApkDir(
              downloadedDir,
              contextIfNewInstall,
              settingsProvider,
              logs,
              apps,
              needsBGWorkaround: true,
              shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
            );
          } else {
            sayInstalled = await AppInstallService.installApkDir(
              downloadedDir,
              contextIfNewInstall,
              settingsProvider,
              logs,
              apps,
              shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
            );
          }
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
          installedIds.add(id);
          notificationsProvider?.cancel(UpdateNotification([]).id);
        }
      } finally {
        apps[id]?.downloadProgress = null;
        notifyListeners();
      }
    }

    Future<Map<Object?, Object?>> downloadFn(
      String id, {
      bool skipInstalls = false,
    }) async {
      bool willBeSilent = false;
      DownloadedApk? downloadedFile;
      DownloadedDir? downloadedDir;
      try {
        var downloadedArtifact =
            await downloadApp(
              app: apps[id]!.app,
              apps: apps,
              settingsProvider: settingsProvider,
              logs: logs,
              APKDir: APKDir,
              notifyListeners: notifyListeners,
              context: context,
              notificationsProvider: notificationsProvider,
              useExisting: useExisting,
            );
        if (downloadedArtifact is Map) { // downloadApp returns Map in service
           // Need to adapt return type of downloadApp service method
           // The service method returns a Map with 'downloadedFile' etc.
           // But the original method returned DownloadedApk or DownloadedDir directly? 
           // Wait, let's check `AppDownloadService.downloadApp` return type.
           // It returns `Future<Object>` which is a Map.
           // But `AppsProvider.downloadApp` logic was different.
           // Let's assume for now we use the service `downloadApp`.
           // We need to parse the map result.
           
           if (downloadedArtifact['isAPK'] == true) {
             downloadedFile = DownloadedApk(id, downloadedArtifact['downloadedFile'] as File);
           } else {
             downloadedDir = DownloadedDir(id, downloadedArtifact['downloadedFile'] as File, downloadedArtifact['apkDir'] as Directory, downloadedArtifact['isXAPK'] ? DownloadedDirType.XAPK : DownloadedDirType.ZIP);
           }
        } else if (downloadedArtifact is DownloadedApk) {
           downloadedFile = downloadedArtifact;
        } else if (downloadedArtifact is DownloadedDir) {
           downloadedDir = downloadedArtifact;
        }

        willBeSilent = await canInstallSilently(apps[id]!.app);
        if (!settingsProvider.useShizuku) {
          if (!(await settingsProvider.getInstallPermission(enforce: false))) {
            throw ObtainiumError(tr('cancelled'));
          }
        } else {
          switch ((await ShizukuApkInstaller.checkPermission())!) {
            case 'binder_not_found':
              throw ObtainiumError(tr('shizukuBinderNotFound'));
            case 'old_shizuku':
              throw ObtainiumError(tr('shizukuOld'));
            case 'old_android_with_adb':
              throw ObtainiumError(tr('shizukuOldAndroidWithADB'));
            case 'denied':
              throw ObtainiumError(tr('cancelled'));
          }
        }
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

    List<Map<Object?, Object?>> downloadResults = [];
    if (forceParallelDownloads || !settingsProvider.parallelDownloads) {
      for (var id in appsToInstall) {
        downloadResults.add(await downloadFn(id));
      }
    } else {
      downloadResults = await Future.wait(
        appsToInstall.map((id) => downloadFn(id, skipInstalls: true)),
      );
    }
    for (var res in downloadResults) {
      if (!errors.appIdNames.containsKey(res['id'])) {
        try {
          await installFn(
            res['id'] as String,
            res['willBeSilent'] as bool,
            res['downloadedFile'] as DownloadedApk?,
            res['downloadedDir'] as DownloadedDir?,
          );
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

  static Future<Object> downloadApp({
    required App app,
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    required LogsProvider logs,
    required Directory APKDir,
    required Function() notifyListeners,
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
        newInfo = await pm.getPackageArchiveInfo(
          archiveFilePath: downloadedFile.path,
        );
      } else {
        String apkDirPath = '${downloadedFile.path}-dir';
        await AppFileService.unzipFile(downloadedFile.path, '${downloadedFile.path}-dir');
        apkDir = Directory(apkDirPath);
        var apks = apkDir
            .listSync()
            .where((e) => e.path.toLowerCase().endsWith('.apk'))
            .toList();

        FileSystemEntity? temp;
        apks.removeWhere((element) {
          bool res = element.uri.pathSegments.last.startsWith(app.id);
          if (res) {
            temp = element;
          }
          return res;
        });
        if (temp != null) {
          apks = [temp!, ...apks];
        }

        if (app.additionalSettings['zippedApkFilterRegEx']?.isNotEmpty ==
            true) {
          var reg = RegExp(app.additionalSettings['zippedApkFilterRegEx']);
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
}
