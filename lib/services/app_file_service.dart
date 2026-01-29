import 'dart:async';
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
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_archive/flutter_archive.dart';

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
      appsDir.createSync();
    }
    return appsDir;
  }

  static Future<String> getStorageRootPath() async {
    return '/${(await getAppStorageDir()).uri.pathSegments.sublist(0, 3).join('/')}';
  }

  static void deleteFile(File file) {
    try {
      file.deleteSync(recursive: true);
    } on PathAccessException catch (e) {
      throw ObtainiumError(
        tr('fileDeletionError', args: [e.path ?? tr('unknown')]),
      );
    }
  }

  static Future<void> unzipFile(String filePath, String destinationPath) async {
    await ZipFile.extractToDirectory(
      zipFile: File(filePath),
      destinationDir: Directory(destinationPath),
    );
  }

  static String hashListOfLists(List<List<int>> data) {
    var bytes = utf8.encode(jsonEncode(data));
    var digest = sha256.convert(bytes);
    var hash = digest.toString();
    return hash.hashCode.toString();
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
    var client = IOClient(createHttpClient(allowInsecure));
    try {
      var response = await client.send(req);
      if (response.statusCode < 200 || response.statusCode > 299) {
        throw ObtainiumError(response.reasonPhrase ?? tr('unexpectedError'));
      }
      List<List<int>> bytes = await response.stream.take(bytesToGrab).toList();
      return hashListOfLists(bytes);
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
    var client = IOClient(createHttpClient(allowInsecure));
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
  }) async {
    var reqHeaders = headers ?? {};
    var req = Request('GET', Uri.parse(url));
    req.headers.addAll(reqHeaders);
    var headersClient = IOClient(createHttpClient(allowInsecure));
    StreamedResponse headersResponse = await headersClient.send(req);
    var resHeaders = headersResponse.headers;

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
        : fileName.split('/').last;
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
      while (isDownloading) {
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

    var received = 0;
    double? progress;
    DateTime? lastProgressUpdate;
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
}
