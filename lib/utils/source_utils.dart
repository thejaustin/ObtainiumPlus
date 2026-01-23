import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/source_provider.dart';

HttpClient createHttpClient(bool allowInsecure) {
  var client = HttpClient();
  if (allowInsecure) {
    client.badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
  }
  return client;
}

Future<MapEntry<String, MapEntry<HttpClient, HttpClientResponse>>> sourceRequestStreamResponse(
  String method,
  String url,
  Map<String, String> headers,
  Map<String, dynamic> sourceConfigSettingValues, {
  bool followRedirects = true,
  int maxRedirects = 5,
  bool allowInsecure = false,
}) async {
  var httpClient = createHttpClient(allowInsecure);
  var currentUrl = url;
  for (var i = 0; i <= maxRedirects; i++) {
    var request = await httpClient.openUrl(method, Uri.parse(currentUrl));
    request.followRedirects = false;
    headers.forEach((key, value) {
      request.headers.set(key, value);
    });
    var response = await request.close();
    if (followRedirects &&
        (
            response.statusCode == 301 ||
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
  static Future<Response> httpRequest(
    String url,
    {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    Map<String, String> sourceConfigSettingValues = const {},
    bool followRedirects = true,
    int maxRedirects = 5,
    bool allowInsecure = false,
  }) async {
    var httpClient = createHttpClient(allowInsecure);
    var currentUrl = url;
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
          (
              response.statusCode == 301 ||
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
      return await httpClientResponseStreamToFinalResponse(
        httpClient,
        method,
        currentUrl,
        response,
      );
    }
    throw ObtainiumError('Too many redirects ($maxRedirects)');
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
      (res.reasonPhrase != null && res.reasonPhrase!.isNotEmpty)
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
    var num = int.tryParse(value);
    if (num == null) {
      return tr('invalidInput');
    }
    if (positive && num <= 0) {
      return tr('invalidInput');
    }
    return null;
  }

  static bool isTempId(App app) {
    return RegExp(r'^[0-9]+$').hasMatch(app.id);
  }

  static String? replaceMatchGroupsInString(RegExpMatch match, String matchGroupString) {
    if (RegExp(r'^\d+$').hasMatch(matchGroupString)) {
      matchGroupString = r'\' + matchGroupString;
    }
    final numberRegex = RegExp(r'\\$\d+');
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

  static String? extractVersion(
    String? versionExtractionRegEx,
    String? matchGroupString,
    String stringToCheck,
  ) {
    if (versionExtractionRegEx?.isNotEmpty == true) {
      String? version = stringToCheck;
      var match = RegExp(versionExtractionRegEx!).allMatches(version);
      if (match.isEmpty) {
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

  static List<MapEntry<String, String>> filterApks(
    List<MapEntry<String, String>> apkUrls,
    String? apkFilterRegEx,
    bool? invert,
  ) {
    if (apkFilterRegEx?.isNotEmpty == true) {
      var reg = RegExp(apkFilterRegEx!);
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
}