import 'dart:convert';

import 'package:html/parser.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/source_provider.dart';

class RockMods extends AppSource {
  RockMods() {
    name = 'RockMods';
    hosts = ['rockmods.net'];
    enforceTrackOnly = true;
    naiveStandardVersionDetection = true;
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegEx = RegExp(
      '^https?://(www\\.)?${getSourceRegex(hosts)}/apps/[^/]+',
      caseSensitive: false,
    );
    RegExpMatch? match = standardUrlRegEx.firstMatch(url);
    if (match == null) {
      throw InvalidURLError(name);
    }
    return match.group(0)!;
  }

  @override
  Future<String?> tryInferringAppId(
    String standardUrl, {
    Map<String, dynamic> additionalSettings = const {},
  }) async {
    return Uri.parse(standardUrl).pathSegments.last;
  }

  @override
  Future<Map<String, String>?> getRequestHeaders(
    Map<String, dynamic> additionalSettings,
    String url, {
    bool forAPKDownload = false,
  }) async {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
    };
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    try {
      var res = await sourceRequest(standardUrl, additionalSettings);
      if (res.statusCode != 200) {
        throw getObtainiumHttpError(res);
      }

      String? appName;
      String? appVersion;
      String? appAuthor;

      var jsonLdMatches = RegExp(
        '<script type="application/ld\\+json">(.*?)</script>',
        dotAll: true,
      ).allMatches(res.body);

      Map<dynamic, dynamic>? appJson;
      for (var m in jsonLdMatches) {
        var j = jsonDecode(m.group(1)!);
        if (j is Map && j['@type'] == 'SoftwareApplication') {
          appJson = j;
          break;
        }
      }

      if (appJson != null) {
        appName = (appJson['name'] as String?)?.trim();
        appVersion = (appJson['softwareVersion'] as String?)?.trim();
        appAuthor = (appJson['author'] as Map?)?['name'] as String?;
      }

      if (appName == null || appName.isEmpty) {
        var html = parse(res.body);
        var h1 = html.querySelector('h1');
        appName = h1?.text?.trim() ?? standardUrl.split('/').last;
      }

      if (appVersion == null || appVersion.isEmpty) {
        throw NoVersionError();
      }

      return APKDetails(
        appVersion,
        getApkUrlsFromUrls([]),
        AppNames(appAuthor ?? name, appName),
      );
    } catch (e) {
      if (e is ObtainiumError) rethrow;
      throw ObtainiumError('RockMods Error: $e');
    }
  }
}
