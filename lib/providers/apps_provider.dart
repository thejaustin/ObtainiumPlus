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
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_export_service.dart';
import 'package:obtainium/services/app_icon_service.dart';
import 'package:obtainium/services/offline_service.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/components/apps/app_dialogs.dart';
// ... (imports)

class AppsProvider with ChangeNotifier {
  // ... (fields)
  late SettingsProvider settingsProvider = SettingsProvider();
  final OfflineService _offlineService = OfflineService();

  // ... (constructor)

  /// Initializes the AppsProvider by loading settings and apps from storage.
  /// This method is called automatically in the constructor for foreground instances.
  Future<void> initialize() async {
    // Register eviction handler...
    AppIconService.setEvictionHandler((appId) {
      if (apps.containsKey(appId) && apps[appId]?.icon != null) {
        apps.update(
          appId,
          (value) => AppInMemory(
            value.app,
            value.downloadProgress,
            value.installedInfo,
            null,
          ),
        );
      }
    });

    await settingsProvider.initializeSettings();
    
    // Initialize Offline Service
    await _offlineService.initialize(settingsProvider, (queuedAppIds) {
      if (queuedAppIds.isNotEmpty) {
        logs.add('OfflineService: Processing queue: ${queuedAppIds.join(', ')}');
        checkUpdates(specificIds: queuedAppIds);
        Fluttertoast.showToast(msg: tr('processingOfflineQueue', args: [queuedAppIds.length.toString()]));
      }
    });

    var cacheDirs = await getExternalCacheDirectories();
    // ...
  }

  // ...

  /// Checks for updates for a single app.
  /// Returns the updated [App] object if an update is found, or null if no update is found.
  Future<App?> checkUpdate(String appId, {bool ignoreCache = false}) async {
    if (_offlineService.isOffline) {
      _offlineService.addToQueue(appId, settingsProvider);
      Fluttertoast.showToast(msg: tr('addedToOfflineQueue', args: [apps[appId]?.name ?? appId]));
      return null;
    }
    return AppUpdateService.checkUpdate(appId, apps, saveApps, ignoreCache: ignoreCache);
  }
// ...