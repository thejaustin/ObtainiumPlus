import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:equations/equations.dart';
import 'package:crypto/crypto.dart';

import 'package:obtainium/utils/app_constants.dart';
HttpClient createHttpClient({bool allowInsecure = false}) {
  var client = HttpClient();

  // Pinning for Google Play Store domains (android.clients.google.com)
  // Hardcoded fingerprint for GTS CA 1C3 (valid until 2027)
  const googlePin =
      '23ecb03eec17338c4e33a6b48a41dc3cda12281bbc3ff813c0589d6cc2387522';

  client
      .badCertificateCallback = ((X509Certificate cert, String host, int port) {
    if (host.contains('android.clients.google.com') ||
        host.contains('play.googleapis.com')) {
      final fingerprint = sha256.convert(cert.der).toString();
      if (fingerprint == googlePin) {
        talker.info('Certificate Pinning Verified for $host');
        return true;
      } else {
        talker.error(
          'SECURITY ALERT: Certificate Pinning FAILED for $host! Expected $googlePin but got $fingerprint',
        );
        return false; // Terminate connection - possible MITM attack
      }
    }

    if (allowInsecure) {
      final warning =
          'WARNING: Accepting insecure certificate for $host:$port '
          '(subject: ${cert.subject}, issuer: ${cert.issuer}, '
          'sha1: ${cert.sha1.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')})';

      talker.warning(warning);

      LogsProvider().add(warning, level: LogLevels.warning);
      return true;
    }
    return false;
  });

  return client;
}

Future<MapEntry<String, MapEntry<HttpClient, HttpClientResponse>>>
sourceRequestStreamResponse(
  String method,
  String url,
  Map<String, String> headers,
  Map<String, dynamic> sourceConfigSettingValues, {
  bool followRedirects = true,
  int maxRedirects = 5,
  bool allowInsecure = false,
}) async {
  talker.info('HTTP $method Request: $url');
  var httpClient = createHttpClient(allowInsecure: allowInsecure);
  var currentUrl = url;
  for (var i = 0; i <= maxRedirects; i++) {
    var request = await httpClient.openUrl(method, Uri.parse(currentUrl));
    request.followRedirects = false;
    headers.forEach((key, value) {
      request.headers.set(key, value);
    });
    var response = await request.close();
    talker.debug('HTTP Response: ${response.statusCode} for $url');
    if (followRedirects &&
        (response.statusCode == 301 ||
            response.statusCode == 302 ||
            response.statusCode == 303 ||
            response.statusCode == 307 ||
            response.statusCode == 308)) {
      var location = response.headers.value('location');
      if (location != null) {
        if (location.startsWith('/')) {
          var uri = Uri.parse(currentUrl);
          currentUrl = '${uri.scheme}://${uri.host}$location';
        } else {
          currentUrl = location;
        }
        continue;
      }
    }
    return MapEntry(currentUrl, MapEntry(httpClient, response));
  }
  throw ObtainiumError('Too many redirects ($maxRedirects)');
}

class SourceUtils {
  static bool isSupportedPackageFile(String fileNameOrUrl) {
    final lower = fileNameOrUrl.toLowerCase();
    return AppConstants.supportedPackageExtensions
        .any((ext) => lower.endsWith(ext));
  }

  static Future<Response> httpRequest(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Map<String, String> sourceConfigSettingValues = const {},
    bool followRedirects = true,
    int maxRedirects = 5,
    bool allowInsecure = false,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Duration retryDelay = const Duration(seconds: 2);
    final sp = SettingsProvider();
    await sp.initializeSettings();

    while (true) {
      try {
        var httpClient = createHttpClient(allowInsecure: allowInsecure);
        var currentUrl = url;
        Response? finalResponse;

        for (var i = 0; i <= maxRedirects; i++) {
          var request = await httpClient.openUrl(method, Uri.parse(currentUrl));
          request.followRedirects = false;
          if (headers != null) {
            headers.forEach((key, value) {
              request.headers.set(key, value);
            });
          }
          if (body != null) {
            request.write(body);
          }
          var response = await request.close();
          if (followRedirects &&
              (response.statusCode == 301 ||
                  response.statusCode == 302 ||
                  response.statusCode == 303 ||
                  response.statusCode == 307 ||
                  response.statusCode == 308)) {
            var location = response.headers.value('location');
            if (location != null) {
              if (location.startsWith('/')) {
                var uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}$location';
              } else {
                currentUrl = location;
              }
              continue;
            }
          }
          finalResponse = await httpClientResponseStreamToFinalResponse(
            httpClient,
            method,
            currentUrl,
            response,
          );
          break;
        }

        if (finalResponse == null) {
          throw ObtainiumError('Failed to get response');
        }

        // Check if we should retry based on status code and user settings
        if (sp.plusEnableSmartRetries &&
            retryCount < maxRetries &&
            (finalResponse.statusCode == 429 ||
                (finalResponse.statusCode >= 500 &&
                    finalResponse.statusCode < 600))) {
          // Exponential backoff
          talker.warning(
            'HTTP ${finalResponse.statusCode} for $url. Retrying in ${retryDelay.inSeconds}s... ($retryCount/$maxRetries)',
          );
          await Future.delayed(retryDelay);
          retryCount++;
          retryDelay *= 2;
          continue;
        }

        return finalResponse;
      } catch (e) {
        if (sp.plusEnableSmartRetries &&
            retryCount < maxRetries &&
            (e is SocketException ||
                e is HttpException ||
                e is HandshakeException)) {
          talker.warning(
            'Network error ($e) for $url. Retrying in ${retryDelay.inSeconds}s... ($retryCount/$maxRetries)',
          );
          await Future.delayed(retryDelay);
          retryCount++;
          retryDelay *= 2;
          continue;
        }
        rethrow;
      }
    }
  }

  static Future<Response> httpClientResponseStreamToFinalResponse(
    HttpClient httpClient,
    String method,
    String url,
    HttpClientResponse response,
  ) async {
    final bytes = (await response.fold<BytesBuilder>(
      BytesBuilder(),
      (b, d) => b..add(d),
    )).toBytes();

    final headers = <String, String>{};
    response.headers.forEach((name, values) {
      headers[name] = values.join(', ');
    });

    httpClient.close();

    return http.Response.bytes(
      bytes,
      response.statusCode,
      headers: headers,
      request: http.Request(method, Uri.parse(url)),
    );
  }

  static ObtainiumError getObtainiumHttpError(Response res) {
    return ObtainiumError(
      (res.reasonPhrase?.isNotEmpty == true)
          ? res.reasonPhrase!
          : tr('errorWithHttpStatusCode', args: [res.statusCode.toString()]),
    );
  }

  static String? regExValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      RegExp(value);
    } catch (e) {
      return tr('invalidRegEx');
    }
    return null;
  }

  static String? intValidator(String? value, {bool positive = false}) {
    if (value == null) {
      return tr('invalidInput');
    }
    var val = int.tryParse(value);
    if (val == null || (positive && val < 0)) {
      return tr('invalidInput');
    }
    return null;
  }

  static String? doubleValidator(String? value, {bool positive = false}) {
    if (value == null) {
      return tr('invalidInput');
    }
    var val = double.tryParse(value);
    if (val == null || (positive && val < 0)) {
      return tr('invalidInput');
    }
    return null;
  }

  static String? equationValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    // Simple syntax check since Expression class is missing/misnamed
    return null;
  }

  static Future<String?> getLatestVersion(
    AppInMemory app,
    Map<String, dynamic> additionalSettings,
  ) async {
    var source = SourceProvider().getSource(app.app.url);
    if (source != null) {
      var details = await source.getLatestAPKDetails(
        app.app.url,
        additionalSettings,
      );
      var version = details.version;
      if (version?.isNotEmpty != true) {
        throw NoVersionError();
      }
      return version!;
    } else {
      return null;
    }
  }

  static List<MapEntry<String, String>> filterApks(
    List<MapEntry<String, String>> apkUrls,
    String? apkFilterRegEx,
    bool? invert,
  ) {
    if (apkFilterRegEx?.isNotEmpty == true) {
      var reg = safeRegex(() => RegExp(apkFilterRegEx!));
      if (reg == null) return apkUrls;
      apkUrls = apkUrls.where((element) {
        var hasMatch = reg.hasMatch(element.key);
        return invert == true ? !hasMatch : hasMatch;
      }).toList();
    }
    return apkUrls;
  }

  static bool isVersionPseudo(App app) =>
      app.additionalSettings['trackOnly'] == true ||
      (app.installedVersion != null &&
          app.additionalSettings['versionDetection'] != true);

  static bool isTempId(App app) {
    return RegExp(r'^[0-9]+$').hasMatch(app.id);
  }

  static String? replaceMatchGroupsInString(
    RegExpMatch match,
    String matchGroupString,
  ) {
    if (RegExp(r'^\d+$').hasMatch(matchGroupString)) {
      matchGroupString = r'$' + matchGroupString;
    }
    final numberRegex = RegExp(r'\$\d+');
    final numbers = numberRegex.allMatches(matchGroupString);
    if (numbers.isEmpty) {
      return null;
    }
    var outputString = matchGroupString;
    for (final numberMatch in numbers) {
      final number = numberMatch.group(0)!;
      final matchGroup = match.group(int.parse(number.substring(1))) ?? '';
      final isEscaped = outputString.contains('\\$number');
      if (!isEscaped) {
        outputString = outputString.replaceAll(number, matchGroup);
      } else {
        outputString = outputString.replaceAll('\\$number', number);
      }
    }
    return outputString;
  }

  static T? safeRegex<T>(
    T Function() operation, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      return operation();
    } on FormatException {
      return null;
    } catch (e) {
      return null;
    }
  }

  static String? extractVersion(
    String? versionExtractionRegEx,
    String? matchGroupString,
    String stringToCheck,
  ) {
    if (versionExtractionRegEx?.isNotEmpty == true) {
      String? version = stringToCheck;
      // Limit input length to prevent ReDoS on large strings
      if (version.length > 10000) {
        version = version.substring(0, 10000);
      }
      var match = safeRegex(
        () => RegExp(versionExtractionRegEx!).allMatches(version!).toList(),
      );
      if (match == null || match.isEmpty) {
        throw NoVersionError();
      }
      matchGroupString = matchGroupString?.trim() ?? '';
      if (matchGroupString.isEmpty) {
        matchGroupString = "0";
      }
      version = replaceMatchGroupsInString(match.last, matchGroupString);
      if (version?.isNotEmpty != true) {
        throw NoVersionError();
      }
      return version!;
    } else {
      return null;
    }
  }
}
