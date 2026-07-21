import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/source_provider.dart';

class XdaDevelopers extends AppSource {
  XdaDevelopers() {
    name = 'XDA Developers';
    hosts = ['xda-developers.com', 'forum.xda-developers.com'];
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegEx = RegExp(
      r'^https?://(forum\.)?xda-developers\.com/t/[a-zA-Z0-9\-]+\.\d+/?',
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
    return matchedUrl;
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
    String threadName = uri.pathSegments.length > 1
        ? uri.pathSegments[1]
        : 'Unknown';
    if (threadName.contains('.')) {
      threadName = threadName.substring(0, threadName.lastIndexOf('.'));
    }
    var names = AppNames(runtimeType.toString(), threadName);

    // Find all links to attachments that end in .apk
    var attachmentLinks = document.querySelectorAll(
      'a[href*="attachments/"]',
    );

    for (var link in attachmentLinks) {
      String text = link.text.trim().toLowerCase();
      if (text.endsWith('.apk')) {
        String href = link.attributes['href'] ?? '';
        if (href.startsWith('/')) {
          href = 'https://forum.xda-developers.com$href';
        }

        var versionMatch = RegExp(
          r'v?(\d+\.\d+(\.\d+)?)',
          caseSensitive: false,
        ).firstMatch(text);
        String version = versionMatch?.group(1) ?? text.replaceAll('.apk', '');

        return APKDetails(
          version,
          getApkUrlsFromUrls([href]),
          names,
          releaseDate: null,
          changeLog: null,
        );
      }
    }

    throw NoAPKError();
  }
}

