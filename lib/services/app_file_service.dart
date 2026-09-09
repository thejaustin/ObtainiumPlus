import 'dart:async';
import 'package:obtainium/utils/logger.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/source_provider.dart' hide createHttpClient;
import 'package:obtainium/utils/source_utils.dart'
    hide sourceRequestStreamResponse;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppFileService {
  AppFileService._();

  static Future<Directory> getAppStorageDir() async =>
      await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();

  static Future<Directory> getAppsDir() async {
    Directory appsDir = Directory(
      '${(await getAppStorageDir()).path}/app_data',
    );
    if (!appsDir.existsSync()) {
      try {
        appsDir.createSync(recursive: true);
      } catch (_) {
        // External storage creation failed (e.g. Android scoped storage
        // restriction). Fall back to internal app documents directory.
        final fallback = await getApplicationDocumentsDirectory();
        appsDir = Directory('${fallback.path}/app_data');
        if (!appsDir.existsSync()) {
          appsDir.createSync(recursive: true);
        }
      }
    }
    return appsDir;
  }

  static Future<String> getStorageRootPath() async {
    return '/${(await getAppStorageDir()).uri.pathSegments.sublist(0, 3).join('/')}';
  }

  static void deleteFile(File file) {
    if (!file.existsSync()) return;
    try {
      file.deleteSync(recursive: true);
    } on PathAccessException catch (e) {
      throw ObtainiumError(
        tr('fileDeletionError', args: [e.path ?? tr('unknown')]),
      );
    }
  }

  static Future<void> unzipFile(String filePath, String destinationPath) async {
    try {
      await ZipFile.extractToDirectory(
        zipFile: File(filePath),
        destinationDir: Directory(destinationPath),
      );
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 28 ||
          e.message.toLowerCase().contains('no space')) {
        throw ObtainiumError(tr('installFailedStorage'));
      }
      rethrow;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('no space') || errStr.contains('enospc')) {
        throw ObtainiumError(tr('installFailedStorage'));
      }
      rethrow;
    }
  }

  static Future<Map<String, Directory>> initAppDirectories() async {
    late Directory APKDir;
    late Directory iconsCacheDir;

    var cacheDirs = await getExternalCacheDirectories();
    if (cacheDirs?.isNotEmpty ?? false) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message:
              'initAppDirectories: using external cache path ${cacheDirs!.first.path}',
        ),
      );
      APKDir = cacheDirs.first;
      iconsCacheDir = Directory('${cacheDirs.first.path}/icons');
      try {
        if (!APKDir.existsSync()) {
          APKDir.createSync(recursive: true);
        }
        if (!iconsCacheDir.existsSync()) {
          iconsCacheDir.createSync(recursive: true);
        }
      } catch (e) {
        // External cache unavailable at runtime; fall through to internal storage
        cacheDirs = null;
      }
    }
    if (cacheDirs == null || cacheDirs.isEmpty) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message:
              'initAppDirectories: external cache unavailable, falling back to app storage',
        ),
      );
      var baseDir = await getAppStorageDir();
      APKDir = Directory('${baseDir.path}/apks');
      iconsCacheDir = Directory('${baseDir.path}/icons');

      try {
        if (!APKDir.existsSync()) {
          APKDir.createSync(recursive: true);
        }
        if (!iconsCacheDir.existsSync()) {
          iconsCacheDir.createSync(recursive: true);
        }
      } catch (e, st) {
        // External storage creation failed, fall back to internal app documents directory
        Sentry.addBreadcrumb(
          Breadcrumb(
            message:
                'initAppDirectories: external storage creation failed, falling back to internal storage',
          ),
        );
        final fallback = await getApplicationDocumentsDirectory();
        APKDir = Directory('${fallback.path}/apks');
        iconsCacheDir = Directory('${fallback.path}/icons');

        if (!APKDir.existsSync()) {
          try {
            APKDir.createSync(recursive: true);
          } catch (fallbackErr, fallbackSt) {
            Sentry.captureException(
              fallbackErr,
              stackTrace: fallbackSt,
              withScope: (scope) {
                scope.setTag('storage_path', APKDir.path);
                scope.setTag(
                  'error_code',
                  (fallbackErr is FileSystemException)
                      ? (fallbackErr.osError?.errorCode.toString() ?? 'unknown')
                      : 'unknown',
                );
              },
            );
            rethrow;
          }
        }
        if (!iconsCacheDir.existsSync()) {
          try {
            iconsCacheDir.createSync(recursive: true);
          } catch (_) {}
        }
      }
    }

    return {'APKDir': APKDir, 'iconsCacheDir': iconsCacheDir};
  }

  static void clearAppCache(String appId, Directory APKDir) {
    var apkFiles = APKDir.listSync();
    apkFiles
        .where((element) => element.path.split('/').last.startsWith('$appId-'))
        .forEach((element) {
          try {
            element.deleteSync(recursive: true);
          } catch (e) {
            // Ignore
          }
        });
  }

  static void cleanupPartialApks(Directory APKDir, bool areDownloadsRunning) {
    var cutoff = DateTime.now().subtract(const Duration(days: 7));
    try {
      APKDir.listSync()
          .where((element) => element.statSync().modified.isBefore(cutoff))
          .forEach((partialApk) {
            if (!areDownloadsRunning) {
              try {
                partialApk.deleteSync(recursive: true);
              } catch (e) {
                // Ignore errors deleting individual files
              }
            }
          });
    } catch (e) {
      // Ignore errors listing directory
    }
  }

  static String hashListOfLists(List<List<int>> data) {
    final builder = BytesBuilder(copy: false);
    for (var chunk in data) {
      builder.add(chunk);
    }
    var digest = sha256.convert(builder.takeBytes());
    return digest.toString().hashCode.toString();
  }

  static Future<String> checkPartialDownloadHashDynamic(
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

  static Future<String> checkPartialDownloadHash(
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
    var client = IOClient(createHttpClient(allowInsecure: allowInsecure));
    try {
      var response = await client.send(req);
      if (response.statusCode < 200 || response.statusCode > 299) {
        throw ObtainiumError(response.reasonPhrase ?? tr('unexpectedError'));
      }
      final builder = BytesBuilder(copy: false);
      await for (var chunk in response.stream) {
        final remaining = bytesToGrab - builder.length;
        if (remaining <= 0) break;
        if (chunk.length <= remaining) {
          builder.add(chunk);
        } else {
          builder.add(chunk.sublist(0, remaining));
          break;
        }
      }
      var digest = sha256.convert(builder.takeBytes());
      return digest.toString().hashCode.toString();
    } finally {
      client.close();
    }
  }

  static Future<String?> checkETagHeader(
    String url, {
    Map<String, String>? headers,
    bool allowInsecure = false,
  }) async {
    var reqHeaders = headers ?? {};
    var req = Request('GET', Uri.parse(url));
    req.headers.addAll(reqHeaders);
    var client = IOClient(createHttpClient(allowInsecure: allowInsecure));
    try {
      StreamedResponse response = await client.send(req);
      var resHeaders = response.headers;
      return resHeaders[HttpHeaders.etagHeader]
          ?.replaceAll('"', '')
          .hashCode
          .toString();
    } finally {
      client.close();
    }
  }

  static Future<File> downloadFileWithRetry(
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
    bool Function()? isCancelled,
    bool useSmartRetries = true,
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
        isCancelled: isCancelled,
      );
    } catch (e) {
      if (e is DownloadCancelledError) rethrow;
      if (retries > 0 &&
          (e is ClientException ||
              e is SocketException ||
              e is HandshakeException ||
              (e is HttpException &&
                  !e.message.contains('404') &&
                  !e.message.contains('403') &&
                  !e.message.contains('401')))) {
        // Exponential backoff: 2^retry_count * 5 seconds
        // retry_count starts at 3, so we use (4 - retries)
        int attempt = 4 - retries;
        int delaySeconds = useSmartRetries
            ? (5 * (1 << (attempt - 1))) // 5, 10, 20
            : 5;

        if (e is HttpException && e.message.contains('429')) {
          final match = RegExp(r'Retry-After:\s*(\d+)').firstMatch(e.message);
          if (match != null) {
            delaySeconds = int.tryParse(match.group(1)!) ?? delaySeconds;
          } else {
            delaySeconds = delaySeconds < 30 ? 30 : delaySeconds;
          }
        }

        logs?.add(
          'Download failed ($e). Retrying in $delaySeconds seconds... (Attempt $attempt)',
        );
        await Future.delayed(Duration(seconds: delaySeconds));

        if (isCancelled?.call() == true) throw DownloadCancelledError();
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
          isCancelled: isCancelled,
          useSmartRetries: useSmartRetries,
        );
      } else {
        rethrow;
      }
    }
  }

  static Future<File> downloadFile(
    String url,
    String fileName,
    bool fileNameHasExt,
    Function? onProgress,
    String destDir, {
    bool useExisting = true,
    Map<String, String>? headers,
    bool allowInsecure = false,
    LogsProvider? logs,
    bool Function()? isCancelled,
  }) async {
    var reqHeaders = headers ?? {};
    var req = Request('GET', Uri.parse(url));
    req.headers.addAll(reqHeaders);
    var headersClient = IOClient(
      createHttpClient(allowInsecure: allowInsecure),
    );
    StreamedResponse headersResponse = await headersClient.send(req);
    var resHeaders = headersResponse.headers;

    String ext = resHeaders['content-disposition']?.split('.').last ?? 'apk';
    if (ext.endsWith('"') || ext.endsWith("other")) {
      ext = ext.substring(0, ext.length - 1);
    }
    final urlPath = Uri.tryParse(url)?.path ?? url;
    if (AppSource.isApkOrContainerFile(
      urlPath,
      includeArchives: true,
      includeTarballs: true,
    )) {
      ext = urlPath.split('.').last.toLowerCase();
    } else if (ext == 'attachment' ||
        ((Uri.tryParse(url)?.path ?? url).toLowerCase().endsWith('.apk') &&
            ext != 'apk')) {
      ext = 'apk';
    }
    fileName = fileNameHasExt ? fileName : fileName.split('/').last;
    File downloadedFile = File('$destDir/$fileName.$ext');
    if (fileNameHasExt) {
      downloadedFile = File('$destDir/$fileName');
    }

    bool rangeFeatureEnabled = false;
    if (resHeaders['accept-ranges']?.isNotEmpty == true) {
      rangeFeatureEnabled =
          resHeaders['accept-ranges']?.trim().toLowerCase() == 'bytes';
    }
    headersClient.close();

    var fullContentLength = headersResponse.contentLength;
    if (useExisting && downloadedFile.existsSync()) {
      var length = downloadedFile.lengthSync();
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

    File tempDownloadedFile = File('${downloadedFile.path}.part');

    bool tempFileExists = tempDownloadedFile.existsSync();
    if (tempFileExists && useExisting) {
      logs?.add(
        'Partial download exists - will wait: ${tempDownloadedFile.uri.pathSegments.last}',
      );
      bool isDownloading = true;
      int currentTempFileSize = await tempDownloadedFile.length();
      bool shouldReturn = false;
      int pollCycles = 0;
      while (isDownloading && pollCycles++ < 30) {
        await Future.delayed(const Duration(seconds: 7));
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
          break;
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

    var targetFileLength = useExisting && tempDownloadedFile.existsSync()
        ? tempDownloadedFile.lengthSync()
        : null;
    int rangeStart = targetFileLength ?? 0;
    IOSink? sink;
    req = Request('GET', Uri.parse(url));
    req.headers.addAll(reqHeaders);
    if (rangeFeatureEnabled && fullContentLength != null && rangeStart > 0) {
      reqHeaders.addAll({
        'range': 'bytes=$rangeStart-${fullContentLength - 1}',
      });
      sink = tempDownloadedFile.openWrite(mode: FileMode.writeOnlyAppend);
    } else if (tempDownloadedFile.existsSync()) {
      deleteFile(tempDownloadedFile);
    }
    var responseWithClient = await sourceRequestStreamResponse(
      'GET',
      url,
      reqHeaders,
      {'allowInsecure': allowInsecure},
    );
    HttpClient responseClient = responseWithClient.value.key;
    HttpClientResponse response = responseWithClient.value.value;

    if (response.statusCode < 200 || response.statusCode > 299) {
      final retryAfter = response.headers.value('retry-after');
      responseClient.close();
      if (tempDownloadedFile.existsSync()) {
        deleteFile(tempDownloadedFile);
      }
      throw HttpException(
        'Server returned status code ${response.statusCode}: ${response.reasonPhrase}${retryAfter != null ? ' (Retry-After: $retryAfter)' : ''}',
      );
    }

    if (rangeStart > 0 && response.statusCode == HttpStatus.ok) {
      // Server returned 200 OK (ignored Range header) — discard append sink & truncate partial file
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
    DateTime? lastProgressUpdate;
    if (rangeStart > 0 && fullContentLength != null) {
      received = rangeStart;
    }
    const downloadUIUpdateInterval = Duration(milliseconds: 500);
    const downloadBufferSize =
        128 * 1024; // 128KB buffer for faster I/O throughput
    final downloadBuffer = BytesBuilder();
    try {
      await response
          .timeout(
            const Duration(seconds: 45),
            onTimeout: (s) {
              s.addError(
                TimeoutException('Download stalled: no data received for 45s'),
              );
            },
          )
          .map((chunk) {
            if (isCancelled?.call() == true) {
              throw DownloadCancelledError();
            }
            received += chunk.length;
            final now = DateTime.now();
            if (onProgress != null &&
                (lastProgressUpdate == null ||
                    now.difference(lastProgressUpdate!) >=
                        downloadUIUpdateInterval)) {
              progress = fullContentLength != null
                  ? clampDouble((received / fullContentLength) * 100, 0, 100)
                  : 30;
              try {
                onProgress(progress, received, fullContentLength);
              } catch (_) {
                onProgress(progress);
              }
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
      sink = null;
    } on FileSystemException catch (e) {
      if (tempDownloadedFile.existsSync()) {
        try {
          tempDownloadedFile.deleteSync();
        } catch (_) {}
      }
      if (e.osError?.errorCode == 28 ||
          e.message.toLowerCase().contains('no space')) {
        throw ObtainiumError(tr('insufficientStorage'));
      }
      rethrow;
    } finally {
      await sink?.close();
      responseClient.close();
    }
    progress = null;
    if (onProgress != null) {
      try {
        onProgress(progress, received, fullContentLength);
      } catch (_) {
        onProgress(progress);
      }
    }

    if (tempDownloadedFile.existsSync()) {
      tempDownloadedFile.renameSync(downloadedFile.path);
    }
    responseClient.close();
    return downloadedFile;
  }

  static Future<int> clearAllDownloadedApks() async {
    int clearedCount = 0;
    try {
      final dirs = await initAppDirectories();
      final apkDir = dirs['APKDir'];
      if (apkDir != null && apkDir.existsSync()) {
        final files = apkDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File &&
              (file.path.endsWith('.apk') || file.path.endsWith('.part'))) {
            file.deleteSync();
            clearedCount++;
          }
        }
      }
    } catch (e) {
      talker.error('Failed to clear APKs: $e');
    }
    return clearedCount;
  }

  /// Computes the SHA-256 hash of a file as a lowercase hexadecimal string.
  static Future<String> computeFileSha256(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString().toLowerCase();
  }

  /// Verifies that [file] matches the [expectedSha256] digest.
  /// Throws [ObtainiumError] if the hash does not match.
  static Future<void> verifyFileSha256(File file, String expectedSha256) async {
    final cleanExpected =
        expectedSha256.toLowerCase().replaceAll('sha256:', '').trim();
    if (cleanExpected.isEmpty) return;
    final actual = await computeFileSha256(file);
    if (actual != cleanExpected) {
      talker.error(
        'SHA-256 mismatch for ${file.path}: expected $cleanExpected, got $actual',
      );
      throw ObtainiumError(
        'Integrity check failed: SHA-256 digest mismatch. The downloaded file may be incomplete or corrupted.',
      );
    }
    talker.info('SHA-256 verified successfully for ${file.path}: $actual');
  }
}
