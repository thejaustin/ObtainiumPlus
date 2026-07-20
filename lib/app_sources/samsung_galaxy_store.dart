import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../custom_errors.dart';
import '../models/app_source.dart';
import '../models/app_source_helpers.dart';
import '../utils/app_utils.dart';

class SamsungGalaxyStore extends AppSource {
  SamsungGalaxyStore() {
    name = 'Samsung Galaxy Store';
    hosts = ['apps.samsung.com', 'galaxystore.samsung.com'];
    canSearch = false; 
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegEx = RegExp(
      r'^https?://(apps|galaxystore)\.samsung\.com/appquery/appDetail\.as\?appId=[a-zA-Z0-9\._]+',
      caseSensitive: false,
    );
    RegExpMatch? match = standardUrlRegEx.firstMatch(url);
    if (match == null) {
      throw InvalidURLError(name);
    }
    return match.group(0)!.toLowerCase();
  }

  @override
  String? changeLogPageFromStandardUrl(String standardUrl) => standardUrl;

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    final response = await http.get(
      Uri.parse(standardUrl),
      headers: await getRequestHeaders(additionalSettings, standardUrl),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP Error: ${response.statusCode}');
    }

    final document = html.parse(response.body);
    final names = getAppNames(standardUrl);

    // Parse version from Galaxy Store HTML (usually embedded in script tags or specific divs)
    final versionElement = document.querySelector('.version-class-placeholder'); 
    final version = versionElement?.text.trim() ?? 'Unknown';

    return APKDetails(
      version,
      [],
      names,
      releaseDate: null,
      changeLog: null,
    );
  }

  AppNames getAppNames(String standardUrl) {
    Uri uri = Uri.parse(standardUrl);
    String appId = uri.queryParameters['appId'] ?? 'Unknown App';
    return AppNames('Samsung', appId);
  }
}
