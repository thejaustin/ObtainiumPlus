import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/app_sources/directAPKLink.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/app_utils.dart';

// Data class to store removed apps for undo functionality
class RemovedAppData {
  final App app;
  final List<File> apkFiles;
  final DateTime removalTime;

  RemovedAppData(this.app, this.apkFiles, this.removalTime);
}

class AppCRUDService {
  AppCRUDService._();

  static final List<RemovedAppData> _recentlyRemovedApps = [];
  static Timer? _cleanupTimer;

  static void addMissingCategories({
    required ViewSettingsProvider viewSettings,
    required Map<String, AppInMemory> apps,
    required dynamic appsProvider,
  }) {
    var cats = viewSettings.categories;
    apps.forEach((key, value) {
      for (var c in value.app.categories) {
        if (!cats.containsKey(c)) {
          cats[c] = generateRandomLightColor().value;
        }
      }
    });
    viewSettings.setCategories(cats, appsProvider: appsProvider);
  }

  static Future<void> saveApps({
    required List<App> appsToSave,
    required Map<String, AppInMemory> apps,
    required LogsProvider logs,
    required SettingsProvider settingsProvider,
    required Function() notifyListeners,
    required Future<String?> Function({bool isAuto}) export,
    bool attemptToCorrectInstallStatus = true,
    bool onlyIfExists = true,
  }) async {
    await Future.wait(
      appsToSave.map((a) async {
        var app = a.deepCopy();
        PackageInfo? info = await AppInstallService.getInstalledInfo(app.id);
        var icon = await info?.applicationInfo?.getAppIcon();
        app.name = await (info?.applicationInfo?.getAppLabel()) ?? app.name;
        if (attemptToCorrectInstallStatus) {
          app =
              AppCRUDService.getCorrectedInstallStatusAppIfPossible(
                app,
                info,
                logs,
              ) ??
              app;
        }
        if (!onlyIfExists || apps.containsKey(app.id)) {
          await AppCRUDService.saveAppToDisk(app);
        }
        try {
          apps.update(
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
    settingsProvider.prefs?.setInt('trackedAppCount', apps.length);
  }

  static Future<void> removeApps({
    required List<String> appIds,
    required Map<String, AppInMemory> apps,
    required LogsProvider logs,
    required SettingsProvider settingsProvider,
    required Directory? APKDir,
    required Function() notifyListeners,
    required Future<String?> Function({bool isAuto}) export,
  }) async {
    var apkFiles = APKDir?.listSync() ?? [];

    // Store removed apps for potential undo
    for (String appId in appIds) {
      if (apps.containsKey(appId)) {
        try {
          // Find associated APK files for this app
          List<File> appApkFiles = apkFiles
              .where(
                (element) => element.path.split('/').last.startsWith('$appId-'),
              )
              .cast<File>()
              .toList();

          // Store the app data for potential undo via CRUD service
          AppCRUDService.addRemovedApp(
            RemovedAppData(
              apps[appId]!.app, // Store the original app object
              appApkFiles, // Store associated APK files
              DateTime.now(), // Timestamp for cleanup later
            ),
          );
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
                  (element) =>
                      element.path.split('/').last.startsWith('$appId-'),
                )
                .forEach((element) {
                  try {
                    unawaited(element.delete(recursive: true));
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
      unawaited(export(isAuto: true));
      settingsProvider.prefs?.setInt('trackedAppCount', apps.length);
    }
  }

  static Future<List<List<String>>> addAppsByURL({
    required List<String> urls,
    required Map<String, AppInMemory> apps,
    required Future<void> Function(List<App>, {bool onlyIfExists}) saveApps,
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

  static void addRemovedApp(RemovedAppData data) {
    _recentlyRemovedApps.add(data);
    _startCleanupTimer();
  }

  static RemovedAppData? popLastRemovedApp() {
    if (_recentlyRemovedApps.isNotEmpty) {
      return _recentlyRemovedApps.removeLast();
    }
    return null;
  }

  static void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupOldRemovedApps();
      if (_recentlyRemovedApps.isEmpty) {
        timer.cancel();
      }
    });
  }

  static void _cleanupOldRemovedApps() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    _recentlyRemovedApps.removeWhere((data) {
      if (data.removalTime.isBefore(cutoff)) {
        // Delete associated APK files
        for (var file in data.apkFiles) {
          if (file.existsSync()) {
            AppFileService.deleteFile(file);
          }
        }
        return true;
      }
      return false;
    });
  }

  static bool isVersionDetectionPossible(AppInMemory? app) {
    if (app?.app == null) {
      return false;
    }
    var source = SourceProvider().getSource(
      app!.app.url,
      overrideSource: app.app.overrideSource,
    );
    var naiveStandardVersionDetection =
        app.app.additionalSettings['naiveStandardVersionDetection'] == true ||
        source.naiveStandardVersionDetection;
    String? realInstalledVersion =
        app.app.additionalSettings['useVersionCodeAsOSVersion'] == true
        ? app.installedInfo?.versionCode.toString()
        : app.installedInfo?.versionName;
    bool isHTMLWithNoVersionDetection =
        (source.runtimeType == HTML().runtimeType &&
        (app.app.additionalSettings['versionExtractionRegEx'] as String?)
                ?.isNotEmpty !=
            true);
    bool isDirectAPKLink = source.runtimeType == DirectAPKLink().runtimeType;
    return app.app.additionalSettings['trackOnly'] != true &&
        app.app.additionalSettings['releaseDateAsVersion'] != true &&
        !isHTMLWithNoVersionDetection &&
        !isDirectAPKLink &&
        realInstalledVersion != null &&
        app.app.installedVersion != null &&
        (reconcileVersionDifferences(
                  realInstalledVersion,
                  app.app.installedVersion!,
                ) !=
                null ||
            naiveStandardVersionDetection);
  }

  static App? getCorrectedInstallStatusAppIfPossible(
    App app,
    PackageInfo? installedInfo,
    LogsProvider logs,
  ) {
    var modded = false;
    var trackOnly = app.additionalSettings['trackOnly'] == true;
    var versionDetectionIsStandard =
        app.additionalSettings['versionDetection'] == true;
    var naiveStandardVersionDetection =
        app.additionalSettings['naiveStandardVersionDetection'] == true ||
        SourceProvider()
            .getSource(app.url, overrideSource: app.overrideSource)
            .naiveStandardVersionDetection;
    String? realInstalledVersion =
        app.additionalSettings['useVersionCodeAsOSVersion'] == true
        ? installedInfo?.versionCode.toString()
        : installedInfo?.versionName;

    // For ObtainiumPlus and other "Plus" apps, we want to be more aggressive about reconciliation
    // to ensure these apps don't show a stale version after an update.
    bool aggressiveRec =
        AppConstants.plusAppIds.contains(app.id) ||
        app.additionalSettings['aggressiveVersionReconciliation'] == true;
    if (aggressiveRec &&
        realInstalledVersion != null &&
        realInstalledVersion != app.installedVersion) {
      app.installedVersion = realInstalledVersion;
      modded = true;
    }

    if (installedInfo == null && app.installedVersion != null && !trackOnly) {
      app.installedVersion = null;
      modded = true;
    } else if (realInstalledVersion != null && app.installedVersion == null) {
      app.installedVersion = realInstalledVersion;
      modded = true;
    }
    if (realInstalledVersion != null &&
        realInstalledVersion != app.installedVersion &&
        versionDetectionIsStandard) {
      var correctedInstalledVersion = reconcileVersionDifferences(
        realInstalledVersion,
        app.installedVersion!,
      );
      if (correctedInstalledVersion?.key == false) {
        app.installedVersion = correctedInstalledVersion!.value;
        modded = true;
      } else if (naiveStandardVersionDetection) {
        app.installedVersion = realInstalledVersion;
        modded = true;
      }
    }
    if (app.installedVersion != null &&
        AppUpdateService.areVersionsDifferent(
          app,
          app.installedVersion,
          app.latestVersion,
        ) &&
        versionDetectionIsStandard) {
      var correctedInstalledVersion = reconcileVersionDifferences(
        app.installedVersion!,
        app.latestVersion,
      );
      if (correctedInstalledVersion?.key == true) {
        app.installedVersion = correctedInstalledVersion!.value;
        modded = true;
      }
    }
    if (installedInfo != null &&
        versionDetectionIsStandard &&
        !isVersionDetectionPossible(
          AppInMemory(app, null, installedInfo, null),
        )) {
      app.additionalSettings['versionDetection'] = false;
      app.installedVersion = app.latestVersion;
      logs.add('Could not reconcile version formats for: ${app.id}');
      modded = true;
    }

    return modded ? app : null;
  }

  static Future<void> saveAppToDisk(App app) async {
    String filePath =
        '${(await AppFileService.getAppsDir()).path}/${app.id}.json';
    File('$filePath.tmp').writeAsStringSync(jsonEncode(app.toJson()));
    File('$filePath.tmp').renameSync(filePath);
  }

  static Future<void> deleteAppFile(String appId) async {
    File file = File('${(await AppFileService.getAppsDir()).path}/$appId.json');
    if (file.existsSync()) {
      AppFileService.deleteFile(file);
    }
  }

  static Future<void> loadApps({
    required Map<String, AppInMemory> apps,
    required LogsProvider logs,
    required SettingsProvider settingsProvider,
    required Function() notifyListeners,
    required Function(List<String>) removeApps,
    String? singleId,
  }) async {
    var sp = SourceProvider();
    List<List<String>> errors = [];
    var installedAppsData = await AppInstallService.getAllInstalledInfo();
    List<String> removedAppIds = [];
    await Future.wait(
      (await AppFileService.getAppsDir()).listSync().map((item) async {
        App? app;
        if (item.path.toLowerCase().endsWith('.json') &&
            (singleId == null ||
                item.path.split('/').last.toLowerCase() ==
                    '${singleId.toLowerCase()}.json')) {
          try {
            app = App.fromJson(jsonDecode(File(item.path).readAsStringSync()));
          } catch (err) {
            // Catch FormatException and any JSON-related errors
            if (err is FormatException ||
                err.toString().contains('FormatException')) {
              logs.add('Corrupt JSON when loading App (will be ignored): $err');
              try {
                item.renameSync('${item.path}.corrupt');
              } catch (renameErr) {
                logs.add('Failed to rename corrupt file: $renameErr');
              }
            } else {
              // Log but don't crash on other errors during app loading
              logs.add('Error loading app from ${item.path}: $err');
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
          if (singleId != null) notifyListeners();
          try {
            sp.getSource(app.url, overrideSource: app.overrideSource);
            // Find installed info for this app (null if not installed)
            PackageInfo? installedInfo;
            for (var info in installedAppsData) {
              if (info.packageName == app!.id) {
                installedInfo = info;
                break;
              }
            }
            var moddedApp =
                AppCRUDService.getCorrectedInstallStatusAppIfPossible(
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
            if (singleId != null) notifyListeners();
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
  }
}

