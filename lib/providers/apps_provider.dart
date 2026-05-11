// Manages state related to the list of Apps tracked by Obtainium,
// Exposes related functions such as those used to add, remove, download, and install Apps.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:battery_plus/battery_plus.dart';
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
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/utils/comparable_utils.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_export_service.dart';
import 'package:obtainium/services/app_icon_service.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/dialog_utils.dart';
import 'package:obtainium/components/apps/app_dialogs.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/models/downloaded_artifact.dart';

export 'package:obtainium/models/app_in_memory.dart';
export 'package:obtainium/models/app.dart';

import 'package:obtainium/services/app_filter_service.dart';
import 'package:obtainium/services/app_removal_service.dart';

class AppsProvider with ChangeNotifier {
  // In memory App state (should always be kept in sync with local storage versions)
  Map<String, AppInMemory> apps = {};
  bool loadingApps = false;
  bool gettingUpdates = false;
  final Set<String> checkingUpdateIds = {};
  final Set<String> _cancelledDownloadIds = {};
  LogsProvider logs = LogsProvider();

  // Completer for proper async synchronization of loadApps
  Completer<void>? _loadAppsCompleter;

  // Variables to keep track of the app foreground status (installs can't run in the background)
  bool isForeground = true;
  late Stream<FGBGType>? foregroundStream;
  late StreamSubscription<FGBGType>? foregroundSubscription;

  // Bulk Selection State
  final Set<String> _selectedAppIds = {};
  Set<String> get selectedAppIds => _selectedAppIds;
  bool get isSelectionMode => _selectedAppIds.isNotEmpty;

  void toggleAppSelection(String appId) {
    if (_selectedAppIds.contains(appId)) {
      _selectedAppIds.remove(appId);
    } else {
      _selectedAppIds.add(appId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedAppIds.clear();
    notifyListeners();
  }
  
  Directory? _APKDir;
  Directory? _iconsCacheDir;

  Directory? get APKDir => _APKDir;
  Directory? get iconsCacheDir => _iconsCacheDir;

  late SettingsProvider settingsProvider;
  String? _lastObtainiumReleaseChannel;

  // Completer for the overall initialization of the provider
  Completer<void>? _initCompleter;
  Future<void> get initializationDone => _initCompleter?.future ?? Future.value();

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
    return AppFilterService.getFilteredSortedApps(
      apps: getAppValues(deepCopy: false),
      filter: filter,
      sortMethod: sortMethod,
      sortColumn: sortColumn,
      sortOrder: sortOrder,
      pinUpdates: pinUpdates,
      groupByCategory: groupByCategory,
      buryNonInstalled: buryNonInstalled,
      existingUpdates: findExistingUpdates(installedOnly: true),
    );
  }

  AppsProvider({bool isBg = false, SettingsProvider? settings}) {
    _initCompleter = Completer<void>();
    settingsProvider = settings ?? SettingsProvider();
    
    // Subscribe to changes in the app foreground status
    if (!isBg) {
      foregroundStream = FGBGEvents.instance.stream.asBroadcastStream();
      foregroundSubscription = foregroundStream?.listen((event) async {
        isForeground = event == FGBGType.foreground;
        if (isForeground) {
          await initializationDone;
          await loadApps();
        }
      });

      // Listen for settings changes that might require an immediate Obtainium+ update check
      settingsProvider.addListener(_onSettingsChanged);
    }

    // Always call initialize to set up directories and load apps
    unawaited(initialize());
  }

  void _onSettingsChanged() {
    if (settingsProvider.obtainiumReleaseChannel != _lastObtainiumReleaseChannel) {
      final oldChannel = _lastObtainiumReleaseChannel;
      _lastObtainiumReleaseChannel = settingsProvider.obtainiumReleaseChannel;
      
      // If the channel changed and we've already initialized (meaning we have an old value to compare against)
      if (oldChannel != null && apps.containsKey(obtainiumId)) {
        unawaited(checkObtainiumUpdate(ignoreCache: true).catchError((e) {
          logs.add('Error checking Obtainium+ update after channel change: $e');
          return null;
        }));
      }
    }
  }

  @override
  void dispose() {
    settingsProvider.removeListener(_onSettingsChanged);
    unawaited(foregroundSubscription?.cancel() ?? Future.value());
    super.dispose();
  }

  /// Initializes the AppsProvider by loading settings and apps from storage.
  /// This method is called automatically in the constructor for foreground instances.
  Future<void> initialize() async {
    if (_initCompleter != null && _initCompleter!.isCompleted) return;
    
    try {
      await settingsProvider.initializeSettings();
      _lastObtainiumReleaseChannel = settingsProvider.obtainiumReleaseChannel;
      // Set up APK and icons cache directories
      var dirs = await AppFileService.initAppDirectories();
      _APKDir = dirs['APKDir']!;
      _iconsCacheDir = dirs['iconsCacheDir']!;
      // Load Apps into memory
      await loadApps();
      // Delete any partial APKs (if safe to do so)
      if (APKDir != null) {
        AppFileService.cleanupPartialApks(APKDir!, areDownloadsRunning());
      }
    } finally {
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter?.complete();
      }
    }
  }

  /// Downloads the latest version of the app.
  /// Returns a [DownloadedApk] or [DownloadedDir] object.
  Future<Object> downloadApp(
    App app,
    BuildContext? context, {
    NotificationsProvider? notificationsProvider,
    bool useExisting = true,
  }) async {
    await initializationDone;
    
    // Check if directories are initialized
    if (APKDir == null) {
      throw ObtainiumError('Storage not initialized. Please restart the app.');
    }
    
    Map<String, dynamic> res = await AppDownloadService.downloadApp(
      app: app,
      apps: apps,
      settingsProvider: settingsProvider,
      logs: logs,
      APKDir: APKDir!,
      notifyListeners: notifyListeners,
      removeApps: removeApps,
      saveApps: (apps, {bool onlyIfExists = true}) => saveApps(apps, onlyIfExists: onlyIfExists),
      context: context,
      notificationsProvider: notificationsProvider,
      useExisting: useExisting,
    );

    bool isAPK = res['isAPK'];
    File downloadedFile = res['downloadedFile'];
    Directory? apkDir = res['apkDir'];
    bool isXAPK = res['isXAPK'];

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

  void cancelDownload(String appId) {
    _cancelledDownloadIds.add(appId);
    notifyListeners();
  }

  bool _isCancelled(String appId) => _cancelledDownloadIds.contains(appId);

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
    if (urlsToSelectFrom.isEmpty) return null;
    MapEntry<String, String>? appFileUrl =
        urlsToSelectFrom[app.preferredApkIndex >= 0
            ? app.preferredApkIndex
            : 0];
    List<String> archs = (await DeviceInfoPlugin().androidInfo).supportedAbis;

    if ((urlsToSelectFrom.length > 1 || evenIfSingleChoice) &&
        context != null) {
      appFileUrl = await showAnimatedDialog(
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
    String? getHost(String url) {
      if (url == 'placeholder') {
        return null;
      }
      var temp = Uri.parse(url).host.split('.');
      return temp.sublist(temp.length - 2).join('.');
    }

    // Domains that belong to the same CDN/infrastructure as their parent host.
    // Treats these as the same source to avoid spurious origin warnings.
    bool isTrustedRelatedDomain(String? sourceHost, String? apkHost) {
      if (sourceHost == null || apkHost == null) return false;
      if (sourceHost == apkHost) return true;
      const githubDomains = {'github.com', 'githubusercontent.com', 'github.io'};
      if (githubDomains.contains(sourceHost) && githubDomains.contains(apkHost)) {
        return true;
      }
      return false;
    }

    if (appFileUrl != null &&
        !isTrustedRelatedDomain(getHost(app.url), getHost(appFileUrl.value)) &&
        getHost(appFileUrl.value) != null &&
        getHost(appFileUrl.value) != 'placeholder' &&
        context != null) {
      if (!(settingsProvider.hideAPKOriginWarning) &&
          await showAnimatedDialog(
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
    if (APKDir == null) {
      throw Exception('APK directory not initialized');
    }
    // Clear any stale cancel flags for these apps before starting
    for (final id in appIds) {
      _cancelledDownloadIds.remove(id);
    }
    try {
      return await AppDownloadService.downloadAndInstallLatestApps(
      appIds: appIds,
      apps: apps,
      settingsProvider: settingsProvider,
      logs: logs,
      APKDir: APKDir!,
      notifyListeners: notifyListeners,
      saveApps: saveApps,
      removeApps: removeApps,
      checkUpdate: checkUpdate,
      confirmAppFileUrl: confirmAppFileUrl,
      canInstallSilently: canInstallSilently,
      waitForUserToReturnToForeground: waitForUserToReturnToForeground,
      context: context,
      notificationsProvider: notificationsProvider,
      forceParallelDownloads: forceParallelDownloads,
      useExisting: useExisting,
      isCancelled: _isCancelled,
    );
    } finally {
      // Clean up cancel flags
      for (final id in appIds) {
        _cancelledDownloadIds.remove(id);
      }
    }
  }

  Future<List<String>> downloadAppAssets(
    List<String> appIds,
    BuildContext context, {
    bool forceParallelDownloads = false,
  }) async {
    return AppDownloadService.downloadAppAssets(
      appIds: appIds,
      apps: apps,
      settingsProvider: settingsProvider,
      logs: logs,
      notifyListeners: notifyListeners,
      confirmAppFileUrl: confirmAppFileUrl,
      checkUpdate: checkUpdate,
      context: context,
      forceParallelDownloads: forceParallelDownloads,
    );
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
    } catch (e) {
      talker.error('Error loading apps: ${e.toString()}');
    } finally {
      loadingApps = false;
      _loadAppsCompleter?.complete();
      _loadAppsCompleter = null;
      notifyListeners();
    }
  }

  Future<void> updateAppIcon(String? appId, {bool ignoreCache = false}) async {
    await initializationDone;
    if (iconsCacheDir == null) return;
    
    await AppIconService.updateAppIcon(
      appId: appId,
      apps: apps,
      iconsCacheDir: iconsCacheDir!,
      notifyListeners: notifyListeners,
      ignoreCache: ignoreCache,
    );
  }

  Future<void> precacheIcons(List<String> appIds) async {
    await initializationDone;
    if (iconsCacheDir == null) return;
    
    await AppIconService.precacheIcons(
      appIds: appIds,
      apps: apps,
      iconsCacheDir: iconsCacheDir!,
      notifyListeners: notifyListeners,
    );
  }

  Future<void> saveApps(
    List<App> appsToSave, {
    bool attemptToCorrectInstallStatus = true,
    bool onlyIfExists = true,
  }) async {
    await AppCRUDService.saveApps(
      appsToSave: appsToSave,
      apps: apps,
      logs: logs,
      settingsProvider: settingsProvider,
      notifyListeners: notifyListeners,
      export: ({bool isAuto = false}) => export(isAuto: isAuto),
      attemptToCorrectInstallStatus: attemptToCorrectInstallStatus,
      onlyIfExists: onlyIfExists,
    );
  }

  Future<void> removeApps(List<String> appIds) async {
    await initializationDone;
    await AppCRUDService.removeApps(
      appIds: appIds,
      apps: apps,
      logs: logs,
      settingsProvider: settingsProvider,
      APKDir: APKDir,
      notifyListeners: notifyListeners,
      export: ({bool isAuto = false}) => export(isAuto: isAuto),
    );
  }

  Future<void> clearAppCache(String appId) async {
    await initializationDone;
    if (APKDir != null) {
      AppFileService.clearAppCache(appId, APKDir!);
    }
    notifyListeners();
  }

  // Method to undo the last app removal
  Future<bool> undoLastRemoval() async {
    RemovedAppData? lastRemoved = AppCRUDService.popLastRemovedApp();
    if (lastRemoved == null) {
      return false; // Nothing to undo
    }

    try {
      // Restore the app to the apps list and persist to disk
      await saveApps([lastRemoved.app], onlyIfExists: false);
      return true;
    } catch (e, stack) {
      // If restoration fails, add it back to the list
      AppCRUDService.addRemovedApp(lastRemoved);
      logs.add('Error restoring app ${lastRemoved.app.id}: $e\n$stack');
      return false;
    }
  }

  Future<bool> removeAppsWithModal(BuildContext context, List<App> apps) async {
    return AppRemovalService.removeAppsWithModal(
      context,
      apps,
      removeApps,
      (apps, {bool attemptToCorrectInstallStatus = true}) => saveApps(apps, attemptToCorrectInstallStatus: attemptToCorrectInstallStatus),
      undoLastRemoval,
      settingsProvider.enableUndoForAppRemoval,
    );
  }

  void addMissingCategories(SettingsProvider settingsProvider) {
    AppCRUDService.addMissingCategories(
      settingsProvider: settingsProvider,
      apps: apps,
      appsProvider: this,
    );
  }

  /// Checks for updates for a single app.
  /// Returns the updated [App] object if an update is found, or null if no update is found.
  Future<App?> checkUpdate(String appId, {bool ignoreCache = false}) async {
    checkingUpdateIds.add(appId);
    notifyListeners();
    try {
      if (appId == obtainiumId) {
        return await checkObtainiumUpdate(ignoreCache: ignoreCache);
      }
      return await AppUpdateService.checkUpdate(appId, apps, saveApps, ignoreCache: ignoreCache);
    } finally {
      checkingUpdateIds.remove(appId);
      notifyListeners();
    }
  }

  Future<App?> checkObtainiumUpdate({bool ignoreCache = false}) async {
    return AppUpdateService.checkObtainiumUpdate(
      apps: apps,
      settingsProvider: settingsProvider,
      checkUpdateFn: (id, {bool ignoreCache = false}) => AppUpdateService.checkUpdate(id, apps, saveApps, ignoreCache: ignoreCache),
      ignoreCache: ignoreCache,
    );
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
    bool isBackground = false,
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
      isBackground: isBackground,
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

    Future<List<List<String>>> addAppsByURL(
      List<String> urls, {
      AppSource? sourceOverride,
    }) async {
      return AppCRUDService.addAppsByURL(
        urls: urls,
        apps: apps,
        saveApps: (apps, {bool onlyIfExists = true}) => saveApps(apps, onlyIfExists: onlyIfExists),
        sourceOverride: sourceOverride,
      );
    }
  }
  