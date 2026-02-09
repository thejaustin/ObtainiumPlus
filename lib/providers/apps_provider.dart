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
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/source_utils.dart';
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
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/utils/comparable_utils.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_export_service.dart';
import 'package:obtainium/services/app_icon_service.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/components/apps/app_dialogs.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/downloaded_artifact.dart';

export 'package:obtainium/models/app_in_memory.dart';

// Data class to store removed apps for undo functionality
class RemovedAppData {
  final App app;
  final List<File> apkFiles;
  final DateTime removalTime;

  RemovedAppData(this.app, this.apkFiles, this.removalTime);
}

class AppsProvider with ChangeNotifier {
  // In memory App state (should always be kept in sync with local storage versions)
  Map<String, AppInMemory> apps = {};
  bool loadingApps = false;
  bool gettingUpdates = false;
  LogsProvider logs = LogsProvider();

  // Undo functionality - store recently removed apps
  final List<RemovedAppData> _recentlyRemovedApps = [];
  Timer? _cleanupTimer;

  // Completer for proper async synchronization of loadApps
  Completer<void>? _loadAppsCompleter;

  // Variables to keep track of the app foreground status (installs can't run in the background)
  bool isForeground = true;
  late Stream<FGBGType>? foregroundStream;
  late StreamSubscription<FGBGType>? foregroundSubscription;
  late Directory APKDir;
  late Directory iconsCacheDir;
  late SettingsProvider settingsProvider = SettingsProvider();

  // Optimized: Return values directly unless deep copy is explicitly needed
  Iterable<AppInMemory> getAppValues({bool deepCopy = true}) => 
      deepCopy ? apps.values.map((a) => a.deepCopy()) : apps.values;

  List<AppInMemory> getFilteredSortedApps({
    required AppsFilter filter,
    required AppSortMethod sortMethod,
    required SortColumnSettings sortColumn,
    required SortOrderSettings sortOrder,
    required bool pinUpdates,
    required bool groupByCategory,
    required bool buryNonInstalled,
  }) {
    var listedApps = getAppValues(deepCopy: false).where((app) {
      if (filter.statusFilter.isNotEmpty) {
        bool hasUpdate = app.app.installedVersion != null && app.app.installedVersion != app.app.latestVersion;
        bool notInstalled = app.app.installedVersion == null;

        bool matches = false;
        if (filter.statusFilter.contains('updates') && hasUpdate) matches = true;
        if (filter.statusFilter.contains('installed') && !notInstalled) matches = true;
        if (filter.statusFilter.contains('trackonly') && app.app.additionalSettings['trackOnly'] == true) matches = true;
        if (filter.statusFilter.contains('uptodate') && app.app.installedVersion != null && !hasUpdate) matches = true;
        if (filter.statusFilter.contains('notinstalled') && notInstalled) matches = true;

        if (!matches) return false;
      }

      if (app.app.installedVersion == app.app.latestVersion && !filter.includeUptodate) return false;
      if (app.app.installedVersion == null && !filter.includeNonInstalled) return false;

      if (filter.nameFilter.isNotEmpty || filter.authorFilter.isNotEmpty) {
        List<String> nameTokens = filter.nameFilter.split(' ').where((e) => e.trim().isNotEmpty).toList();
        List<String> authorTokens = filter.authorFilter.split(' ').where((e) => e.trim().isNotEmpty).toList();

        for (var t in nameTokens) {
          if (!app.name.toLowerCase().contains(t.toLowerCase())) return false;
        }
        for (var t in authorTokens) {
          if (!app.author.toLowerCase().contains(t.toLowerCase())) return false;
        }
      }
      if (filter.idFilter.isNotEmpty && !app.app.id.contains(filter.idFilter)) return false;
      if (filter.categoryFilter.isNotEmpty && filter.categoryFilter.intersection(app.app.categories.toSet()).isEmpty) return false;
      if (filter.sourceFilter.isNotEmpty && SourceProvider().getSource(app.app.url, overrideSource: app.app.overrideSource).runtimeType.toString() != filter.sourceFilter) return false;
      
      return true;
    }).toList();

    // Sorting
    if (sortMethod == AppSortMethod.latestUpdates) {
      listedApps.sort((a, b) {
        final aDate = a.installedInfo?.lastUpdateTime != null ? DateTime.fromMillisecondsSinceEpoch(a.installedInfo!.lastUpdateTime!) : null;
        final bDate = b.installedInfo?.lastUpdateTime != null ? DateTime.fromMillisecondsSinceEpoch(b.installedInfo!.lastUpdateTime!) : null;
        if (aDate == null && bDate == null) return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    } else if (sortMethod == AppSortMethod.nameAZ) {
      listedApps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (sortMethod == AppSortMethod.nameZA) {
      listedApps.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (sortMethod == AppSortMethod.recentlyAdded) {
      listedApps.sort((a, b) => b.app.id.toLowerCase().compareTo(a.app.id.toLowerCase()));
    } else if (sortMethod == AppSortMethod.installStatus) {
      listedApps.sort((a, b) {
        if ((a.installedInfo != null) == (b.installedInfo != null)) return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return a.installedInfo != null ? -1 : 1;
      });
    } else if (sortMethod == AppSortMethod.defaultSort) {
      listedApps.sort((a, b) {
        dynamic aVal;
        dynamic bVal;
        switch (sortColumn) {
          case SortColumnSettings.added: aVal = a.app.id; bVal = b.app.id; break;
          case SortColumnSettings.nameAuthor: aVal = a.name; bVal = b.name; break;
          case SortColumnSettings.authorName: aVal = a.author; bVal = b.author; break;
          case SortColumnSettings.releaseDate: aVal = a.app.releaseDate; bVal = b.app.releaseDate; break;
          case SortColumnSettings.lastUpdated: aVal = a.app.lastUpdateCheck; bVal = b.app.lastUpdateCheck; break;
          case SortColumnSettings.source: aVal = a.app.url; bVal = b.app.url; break;
          case SortColumnSettings.installDate: aVal = a.installedInfo?.firstInstallTime; bVal = b.installedInfo?.firstInstallTime; break;
          case SortColumnSettings.lastCheckDate: aVal = a.app.lastUpdateCheck; bVal = b.app.lastUpdateCheck; break;
        }
        int res = 0;
        if (aVal == null && bVal == null) res = 0;
        else if (aVal == null) res = 1;
        else if (bVal == null) res = -1;
        else if (aVal is String) res = aVal.toLowerCase().compareTo(bVal.toString().toLowerCase());
        else if (aVal is DateTime) res = aVal.compareTo(bVal as DateTime);
        else if (aVal is num) res = aVal.compareTo(bVal as num);
        
        if (res == 0) res = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return sortOrder == SortOrderSettings.ascending ? res : -res;
      });
    }

    if (pinUpdates) {
      final existingUpdates = findExistingUpdates(installedOnly: true);
      var temp = listedApps.where((sa) => existingUpdates.contains(sa.app.id)).toList();
      listedApps.removeWhere((sa) => existingUpdates.contains(sa.app.id));
      listedApps = [...temp, ...listedApps];
    }

    if (buryNonInstalled) {
      var temp = listedApps.where((a) => a.installedInfo == null).toList();
      listedApps.removeWhere((a) => a.installedInfo == null);
      listedApps = [...listedApps, ...temp];
    }

    var tempPinned = listedApps.where((a) => a.app.pinned).toList();
    var tempNotPinned = listedApps.where((a) => !a.app.pinned).toList();
    listedApps = [...tempPinned, ...tempNotPinned];

    return listedApps;
  }

  AppsProvider({isBg = false}) {
    // Subscribe to changes in the app foreground status
    foregroundStream = FGBGEvents.instance.stream.asBroadcastStream();
    foregroundSubscription = foregroundStream?.listen((event) async {
      isForeground = event == FGBGType.foreground;
      if (isForeground) {
        await loadApps();
      }
    });
    if (!isBg) {
      initialize();
    }
  }

  /// Initializes the AppsProvider by loading settings and apps from storage.
  /// This method is called automatically in the constructor for foreground instances.
  Future<void> initialize() async {
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
    // Load Apps into memory
    await loadApps();
    // Delete any partial APKs (if safe to do so)
    var cutoff = DateTime.now().subtract(const Duration(days: 7));
    try {
      APKDir.listSync()
          .where((element) => element.statSync().modified.isBefore(cutoff))
          .forEach((partialApk) {
            if (!areDownloadsRunning()) {
              partialApk.delete(recursive: true);
            }
          });
    } catch (e) {
      // Ignore errors listing/deleting directory
    }
  }

  Future<File> handleAPKIDChange(
    App app,
    PackageInfo newInfo,
    File downloadedFile,
    String downloadUrl,
  ) async {
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

  /// Downloads the latest version of the app.
  /// Returns a [DownloadedApk] or [DownloadedDir] object.
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

  /// Installs a downloaded APK file.
  /// Returns true if installation was successful.
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
    return AppDownloadService.downloadAndInstallLatestApps(
      appIds: appIds,
      apps: apps,
      settingsProvider: settingsProvider,
      logs: logs,
      APKDir: APKDir,
      notifyListeners: notifyListeners,
      saveApps: saveApps,
      checkUpdate: checkUpdate,
      confirmAppFileUrl: confirmAppFileUrl,
      canInstallSilently: canInstallSilently,
      waitForUserToReturnToForeground: waitForUserToReturnToForeground,
      context: context,
      notificationsProvider: notificationsProvider,
      forceParallelDownloads: forceParallelDownloads,
      useExisting: useExisting,
    );
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



  /// Loads apps from storage into memory.
  /// If [singleId] is provided, only that app is reloaded.
  Future<void> loadApps({String? singleId}) async {
    // If already loading, wait for the existing operation to complete
    if (loadingApps && _loadAppsCompleter != null) {
      await _loadAppsCompleter!.future;
      return;
    }
    loadingApps = true;
    _loadAppsCompleter = Completer<void>();
    notifyListeners();

    try {
      await AppCRUDService.loadApps(
        apps: apps,
        logs: logs,
        settingsProvider: settingsProvider,
        notifyListeners: notifyListeners,
        removeApps: removeApps,
        singleId: singleId,
      );
    } finally {
      loadingApps = false;
      _loadAppsCompleter?.complete();
      _loadAppsCompleter = null;
      notifyListeners();
    }
  }

  Future<void> updateAppIcon(String? appId, {bool ignoreCache = false}) async {
    await AppIconService.updateAppIcon(
      appId: appId,
      apps: apps,
      iconsCacheDir: iconsCacheDir,
      notifyListeners: notifyListeners,
      ignoreCache: ignoreCache,
    );
  }

  Future<void> precacheIcons(List<String> appIds) async {
    await AppIconService.precacheIcons(
      appIds: appIds,
      apps: apps,
      iconsCacheDir: iconsCacheDir,
      notifyListeners: notifyListeners,
    );
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

    // Update app count for smart defaults in settings
    settingsProvider.prefs?.setInt('trackedAppCount', this.apps.length);
  }

  Future<void> removeApps(List<String> appIds) async {
    var apkFiles = APKDir.listSync();

    // Store removed apps for potential undo
    for (String appId in appIds) {
      if (apps.containsKey(appId)) {
        try {
          // Find associated APK files for this app
          List<File> appApkFiles = apkFiles
              .where((element) => element.path.split('/').last.startsWith('$appId-'))
              .cast<File>()
              .toList();

          // Store the app data for potential undo
          _recentlyRemovedApps.add(RemovedAppData(
            apps[appId]!.app, // Store the original app object
            appApkFiles,      // Store associated APK files
            DateTime.now(),   // Timestamp for cleanup later
          ));
        } catch (e, stack) {
          logs.add('Error preparing app $appId for removal: $e\n$stack');
        }
      }
    }

    try {
      await Future.wait(
        appIds.map((appId) async {
          try {
            await AppCRUDService.deleteAppFile(appId);
            apkFiles
                .where(
                  (element) => element.path.split('/').last.startsWith('$appId-'),
                )
                .forEach((element) {
                  try {
                    element.delete(recursive: true);
                  } catch (e) {
                    logs.add('Error deleting APK file ${element.path}: $e');
                  }
                });
            if (apps.containsKey(appId)) {
              apps.remove(appId);
            }
          } catch (e, stack) {
            logs.add('Error removing app $appId: $e\n$stack');
          }
        }),
      );
    } catch (e, stack) {
      logs.add('Error in bulk app removal: $e\n$stack');
    }

    if (appIds.isNotEmpty) {
      notifyListeners();
      export(isAuto: true);

      // Start timer to clean up old removed apps after 60 seconds
      _cleanupTimer?.cancel();
      _cleanupTimer = Timer(const Duration(seconds: 60), () {
        _cleanupOldRemovedApps();
      });
    }
  }

  // Helper method to clean up old removed apps
  void _cleanupOldRemovedApps() {
    final now = DateTime.now();
    _recentlyRemovedApps.removeWhere((removedApp) {
      return now.difference(removedApp.removalTime).inSeconds > 60;
    });
  }

  // Method to undo the last app removal
  Future<bool> undoLastRemoval() async {
    if (_recentlyRemovedApps.isEmpty) {
      return false; // Nothing to undo
    }

    // Get the most recently removed app
    RemovedAppData lastRemoved = _recentlyRemovedApps.removeLast();

    try {
      // Restore the app to the apps list
      apps[lastRemoved.app.id] = AppInMemory(lastRemoved.app, null, null, null);

      // Notify listeners about the change
      notifyListeners();
      export(isAuto: true);

      return true;
    } catch (e, stack) {
      // If restoration fails, add it back to the list
      _recentlyRemovedApps.add(lastRemoved);
      logs.add('Error restoring app ${lastRemoved.app.id}: $e\n$stack');
      return false;
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
        List<String> appIdsToRemove = apps.map((e) => e.id).toList();
        await removeApps(appIdsToRemove);

        // Show snackbar with undo option if enabled in settings
        if (context.mounted && settingsProvider.enableUndoForAppRemoval) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(plural('appsRemoved', apps.length)),
              action: SnackBarAction(
                label: tr('undo'),
                onPressed: () async {
                  bool success = await undoLastRemoval();
                  if (success && context.mounted) {
                    showMessage(tr('appsRestored'), context);
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      return uninstall || remove;
    }
    return false;
  }

  void clearAppCache(String appId) {
    var apkFiles = APKDir.listSync();
    apkFiles
        .where(
          (element) => element.path.split('/').last.startsWith('$appId-'),
        )
        .forEach((element) {
          try {
            element.deleteSync(recursive: true);
          } catch (e) {
            // Ignore
          }
        });
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

  /// Checks for updates for a single app.
  /// Returns the updated [App] object if an update is found, or null if no update is found.
  Future<App?> checkUpdate(String appId, {bool ignoreCache = false}) async {
    return AppUpdateService.checkUpdate(appId, apps, saveApps, ignoreCache: ignoreCache);
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
    bool ignoreCache = false,
  }) async {
    return AppUpdateService.checkUpdates(
      apps: apps,
      settingsProvider: sp ?? settingsProvider,
      checkUpdateFn: (id) => checkUpdate(id, ignoreCache: ignoreCache),
      ignoreAppsCheckedAfter: ignoreAppsCheckedAfter,
      throwErrorsForRetry: throwErrorsForRetry,
      specificIds: specificIds,
      gettingUpdates: gettingUpdates,
      setGettingUpdates: (val) => gettingUpdates = val,
      ignoreCache: ignoreCache,
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