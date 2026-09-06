import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/app_utils.dart' show safeJsonEncode;
import 'package:obtainium/utils/url_validator.dart';
import 'package:home_widget/home_widget.dart';
// Manages state related to the list of Apps tracked by Obtainium,
// Exposes related functions such as those used to add, remove, download, and install Apps.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:android_system_font/android_system_font.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/io_client.dart';
import 'package:obtainium/app_sources/direct_apk_link.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/services/app_download_service.dart';
import 'package:obtainium/services/app_install_service.dart';
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
import 'package:android_intent_plus/flag.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:archive/archive.dart' as archive;
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
import 'package:obtainium/utils/version_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:obtainium/providers/apps_provider_import_export.dart';
import 'package:obtainium/providers/apps_provider_install.dart';
import 'package:obtainium/providers/apps_provider_lifecycle.dart';
import 'package:obtainium/providers/apps_provider_updates.dart';
import 'package:obtainium/components/ui_widgets.dart';

export 'apps_provider_import_export.dart';
export 'apps_provider_install.dart';
export 'apps_provider_lifecycle.dart';
export 'apps_provider_updates.dart';

// Named constants for magic numbers and hardcoded values
const int _defaultRetries = 3;
const int _retryDelaySeconds = 5;
const int _partialHashCheckStartingSize = 1024;
const int _partialHashCheckLowerLimit = 128;
const int _partialHashCheckDecrement = 256;
const int _maxDownloadPolls = 43;
const int _downloadPollIntervalSeconds = 7;
const int _progressUpdateIntervalMs = 500;
const int _downloadBufferSize = 32 * 1024;
const int _downloadProgressFallback = 30;
const int _bgUpdateMaxAttempts = 4;
const int _bgUpdateMaxRetryWaitSeconds = 30;
const int _bgClientExceptionRetryWaitSeconds = 15 * 60;

final packageManager = AndroidPackageManager();
final packageInfoFlags = PackageInfoFlags({PMFlag.getSigningCertificates});

/// Removes all matching elements and appends the last match to the end.
/// This is intentionally deduplicating — only one instance is re-added.
List<T> _moveToEnd<T extends Object>(List<T> arr, bool Function(T) match) {
  T? temp;
  arr.removeWhere((element) {
    if (match(element)) {
      temp = element;
      return true;
    }
    return false;
  });
  if (temp != null) {
    arr.add(temp as T);
  }
  return arr;
}

List<String> moveStrToEnd(List<String> arr, String str, {String? strB}) =>
    _moveToEnd(arr, (e) => e == str || e == strB);

/// See [_moveToEnd] for semantic details.
List<MapEntry<String, int>> moveStrToEndMapEntryWithCount(
  List<MapEntry<String, int>> arr,
  MapEntry<String, int> str, {
  MapEntry<String, int>? strB,
}) => _moveToEnd(arr, (e) => e.key == str.key || e.key == strB?.key);

class CancellationException implements Exception {}

class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw CancellationException();
  }
}

Future<File> downloadFileWithRetry(
  String url,
  String fileName,
  bool fileNameHasExt,
  Function? onProgress,
  String destDir, {
  bool useExisting = true,
  Map<String, String>? headers,
  int retries = _defaultRetries,
  bool allowInsecure = false,
  LogsProvider? logs,
  CancellationToken? cancellationToken,
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
      cancellationToken: cancellationToken,
    );
  } catch (e) {
    // A cancellation is not one of the retryable error types, so it naturally
    // falls through to rethrow below.
    if (retries > 0 &&
        (e is ClientException ||
            e is SocketException ||
            e is TimeoutException)) {
      await Future.delayed(const Duration(seconds: _retryDelaySeconds));
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
        cancellationToken: cancellationToken,
      );
    } else {
      rethrow;
    }
  }
}

String hashListOfLists(List<List<int>> data) {
  final bytes = utf8.encode(jsonEncode(data));
  return sha256.convert(bytes).toString().substring(0, 8);
}

Future<String> checkPartialDownloadHashDynamic(
  String url, {
  int startingSize = _partialHashCheckStartingSize,
  int lowerLimit = _partialHashCheckLowerLimit,
  Map<String, String>? headers,
  bool allowInsecure = false,
}) async {
  for (int i = startingSize; i >= lowerLimit; i -= _partialHashCheckDecrement) {
    // Both requests fetch the same byte range to confirm the hash is
    // stable. The loop decrements on mismatch; when two consecutive
    // requests agree, the hash is considered valid.
    final List<String> ab = await Future.wait([
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
  final req = Request('GET', Uri.parse(url));
  if (headers != null) {
    req.headers.addAll(headers);
  }
  req.headers[HttpHeaders.rangeHeader] = 'bytes=0-$bytesToGrab';
  final client = IOClient(createHttpClient(allowInsecure));
  try {
    final response = await client.send(req);
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw ObtainiumError(response.reasonPhrase ?? tr('unexpectedError'))
        ..url = url;
    }
    final List<List<int>> bytes = await response.stream
        .take(bytesToGrab)
        .toList();
    return hashListOfLists(bytes);
  } finally {
    client.close();
  }
}

Future<String?> checkETagHeader(
  String url, {
  Map<String, String>? headers,
  bool allowInsecure = false,
}) async {
  final reqHeaders = headers ?? {};
  final req = Request('GET', Uri.parse(url));
  req.headers.addAll(reqHeaders);
  final client = IOClient(createHttpClient(allowInsecure));
  try {
    final StreamedResponse response = await client.send(req);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final etag = response.headers[HttpHeaders.etagHeader]?.replaceAll('"', '');
    return etag != null
        ? sha256.convert(utf8.encode(etag)).toString().substring(0, 12)
        : null;
  } finally {
    client.close();
  }
}

void deleteFile(File file) {
  try {
    file.deleteSync();
  } on PathAccessException catch (e) {
    throw ObtainiumError(
      tr('fileDeletionError', args: [e.path ?? tr('unknown')]),
    );
  }
}

/// Waits for a concurrent download to finish by polling the temp file size.
/// Returns the completed file if one is available, or null if a fresh download is needed.
Future<File?> _waitForConcurrentDownload(
  File tempDownloadedFile,
  File downloadedFile,
  LogsProvider? logs,
) async {
  unawaited(
    logs?.add(
      'Partial download exists - will wait: ${tempDownloadedFile.uri.pathSegments.last}',
    ),
  );
  int currentTempFileSize = await tempDownloadedFile.length();
  int pollCount = 0;
  while (pollCount < _maxDownloadPolls) {
    pollCount++;
    await Future.delayed(const Duration(seconds: _downloadPollIntervalSeconds));
    if (tempDownloadedFile.existsSync()) {
      final int newTempFileSize;
      try {
        newTempFileSize = await tempDownloadedFile.length();
      } on FileSystemException {
        return downloadedFile.existsSync() ? downloadedFile : null;
      }
      if (newTempFileSize > currentTempFileSize) {
        currentTempFileSize = newTempFileSize;
        unawaited(
          logs?.add(
            'Existing partial download still in progress: ${tempDownloadedFile.uri.pathSegments.last}',
          ),
        );
      } else {
        unawaited(
          logs?.add(
            'Ignoring existing partial download: ${tempDownloadedFile.uri.pathSegments.last}',
          ),
        );
        break;
      }
    } else {
      return downloadedFile.existsSync() ? downloadedFile : null;
    }
  }
  if (downloadedFile.existsSync()) {
    unawaited(
      logs?.add(
        'Existing partial download completed - not repeating: ${tempDownloadedFile.uri.pathSegments.last}',
      ),
    );
    return downloadedFile;
  }
  unawaited(
    logs?.add(
      'Existing partial download not in progress: ${tempDownloadedFile.uri.pathSegments.last}',
    ),
  );
  return null;
}

/// Downloads a file to [destDir] with progress reporting, resuming partial downloads when supported.
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
  CancellationToken? cancellationToken,
}) async {
  final reqHeaders = headers ?? {};
  final headersClient = IOClient(createHttpClient(allowInsecure));

  final getReq = Request('GET', Uri.parse(url));
  getReq.headers.addAll(reqHeaders);
  final headersResponse = await headersClient.send(getReq);

  final resHeaders = headersResponse.headers;

  // Use the headers to decide what the file extension is, and
  // whether it supports partial downloads (range request), and
  // what the total size of the file is (if provided)
  String ext = resHeaders['content-disposition']?.split('.').last ?? 'apk';
  if (ext.endsWith('"')) {
    ext = ext.substring(0, ext.length - 1);
  }
  final urlPath = Uri.tryParse(url)?.path ?? url;
  if (AppSource.isApkOrContainerFile(
    urlPath,
    includeArchives: true,
    includeTarballs: true,
  )) {
    // Preserve the real extension (.apk/.xapk/.apkm/.apks) so XAPK/APKS
    // bundles are still detected and extracted downstream rather than forced
    // to .apk and handed to the APK parser.
    ext = urlPath.split('.').last.toLowerCase();
  } else if (ext == 'attachment') {
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
  final fullContentLength = headersResponse.contentLength;
  if (useExisting && downloadedFile.existsSync()) {
    final length = downloadedFile.lengthSync();
    if (fullContentLength == null || !rangeFeatureEnabled) {
      return downloadedFile;
    } else {
      if (length == fullContentLength) {
        return downloadedFile;
      }
      if (length > fullContentLength) {
        useExisting = false;
      }
    }
  }

  final File tempDownloadedFile = File('${downloadedFile.path}.part');

  // If there is already a temp file, a download may already be in progress - account for this (see #2073)
  final bool tempFileExists = tempDownloadedFile.existsSync();
  if (tempFileExists && useExisting) {
    final result = await _waitForConcurrentDownload(
      tempDownloadedFile,
      downloadedFile,
      logs,
    );
    if (result != null) return result;
  }

  // If the range feature is not available (or you need to start a ranged req from 0),
  // complete the already-started request, else cancel it and start a ranged request,
  // and open the file for writing in the appropriate mode
  final targetFileLength = () {
    if (!useExisting) return null;
    try {
      if (tempDownloadedFile.existsSync()) {
        return tempDownloadedFile.lengthSync();
      }
    } on FileSystemException {
      // File disappeared between existsSync and lengthSync
    }
    return null;
  }();
  int rangeStart = targetFileLength ?? 0;
  IOSink? sink;
  bool sentRangeRequest = false;
  if (rangeFeatureEnabled && fullContentLength != null && rangeStart > 0) {
    reqHeaders.addAll({'range': 'bytes=$rangeStart-${fullContentLength - 1}'});
    sink = tempDownloadedFile.openWrite(mode: FileMode.writeOnlyAppend);
    sentRangeRequest = true;
  } else if (tempDownloadedFile.existsSync()) {
    deleteFile(tempDownloadedFile);
  }
  final responseWithClient = await sourceRequestStreamResponse(
    'GET',
    url,
    reqHeaders,
    {'allowInsecure': allowInsecure},
  );
  final HttpClient responseClient = responseWithClient.value.key;
  final HttpClientResponse response = responseWithClient.value.value;
  try {
    // If we requested a byte range to resume a partial download but the server
    // ignored it and returned the full file (200 instead of 206 Partial
    // Content), appending would corrupt the file - discard the partial data and
    // start the download over from the beginning.
    if (sentRangeRequest && response.statusCode == HttpStatus.ok) {
      await sink?.close();
      sink = null;
      rangeStart = 0;
      if (tempDownloadedFile.existsSync()) {
        deleteFile(tempDownloadedFile);
      }
    }
    sink ??= tempDownloadedFile.openWrite(mode: FileMode.writeOnly);

    var received = 0;
    double? progress;
    DateTime? lastProgressUpdate; // Track last progress update time
    if (rangeStart > 0 && fullContentLength != null) {
      received = rangeStart;
    }

    const downloadUIUpdateInterval = Duration(
      milliseconds: _progressUpdateIntervalMs,
    );
    const downloadBufferSizeLocal = _downloadBufferSize;

    // Check status code BEFORE finishing the download stream so we can
    // abort early on errors and avoid wasting bandwidth reading a body
    // the server already rejected.
    if (response.statusCode < 200 || response.statusCode > 299) {
      await sink.close();
      sink = null;
      await response.drain<void>().catchError((_) {
        unawaited(
          logs?.add('Failed to drain response body', level: LogLevel.warning),
        );
      });
      if (tempDownloadedFile.existsSync()) {
        deleteFile(tempDownloadedFile);
      }
      throw ObtainiumError(
        response.reasonPhrase.isNotEmpty
            ? response.reasonPhrase
            : tr(
                'errorWithHttpStatusCode',
                args: [response.statusCode.toString()],
              ),
      )..url = url;
    }

    final downloadBuffer = BytesBuilder();
    try {
      await response
          .map((chunk) {
            cancellationToken?.throwIfCancelled();
            received += chunk.length;
            final now = DateTime.now();
            if (onProgress != null &&
                (lastProgressUpdate == null ||
                    now.difference(lastProgressUpdate!) >=
                        downloadUIUpdateInterval)) {
              progress = fullContentLength != null
                  ? (received / fullContentLength * 100).clamp(0, 100)
                  : _downloadProgressFallback.toDouble();
              onProgress(progress, received, fullContentLength);
              lastProgressUpdate = now;
            }
            return chunk;
          })
          .transform(
            StreamTransformer<List<int>, List<int>>.fromHandlers(
              handleData: (List<int> data, EventSink<List<int>> s) {
                downloadBuffer.add(data);
                if (downloadBuffer.length >= downloadBufferSizeLocal) {
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
    } catch (e) {
      // Release the file handle, ignoring "file already closed" races that can
      // happen when the stream is torn down mid-write. The .part file is kept so
      // the download can be resumed later.
      try {
        await sink.close();
      } catch (_) {
        sink = null;
      }
      // Surface a cancellation as such (even if the underlying stream error was
      // a file/socket error caused by the abort) so callers handle it silently.
      if (e is CancellationException ||
          (cancellationToken?.isCancelled ?? false)) {
        throw CancellationException();
      }
      rethrow;
    }
    await sink.close();
    sink = null;
    progress = null;
    if (onProgress != null) {
      onProgress(progress, null, null);
    }
    try {
      if (tempDownloadedFile.existsSync()) {
        if (downloadedFile.existsSync()) {
          try {
            tempDownloadedFile.renameSync(downloadedFile.path);
          } catch (firstErr) {
            try {
              downloadedFile.deleteSync();
              tempDownloadedFile.renameSync(downloadedFile.path);
            } catch (secondErr) {
              unawaited(
                logs?.add(
                  'Rename of temp download failed: $firstErr / $secondErr. Temp file left at ${tempDownloadedFile.path}',
                  level: LogLevel.warning,
                ),
              );
            }
          }
        } else {
          tempDownloadedFile.renameSync(downloadedFile.path);
        }
      }
    } on FileSystemException {
      // File disappeared between existence check and operation.
      // The temp file may have been cleaned up by another process.
      // Return the downloaded file if it still exists; otherwise the
      // caller will re-download.
      if (!downloadedFile.existsSync() && !tempDownloadedFile.existsSync()) {
        rethrow;
      }
    }
    return downloadedFile;
  } finally {
    responseClient.close();
    unawaited(
      sink?.close().catchError((_) {
        logs?.add('Failed to close download sink', level: LogLevel.warning);
      }),
    );
  }
}

/// Best-effort probe of a download's size via its Content-Length header. Returns
/// null when the server doesn't report it (or the request fails), so callers can
/// treat the size as unknown ("when possible").
Future<int?> getDownloadSize(
  String url, {
  Map<String, String>? headers,
  bool allowInsecure = false,
}) async {
  final reqHeaders = headers ?? {};
  final client = IOClient(createHttpClient(allowInsecure));
  try {
    final getReq = Request('GET', Uri.parse(url));
    getReq.headers.addAll(reqHeaders);
    final response = await client.send(getReq);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final length = response.contentLength;
    return (length != null && length > 0) ? length : null;
  } on SocketException {
    return null;
  } on TimeoutException {
    return null;
  } on ClientException {
    return null;
  } on HandshakeException {
    return null;
  } catch (e) {
    unawaited(
      LogsProvider().add(
        'Unexpected error in getDownloadSize: $e',
        level: LogLevel.error,
      ),
    );
    return null;
  } finally {
    client.close();
  }
}

/// Formats a byte count as a short human-readable string (e.g. "5.0 MB").
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final value = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$value ${units[unit]}';
}

/// Formats download progress as "received / total" (e.g. "5.0 MB / 20.0 MB"),
/// or just the received amount when the total is unknown. Returns null when no
/// bytes have been received yet.
String? formatDownloadSize(int? receivedBytes, int? totalBytes) {
  if (receivedBytes == null) return null;
  if (totalBytes != null && totalBytes > 0) {
    return '${formatBytes(receivedBytes)} / ${formatBytes(totalBytes)}';
  }
  return formatBytes(receivedBytes);
}

Future<List<PackageInfo>> getAllInstalledInfo() async {
  return await packageManager.getInstalledPackages(flags: packageInfoFlags) ??
      [];
}

Future<PackageInfo?> getInstalledInfo(String? packageName) async {
  if (packageName != null) {
    try {
      return await packageManager
          .getPackageInfo(packageName: packageName, flags: packageInfoFlags)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }
  return null;
}

/// Snapshot of a package's install state, taken before an install so that
/// [waitForPackageInstall] can later tell whether the install landed.
class InstallBaseline {
  final bool wasInstalled;
  final int? updateTime;
  const InstallBaseline(this.wasInstalled, this.updateTime);
}

/// Captures the current install state of [appId] to compare against later.
Future<InstallBaseline> captureInstallBaseline(String appId) async {
  final info = await getInstalledInfo(appId);
  return InstallBaseline(info != null, info?.lastUpdateTime);
}

/// Polls for an install that can't report completion synchronously (a silent
/// background install, or a hand-off to an external installer). Returns true as
/// soon as the package appears (when it wasn't installed before) or its update
/// timestamp changes relative to [baseline] — a version-agnostic signal that
/// also works with pseudo-versions — or false if neither happens within
/// [attempts] × [interval].
Future<bool> waitForPackageInstall(
  String appId,
  InstallBaseline baseline, {
  required int attempts,
  Duration interval = const Duration(milliseconds: 500),
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    final info = await getInstalledInfo(appId);
    if (info != null) {
      if (!baseline.wasInstalled) return true;
      final updateTimeAfter = info.lastUpdateTime;
      if (baseline.updateTime == null ||
          (updateTimeAfter != null && updateTimeAfter != baseline.updateTime)) {
        return true;
      }
    }
    await Future.delayed(interval);
  }
  return false;
}

Future<Directory> getAppStorageDir() async {
  try {
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      if (!extDir.existsSync()) {
        extDir.createSync(recursive: true);
      }
      return extDir;
    }
  } catch (_) {}
  return await getApplicationDocumentsDirectory();
}

class AppsProvider with ChangeNotifier {
  // Static, app-lifetime cross-instance save-notification bus; intentionally
  // never closed. The foreground instance subscribes so it can detect saves
  // made by background tasks and reload as needed.
  // ignore: close_sinks
  static final StreamController<void> _eventsController =
      StreamController<void>.broadcast();

  // In memory App state (should always be kept in sync with local storage versions)
  Map<String, AppInMemory> apps = {};
  bool loadingApps = false;

  // Active per-app download cancellation tokens, keyed by app ID.
  final Map<String, CancellationToken> _downloadCancellations = {};

  /// Non-null when the provider failed to initialize. Callers can check this
  /// before assuming the provider is in a usable state.
  String? initError;

  /// Non-null while a [checkUpdates] batch is in flight. Serves as both an
  /// atomic guard (preventing concurrent batches) and a deduplication
  /// mechanism: subsequent callers receive the existing completer's future.
  Completer<List<App>>? updateCheckCompleter;

  /// Update-check progress (0..1), or null when no check is running. Exposed as
  /// a [ValueNotifier] so the progress bar can rebuild on frequent ticks
  /// WITHOUT triggering a full [notify] (which would rerun the expensive app
  /// list pipeline on every listener each tick and stutter the UI).
  final ValueNotifier<double?> refreshProgress = ValueNotifier<double?>(null);
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

  // Serializes concurrent loadApps() calls without busy-waiting.
  Completer<void>? appsLoadingCompleter;

  // Coalesces bursts of saveApps()/removeApps() into a single auto-export.
  Timer? _autoExportDebounce;

  // Set in dispose() to guard against deferred callbacks running post-disposal.
  bool _disposed = false;

  // Tracks whether a background save occurred since the last load.
  bool _needsBgReload = false;
  StreamSubscription<void>? _eventSubscription;
  bool gettingUpdates = false;

  // Variables to keep track of the app foreground status (installs can't run in the background)
  bool isForeground = true;
  bool _isBg = false;

  /// Whether this provider runs in the background (WorkManager) isolate rather
  /// than the main UI isolate.
  bool get isBg => _isBg;
  Stream<FGBGType>? foregroundStream;
  StreamSubscription<FGBGType>? foregroundSubscription;
  late final SettingsProvider settingsProvider;
  Directory? _apkDir;
  Directory? _iconsCacheDir;
  late ThemeSettingsProvider themeSettings = ThemeSettingsProvider();
  late UpdateSettingsProvider updateSettings = UpdateSettingsProvider();
  late BehaviorSettingsProvider behaviorSettings = BehaviorSettingsProvider();
  late ViewSettingsProvider viewSettings = ViewSettingsProvider();
  late PlusSettingsProvider plusSettings = PlusSettingsProvider();
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initializationDone => _initCompleter.future;
  Directory? cachedAppsDir;

  Iterable<AppInMemory> getAppValues({bool deepCopy = true}) {
    _reloadIfBgSaved();
    return deepCopy ? apps.values.map((a) => a.deepCopy()) : apps.values;
  }

  Directory get apkDir {
    if (_apkDir == null) {
      throw StateError(
        'apkDir not initialized - wait for async init to complete',
      );
    }
    return _apkDir!;
  }

  Directory get iconsCacheDir {
    if (_iconsCacheDir == null) {
      throw StateError(
        'iconsCacheDir not initialized - wait for async init to complete',
      );
    }
    return _iconsCacheDir!;
  }

  void _reloadIfBgSaved() {
    if (!_needsBgReload) return;
    _needsBgReload = false;
    loadApps().catchError((e) {
      unawaited(
        logs.add(
          'Reload after background save failed: $e',
          level: LogLevel.error,
        ),
      );
    });
  }

  /// Public wrapper around the protected [notifyListeners] so the provider's
  /// part-file extensions can request listeners to rebuild.
  void notify() => notifyListeners();

  /// Registers a cancellation token for an in-flight download of [appId].
  CancellationToken registerDownloadCancellation(String appId) {
    final token = CancellationToken();
    _downloadCancellations[appId] = token;
    return token;
  }

  /// Clears the cancellation token once a download of [appId] finishes.
  void clearDownloadCancellation(String appId) {
    _downloadCancellations.remove(appId);
  }

  /// Requests cancellation of an ongoing download for [appId], if any.
  void cancelDownload(String appId) {
    _downloadCancellations[appId]?.cancel();
    final entry = apps[appId];
    if (entry != null && entry.downloadProgress != null) {
      entry.downloadProgress = null;
    }
    notify();
  }

  /// Waits for any in-flight [loadApps] to finish, so concurrent callers
  /// serialize instead of busy-waiting on a polling loop.
  Future<void> waitForAppsToLoad() async {
    final completer = appsLoadingCompleter;
    if (completer != null) {
      await completer.future;
      await waitForAppsToLoad();
    }
  }

  /// Schedules a debounced automatic export. Coalesces the many per-app
  /// save/remove operations that happen in bursts into a single export.
  /// No-op (cheaply returns) if auto-export is disabled inside [export].
  void scheduleAutoExport() {
    _autoExportDebounce?.cancel();
    _autoExportDebounce = Timer(const Duration(seconds: 2), () {
      if (!_disposed) {
        export(isAuto: true).catchError((e) {
          unawaited(
            logs.add('Auto-export failed: $e', level: LogLevel.warning),
          );
          return null;
        });
      }
    });
  }

  AppsProvider({
    bool isBg = false,
    SettingsProvider? settingsProvider,
    LogsProvider? logsProvider,
  }) {
    _isBg = isBg;
    this.settingsProvider = settingsProvider ?? SettingsProvider();
    logs = logsProvider ?? LogsProvider();
    // Subscribe to changes in the app foreground status
    foregroundStream = FGBGEvents.instance.stream.asBroadcastStream();
    foregroundSubscription = foregroundStream?.listen((event) async {
      isForeground = event == FGBGType.foreground;
      if (isForeground) {
        await loadApps();
      }
    });
    if (!_isBg) {
      _eventSubscription = _eventsController.stream.listen((_) {
        _needsBgReload = true;
      });
      // Let the download notification's Cancel action reach this provider,
      // including taps routed through the FLN background isolate.
      NotificationsProvider.onDownloadCancelRequested = cancelDownload;
      NotificationsProvider.listenForDownloadCancelFromMain();
    }
    () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final initFutures = Future.wait([
        this.settingsProvider.initializeSettings(),
        themeSettings.initializeSettings(prefs),
        updateSettings.initializeSettings(prefs),
        behaviorSettings.initializeSettings(prefs),
        viewSettings.initializeSettings(prefs),
        plusSettings.initializeSettings(prefs),
      ]);

      final dirsFuture = AppFileService.initAppDirectories();

      await initFutures;
      final dirs = await dirsFuture;

      _apkDir = dirs['APKDir']!;
      _iconsCacheDir = dirs['iconsCacheDir']!;
      if (!isBg) {
        loadingApps = true;
        notify();
        await loadApps();
        // Delete any partial APKs (if safe to do so)
        var cutoff = DateTime.now().subtract(const Duration(days: 7));
        apkDir
            .listSync()
            .where((element) => element.statSync().modified.isBefore(cutoff))
            .forEach((partialApk) {
              if (!areDownloadsRunning()) {
                partialApk.delete(recursive: true);
              }
            });
      }
      _initCompleter.complete();
    }().catchError((e) {
      initError = e.toString();
      unawaited(
        logs.add('AppsProvider async init error: $e', level: LogLevel.error),
      );
    });
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
      // newInfo.packageName comes from parsing the downloaded (not-yet-installed)
      // APK's manifest via getPackageArchiveInfo, not a verified installed package —
      // sanitize before it's used to build a file path below.
      app.id = URLValidator.sanitizeAppId(newInfo.packageName!);
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
    var notifId = DownloadNotification(app.finalName, 0, appId: app.id).id;
    registerDownloadCancellation(app.id);
    if (apps[app.id] != null) {
      apps[app.id]!.downloadProgress = 0;
      notifyListeners();
    }
    try {
      if (app.apkUrls.isEmpty) throw NoAPKError();
      if (app.preferredApkIndex >= app.apkUrls.length) {
        app.preferredApkIndex = app.apkUrls.length - 1;
      }
      if (app.preferredApkIndex < 0) app.preferredApkIndex = 0;
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
      var notif = DownloadNotification(app.finalName, 100, appId: app.id);
      notificationsProvider?.cancel(notif.id);
      int? prevProg;
      DateTime? lastNotificationTime;
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
          notif = DownloadNotification(
            app.finalName,
            prog ?? 100,
            appId: app.id,
          );
          final now = DateTime.now();
          final shouldNotify = prog != null &&
              prevProg != prog &&
              (prevProg == null ||
                  prog == 100 ||
                  ((prog - prevProg!).abs() >= 2 &&
                      (lastNotificationTime == null ||
                          now.difference(lastNotificationTime!).inMilliseconds >= 300)));
          if (shouldNotify) {
            notificationsProvider?.notify(notif);
            prevProg = prog;
            lastNotificationTime = now;
          }
        },
        apkDir.path,
        useExisting: useExisting,
        allowInsecure: app.additionalSettings['allowInsecure'] == true,
        logs: logs,
        isCancelled: () => _downloadCancellations[app.id]?.isCancelled ?? false,
      );

      // Verify SHA-256 digest if available
      final dynamic rawShaMap = app.additionalSettings['assetSha256s'];
      final Map<dynamic, dynamic>? shaMap =
          rawShaMap is Map ? rawShaMap : null;
      final expectedSha = shaMap?[downloadUrl]?.toString() ??
          shaMap?[app.apkUrls[app.preferredApkIndex].key]?.toString() ??
          app.additionalSettings['expectedSha256']?.toString();
      if (expectedSha != null && expectedSha.trim().isNotEmpty) {
        await AppFileService.verifyFileSha256(downloadedFile, expectedSha);
      }

      // Set to 90 for remaining steps, will make null in 'finally'
      if (apps[app.id] != null) {
        apps[app.id]!.downloadProgress = -1;
        notifyListeners();
        notif = DownloadNotification(app.finalName, -1, appId: app.id);
        notificationsProvider?.notify(notif);
      }
      PackageInfo? newInfo;
      var originalAssetName = app.apkUrls[app.preferredApkIndex].key
          .toLowerCase();
      var isAPK = downloadedFile.path.toLowerCase().endsWith('.apk');
      var isXAPK = downloadedFile.path.toLowerCase().endsWith('.xapk');
      var isTarball =
          originalAssetName.endsWith('.tar.gz') ||
          originalAssetName.endsWith('.tgz') ||
          originalAssetName.endsWith('.tar.bz2') ||
          originalAssetName.endsWith('.tar.xz');
      Directory? extractedApkDir;
      if (isAPK) {
        newInfo = await packageManager.getPackageArchiveInfo(
          archiveFilePath: downloadedFile.path,
        );
      } else {
        // Assume XAPK, ZIP, or tarball
        String apkDirPath = '${downloadedFile.path}-dir';
        if (isTarball) {
          await extractTarballFile(downloadedFile.path, apkDirPath);
        } else {
          await unzipFile(downloadedFile.path, apkDirPath);
        }
        extractedApkDir = Directory(apkDirPath);
        var apks = extractedApkDir
            .listSync(recursive: true)
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

        String? filterRegEx;
        if (isTarball &&
            app.additionalSettings['tarballedApkFilterRegEx']?.isNotEmpty ==
                true) {
          filterRegEx = app.additionalSettings['tarballedApkFilterRegEx'];
        } else if (!isTarball &&
            app.additionalSettings['zippedApkFilterRegEx']?.isNotEmpty ==
                true) {
          filterRegEx = app.additionalSettings['zippedApkFilterRegEx'];
        }
        if (filterRegEx != null) {
          var reg = RegExp(filterRegEx);
          apks.removeWhere((apk) {
            var relativePath = apk.path.substring(
              extractedApkDir!.path.length + 1,
            );
            var shouldDelete = !reg.hasMatch(relativePath);
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
            newInfo = await packageManager.getPackageArchiveInfo(
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
        DownloadedDirType dirType;
        if (isXAPK) {
          dirType = DownloadedDirType.XAPK;
        } else if (isTarball) {
          dirType = DownloadedDirType.TARBALL;
        } else {
          dirType = DownloadedDirType.ZIP;
        }
        return DownloadedDir(app.id, downloadedFile, extractedApkDir!, dirType);
      }
    } finally {
      clearDownloadCancellation(app.id);
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

  Future<bool> canInstallSilently(App app) =>
      AppInstallService.canInstallSilently(
        app,
        behaviorSettings,
        plusSettings,
        updateSettings,
        logs,
      );

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

  Future<void> extractTarballFile(
    String filePath,
    String destinationPath,
  ) async {
    final bytes = await File(filePath).readAsBytes();
    List<int> decompressed;

    // Detect compression by magic bytes (file extension may be wrong after download)
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      // gzip
      decompressed = archive.GZipDecoder().decodeBytes(bytes);
    } else if (bytes.length >= 3 &&
        bytes[0] == 0x42 &&
        bytes[1] == 0x5a &&
        bytes[2] == 0x68) {
      // bzip2 ('BZh')
      decompressed = archive.BZip2Decoder().decodeBytes(bytes);
    } else if (bytes.length >= 6 &&
        bytes[0] == 0xfd &&
        bytes[1] == 0x37 &&
        bytes[2] == 0x7a &&
        bytes[3] == 0x58 &&
        bytes[4] == 0x5a &&
        bytes[5] == 0x00) {
      // xz
      decompressed = archive.XZDecoder().decodeBytes(bytes);
    } else {
      // Assume uncompressed tar
      decompressed = bytes;
    }

    final tarArchive = archive.TarDecoder().decodeBytes(decompressed);
    final destDir = Directory(destinationPath);
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }
    for (final file in tarArchive.files) {
      if (file.isFile) {
        final content = file.content;
        if (content == null) continue;
        final outPath = '${destDir.path}/${file.name}';
        final outFile = File(outPath);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(content);
      }
    }
  }

  Future<bool> installApkDir(
    DownloadedDir dir,
    BuildContext? firstTimeWithContext, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
  }) =>
      AppInstallService.installApkDir(
        dir,
        firstTimeWithContext,
        behaviorSettings,
        plusSettings,
        updateSettings,
        logs,
        apps,
        needsBGWorkaround: needsBGWorkaround,
        shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
        saveApps: saveApps,
      );

  Future<bool> installApk(
    DownloadedApk file,
    BuildContext? firstTimeWithContext, {
    bool needsBGWorkaround = false,
    bool shizukuPretendToBeGooglePlay = false,
    List<DownloadedApk> additionalAPKs = const [],
  }) =>
      AppInstallService.installApk(
        file,
        firstTimeWithContext,
        behaviorSettings,
        plusSettings,
        updateSettings,
        logs,
        apps,
        needsBGWorkaround: needsBGWorkaround,
        shizukuPretendToBeGooglePlay: shizukuPretendToBeGooglePlay,
        additionalAPKs: additionalAPKs,
        saveApps: saveApps,
      );

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

  Future<void> uninstallApp(String appId) async {
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
    // When picking any asset, use the APK filter regex to pre-select the best matching
    // asset by default, without hiding other assets from the user.
    if (pickAnyAsset &&
        app.additionalSettings['apkFilterRegEx'] is String &&
        (app.additionalSettings['apkFilterRegEx'] as String).isNotEmpty) {
      var matching = filterApks(
        urlsToSelectFrom,
        app.additionalSettings['apkFilterRegEx'],
        app.additionalSettings['invertAPKFilter'] == true,
      );
      if (matching.isNotEmpty) {
        appFileUrl = matching.first;
      }
    }
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
    for (var id in appIds) {
      registerDownloadCancellation(id);
    }
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
            APKDir: apkDir,
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
            isCancelled:
                (appId) => _downloadCancellations[appId]?.isCancelled ?? false,
          );
      if (context != null && installedIds.isNotEmpty) {
        AppHaptics.success();
      }
      return installedIds;
    } catch (errors) {
      if (context != null && context.mounted) {
        AppHaptics.failure();
        showError(errors, context);
        if (errors is MultiAppMultiError &&
            errors.successfulAppIds.isNotEmpty) {
          return errors.successfulAppIds;
        }
        return [];
      } else {
        rethrow;
      }
    } finally {
      for (var id in appIds) {
        clearDownloadCancellation(id);
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
        // The confirmAppFileUrl dialog above can stay open long enough for
        // the app to be removed/untracked elsewhere in the meantime (#227-class race).
        if (apps[id] == null) throw ObtainiumError(tr('appNotFound'));
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
          if (apps[id] == null) throw ObtainiumError(tr('appNotFound'));
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
        downloadedIds.add(fileUrl.key);
      } catch (e) {
        errors.add(fileUrl.key, e);
      } finally {
        notificationsProvider.cancel(DownloadNotification(fileUrl.key, 0).id);
      }
    }

    if (!forceParallelDownloads && !behaviorSettings.parallelDownloads) {
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
      // recursive: true — the parent external-storage dir can be transiently
      // missing on disk right after a storage clear/remount even though
      // path_provider still returns its path (#226).
      appsDir.createSync(recursive: true);
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
    try {
      await _loadAppsBody(singleId).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          logs.add(
            'loadApps() timed out after 45s (singleId: $singleId) — '
            'a native call (e.g. getAllInstalledInfo) likely hung. '
            'Aborting so the UI does not freeze on "Please wait" forever.',
            level: LogLevel.error,
          );
        },
      );
    } finally {
      loadingApps = false;
      notifyListeners();
    }
  }

  Future<void> _loadAppsBody(String? singleId) async {
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
                    'Corrupt JSON when loading App (will be ignored): $err',
                  );
                  item.renameSync('${item.path}.corrupt');
                } else if (err is FileSystemException) {
                  // The file can vanish between listSync() and this read (concurrent
                  // removal/storage clear) — skip it instead of aborting the whole load.
                  logs.add(
                    'Skipped missing/unreadable app file ${item.path}: $err',
                  );
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
                  // Persist the correction so it doesn't get recomputed (and
                  // re-logged) on every subsequent load/background check —
                  // loadApps() itself never writes to disk otherwise.
                  await saveApps(
                    [moddedApp],
                    attemptToCorrectInstallStatus: false,
                    reuseInstalledInfo: true,
                  );
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
    if (removedAppIds.isNotEmpty &&
        behaviorSettings.removeOnExternalUninstall) {
      await removeApps(removedAppIds);
    }
  }

  Future<void> updateAppIcon(String? appId, {bool ignoreCache = false}) async {
    if (apps[appId]?.icon == null) {
      var cachedIcon = File('${iconsCacheDir.path}/$appId.png');
      var alreadyCached = cachedIcon.existsSync() && !ignoreCache;
      Uint8List? icon;
      if (alreadyCached) {
        try {
          icon = await cachedIcon.readAsBytes();
        } catch (e) {
          // The cache file can vanish between the existsSync() check above
          // and this read (concurrent cache clear / low-storage cleanup) —
          // fall back to re-fetching from the installed package (#235).
          alreadyCached = false;
          LogsProvider().add('Failed to read cached icon for $appId: $e');
        }
      }
      icon ??= await apps[appId]?.installedInfo?.applicationInfo?.getAppIcon();
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
      }
    }
  }

  Future<void> saveApps(
    List<App> apps, {
    bool attemptToCorrectInstallStatus = true,
    bool onlyIfExists = true,
    bool reuseInstalledInfo = false,
  }) async {
    await Future.wait(
      apps.map((a) async {
        var app = a.deepCopy();
        final bool canReuse =
            reuseInstalledInfo && this.apps.containsKey(app.id);
        PackageInfo? info = canReuse
            ? this.apps[app.id]!.installedInfo
            : await getInstalledInfo(app.id);
        var icon = canReuse
            ? this.apps[app.id]!.icon
            : await info?.applicationInfo?.getAppIcon();
        if (!canReuse) {
          app.name = await (info?.applicationInfo?.getAppLabel()) ?? app.name;
        }
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
    var apkFiles = apkDir.listSync();
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
    // apps[appId] can go missing if the app was removed/untracked while
    // this check was queued (e.g. a concurrent batch checkUpdates() slot,
    // or the detail page's own auto-check racing a removal elsewhere) (#227).
    App? currentApp = apps[appId]?.app;
    if (currentApp == null) {
      return null;
    }
    // Pause update checks until the user resolves a pending repo rename.
    if (currentApp.hasPendingRepoRename) {
      return null;
    }
    checkingUpdateIds.add(appId);
    notify();
    try {
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
    } finally {
      checkingUpdateIds.remove(appId);
      notify();
    }
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
      notify();
      try {
        List<String> appIds = getAppsSortedByUpdateCheckTime(
          ignoreAppsCheckedAfter: ignoreAppsCheckedAfter,
          onlyCheckInstalledOrTrackOnlyApps:
              updateSettings.onlyCheckInstalledOrTrackOnlyApps,
        );
        if (specificIds != null) {
          appIds = appIds.where((aId) => specificIds.contains(aId)).toList();
        }

        final int totalToProcess = appIds.length;
        int completedCount = 0;
        refreshProgress.value = totalToProcess > 0 ? 0.0 : null;

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
            } finally {
              completedCount++;
              if (totalToProcess > 0) {
                refreshProgress.value = completedCount / totalToProcess;
              }
            }
            if (newApp != null) {
              updates.add(newApp);
            }
          },
        );
      } finally {
        gettingUpdates = false;
        refreshProgress.value = null;
        checkingUpdateIds.clear();
        notify();
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
    bool includeAmbiguous = true,
  }) {
    return AppUpdateService.findExistingUpdates(
      apps,
      installedOnly: installedOnly,
      nonInstalledOnly: nonInstalledOnly,
      includeAmbiguous: includeAmbiguous,
    );
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
      var settingsValueKeys = settingsProvider.prefs?.getKeys().toSet();
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
      var installedInfo = await getInstalledInfo(a.id);
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
    _disposed = true;
    foregroundSubscription?.cancel();
    _autoExportDebounce?.cancel();
    _eventSubscription?.cancel();
    refreshProgress.dispose();
    super.dispose();
  }

  Future<List<List<String>>> addAppsByURL(
    List<String> urls, {
    AppSource? sourceOverride,
  }) async {
    final List<dynamic> results = await SourceProvider().getAppsByURLNaive(
      urls,
      alreadyAddedUrls: apps.values.map((e) => e.app.url).toSet(),
      sourceOverride: sourceOverride,
    );
    final List<App> pps = results[0];
    final Map<String, dynamic> errorsMap = results[1];
    for (var app in pps) {
      if (apps.containsKey(app.id)) {
        errorsMap.addAll({app.id: tr('appAlreadyAdded')});
      } else {
        await saveApps([app], onlyIfExists: false);
      }
    }
    final List<List<String>> errors = errorsMap.keys
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
