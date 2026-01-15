// Manages state related to the list of Apps tracked by Obtainium,
// Exposes related functions such as those used to add, remove, download, and install Apps.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:battery_plus/battery_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';

import 'package:android_intent_plus/flag.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/io_client.dart';
import 'package:obtainium/app_sources/directAPKLink.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:http/http.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_storage/shared_storage.dart' as saf;
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/services/app_crud_service.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_export_service.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/components/apps/app_dialogs.dart';
import 'package:obtainium/models/app_in_memory.dart';

export 'package:obtainium/models/app_in_memory.dart';

class DownloadedApk {
  String appId;
  File file;
  DownloadedApk(this.appId, this.file);
}

enum DownloadedDirType { XAPK, ZIP }

class DownloadedDir {
  String appId;
  File file;
  Directory extracted;
  DownloadedDirType type;
  DownloadedDir(this.appId, this.file, this.extracted, this.type);
}

class AppsProvider with ChangeNotifier {
  // In memory App state (should always be kept in sync with local storage versions)
  Map<String, AppInMemory> apps = {};
  bool loadingApps = false;
  bool gettingUpdates = false;
  LogsProvider logs = LogsProvider();

  // Variables to keep track of the app foreground status (installs can't run in the background)
  bool isForeground = true;
  late Stream<FGBGType>? foregroundStream;
  late StreamSubscription<FGBGType>? foregroundSubscription;
  late Directory APKDir;
  late Directory iconsCacheDir;
  late SettingsProvider settingsProvider = SettingsProvider();

  Iterable<AppInMemory> getAppValues() => apps.values.map((a) => a.deepCopy());

  AppsProvider({isBg = false}) {
    // Subscribe to changes in the app foreground status
    foregroundStream = FGBGEvents.instance.stream.asBroadcastStream();
    foregroundSubscription = foregroundStream?.listen((event) async {
      isForeground = event == FGBGType.foreground;
      if (isForeground) {
        await loadApps();
      }
    });
    () async {
      await settingsProvider.initializeSettings();
      var cacheDirs = await getExternalCacheDirectories();
      if (cacheDirs?.isNotEmpty ?? false) {
        APKDir = cacheDirs!.first;
        iconsCacheDir = Directory('${cacheDirs.first.path}/icons');
        if (!iconsCacheDir.existsSync()) {
          iconsCacheDir.createSync();
        }
      } else {
        APKDir = Directory('${(await AppFileService.getAppStorageDir()).path}/apks');
        if (!APKDir.existsSync()) {
          APKDir.createSync();
        }
        iconsCacheDir = Directory('${(await AppFileService.getAppStorageDir()).path}/icons');
        if (!iconsCacheDir.existsSync()) {
          iconsCacheDir.createSync();
        }
      }
      if (!isBg) {
        // Load Apps into memory (in background processes, this is done later instead of in the constructor)
        await loadApps();
        // Delete any partial APKs (if safe to do so)
        var cutoff = DateTime.now().subtract(const Duration(days: 7));
        APKDir.listSync()
            .where((element) => element.statSync().modified.isBefore(cutoff))
            .forEach((partialApk) {
              if (!areDownloadsRunning()) {
                partialApk.delete(recursive: true);
              }
            });
      }
    }();
  }

  Future<File> handleAPKIDChange(
    App app,
    PackageInfo newInfo,
    File downloadedFile,
    String downloadUrl,
  ) async {
    var isTempIdBool = isTempId(app);
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

  Future<Object> downloadApp(
    App app,
    BuildContext? context, {
    NotificationsProvider? notificationsProvider,
    bool useExisting = true,
  }) async {
    Map<String, dynamic> res = await AppDownloadService.downloadApp(
      app: app,
      apps: apps,
      settingsProvider: settingsProvider,
      logs: logs,
      APKDir: APKDir,
      notifyListeners: notifyListeners,
      context: context,
      notificationsProvider: notificationsProvider,
      useExisting: useExisting,
    ) as Map<String, dynamic>;

    PackageInfo? newInfo = res['newInfo'];
    File downloadedFile = res['downloadedFile'];
    String downloadUrl = res['downloadUrl'];
    bool isAPK = res['isAPK'];
    Directory? apkDir = res['apkDir'];
    bool isXAPK = res['isXAPK'];

    if (newInfo == null) {
      downloadedFile.delete();
      throw ObtainiumError('Could not get ID from APK');
    }
    downloadedFile = await handleAPKIDChange(
      app,
      newInfo,
      downloadedFile,
      downloadUrl,
    );
    for (var file in downloadedFile.parent.listSync()) {
      var fn = file.path.split('/').last;
      if (fn.startsWith('${app.id}-') &&
          FileSystemEntity.isFileSync(file.path) &&
          file.path != downloadedFile.path) {
        file.delete(recursive: true);
      }
    }
    if (isAPK) {
      return DownloadedApk(app.id, downloadedFile);
    } else {
      return DownloadedDir(
        app.id,
        downloadedFile,
        apkDir!,
        isXAPK ? DownloadedDirType.XAPK : DownloadedDirType.ZIP,
      );
    }
  }

  bool areDownloadsRunning() => apps.values
      .where((element) => element.downloadProgress != null)
      .isNotEmpty;

  Future<bool> canInstallSilently(App app) async {
    return AppInstallService.canInstallSilently(app, settingsProvider, logs);
  }

  Future<void> waitForUserToReturnToForeground(BuildContext context) async {
    NotificationsProvider notificationsProvider = context
        .read<NotificationsProvider>();
    if (!isForeground) {
      await notificationsProvider.notify(
        completeInstallationNotification,
        cancelExisting: true,
      );
      while (await FGBGEvents.instance.stream.first != FGBGType.foreground) {}
      await notificationsProvider.cancel(completeInstallationNotification.id);
    }
  }

  Future<bool> canDowngradeApps() async =>
      AppInstallService.canDowngradeApps();

  Future<bool> installApkDir(
    DownloadedDir dir,
    BuildContext? firstTimeWithContext, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
  }) async {
    bool installed = await AppInstallService.installApkDir(
      dir,
      firstTimeWithContext,
      settingsProvider,
      logs,
      apps,
      needsBGWorkaround: needsBGWorkaround,
      shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
    );
    if (installed) {
      await saveApps([apps[dir.appId]!.app]);
    }
    return installed;
  }

  Future<bool> installApk(
    DownloadedApk file,
    BuildContext? firstTimeWithContext, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
    List<DownloadedApk> additionalAPKs = const [],
  }) async {
    bool installed = await AppInstallService.installApk(
      file,
      firstTimeWithContext,
      settingsProvider,
      logs,
      apps,
      needsBGWorkaround: needsBGWorkaround,
      shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
      additionalAPKs: additionalAPKs,
    );
    if (installed) {
      await saveApps([apps[file.appId]!.app]);
    }
    return installed;
  }

  Future<void> openAppSettings(String appId) async {
    await AppInstallService.openAppSettings(appId);
  }

  Future<MapEntry<String, String>?> confirmAppFileUrl(
    App app,
    BuildContext? context,
    bool pickAnyAsset, {
    bool evenIfSingleChoice = false,
  }) async {
    var urlsToSelectFrom = app.apkUrls;
    if (pickAnyAsset) {
      urlsToSelectFrom = [...urlsToSelectFrom, ...app.otherAssetUrls];
    }
    MapEntry<String, String>? appFileUrl =
        urlsToSelectFrom[app.preferredApkIndex >= 0
            ? app.preferredApkIndex
            : 0];
    List<String> archs = (await DeviceInfoPlugin().androidInfo).supportedAbis;

    if ((urlsToSelectFrom.length > 1 || evenIfSingleChoice) &&
        context != null) {
      appFileUrl = await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AppFilePicker(
            app: app,
            initVal: appFileUrl,
            archs: archs,
            pickAnyAsset: pickAnyAsset,
          );
        },
      );
    }
    getHost(String url) {
      if (url == 'placeholder') {
        return null;
      }
      var temp = Uri.parse(url).host.split('.');
      return temp.sublist(temp.length - 2).join('.');
    }

    if (appFileUrl != null &&
        ![
          getHost(app.url),
          'placeholder',
        ].contains(getHost(appFileUrl.value)) &&
        context != null) {
      if (!(settingsProvider.hideAPKOriginWarning) &&
          await showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return APKOriginWarningDialog(
                    sourceUrl: app.url,
                    apkUrl: appFileUrl!.value,
                  );
                },
              ) !=
              true) {
        appFileUrl = null;
      }
    }
    return appFileUrl;
  }

  Future<List<String>> downloadAndInstallLatestApps(
    List<String> appIds,
    BuildContext? context, {
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
        await checkUpdate(apps[id]!.app.id);
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

    appsToInstall = moveStrToEnd(
      appsToInstall,
      obtainiumId,
      strB: obtainiumTempId,
    );
    appsToInstall = moveStrToEnd(appsToInstall, '$obtainiumId.fdroid');

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
        var contextIfNewInstall = apps[id]?.installedInfo == null
            ? context
            : null;
        bool needBGWorkaround =
            willBeSilent && context == null && !settingsProvider.useShizuku;
        bool shizukuPretendToBeGooglePlay =
            settingsProvider.shizukuPretendToBeGooglePlay ||
            apps[id]!.app.additionalSettings['shizukuPretendToBeGooglePlay'] ==
                true;
        if (downloadedFile != null) {
          if (needBGWorkaround) {
            installApk(
              downloadedFile,
              contextIfNewInstall,
              needsBGWorkaround: true,
              shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
            );
          } else {
            sayInstalled = await installApk(
              downloadedFile,
              contextIfNewInstall,
              shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
            );
          }
        } else {
          if (needBGWorkaround) {
            installApkDir(
              downloadedDir!,
              contextIfNewInstall,
              needsBGWorkaround: true,
            );
          } else {
            sayInstalled = await installApkDir(
              downloadedDir!,
              contextIfNewInstall,
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
              SilentUpdateNotification(
                [apps[id]!.app],
                sayInstalled,
                id: id.hashCode,
              ),
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
              apps[id]!.app,
              context,
              notificationsProvider: notificationsProvider,
              useExisting: useExisting,
            );
        if (downloadedArtifact is DownloadedApk) {
          downloadedFile = downloadedArtifact;
        } else {
          downloadedDir = downloadedArtifact as DownloadedDir;
        }
        id = downloadedFile?.appId ?? downloadedDir!.appId;
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

  Future<List<String>> downloadAppAssets(
    List<String> appIds,
    BuildContext context, {
    bool forceParallelDownloads = false,
  }) async {
    NotificationsProvider notificationsProvider = context
        .read<NotificationsProvider>();
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
        await checkUpdate(apps[id]!.app.id);
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



  Future<void> loadApps({String? singleId}) async {
    while (loadingApps) {
      await Future.delayed(const Duration(microseconds: 1));
    }
    loadingApps = true;
    notifyListeners();
    var sp = SourceProvider();
    List<List<String>> errors = [];
    var installedAppsData = await AppInstallService.getAllInstalledInfo();
    List<String> removedAppIds = [];
    await Future.wait(
      (await AppFileService.getAppsDir())
          .listSync()
          .map((item) async {
            App? app;
            if (item.path.toLowerCase().endsWith('.json') &&
                (singleId == null ||
                    item.path.split('/').last.toLowerCase() ==
                        '${singleId.toLowerCase()}.json')) {
              try {
                app = App.fromJson(
                  jsonDecode(File(item.path).readAsStringSync()),
                );
              } catch (err) {
                if (err is FormatException) {
                  logs.add(
                    'Corrupt JSON when loading App (will be ignored): $err',
                  );
                  item.renameSync('${item.path}.corrupt');
                } else {
                  rethrow;
                }
              }
            }
            if (app != null) {
              apps.update(
                app.id,
                (value) => AppInMemory(
                  app!,
                  value.downloadProgress,
                  value.installedInfo,
                  value.icon,
                ),
                ifAbsent: () => AppInMemory(app!, null, null, null),
              );
              notifyListeners();
              try {
                sp.getSource(app.url, overrideSource: app.overrideSource);
                PackageInfo? installedInfo;
                try {
                  installedInfo = installedAppsData.firstWhere(
                    (i) => i.packageName == app!.id,
                  );
                } catch (e) {
                }
                var moddedApp = AppCRUDService.getCorrectedInstallStatusAppIfPossible(
                  app,
                  installedInfo,
                  logs,
                );
                if (moddedApp != null) {
                  app = moddedApp;
                  if (moddedApp.installedVersion == null) {
                    removedAppIds.add(moddedApp.id);
                  }
                }
                apps.update(
                  app.id,
                  (value) => AppInMemory(
                    app!,
                    value.downloadProgress,
                    installedInfo,
                    value.icon,
                  ),
                  ifAbsent: () => AppInMemory(app!, null, installedInfo, null),
                );
                notifyListeners();
              } catch (e) {
                errors.add([app!.id, app.finalName, e.toString()]);
              }
            }
          }),
    );
    if (errors.isNotEmpty) {
      removeApps(errors.map((e) => e[0]).toList());
      NotificationsProvider().notify(
        AppsRemovedNotification(errors.map((e) => [e[1], e[2]]).toList()),
      );
    }
    if (removedAppIds.isNotEmpty) {
      if (settingsProvider.removeOnExternalUninstall) {
        await removeApps(removedAppIds);
      }
    }
    loadingApps = false;
    notifyListeners();
  }

  Future<void> updateAppIcon(String? appId, {bool ignoreCache = false}) async {
    if (apps[appId]?.icon == null) {
      var iconsCacheDir = this.iconsCacheDir;
      var cachedIcon = File('${iconsCacheDir.path}/$appId.png');
      var alreadyCached = cachedIcon.existsSync() && !ignoreCache;
      var icon = alreadyCached
          ? (await cachedIcon.readAsBytes())
          : (await (await AppInstallService.getInstalledInfo(appId))?.applicationInfo?.getAppIcon());
      if (icon != null && !alreadyCached) {
        unawaited(cachedIcon.writeAsBytes(icon.toList()));
      }
      if (icon != null) {
        apps.update(
          apps[appId]!.app.id,
          (value) => AppInMemory(
            apps[appId]!.app,
            value.downloadProgress,
            value.installedInfo,
            icon,
          ),
          ifAbsent: () => AppInMemory(
            apps[appId]!.app,
            null,
            apps[appId]?.installedInfo,
            icon,
          ),
        );
        notifyListeners();
      }
    }
  }

  Future<void> precacheIcons(List<String> appIds) async {
    final appsNeedingIcons = appIds.where((id) =>
      apps[id] != null && apps[id]!.icon == null
    ).toList();

    if (appsNeedingIcons.isEmpty) return;

    final batch = appsNeedingIcons.take(10).toList();

    for (final appId in batch) {
      unawaited(updateAppIcon(appId));
    }
  }

  Future<void> saveApps(
    List<App> apps, {
    bool attemptToCorrectInstallStatus = true,
    bool onlyIfExists = true,
  }) async {
    await Future.wait(
      apps.map((a) async {
        var app = a.deepCopy();
        PackageInfo? info = await AppInstallService.getInstalledInfo(app.id);
        var icon = await info?.applicationInfo?.getAppIcon();
        app.name = await (info?.applicationInfo?.getAppLabel()) ?? app.name;
        if (attemptToCorrectInstallStatus) {
          app = AppCRUDService.getCorrectedInstallStatusAppIfPossible(app, info, logs) ?? app;
        }
        if (!onlyIfExists || this.apps.containsKey(app.id)) {
          await AppCRUDService.saveAppToDisk(app);
        }
        try {
          this.apps.update(
            app.id,
            (value) => AppInMemory(app, value.downloadProgress, info, icon),
            ifAbsent: onlyIfExists
                ? null
                : () => AppInMemory(app, null, info, icon),
          );
        } catch (e) {
          if (e is! ArgumentError || e.name != 'key') {
            rethrow;
          }
        }
      }),
    );
    notifyListeners();
    export(isAuto: true);
  }

  Future<void> removeApps(List<String> appIds) async {
    var apkFiles = APKDir.listSync();
    await Future.wait(
      appIds.map((appId) async {
        await AppCRUDService.deleteAppFile(appId);
        apkFiles
            .where(
              (element) => element.path.split('/').last.startsWith('$appId-'),
            )
            .forEach((element) {
              element.delete(recursive: true);
            });
        if (apps.containsKey(appId)) {
          apps.remove(appId);
        }
      }),
    );
    if (appIds.isNotEmpty) {
      notifyListeners();
      export(isAuto: true);
    }
  }

  Future<bool> removeAppsWithModal(BuildContext context, List<App> apps) async {
    var showUninstallOption = apps
        .where(
          (a) =>
              a.installedVersion != null &&
              a.additionalSettings['trackOnly'] != true,
        )
        .isNotEmpty;
    var values = await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return GeneratedFormModal(
          primaryActionColour: Theme.of(context).colorScheme.error,
          title: plural('removeAppQuestion', apps.length),
          items: !showUninstallOption
              ? []
              : [
                  [
                    GeneratedFormSwitch(
                      'rmAppEntry',
                      label: tr('removeFromObtainium'),
                      defaultValue: true,
                    ),
                  ],
                  [
                    GeneratedFormSwitch(
                      'uninstallApp',
                      label: tr('uninstallFromDevice'),
                    ),
                  ],
                ],
          initValid: true,
        );
      },
    );
    if (values != null) {
      bool uninstall = values['uninstallApp'] == true && showUninstallOption;
      bool remove = values['rmAppEntry'] == true || !showUninstallOption;
      if (uninstall) {
        for (var i = 0; i < apps.length; i++) {
          if (apps[i].installedVersion != null) {
            AppInstallService.uninstallApp(apps[i].id);
            apps[i].installedVersion = null;
          }
        }
        await saveApps(apps, attemptToCorrectInstallStatus: false);
      }
      if (remove) {
        await removeApps(apps.map((e) => e.id).toList());
      }
      return uninstall || remove;
    }
    return false;
  }

  void addMissingCategories(SettingsProvider settingsProvider) {
    var cats = settingsProvider.categories;
    apps.forEach((key, value) {
      for (var c in value.app.categories) {
        if (!cats.containsKey(c)) {
          cats[c] = generateRandomLightColor().value;
        }
      }
    });
    settingsProvider.setCategories(cats, appsProvider: this);
  }

  Future<App?> checkUpdate(String appId) async {
    return AppUpdateService.checkUpdate(appId, apps, saveApps);
  }

  List<String> getAppsSortedByUpdateCheckTime({
    DateTime? ignoreAppsCheckedAfter,
    bool onlyCheckInstalledOrTrackOnlyApps = false,
  }) {
    return AppUpdateService.getAppsSortedByUpdateCheckTime(
      apps,
      ignoreAppsCheckedAfter: ignoreAppsCheckedAfter,
      onlyCheckInstalledOrTrackOnlyApps: onlyCheckInstalledOrTrackOnlyApps,
    );
  }

  Future<List<App>> checkUpdates({
    DateTime? ignoreAppsCheckedAfter,
    bool throwErrorsForRetry = false,
    List<String>? specificIds,
    SettingsProvider? sp,
  }) async {
    return AppUpdateService.checkUpdates(
      apps: apps,
      settingsProvider: sp ?? settingsProvider,
      checkUpdateFn: checkUpdate,
      ignoreAppsCheckedAfter: ignoreAppsCheckedAfter,
      throwErrorsForRetry: throwErrorsForRetry,
      specificIds: specificIds,
      gettingUpdates: gettingUpdates,
      setGettingUpdates: (val) => gettingUpdates = val,
    );
  }

  List<String> findExistingUpdates({
    bool installedOnly = false,
    bool nonInstalledOnly = false,
  }) {
    return AppUpdateService.findExistingUpdates(
      apps,
      installedOnly: installedOnly,
      nonInstalledOnly: nonInstalledOnly,
    );
  }

  Map<String, dynamic> generateExportJSON({
    List<String>? appIds,
    int? overrideExportSettings,
  }) {
    return AppExportService.generateExportJSON(
      apps: apps,
      settingsProvider: settingsProvider,
      appIds: appIds,
      overrideExportSettings: overrideExportSettings,
    );
  }

  Future<String?> export({
    bool pickOnly = false,
    isAuto = false,
    SettingsProvider? sp,
  }) async {
    return AppExportService.export(
      apps: apps,
      settingsProvider: sp ?? settingsProvider,
      pickOnly: pickOnly,
      isAuto: isAuto,
    );
  }

  Future<MapEntry<List<App>, bool>> import(String appsJSON) async {
    return AppExportService.import(
      appsJSON: appsJSON,
      getLoadingApps: () => loadingApps,
      settingsProvider: settingsProvider,
      saveApps: saveApps,
      notifyListeners: notifyListeners,
    );
  }

  @override
  void dispose() {
    foregroundSubscription?.cancel();
    super.dispose();
  }

  Future<List<List<String>>> addAppsByURL(
    List<String> urls, {
    AppSource? sourceOverride,
  }) async {
    List<dynamic> results = await SourceProvider().getAppsByURLNaive(
      urls,
      alreadyAddedUrls: apps.values.map((e) => e.app.url).toList(),
      sourceOverride: sourceOverride,
    );
    List<App> pps = results[0];
    Map<String, dynamic> errorsMap = results[1];
    for (var app in pps) {
      if (apps.containsKey(app.id)) {
        errorsMap.addAll({app.id: tr('appAlreadyAdded')});
      } else {
        await saveApps([app], onlyIfExists: false);
      }
    }
    List<List<String>> errors = errorsMap.keys
        .map((e) => [e, errorsMap[e].toString()])
        .toList();
    return errors;
  }
}