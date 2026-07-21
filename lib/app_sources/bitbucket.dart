import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/utils/app_utils.dart';

class Bitbucket extends AppSource {
  Bitbucket() {
    name = 'Bitbucket';
    hosts = ['bitbucket.org'];
    canSearch = false; // Bitbucket global search is restricted/hard to parse
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegEx = RegExp(
      r'^https?://(www\.)?bitbucket\.org/[^/]+/[^/]+',
      caseSensitive: false,
    );
    RegExpMatch? match = standardUrlRegEx.firstMatch(url);
    if (match == null) {
      throw InvalidURLError(name);
    }
    String matchedUrl = match.group(0)!;
    if (matchedUrl.endsWith('/')) {
      matchedUrl = matchedUrl.substring(0, matchedUrl.length - 1);
    }
    return matchedUrl.toLowerCase();
  }

  @override
  String? changeLogPageFromStandardUrl(String standardUrl) =>
      '$standardUrl/downloads';

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    final names = getAppNames(standardUrl);
    final workspace = names.author;
    final repo = names.name;

    final apiUrl =
        'https://api.bitbucket.org/2.0/repositories/$workspace/$repo/downloads';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: await getRequestHeaders(additionalSettings, apiUrl),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP Error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final values = data['values'] as List<dynamic>?;
    if (values == null || values.isEmpty) {
      throw NoAPKError();
    }

    // Find the latest APK (assuming values are sorted by date descending, which Bitbucket usually does)
    for (var download in values) {
      final downloadName = download['name'] as String?;
      if (downloadName != null && downloadName.toLowerCase().endsWith('.apk')) {
        final downloadUrl = download['links']['self']['href'];
        // Note: Bitbucket doesn't have a strict 'version' attached to simple downloads unless parsed from name
        final versionMatch = RegExp(
          r'v?(\d+\.\d+(\.\d+)?)',
          caseSensitive: false,
        ).firstMatch(downloadName);
        final version =
            versionMatch?.group(1) ?? downloadName.replaceAll('.apk', '');

        return APKDetails(
          version,
          [MapEntry(downloadName, downloadUrl)],
          names,
          releaseDate: null,
          changeLog: null,
        );
      }
    }

    throw NoAPKError();
  }

  AppNames getAppNames(String standardUrl) {
    String temp = standardUrl.substring(standardUrl.indexOf('://') + 3);
    List<String> names = temp.substring(temp.indexOf('/') + 1).split('/');
    return AppNames(names[0], names[1]);
  }
}
