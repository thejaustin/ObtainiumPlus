import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';

class Gitea extends AppSource {
  GitHub gh = GitHub(hostChanged: true);
  Gitea() {
    name = 'Gitea (Self-Hosted)';
    hosts = []; // Generic, relies on overrideSource or specific URL matching
    
    additionalSourceAppSpecificSettingFormItems =
        gh.additionalSourceAppSpecificSettingFormItems;

    canSearch = false; // Cannot globally search all generic Gitea instances
    searchQuerySettingFormItems = gh.searchQuerySettingFormItems;
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    // Basic validation for a Git repository URL (e.g., https://domain.com/user/repo)
    RegExp standardUrlRegEx = RegExp(
      '^https?://[^/]+/[^/]+/[^/]+',
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
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    return await gh.getLatestAPKDetailsCommon2(standardUrl, additionalSettings, (
      bool useTagUrl,
    ) async {
      final standardUri = Uri.parse(standardUrl);
      final apiPath =
          '/api/v1/repos${standardUri.path}/${useTagUrl ? 'tags' : 'releases'}';
      return standardUri
          .replace(path: apiPath, queryParameters: {'per_page': '100'})
          .toString();
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
    throw UnimplementedError("Generic Gitea search is not supported.");
  }
}
