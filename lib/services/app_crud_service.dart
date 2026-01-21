import 'dart:convert';
import 'dart:io';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/app_sources/directAPKLink.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/utils/version_utils.dart';

class AppCRUDService {
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
        app.installedVersion != app.latestVersion &&
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
    String filePath = '${(await AppFileService.getAppsDir()).path}/${app.id}.json';
    File(
      '$filePath.tmp',
    ).writeAsStringSync(jsonEncode(app.toJson()));
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
                // Catch FormatException and any JSON-related errors
                if (err is FormatException || err.toString().contains('FormatException')) {
                  logs.add(
                    'Corrupt JSON when loading App (will be ignored): $err',
                  );
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
              notifyListeners();
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
  }
}
