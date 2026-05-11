<<<<<<< HEAD
import 'package:obtainium/app_sources/git_source.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';

class Codeberg extends GitSource {
=======
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/source_provider.dart';

class Codeberg extends AppSource {
  GitHub gh = GitHub(hostChanged: true);
>>>>>>> upstream/main
  Codeberg() {
    name = 'Forgejo (Codeberg)';
    hosts = ['codeberg.org'];

<<<<<<< HEAD
    additionalSourceAppSpecificSettingFormItems = GitHub(
      hostChanged: true,
    ).additionalSourceAppSpecificSettingFormItems;

    canSearch = true;
    searchQuerySettingFormItems = GitHub(
      hostChanged: true,
    ).searchQuerySettingFormItems;
  }

  @override
=======
    additionalSourceAppSpecificSettingFormItems =
        gh.additionalSourceAppSpecificSettingFormItems;

    canSearch = true;
    searchQuerySettingFormItems = gh.searchQuerySettingFormItems;
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegEx = RegExp(
      '^https?://(www\\.)?${getSourceRegex(hosts)}/[^/]+/[^/]+',
      caseSensitive: false,
    );
    RegExpMatch? match = standardUrlRegEx.firstMatch(url);
    if (match == null) {
      throw InvalidURLError(name);
    }
    return match.group(0)!;
  }

  @override
  String? changeLogPageFromStandardUrl(String standardUrl) =>
      '$standardUrl/releases';

  @override
>>>>>>> upstream/main
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
<<<<<<< HEAD
    return await GitHub(
      hostChanged: true,
    ).getLatestAPKDetailsCommon2(standardUrl, additionalSettings, (
      bool useTagUrl,
    ) async {
      return 'https://${hosts[0]}/api/v1/repos${standardUrl.substring('https://${hosts[0]}'.length)}/${useTagUrl ? 'tags' : 'releases'}?per_page=100';
=======
    return await gh.getLatestAPKDetailsCommon2(standardUrl, additionalSettings, (
      bool useTagUrl,
    ) async {
      final standardUri = Uri.parse(standardUrl);
      final apiPath =
          '/api/v1/repos${standardUri.path}/${useTagUrl ? 'tags' : 'releases'}';
      return standardUri.replace(
        path: apiPath,
        queryParameters: {'per_page': '100'},
      ).toString();
>>>>>>> upstream/main
    }, null);
  }

  AppNames getAppNames(String standardUrl) {
    String temp = standardUrl.substring(standardUrl.indexOf('://') + 3);
    List<String> names = temp.substring(temp.indexOf('/') + 1).split('/');
    return AppNames(names[0], names[1]);
  }

  @override
  Future<Map<String, List<String>>> search(
    String query, {
    Map<String, dynamic> querySettings = const {},
  }) async {
<<<<<<< HEAD
    return GitHub(hostChanged: true).searchCommon(
=======
    return gh.searchCommon(
>>>>>>> upstream/main
      query,
      'https://${hosts[0]}/api/v1/repos/search?q=${Uri.encodeQueryComponent(query)}&limit=100',
      'data',
      querySettings: querySettings,
    );
  }
}
