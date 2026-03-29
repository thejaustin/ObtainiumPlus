import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/downloaded_artifact.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

final pm = AndroidPackageManager();
final packageInfoFlags = PackageInfoFlags({PMFlag.getSigningCertificates});

class AppInstallService {
  AppInstallService._();

  static Future<List<PackageInfo>> getAllInstalledInfo() async {
    try {
      return await pm.getInstalledPackages(flags: packageInfoFlags) ?? [];
    } catch (e) {
      talker.error('Error fetching installed packages: ${e.toString()}');
      return [];
    }
  }

  static Future<PackageInfo?> getInstalledInfo(
    String? packageName, {
    bool printErr = true,
  }) async {
    if (packageName != null) {
      try {
        return await pm.getPackageInfo(
          packageName: packageName,
          flags: packageInfoFlags,
        );
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

  static Future<void> openNotificationSettings(String appId) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.settings.APP_NOTIFICATION_SETTINGS',
      arguments: <String, dynamic>{
        'android.provider.extra.APP_PACKAGE': appId,
      },
    );
    await intent.launch();
  }

  static Future<void> openBatteryOptimizationSettings() async {
    const AndroidIntent intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    await intent.launch();
  }

  static Future<void> openInstallUnknownAppsSettings(String appId) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
      data: 'package:$appId',
    );
    await intent.launch();
  }

  static Future<void> openOverlaySettings(String appId) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
      data: 'package:$appId',
    );
    await intent.launch();
  }

  static Future<void> openUsageAccessSettings() async {
    const AndroidIntent intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
    );
    await intent.launch();
  }

  static Future<bool> isUsageAccessGranted() async {
    try {
      final bool? granted = await const MethodChannel('app.obtainiumplus/native')
          .invokeMethod<bool>('isUsageAccessGranted');
      return granted ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openApp(String appId) async {
    await pm.openApp(appId);
  }

  static Future<void> openXiaomiAutostartSettings() async {
    final AndroidIntent intent = AndroidIntent(
      action: 'miui.intent.action.OP_AUTO_START',
      componentName: 'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
    );
    try {
      await intent.launch();
    } catch (e) {
      // Fallback to security center
      final AndroidIntent fallback = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.miui.securitycenter',
      );
      try {
        await fallback.launch();
      } catch (e2) {
        openAppSettings('app.obtainiumplus');
      }
    }
  }

  static Future<void> openXiaomiBatterySaverSettings() async {
    // This is more complex across MIUI versions, usually app settings is best
    // but we can try to open the power center
    final AndroidIntent intent = AndroidIntent(
      action: 'miui.intent.action.POWER_HIDE_MODE_LIST',
      componentName: 'com.miui.securitycenter/com.miui.powercenter.PowerSettings',
    );
    try {
      await intent.launch();
    } catch (e) {
      openAppSettings('app.obtainiumplus');
    }
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

    if (app.id == 'app.obtainiumplus') { // obtainiumId
      return false;
    }
    if (installerPackageName != 'app.obtainiumplus') {
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
    PackageInfo? newInfo;
    try {
      newInfo = await pm.getPackageArchiveInfo(
        archiveFilePath: file.file.path,
      );
    } catch (e) {
      talker.error('Error getting package archive info during installApk: ${e.toString()}');
    }
    if (newInfo == null) {
      try {
        AppFileService.deleteFile(file.file);
        for (var a in additionalAPKs) {
          AppFileService.deleteFile(a.file);
        }
      } catch (e) {
        //
      } finally {
        throw BadDownloadError(appId: file.appId);
      }
    }
    PackageInfo? appInfo = await getInstalledInfo(apps[file.appId]!.app.id);
    logs.add(
      'Installing "${newInfo.packageName}" version "${newInfo.versionName}" versionCode "${newInfo.versionCode}"${appInfo != null ? ' (from existing version "${appInfo.versionName}" versionCode "${appInfo.versionCode}")' : ''}',
    );
    if (appInfo != null &&
        newInfo.versionCode! < appInfo.versionCode! &&
        !(await canDowngradeApps())) {
      throw DowngradeError(appInfo.versionCode!, newInfo.versionCode!, appId: apps[file.appId]!.app.id);
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
        throw InstallError(code, appId: apps[file.appId]!.app.id);
      }
    } else if (code == 0) {
      installed = true;
      apps[file.appId]!.app.installedVersion =
          apps[file.appId]!.app.latestVersion;
      file.file.delete(recursive: true);
    } else if (code == 3 && firstTimeWithContext != null && firstTimeWithContext.mounted) {
      ScaffoldMessenger.of(firstTimeWithContext).showSnackBar(
        SnackBar(content: Text(tr('installationCancelled'))),
      );
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
