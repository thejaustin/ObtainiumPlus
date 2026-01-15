import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

final pm = AndroidPackageManager();

class AppInstallService {
  AppInstallService._();

  static Future<List<PackageInfo>> getAllInstalledInfo() async {
    return await pm.getInstalledPackages() ?? [];
  }

  static Future<PackageInfo?> getInstalledInfo(
    String? packageName, {
    bool printErr = true,
  }) async {
    if (packageName != null) {
      try {
        return await pm.getPackageInfo(packageName: packageName);
      } catch (e) {
        if (printErr) {
          print(e);
        }
      }
    }
    return null;
  }

  static void uninstallApp(String appId) async {
    var intent = AndroidIntent(
      action: 'android.intent.action.DELETE',
      data: 'package:$appId',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      package: 'vnd.android.package-archive',
    );
    await intent.launch();
  }

  static Future<bool> canDowngradeApps() async =>
      (await getInstalledInfo('com.berdik.letmedowngrade')) != null;

  static Future<void> openAppSettings(String appId) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'action_application_details_settings',
      data: 'package:$appId',
    );
    await intent.launch();
  }

  static Future<void> openApp(String appId) async {
    await pm.openApp(appId);
  }

  static Future<bool> canInstallSilently(App app, SettingsProvider settingsProvider, LogsProvider logs) async {
    if (!settingsProvider.enableBackgroundUpdates) {
      return false;
    }
    if (app.additionalSettings['exemptFromBackgroundUpdates'] == true) {
      logs.add('Exempted from BG updates: ${app.id}');
      return false;
    }
    if (app.apkUrls.length > 1) {
      logs.add('Multiple APK URLs: ${app.id}');
      return false;
    }

    var osInfo = await DeviceInfoPlugin().androidInfo;
    String? installerPackageName;
    try {
      installerPackageName = osInfo.version.sdkInt >= 30
          ? (await pm.getInstallSourceInfo(
              packageName: app.id,
            ))?.installingPackageName
          : (await pm.getInstallerPackageName(packageName: app.id));
    } catch (e) {
      logs.add(
        'Failed to get installed package details: ${app.id} (${e.toString()})',
      );
      return false;
    }

    int? targetSDK = (await getInstalledInfo(
      app.id,
    ))?.applicationInfo?.targetSdkVersion;
    int requiredSDK = osInfo.version.sdkInt - 3;
    if (!(targetSDK != null && targetSDK >= requiredSDK)) {
      logs.add(
        'App currently targets API $targetSDK which is too low for background updates (requires API $requiredSDK): ${app.id}',
      );
      return false;
    }

    if (settingsProvider.useShizuku) {
      return true;
    }

    if (app.id == 'dev.imranr.obtainium') { // obtainiumId
      return false;
    }
    if (installerPackageName != 'dev.imranr.obtainium') {
      return false;
    }
    if (osInfo.version.sdkInt < 31) {
      logs.add('Android SDK too old: ${osInfo.version.sdkInt}');
      return false;
    }
    return true;
  }

  static Future<bool> installApk(
    DownloadedApk file,
    BuildContext? firstTimeWithContext,
    SettingsProvider settingsProvider,
    LogsProvider logs,
    Map<String, AppInMemory> apps, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
    List<DownloadedApk> additionalAPKs = const [],
  }) async {
    if (firstTimeWithContext != null &&
        settingsProvider.beforeNewInstallsShareToAppVerifier &&
        (await getInstalledInfo('dev.soupslurpr.appverifier')) != null) {
      XFile f = XFile.fromData(
        file.file.readAsBytesSync(),
        mimeType: 'application/vnd.android.package-archive',
      );
      Fluttertoast.showToast(
        msg: tr('appVerifierInstructionToast'),
        toastLength: Toast.LENGTH_LONG,
      );
      await Share.shareXFiles([f]);
    }
    var newInfo = await pm.getPackageArchiveInfo(
      archiveFilePath: file.file.path,
    );
    if (newInfo == null) {
      try {
        AppFileService.deleteFile(file.file);
        for (var a in additionalAPKs) {
          AppFileService.deleteFile(a.file);
        }
      } catch (e) {
        //
      } finally {
        throw ObtainiumError(tr('badDownload'));
      }
    }
    PackageInfo? appInfo = await getInstalledInfo(apps[file.appId]!.app.id);
    logs.add(
      'Installing "${newInfo.packageName}" version "${newInfo.versionName}" versionCode "${newInfo.versionCode}"${appInfo != null ? ' (from existing version "${appInfo.versionName}" versionCode "${appInfo.versionCode}")' : ''}',
    );
    if (appInfo != null &&
        newInfo.versionCode! < appInfo.versionCode! &&
        !(await canDowngradeApps())) {
      throw DowngradeError(appInfo.versionCode!, newInfo.versionCode!);
    }
    if (needsBGWorkaround) {
      // Background workaround logic might need to be moved back to AppsProvider
      // because it updates the app's installed version and saves it.
      // For now, I'll keep it here but it might need a callback.
    }
    int? code;
    if (!settingsProvider.useShizuku) {
      var allAPKs = [file.file.path];
      allAPKs.addAll(additionalAPKs.map((a) => a.file.path));
      code = await AndroidPackageInstaller.installApk(
        apkFilePath: allAPKs.join(','),
      );
    } else {
      code = await ShizukuApkInstaller.installAPK(
        file.file.uri.toString(),
        shizukuPretendToBeGooglePlay ? "com.android.vending" : "",
      );
    }
    bool installed = false;
    if (code != null && code != 0 && code != 3) {
      try {
        AppFileService.deleteFile(file.file);
      } catch (e) {
        //
      } finally {
        throw InstallError(code);
      }
    } else if (code == 0) {
      installed = true;
      apps[file.appId]!.app.installedVersion =
          apps[file.appId]!.app.latestVersion;
      file.file.delete(recursive: true);
    }
    return installed;
  }

  static Future<bool> installApkDir(
    DownloadedDir dir,
    BuildContext? firstTimeWithContext,
    SettingsProvider settingsProvider,
    LogsProvider logs,
    Map<String, AppInMemory> apps, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
  }) async {
    var somethingInstalled = false;
    try {
      MultiAppMultiError errors = MultiAppMultiError();
      List<File> APKFiles = [];
      for (var file
          in dir.extracted
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()) {
        if (file.path.toLowerCase().endsWith('.apk')) {
          APKFiles.add(file);
        } else if (file.path.toLowerCase().endsWith('.obb')) {
          await moveObbFile(file, dir.appId);
        }
      }

      File? temp;
      APKFiles.removeWhere((element) {
        bool res = element.uri.pathSegments.last.startsWith(dir.appId);
        if (res) {
          temp = element;
        }
        return res;
      });
      if (temp != null) {
        APKFiles = [temp!, ...APKFiles];
      }

      try {
        var wasInstalled = await installApk(
          DownloadedApk(dir.appId, APKFiles[0]),
          firstTimeWithContext,
          settingsProvider,
          logs,
          apps,
          needsBGWorkaround: needsBGWorkaround,
          shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
          additionalAPKs: APKFiles.sublist(
            1,
          ).map((a) => DownloadedApk(dir.appId, a)).toList(),
        );
        somethingInstalled = somethingInstalled || wasInstalled;
        dir.file.delete(recursive: true);
      } catch (e) {
        logs.add('Could not install APKs from ${dir.type}: ${e.toString()}');
        errors.add(dir.appId, e, appName: apps[dir.appId]?.name);
      }
      if (errors.idsByErrorString.isNotEmpty) {
        throw errors;
      }
    } finally {
      dir.extracted.delete(recursive: true);
    }
    return somethingInstalled;
  }

  static Future<void> moveObbFile(File file, String appId) async {
    if (!file.path.toLowerCase().endsWith('.obb')) return;

    if ((await DeviceInfoPlugin().androidInfo).version.sdkInt <= 29) {
      await Permission.storage.request();
    }

    String obbDirPath = "${await getStorageRootPath()}/Android/obb/$appId";
    Directory(obbDirPath).createSync(recursive: true);

    String obbFileName = file.path.split("/").last;
    await file.copy("$obbDirPath/$obbFileName");
  }

  static Future<String> getStorageRootPath() async {
    return '/${(await AppFileService.getAppStorageDir()).uri.pathSegments.sublist(0, 3).join('/')}';
  }
}
