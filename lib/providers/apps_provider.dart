import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/app_utils.dart' show safeJsonEncode;
import 'package:home_widget/home_widget.dart';
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
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/services/app_download_service.dart';
export 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:obtainium/components/glass_dialog.dart';
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
import 'package:obtainium/models/downloaded_artifact.dart';
export 'package:obtainium/models/downloaded_artifact.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pm = AndroidPackageManager();
final packageInfoFlags = PackageInfoFlags({PMFlag.getSigningCertificates});

List<String> generateStandardVersionRegExStrings() {
  var basics = [
    '[0-9]+',
    '[0-9]+\\.[0-9]+',
    '[0-9]+\\.[0-9]+\\.[0-9]+',
    '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+',
  ];
  var preSuffixes = ['-', '\\+'];
  // 'p[0-9]+' covers patch-style suffixes like 1.4.3-p15 (used by
  // Obtainium+ itself) — without it version detection gets auto-disabled
  // and the installed version freezes (issue #218)
  var suffixes = ['alpha', 'beta', 'ose', 'p[0-9]+', 'rc[0-9]+', '[0-9]+'];
  var finals = ['\\+[0-9]+', '[0-9]+'];
  List<String> results = [];
  for (var b in basics) {
    results.add(b);
    for (var p in preSuffixes) {
      for (var s in suffixes) {
        results.add('$b$s');
        results.add('$b$p$s');
        for (var f in finals) {
          results.add('$b$s$f');
          results.add('$b$p$s$f');
        }
      }
    }
  }
  return results;
}

List<String> standardVersionRegExStrings =
    generateStandardVersionRegExStrings();

Set<String> findStandardFormatsForVersion(String version, bool strict) {
  // If !strict, even a substring match is valid
  Set<String> results = {};
  for (var pattern in standardVersionRegExStrings) {
    if (RegExp(
      '${strict ? '^' : ''}$pattern${strict ? '\$' : ''}',
    ).hasMatch(version)) {
      results.add(pattern);
    }
  }
  return results;
}

List<String> moveStrToEnd(List<String> arr, String str, {String? strB}) {
  String? temp;
  arr.removeWhere((element) {
    bool res = element == str || element == strB;
    if (res) {
      temp = element;
    }
    return res;
  });
  if (temp != null) {
    arr = [...arr, temp!];
  }
  return arr;
}

List<MapEntry<String, int>> moveStrToEndMapEntryWithCount(
  List<MapEntry<String, int>> arr,
  MapEntry<String, int> str, {
  MapEntry<String, int>? strB,
}) {
  MapEntry<String, int>? temp;
  arr.removeWhere((element) {
    bool resA = element.key == str.key;
    bool resB = element.key == strB?.key;
    if (resA) {
      temp = str;
    } else if (resB) {
      temp = strB;
    }
    return resA || resB;
  });
  if (temp != null) {
    arr = [...arr, temp!];
  }
  return arr;
}

Future<File> downloadFileWithRetry(
  String url,
  String fileName,
  bool fileNameHasExt,
  Function? onProgress,
  String destDir, {
  bool useExisting = true,
  Map<String, String>? headers,
  int retries = 3,
  bool allowInsecure = false,
  LogsProvider? logs,
}) async {
  try {
    return await downloadFile(
      url,
      fileName,
      fileNameHasExt,
      onProgress,
      destDir,
      useExisting: useExisting,
      headers: headers,
      allowInsecure: allowInsecure,
      logs: logs,
    );
  } catch (e) {
    if (retries > 0 && e is ClientException) {
      await Future.delayed(const Duration(seconds: 5));
      return await downloadFileWithRetry(
        url,
        fileName,
        fileNameHasExt,
        onProgress,
        destDir,
        useExisting: useExisting,
        headers: headers,
        retries: (retries - 1),
        allowInsecure: allowInsecure,
        logs: logs,
      );
    } else {
      rethrow;
    }
  }
}

String hashListOfLists(List<List<int>> data) {
  var bytes = utf8.encode(jsonEncode(data));
  var digest = sha256.convert(bytes);
  var hash = digest.toString();
  return hash.hashCode.toString();
}

Future<String> checkPartialDownloadHashDynamic(
  String url, {
  int startingSize = 1024,
  int lowerLimit = 128,
  Map<String, String>? headers,
  bool allowInsecure = false,
}) async {
  for (int i = startingSize; i >= lowerLimit; i -= 256) {
    List<String> ab = await Future.wait([
      checkPartialDownloadHash(
        url,
        i,
        headers: headers,
        allowInsecure: allowInsecure,
      ),
      checkPartialDownloadHash(
        url,
        i,
        headers: headers,
        allowInsecure: allowInsecure,
      ),
    ]);
    if (ab[0] == ab[1]) {
      return ab[0];
    }
  }
  throw NoVersionError();
}

Future<String> checkPartialDownloadHash(
  String url,
  int bytesToGrab, {
  Map<String, String>? headers,
  bool allowInsecure = false,
}) async {
  var req = Request('GET', Uri.parse(url));
  if (headers != null) {
    req.headers.addAll(headers);
  }
  req.headers[HttpHeaders.rangeHeader] = 'bytes=0-$bytesToGrab';
  var client = IOClient(createHttpClient(allowInsecure));
  var response = await client.send(req);
  if (response.statusCode < 200 || response.statusCode > 299) {
    throw ObtainiumError(response.reasonPhrase ?? tr('unexpectedError'));
  }
  List<List<int>> bytes = await response.stream.take(bytesToGrab).toList();
  return hashListOfLists(bytes);
}

Future<String?> checkETagHeader(
  String url, {
  Map<String, String>? headers,
  bool allowInsecure = false,
}) async {
  // Send the initial request but cancel it as soon as you have the headers
  var reqHeaders = headers ?? {};
  var req = Request('GET', Uri.parse(url));
  req.headers.addAll(reqHeaders);
  var client = IOClient(createHttpClient(allowInsecure));
  StreamedResponse response = await client.send(req);
  var resHeaders = response.headers;
  client.close();
  return resHeaders[HttpHeaders.etagHeader]
      ?.replaceAll('"', '')
      .hashCode
      .toString();
}

void deleteFile(File file) {
  try {
    file.deleteSync(recursive: true);
  } on PathAccessException catch (e) {
    throw ObtainiumError(
      tr('fileDeletionError', args: [e.path ?? tr('unknown')]),
    );
  }
}

Future<File> downloadFile(
  String url,
  String fileName,
  bool fileNameHasExt,
  Function? onProgress,
  String destDir, {
  bool useExisting = true,
  Map<String, String>? headers,
  bool allowInsecure = false,
  LogsProvider? logs,
}) async {
  // Send the initial request but cancel it as soon as you have the headers
  var reqHeaders = headers ?? {};
  var req = Request('GET', Uri.parse(url));
  req.headers.addAll(reqHeaders);
  var headersClient = IOClient(createHttpClient(allowInsecure));
  StreamedResponse headersResponse = await headersClient.send(req);
  var resHeaders = headersResponse.headers;

  // Use the headers to decide what the file extension is, and
  // whether it supports partial downloads (range request), and
  // what the total size of the file is (if provided)
  String ext = resHeaders['content-disposition']?.split('.').last ?? 'apk';
  if (ext.endsWith('"') || ext.endsWith("other")) {
    ext = ext.substring(0, ext.length - 1);
  }
  if (((Uri.tryParse(url)?.path ?? url).toLowerCase().endsWith('.apk') ||
          ext == 'attachment') &&
      ext != 'apk') {
    ext = 'apk';
  }
  fileName = fileNameHasExt
      ? fileName
      : fileName.split('/').last; // Ensure the fileName is a file name
  File downloadedFile = File('$destDir/$fileName.$ext');
  if (fileNameHasExt) {
    // If the user says the filename already has an ext, ignore whatever you inferred from above
    downloadedFile = File('$destDir/$fileName');
  }

  bool rangeFeatureEnabled = false;
  if (resHeaders['accept-ranges']?.isNotEmpty == true) {
    rangeFeatureEnabled =
        resHeaders['accept-ranges']?.trim().toLowerCase() == 'bytes';
  }
  headersClient.close();

  // If you have an existing file that is usable,
  // decide whether you can use it (either return full or resume partial)
  var fullContentLength = headersResponse.contentLength;
  if (useExisting && downloadedFile.existsSync()) {
    var length = downloadedFile.lengthSync();
    if (fullContentLength == null || !rangeFeatureEnabled) {
      // If there is no content length reported, assume it the existing file is fully downloaded
      // Also if the range feature is not supported, don't trust the content length if any (#1542)
      return downloadedFile;
    } else {
      // Check if resume needed/possible
      if (length == fullContentLength) {
        return downloadedFile;
      }
      if (length > fullContentLength) {
        useExisting = false;
      }
    }
  }

  // Download to a '.temp' file (to distinguish btn. complete/incomplete files)
  File tempDownloadedFile = File('${downloadedFile.path}.part');

  // If there is already a temp file, a download may already be in progress - account for this (see #2073)
  bool tempFileExists = tempDownloadedFile.existsSync();
  if (tempFileExists && useExisting) {
    logs?.add(
      'Partial download exists - will wait: ${tempDownloadedFile.uri.pathSegments.last}',
    );
    bool isDownloading = true;
    int currentTempFileSize = await tempDownloadedFile.length();
    bool shouldReturn = false;
    while (isDownloading) {
      await Future.delayed(Duration(seconds: 7));
      if (tempDownloadedFile.existsSync()) {
        int newTempFileSize = await tempDownloadedFile.length();
        if (newTempFileSize > currentTempFileSize) {
          currentTempFileSize = newTempFileSize;
          logs?.add(
            'Existing partial download still in progress: ${tempDownloadedFile.uri.pathSegments.last}',
          );
        } else {
          logs?.add(
            'Ignoring existing partial download: ${tempDownloadedFile.uri.pathSegments.last}',
          );
          break;
        }
      } else {
        shouldReturn = downloadedFile.existsSync();
      }
    }
    if (shouldReturn) {
      logs?.add(
        'Existing partial download completed - not repeating: ${tempDownloadedFile.uri.pathSegments.last}',
      );
      return downloadedFile;
    } else {
      logs?.add(
        'Existing partial download not in progress: ${tempDownloadedFile.uri.pathSegments.last}',
      );
    }
  }

  // If the range feature is not available (or you need to start a ranged req from 0),
  // complete the already-started request, else cancel it and start a ranged request,
  // and open the file for writing in the appropriate mode
  var targetFileLength = useExisting && tempDownloadedFile.existsSync()
      ? tempDownloadedFile.lengthSync()
      : null;
  int rangeStart = targetFileLength ?? 0;
  IOSink? sink;
  req = Request('GET', Uri.parse(url));
  req.headers.addAll(reqHeaders);
  if (rangeFeatureEnabled && fullContentLength != null && rangeStart > 0) {
    reqHeaders.addAll({'range': 'bytes=$rangeStart-${fullContentLength - 1}'});
    sink = tempDownloadedFile.openWrite(mode: FileMode.writeOnlyAppend);
  } else if (tempDownloadedFile.existsSync()) {
    deleteFile(tempDownloadedFile);
  }
  var responseWithClient = await sourceRequestStreamResponse(
    'GET',
    url,
    reqHeaders,
    {},
  );
  HttpClient responseClient = responseWithClient.value.key;
  HttpClientResponse response = responseWithClient.value.value;
  sink ??= tempDownloadedFile.openWrite(mode: FileMode.writeOnly);

  // Perform the download
  var received = 0;
  double? progress;
  DateTime? lastProgressUpdate; // Track last progress update time
  if (rangeStart > 0 && fullContentLength != null) {
    received = rangeStart;
  }
  const downloadUIUpdateInterval = Duration(milliseconds: 500);
  const downloadBufferSize = 32 * 1024; // 32KB
  final downloadBuffer = BytesBuilder();
  await response
      .asBroadcastStream()
      .map((chunk) {
        received += chunk.length;
        final now = DateTime.now();
        if (onProgress != null &&
            (lastProgressUpdate == null ||
                now.difference(lastProgressUpdate!) >=
                    downloadUIUpdateInterval)) {
          progress = fullContentLength != null
              ? clampDouble((received / fullContentLength) * 100, 0, 100)
              : 30;
          onProgress(progress);
          lastProgressUpdate = now;
        }
        return chunk;
      })
      .transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (List<int> data, EventSink<List<int>> s) {
            downloadBuffer.add(data);
            if (downloadBuffer.length >= downloadBufferSize) {
              s.add(downloadBuffer.takeBytes());
            }
          },
          handleDone: (EventSink<List<int>> s) {
            if (downloadBuffer.isNotEmpty) {
              s.add(downloadBuffer.takeBytes());
            }
            s.close();
          },
        ),
      )
      .pipe(sink);
  await sink.close();
  progress = null;
  if (onProgress != null) {
    onProgress(progress);
  }
  if (response.statusCode < 200 || response.statusCode > 299) {
    deleteFile(tempDownloadedFile);
    throw response.reasonPhrase;
  }
  if (tempDownloadedFile.existsSync()) {
    tempDownloadedFile.renameSync(downloadedFile.path);
  }
  responseClient.close();
  return downloadedFile;
}

Future<List<PackageInfo>> getAllInstalledInfo() async {
  return await pm.getInstalledPackages(flags: packageInfoFlags) ?? [];
}

Future<PackageInfo?> getInstalledInfo(
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
        print(e); // OK
      }
    }
  }
  return null;
}

Future<Directory> getAppStorageDir() async =>
    await getExternalStorageDirectory() ??
    await getApplicationDocumentsDirectory();

class AppsProvider with ChangeNotifier {
  // In memory App state (should always be kept in sync with local storage versions)
  Map<String, AppInMemory> apps = {};
  bool loadingApps = false;
  bool gettingUpdates = false;
  LogsProvider logs = LogsProvider();

  bool isSelectionMode = false;
  Set<String> selectedAppIds = {};
  Set<String> checkingUpdateIds = {};
  Set<String> get selectedApps => selectedAppIds;

  void toggleAppSelection(String appId) {
    if (selectedAppIds.contains(appId)) {
      selectedAppIds.remove(appId);
      if (selectedAppIds.isEmpty) {
        isSelectionMode = false;
      }
    } else {
      selectedAppIds.add(appId);
      isSelectionMode = true;
    }
    notifyListeners();
  }

  void selectAll() {
    selectedAppIds = apps.keys.toSet();
    isSelectionMode = true;
    notifyListeners();
  }

  void deselectAll() {
    selectedAppIds.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  void clearSelection() {
    selectedAppIds.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  // Variables to keep track of the app foreground status (installs can't run in the background)
  bool isForeground = true;
  late Stream<FGBGType>? foregroundStream;
  late StreamSubscription<FGBGType>? foregroundSubscription;
  late Directory APKDir;
  late Directory iconsCacheDir;
  late SettingsProvider settingsProvider = SettingsProvider();
  late ThemeSettingsProvider themeSettings = ThemeSettingsProvider();
  late UpdateSettingsProvider updateSettings = UpdateSettingsProvider();
  late BehaviorSettingsProvider behaviorSettings = BehaviorSettingsProvider();
  late ViewSettingsProvider viewSettings = ViewSettingsProvider();
  late PlusSettingsProvider plusSettings = PlusSettingsProvider();
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initializationDone => _initCompleter.future;

  Iterable<AppInMemory> getAppValues({bool deepCopy = true}) =>
      deepCopy ? apps.values.map((a) => a.deepCopy()) : apps.values;

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
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final initFutures = Future.wait([
        settingsProvider.initializeSettings(),
        themeSettings.initializeSettings(prefs),
        updateSettings.initializeSettings(prefs),
        behaviorSettings.initializeSettings(prefs),
        viewSettings.initializeSettings(prefs),
        plusSettings.initializeSettings(prefs),
      ]);

      final dirsFuture = AppFileService.initAppDirectories();

      await initFutures;
      final dirs = await dirsFuture;

      APKDir = dirs['APKDir']!;
      iconsCacheDir = dirs['iconsCacheDir']!;
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
      _initCompleter.complete();
    }();
  }

  Future<File> handleAPKIDChange(
    App app,
    PackageInfo newInfo,
    File downloadedFile,
    String downloadUrl,
  ) async {
    // If the APK package ID is different from the App ID, it is either new (using a placeholder ID) or the ID has changed
    // The former case should be handled (give the App its real ID), the latter is a security issue
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

  Future<void> updatePendingRepoRename(String appId, String? newUrl) async {
    if (apps.containsKey(appId)) {
      apps[appId]!.app.pendingRepoRenameUrl = newUrl;
      await saveApps([apps[appId]!.app]);
    }
  }

  Future<void> acceptRepoRename(String appId, String newUrl) async {
    if (apps.containsKey(appId)) {
      apps[appId]!.app.url = newUrl;
      apps[appId]!.app.pendingRepoRenameUrl = null;
      await saveApps([apps[appId]!.app]);
    }
  }

  Future<Object> downloadApp(
    App app,
    BuildContext? context, {
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
      var downloadedFile = await downloadFileWithRetry(
        downloadUrl,
        fileNameNoExt,
        source.urlsAlwaysHaveExtension,
        headers: headers,
        (double? progress) {
          int? prog = progress?.ceil();
          if (apps[app.id] != null) {
            apps[app.id]!.downloadProgress = progress;
            // notifyListeners() removed here to prevent massive UI rebuilds
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
      // Set to 90 for remaining steps, will make null in 'finally'
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
        // Assume XAPK or ZIP
        String apkDirPath = '${downloadedFile.path}-dir';
        await unzipFile(downloadedFile.path, '${downloadedFile.path}-dir');
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
      // Delete older versions of the file if any
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
    } finally {
      notificationsProvider?.cancel(notifId);
      if (apps[app.id] != null) {
        apps[app.id]!.downloadProgress = null;
        notifyListeners();
      }
    }
  }

  bool areDownloadsRunning() => apps.values
      .where((element) => element.downloadProgress != null)
      .isNotEmpty;

  Future<bool> canInstallSilently(App app) async {
    if (!updateSettings.enableBackgroundUpdates) {
      return false;
    }
    if (app.additionalSettings['exemptFromBackgroundUpdates'] == true) {
      logs.add('Exempted from BG updates: ${app.id}');
      return false;
    }
    if (app.apkUrls.length > 1) {
      logs.add('Multiple APK URLs: ${app.id}');
      return false; // Manual API selection means silent install is not possible
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
      return false; // App probably not installed
    }

    int? targetSDK = (await getInstalledInfo(
      app.id,
    ))?.applicationInfo?.targetSdkVersion;
    int requiredSDK = osInfo.version.sdkInt - 3;
    // The APK should target a new enough API
    // https://developer.android.com/reference/android/content/pm/PackageInstaller.SessionParams#setRequireUserAction(int)
    if (!(targetSDK != null && targetSDK >= requiredSDK)) {
      logs.add(
        'App currently targets API ${targetSDK} which is too low for background updates (requires API ${requiredSDK}): ${app.id}',
      );
      return false;
    }

    if (behaviorSettings.useShizuku) {
      return true;
    }

    if (app.id == obtainiumId) {
      return false;
    }
    if (installerPackageName != obtainiumId) {
      // If we did not install the app, silent install is not possible
      return false;
    }
    if (osInfo.version.sdkInt < 31) {
      // The OS must also be new enough
      logs.add('Android SDK too old: ${osInfo.version.sdkInt}');
      return false;
    }
    return true;
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
      (await getInstalledInfo('com.berdik.letmedowngrade')) != null;

  Future<void> unzipFile(String filePath, String destinationPath) async {
    await ZipFile.extractToDirectory(
      zipFile: File(filePath),
      destinationDir: Directory(destinationPath),
    );
  }

  Future<bool> installApkDir(
    DownloadedDir dir,
    BuildContext? firstTimeWithContext, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
  }) async {
    // We don't know which APKs in an XAPK or ZIP are supported by the user's device
    // So we try installing all of them and assume success if at least one installed
    // If 0 APKs installed, throw the first install error encountered
    // Obviously this approach is naive and is undesirable in many cases, needs to be improved
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
          firstTimeWithContext?.mounted == true ? firstTimeWithContext : null,
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

  Future<bool> installApk(
    DownloadedApk file,
    BuildContext? firstTimeWithContext, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
    List<DownloadedApk> additionalAPKs = const [],
  }) async {
    if (firstTimeWithContext != null &&
        behaviorSettings.beforeNewInstallsShareToAppVerifier &&
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
        deleteFile(file.file);
        for (var a in additionalAPKs) {
          deleteFile(a.file);
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
    // versionCode is int? in the plugin — null on Android 15 for apps using
    // longVersionCode > Integer.MAX_VALUE. Fall back to 0 to skip downgrade check.
    final newVersionCode = newInfo.versionCode ?? 0;
    final existingVersionCode = appInfo?.versionCode ?? 0;
    if (appInfo != null &&
        newVersionCode > 0 &&
        existingVersionCode > 0 &&
        newVersionCode < existingVersionCode &&
        !(await canDowngradeApps())) {
      throw DowngradeError(existingVersionCode, newVersionCode);
    }
    if (needsBGWorkaround) {
      // The below 'await' will never return if we are in a background process
      // To work around this, we should assume the install will be successful
      // So we update the app's installed version first as we will never get to the later code
      // We can't conditionally get rid of the 'await' as this causes install fails (BG process times out) - see #896
      // TODO: When fixed, update this function and the calls to it accordingly
      apps[file.appId]!.app.installedVersion =
          apps[file.appId]!.app.latestVersion;
      await saveApps([
        apps[file.appId]!.app,
      ], attemptToCorrectInstallStatus: false);
    }
    int? code;
    if (!behaviorSettings.useShizuku) {
      var allAPKs = [file.file.path];
      allAPKs.addAll(additionalAPKs.map((a) => a.file.path));
      code = await AndroidPackageInstaller.installApk(
        apkFilePath: allAPKs.join(','),
      );
    } else {
      code = await ShizukuApkInstaller().installAPK(
        file.file.uri.toString(),
        shizukuPretendToBeGooglePlay ? "com.android.vending" : "",
      );
    }
    bool installed = false;
    if (code != null && code != 0 && code != 3) {
      try {
        deleteFile(file.file);
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
    await saveApps([apps[file.appId]!.app]);
    return installed;
  }

  Future<String> getStorageRootPath() async {
    return '/${(await getAppStorageDir()).uri.pathSegments.sublist(0, 3).join('/')}';
  }

  Future<void> moveObbFile(File file, String appId) async {
    if (!file.path.toLowerCase().endsWith('.obb')) return;

    if ((await DeviceInfoPlugin().androidInfo).version.sdkInt <= 29) {
      await Permission.storage.request();
    } else {
      await Permission.manageExternalStorage.request();
    }

    String obbDirPath = "${await getStorageRootPath()}/Android/obb/$appId";
    Directory(obbDirPath).createSync(recursive: true);

    String obbFileName = file.path.split("/").last;
    await file.copy("$obbDirPath/$obbFileName");
  }

  void uninstallApp(String appId) async {
    var intent = AndroidIntent(
      action: 'android.intent.action.DELETE',
      data: 'package:$appId',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      package: 'vnd.android.package-archive',
    );
    await intent.launch();
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
    // If the App has more than one APK, the user should pick one (if context provided)
    MapEntry<String, String>? appFileUrl =
        urlsToSelectFrom[app.preferredApkIndex >= 0
            ? app.preferredApkIndex
            : 0];
    // get device supported architecture
    List<String> archs = (await DeviceInfoPlugin().androidInfo).supportedAbis;

    if ((urlsToSelectFrom.length > 1 || evenIfSingleChoice) &&
        context != null) {
      appFileUrl = await showDialog(
        // ignore: use_build_context_synchronously
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

    // If the picked APK comes from an origin different from the source, get user confirmation (if context provided)
    if (appFileUrl != null &&
        ![
          getHost(app.url),
          'placeholder',
        ].contains(getHost(appFileUrl.value)) &&
        context != null) {
      if (!(settingsProvider.hideAPKOriginWarning) &&
          await showDialog(
                // ignore: use_build_context_synchronously
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

  // Given a list of AppIds, uses stored info about the apps to download APKs and install them
  // If the APKs can be installed silently, they are
  // If no BuildContext is provided, apps that require user interaction are ignored
  // If user input is needed and the App is in the background, a notification is sent to get the user's attention
  // Returns an array of Ids for Apps that were successfully downloaded, regardless of installation result
  Future<List<String>> downloadAndInstallLatestApps(
    List<String> appIds,
    BuildContext? context, {
    NotificationsProvider? notificationsProvider,
    bool forceParallelDownloads = false,
    bool useExisting = true,
  }) async {
    try {
      final installedIds =
          await AppDownloadService.downloadAndInstallLatestApps(
            appIds: appIds,
            apps: apps,
            settingsProvider: settingsProvider,
            behaviorSettings: behaviorSettings,
            plusSettings: plusSettings,
            updateSettings: updateSettings,
            logs: logs,
            APKDir: APKDir,
            notifyListeners: forceNotifyListeners,
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
          );
      if (context != null && installedIds.isNotEmpty) {
        AppHaptics.success();
      }
      return installedIds;
    } catch (errors) {
      if (context != null && context.mounted) {
        AppHaptics.failure();
        showError(errors, context);
        return [];
      } else {
        rethrow;
      }
    }
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
        if (apps[id] == null) throw ObtainiumError(tr('appNotFound'));
      }
      if (apps[id]!.app.apkUrls.isNotEmpty ||
          apps[id]!.app.otherAssetUrls.isNotEmpty) {
        MapEntry<String, String>? tempFileUrl = await confirmAppFileUrl(
          apps[id]!.app,
          context?.mounted == true ? context : null,
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

    // Prepare to download+install Apps
    MultiAppMultiError errors = MultiAppMultiError();
    List<String> downloadedIds = [];

    Future<void> downloadFn(MapEntry<String, String> fileUrl, App app) async {
      try {
        String downloadPath = '${await getStorageRootPath()}/Download';
        await downloadFile(
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

    if (forceParallelDownloads || !behaviorSettings.parallelDownloads) {
      for (var urlWithApp in filesToDownload) {
        await downloadFn(urlWithApp.key, urlWithApp.value);
      }
    } else {
      await _runWithConcurrencyLimit<MapEntry<MapEntry<String, String>, App>>(
        filesToDownload,
        settingsProvider.updateDownloadConcurrencyLimit,
        (urlWithApp) => downloadFn(urlWithApp.key, urlWithApp.value),
      );
    }
    if (errors.idsByErrorString.isNotEmpty) {
      throw errors;
    }
    return downloadedIds;
  }

  Future<Directory> getAppsDir() async {
    Directory appsDir = Directory(
      '${(await getAppStorageDir()).path}/app_data',
    );
    if (!appsDir.existsSync()) {
      appsDir.createSync();
    }
    return appsDir;
  }

  bool isVersionDetectionPossible(AppInMemory? app) {
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

  // Given an App and it's on-device info...
  // Reconcile unexpected differences between its reported installed version, real installed version, and reported latest version
  App? getCorrectedInstallStatusAppIfPossible(
    App app,
    PackageInfo? installedInfo,
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
    // FIRST, COMPARE THE APP'S REPORTED AND REAL INSTALLED VERSIONS, WHERE ONE IS NULL
    if (installedInfo == null && app.installedVersion != null && !trackOnly) {
      // App says it's installed but isn't really (and isn't track only) - set to not installed
      app.installedVersion = null;
      modded = true;
    } else if (realInstalledVersion != null && app.installedVersion == null) {
      // App says it's not installed but really is - set to installed and use real package versionName (or versionCode if chosen)
      app.installedVersion = realInstalledVersion;
      modded = true;
    }
    // SECOND, RECONCILE DIFFERENCES BETWEEN THE APP'S REPORTED AND REAL INSTALLED VERSIONS, WHERE NEITHER IS NULL
    if (realInstalledVersion != null &&
        realInstalledVersion != app.installedVersion &&
        versionDetectionIsStandard) {
      // App's reported version and real version don't match (and it uses standard version detection)
      // If they share a standard format (and are still different under it), update the reported version accordingly
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
    // THIRD, RECONCILE THE APP'S REPORTED INSTALLED AND LATEST VERSIONS
    if (app.installedVersion != null &&
        AppUpdateService.areVersionsDifferent(
          app,
          app.installedVersion,
          app.latestVersion,
          // This is a "do the version strings mismatch at all" check for
          // format reconciliation, not an "is an update available" check
          ignoreOrdering: true,
        ) &&
        versionDetectionIsStandard) {
      // App's reported installed and latest versions don't match (and it uses standard version detection)
      // If they share a standard format, make sure the App's reported installed version uses that format
      var correctedInstalledVersion = reconcileVersionDifferences(
        app.installedVersion!,
        app.latestVersion,
      );
      if (correctedInstalledVersion?.key == true) {
        app.installedVersion = correctedInstalledVersion!.value;
        modded = true;
      }
    }
    // FOURTH, DISABLE VERSION DETECTION IF ENABLED AND THE REPORTED/REAL INSTALLED VERSIONS ARE NOT STANDARDIZED
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
    // FIFTH, EVEN WITHOUT VERSION DETECTION, IF THE OS SAYS THE INSTALLED
    // BUILD IS THE LATEST VERSION, RECORD THAT — otherwise an app updated
    // outside the normal flow keeps prompting to update forever (issue #218)
    if (!versionDetectionIsStandard &&
        !trackOnly &&
        realInstalledVersion != null &&
        app.installedVersion != null &&
        app.installedVersion != app.latestVersion &&
        reconcileVersionDifferences(
              realInstalledVersion,
              app.latestVersion,
            )?.key ==
            true) {
      app.installedVersion = app.latestVersion;
      modded = true;
    }

    return modded ? app : null;
  }

  MapEntry<bool, String>? reconcileVersionDifferences(
    String templateVersion,
    String comparisonVersion,
  ) {
    // Returns null if the versions don't share a common standard format
    // Returns <true, comparisonVersion> if they share a common format and are equal
    // Returns <false, templateVersion> if they share a common format but are not equal
    // templateVersion must fully match a standard format, while comparisonVersion can have a substring match
    var templateVersionFormats = findStandardFormatsForVersion(
      templateVersion,
      true,
    );
    var comparisonVersionFormats = findStandardFormatsForVersion(
      comparisonVersion,
      true,
    );
    if (comparisonVersionFormats.isEmpty) {
      comparisonVersionFormats = findStandardFormatsForVersion(
        comparisonVersion,
        false,
      );
    }
    var commonStandardFormats = templateVersionFormats.intersection(
      comparisonVersionFormats,
    );
    if (commonStandardFormats.isEmpty) {
      return null;
    }
    for (String pattern in commonStandardFormats) {
      if (doStringsMatchUnderRegEx(
        pattern,
        comparisonVersion,
        templateVersion,
      )) {
        return MapEntry(true, comparisonVersion);
      }
    }
    return MapEntry(false, templateVersion);
  }

  bool doStringsMatchUnderRegEx(String pattern, String value1, String value2) {
    var r = RegExp(pattern);
    var m1 = r.firstMatch(value1);
    var m2 = r.firstMatch(value2);
    return m1 != null && m2 != null
        ? value1.substring(m1.start, m1.end) ==
              value2.substring(m2.start, m2.end)
        : false;
  }

  Future<void> loadApps({String? singleId}) async {
    while (loadingApps) {
      await Future.delayed(const Duration(microseconds: 1));
    }
    loadingApps = true;
    notifyListeners();
    var sp = SourceProvider();
    List<List<String>> errors = [];
    var installedAppsData = await getAllInstalledInfo();
    List<String> removedAppIds = [];
    await Future.wait(
      (await getAppsDir()) // Parse Apps from JSON
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
                    'Corrupt JSON when loading App (will be ignored): $e',
                  );
                  item.renameSync('${item.path}.corrupt');
                } else {
                  rethrow;
                }
              }
            }
            if (app != null) {
              // Save the app to the in-memory list without grabbing any OS info first
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
                // Try getting the app's source to ensure no invalid apps get loaded
                sp.getSource(app.url, overrideSource: app.overrideSource);
                // If the app is installed, grab its OS data and reconcile install statuses
                PackageInfo? installedInfo;
                try {
                  installedInfo = installedAppsData.firstWhere(
                    (i) => i.packageName == app!.id,
                  );
                } catch (e) {
                  // If the app isn't installed the above throws an error
                }
                // Reconcile differences between the installed and recorded install info
                var moddedApp = getCorrectedInstallStatusAppIfPossible(
                  app,
                  installedInfo,
                );
                if (moddedApp != null) {
                  app = moddedApp;
                  // Note the app ID if it was uninstalled externally
                  if (moddedApp.installedVersion == null) {
                    removedAppIds.add(moddedApp.id);
                  }
                }
                // Update the app in memory with install info and corrections
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
    // Delete externally uninstalled Apps if needed
    if (removedAppIds.isNotEmpty) {
      if (removedAppIds.isNotEmpty) {
        if (behaviorSettings.removeOnExternalUninstall) {
          await removeApps(removedAppIds);
        }
      }
    }
    loadingApps = false;
    notifyListeners();
  }

  Future<void> updateAppIcon(String? appId, {bool ignoreCache = false}) async {
    if (apps[appId]?.icon == null) {
      var cachedIcon = File('${iconsCacheDir.path}/$appId.png');
      var alreadyCached = cachedIcon.existsSync() && !ignoreCache;
      var icon = alreadyCached
          ? (await cachedIcon.readAsBytes())
          : (await apps[appId]?.installedInfo?.applicationInfo?.getAppIcon());
      if (icon != null && !alreadyCached) {
        try {
          if (!iconsCacheDir.existsSync()) {
            await iconsCacheDir.create(recursive: true);
          }
          await cachedIcon.writeAsBytes(icon.toList());
        } catch (e) {
          LogsProvider().add('Failed to write cached icon for $appId: $e');
        }
      }
      if (icon != null) {
        final currentApp = apps[appId];
        if (currentApp == null) return;
        apps.update(
          currentApp.app.id,
          (value) => AppInMemory(
            currentApp.app,
            value.downloadProgress,
            value.installedInfo,
            icon,
          ),
          ifAbsent: () =>
              AppInMemory(currentApp.app, null, currentApp.installedInfo, icon),
        );
        notifyListeners();
      }
    }
  }

  Future<void> saveApps(
    List<App> apps, {
    bool attemptToCorrectInstallStatus = true,
    bool onlyIfExists = true,
  }) async {
    attemptToCorrectInstallStatus = attemptToCorrectInstallStatus;
    await Future.wait(
      apps.map((a) async {
        var app = a.deepCopy();
        PackageInfo? info = await getInstalledInfo(app.id);
        var icon = await info?.applicationInfo?.getAppIcon();
        app.name = await (info?.applicationInfo?.getAppLabel()) ?? app.name;
        if (attemptToCorrectInstallStatus) {
          app = getCorrectedInstallStatusAppIfPossible(app, info) ?? app;
        }
        if (!onlyIfExists || this.apps.containsKey(app.id)) {
          String filePath = '${(await getAppsDir()).path}/${app.id}.json';
          File(
            '$filePath.tmp',
          ).writeAsStringSync(safeJsonEncode(app.toJson())); // #2089
          File('$filePath.tmp').renameSync(filePath);
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
        File file = File('${(await getAppsDir()).path}/$appId.json');
        if (file.existsSync()) {
          deleteFile(file);
        }
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
            uninstallApp(apps[i].id);
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

  Future<void> openAppSettings(String appId) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'action_application_details_settings',
      data: 'package:$appId',
    );
    await intent.launch();
  }

  void addMissingCategories(ViewSettingsProvider viewSettings) {
    var cats = viewSettings.categories;
    apps.forEach((key, value) {
      for (var c in value.app.categories) {
        if (!cats.containsKey(c)) {
          cats[c] = generateRandomLightColor().value;
        }
      }
    });
    viewSettings.setCategories(cats, appsProvider: this);
  }

  Future<App?> checkUpdate(String appId, {bool ignoreCache = false}) async {
    App? currentApp = apps[appId]!.app;
    // Pause update checks until the user resolves a pending repo rename.
    if (currentApp.hasPendingRepoRename) {
      return null;
    }
    SourceProvider sourceProvider = SourceProvider();
    App newApp = await sourceProvider.getApp(
      sourceProvider.getSource(
        currentApp.url,
        overrideSource: currentApp.overrideSource,
      ),
      currentApp.url,
      currentApp.additionalSettings,
      currentApp: currentApp,
    );
    if (currentApp.preferredApkIndex < newApp.apkUrls.length) {
      newApp.preferredApkIndex = currentApp.preferredApkIndex;
    }
    await saveApps([newApp]);
    return newApp.latestVersion != currentApp.latestVersion ? newApp : null;
  }

  List<String> getAppsSortedByUpdateCheckTime({
    DateTime? ignoreAppsCheckedAfter,
    bool onlyCheckInstalledOrTrackOnlyApps = false,
  }) {
    List<String> appIds = apps.values
        .where(
          (app) =>
              app.app.lastUpdateCheck == null ||
              ignoreAppsCheckedAfter == null ||
              app.app.lastUpdateCheck!.isBefore(ignoreAppsCheckedAfter),
        )
        .where((app) {
          if (!onlyCheckInstalledOrTrackOnlyApps) {
            return true;
          } else {
            return app.app.installedVersion != null ||
                app.app.additionalSettings['trackOnly'] == true;
          }
        })
        .map((e) => e.app.id)
        .toList();
    appIds.sort(
      (a, b) =>
          (apps[a]!.app.lastUpdateCheck ??
                  DateTime.fromMicrosecondsSinceEpoch(0))
              .compareTo(
                apps[b]!.app.lastUpdateCheck ??
                    DateTime.fromMicrosecondsSinceEpoch(0),
              ),
    );
    return appIds;
  }

  Future<List<App>> checkUpdates({
    DateTime? ignoreAppsCheckedAfter,
    bool throwErrorsForRetry = false,
    List<String>? specificIds,
    UpdateSettingsProvider? usp,
  }) async {
    UpdateSettingsProvider updateSettings = usp ?? this.updateSettings;
    List<App> updates = [];
    MultiAppMultiError errors = MultiAppMultiError();
    if (!gettingUpdates) {
      gettingUpdates = true;
      try {
        List<String> appIds = getAppsSortedByUpdateCheckTime(
          ignoreAppsCheckedAfter: ignoreAppsCheckedAfter,
          onlyCheckInstalledOrTrackOnlyApps:
              updateSettings.onlyCheckInstalledOrTrackOnlyApps,
        );
        if (specificIds != null) {
          appIds = appIds.where((aId) => specificIds.contains(aId)).toList();
        }

        // Trigger dispenser ban warning if enabled and a large query (exceeding custom threshold) is run
        try {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final bool enableBanWarnings =
              prefs.safeBool('plusEnableBanWarnings') ?? false;
          final int threshold = prefs.safeInt('plusBanWarningThreshold') ?? 5;
          if (enableBanWarnings && appIds.length > threshold) {
            NotificationsProvider().notify(
              DispenserBanWarningNotification(appIds.length),
            );
          }
        } catch (_) {}

        await _runWithConcurrencyLimit<String>(
          appIds,
          settingsProvider.updateCheckConcurrencyLimit,
          (appId) async {
            App? newApp;
            try {
              newApp = await checkUpdate(appId);
            } catch (e) {
              if ((e is RateLimitError || e is SocketException) &&
                  throwErrorsForRetry) {
                rethrow;
              }
              if (e is RepositoryRenamedError) {
                await updatePendingRepoRename(appId, e.newUrl);
              } else {
                errors.add(appId, e, appName: apps[appId]?.name);
              }
            }
            if (newApp != null) {
              updates.add(newApp);
            }
          },
        );
      } finally {
        gettingUpdates = false;
      }
    }
    if (errors.idsByErrorString.isNotEmpty) {
      var res = <String, dynamic>{};
      res['errors'] = errors;
      res['updates'] = updates;
      throw res;
    }
    return updates;
  }

  List<String> findExistingUpdates({
    bool installedOnly = false,
    bool nonInstalledOnly = false,
  }) {
    List<String> updateAppIds = [];
    List<String> appIds = apps.keys.toList();
    for (int i = 0; i < appIds.length; i++) {
      App? app = apps[appIds[i]]!.app;
      // For installed apps: check if a newer version is available via areVersionsDifferent.
      // For uninstalled apps (nonInstalledOnly): areVersionsDifferent always returns false
      // when installedVersion is null, so we use a direct check instead —
      // any uninstalled, non-track-only app with a known latestVersion is a candidate.
      bool isCandidate;
      if (app.installedVersion == null) {
        isCandidate = !nonInstalledOnly
            ? false
            : app.additionalSettings['trackOnly'] != true &&
                  app.latestVersion.isNotEmpty;
      } else {
        isCandidate =
            AppUpdateService.areVersionsDifferent(
              app,
              app.installedVersion,
              app.latestVersion,
            ) &&
            (!installedOnly || !nonInstalledOnly);
      }
      if (isCandidate) {
        if ((app.installedVersion == null &&
                (nonInstalledOnly || !installedOnly) ||
            (app.installedVersion != null &&
                (installedOnly || !nonInstalledOnly)))) {
          updateAppIds.add(app.id);
        }
      }
    }
    return updateAppIds;
  }

  Map<String, dynamic> generateExportJSON({
    List<String>? appIds,
    int? overrideExportSettings,
  }) {
    Map<String, dynamic> finalExport = {};
    finalExport['apps'] = apps.values
        .where((e) {
          if (appIds == null) {
            return true;
          } else {
            return appIds.contains(e.app.id);
          }
        })
        .map((e) => e.app.toJson())
        .toList();
    int shouldExportSettings = behaviorSettings.exportSettings;
    if (overrideExportSettings != null) {
      shouldExportSettings = overrideExportSettings;
    }
    if (shouldExportSettings > 0) {
      var settingsValueKeys = settingsProvider.prefs?.getKeys();
      if (shouldExportSettings < 2) {
        settingsValueKeys?.removeWhere((k) => k.endsWith('-creds'));
      }
      finalExport['settings'] = Map<String, Object?>.fromEntries(
        (settingsValueKeys
                ?.map((key) => MapEntry(key, settingsProvider.prefs?.get(key)))
                .toList()) ??
            [],
      );
    }
    return finalExport;
  }

  Future<String?> export({
    bool pickOnly = false,
    isAuto = false,
    BehaviorSettingsProvider? bsp,
  }) async {
    BehaviorSettingsProvider behaviorSettings = bsp ?? this.behaviorSettings;
    var exportDir = await behaviorSettings.getExportDir();
    if (isAuto) {
      if (behaviorSettings.autoExportOnChanges != true) {
        return null;
      }
      if (exportDir == null) {
        return null;
      }
      var files = await saf
          .listFiles(exportDir, columns: [saf.DocumentFileColumn.id])
          .where((f) => f.uri.pathSegments.last.endsWith('-auto.json'))
          .toList();
      if (files.isNotEmpty) {
        for (var f in files) {
          saf.delete(f.uri);
        }
      }
    }
    if (exportDir == null || pickOnly) {
      await behaviorSettings.pickExportDir();
      exportDir = await behaviorSettings.getExportDir();
    }
    if (exportDir == null) {
      return null;
    }
    String? returnPath;
    if (!pickOnly) {
      var encoder = const JsonEncoder.withIndent("    ");
      Map<String, dynamic> finalExport = generateExportJSON();
      var result = await saf.createFile(
        exportDir,
        displayName:
            '${tr('obtainiumExportHyphenatedLowercase')}-${DateTime.now().toIso8601String().replaceAll(':', '-')}${isAuto ? '-auto' : ''}.json',
        mimeType: 'application/json',
        bytes: Uint8List.fromList(utf8.encode(encoder.convert(finalExport))),
      );
      if (result == null) {
        throw ObtainiumError(tr('unexpectedError'));
      }
      returnPath = exportDir.pathSegments
          .join('/')
          .replaceFirst('tree/primary:', '/');
    }
    return returnPath;
  }

  Future<MapEntry<List<App>, bool>> import(String appsJSON) async {
    var decodedJSON = jsonDecode(appsJSON);
    var newFormat = decodedJSON is! List;
    List<App> importedApps =
        ((newFormat ? decodedJSON['apps'] : decodedJSON) as List<dynamic>)
            .map((e) => App.fromJson(e))
            .toList();
    while (loadingApps) {
      await Future.delayed(const Duration(microseconds: 1));
    }
    for (App a in importedApps) {
      var installedInfo = await getInstalledInfo(a.id, printErr: false);
      a.installedVersion =
          a.additionalSettings['useVersionCodeAsOSVersion'] == true
          ? installedInfo?.versionCode.toString()
          : installedInfo?.versionName;
    }
    await saveApps(importedApps, onlyIfExists: false);
    notifyListeners();
    if (newFormat && decodedJSON['settings'] != null) {
      var settingsMap = decodedJSON['settings'] as Map<String, Object?>;
      settingsMap.forEach((key, value) {
        if (value is int) {
          settingsProvider.prefs?.setInt(key, value);
        } else if (value is double) {
          settingsProvider.prefs?.setDouble(key, value);
        } else if (value is bool) {
          settingsProvider.prefs?.setBool(key, value);
        } else if (value is List) {
          settingsProvider.prefs?.setStringList(
            key,
            value.map((e) => e as String).toList(),
          );
        } else {
          settingsProvider.prefs?.setString(key, value as String);
        }
      });
    }
    return MapEntry<List<App>, bool>(
      importedApps,
      newFormat && decodedJSON['settings'] != null,
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

  @override
  void notifyListeners() {
    super.notifyListeners();
    _updateWidgetData();
  }

  Future<void> _updateWidgetData() async {
    try {
      int count = 0;
      for (var entry in apps.entries) {
        if (AppUpdateService.areVersionsDifferent(
          entry.value.app,
          entry.value.app.installedVersion,
          entry.value.app.latestVersion,
        )) {
          count++;
        }
      }
      await HomeWidget.saveWidgetData<int>('pending_updates_count', count);
      await HomeWidget.updateWidget(androidName: 'HomeWidgetProvider');
    } catch (e) {
      // Ignore widget update errors
    }
  }

  void forceNotifyListeners() => notifyListeners();

  Future<void> _runWithConcurrencyLimit<T>(
    List<T> items,
    int limit,
    Future<void> Function(T) action,
  ) async {
    if (items.isEmpty) return;
    int index = 0;
    Future<void> worker() async {
      while (index < items.length) {
        final current = index;
        index++;
        if (current >= items.length) break;
        await action(items[current]);
      }
    }

    final actualLimit = limit < items.length ? limit : items.length;
    final workers = List.generate(actualLimit, (_) => worker());
    await Future.wait(workers);
  }
}

class AppFilePicker extends StatefulWidget {
  const AppFilePicker({
    super.key,
    required this.app,
    this.initVal,
    this.archs,
    this.pickAnyAsset = false,
  });

  final App app;
  final MapEntry<String, String>? initVal;
  final List<String>? archs;
  final bool pickAnyAsset;

  @override
  State<AppFilePicker> createState() => _AppFilePickerState();
}

class _AppFilePickerState extends State<AppFilePicker> {
  MapEntry<String, String>? fileUrl;

  @override
  Widget build(BuildContext context) {
    fileUrl ??= widget.initVal;
    var urlsToSelectFrom = widget.app.apkUrls;
    if (widget.pickAnyAsset) {
      urlsToSelectFrom = [...urlsToSelectFrom, ...widget.app.otherAssetUrls];
    }
    return GlassDialog(
      title: widget.pickAnyAsset
          ? tr('selectX', args: [lowerCaseIfEnglish(tr('releaseAsset'))])
          : tr('pickAnAPK'),
      icon: widget.pickAnyAsset
          ? Icons.file_present_rounded
          : Icons.android_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          urlsToSelectFrom.length > 1
              ? Text(
                  tr('appHasMoreThanOnePackage', args: [widget.app.finalName]),
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 16),
          ...urlsToSelectFrom.map(
            (u) => RadioListTile<String>(
              title: Text(u.key),
              value: u.value,
              groupValue: fileUrl!.value,
              onChanged: (String? val) {
                setState(() {
                  fileUrl = urlsToSelectFrom.where((e) => e.value == val).first;
                });
              },
            ),
          ),
          if (widget.archs != null) const SizedBox(height: 16),
          if (widget.archs != null)
            Text(
              widget.archs!.length == 1
                  ? tr('deviceSupportsXArch', args: [widget.archs![0]])
                  : tr('deviceSupportsFollowingArchs') +
                        list2FriendlyString(
                          widget.archs!.map((e) => '\'$e\'').toList(),
                        ),
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () {
            AppHaptics.selectionClick();
            Navigator.of(context).pop(fileUrl);
          },
          child: Text(tr('continue')),
        ),
      ],
    );
  }
}

class APKOriginWarningDialog extends StatefulWidget {
  const APKOriginWarningDialog({
    super.key,
    required this.sourceUrl,
    required this.apkUrl,
  });

  final String sourceUrl;
  final String apkUrl;

  @override
  State<APKOriginWarningDialog> createState() => _APKOriginWarningDialogState();
}

class _APKOriginWarningDialogState extends State<APKOriginWarningDialog> {
  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: tr('warning'),
      icon: Icons.warning_amber_rounded,
      content: Text(
        tr(
          'sourceIsXButPackageFromYPrompt',
          args: [
            Uri.parse(widget.sourceUrl).host,
            Uri.parse(widget.apkUrl).host,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () {
            AppHaptics.selectionClick();
            Navigator.of(context).pop(true);
          },
          child: Text(tr('continue')),
        ),
      ],
    );
  }
}
