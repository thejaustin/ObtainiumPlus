import 'package:obtainium/app_sources/git_source.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';

class Codeberg extends GitSource {
  Codeberg() {
    name = 'Forgejo (Codeberg)';
    hosts = ['codeberg.org'];

    additionalSourceAppSpecificSettingFormItems =
        GitHub(hostChanged: true).additionalSourceAppSpecificSettingFormItems;

    canSearch = true;
    searchQuerySettingFormItems = GitHub(hostChanged: true).searchQuerySettingFormItems;
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    return await GitHub(hostChanged: true).getLatestAPKDetailsCommon2(standardUrl, additionalSettings, (
      bool useTagUrl,
    ) async {
      return 'https://${hosts[0]}/api/v1/repos${standardUrl.substring('https://${hosts[0]}'.length)}/${useTagUrl ? 'tags' : 'releases'}?per_page=100';
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
    return GitHub(hostChanged: true).searchCommon(
      query,
      'https://${hosts[0]}/api/v1/repos/search?q=${Uri.encodeQueryComponent(query)}&limit=100',
      'data',
      querySettings: querySettings,
    );
  }
}
