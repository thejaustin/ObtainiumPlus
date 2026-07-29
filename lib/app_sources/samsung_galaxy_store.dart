import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/source_provider.dart';

class SamsungGalaxyStore extends AppSource {
  SamsungGalaxyStore() {
    name = 'Samsung Galaxy Store';
    hosts = ['apps.samsung.com', 'galaxystore.samsung.com'];
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
    return match.group(0)!;
  }

  @override
  String? changeLogPageFromStandardUrl(String standardUrl) => standardUrl;

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    Response res = await sourceRequest(standardUrl, additionalSettings);
    if (res.statusCode != 200) {
      throw getObtainiumHttpError(res);
    }

    var document = parse(res.body);
    Uri uri = Uri.parse(standardUrl);
    String appId = uri.queryParameters['appId'] ?? 'Unknown App';
    var names = AppNames(runtimeType.toString(), appId);

    var versionElement = document.querySelector('.version-class-placeholder');
    String version = versionElement?.text.trim() ?? 'Unknown';

    return APKDetails(version, [], names, releaseDate: null, changeLog: null);
  }
}
