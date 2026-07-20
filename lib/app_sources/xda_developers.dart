import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../custom_errors.dart';
import '../models/app_source.dart';
import '../models/app_source_helpers.dart';
import '../utils/app_utils.dart';

class XdaDevelopers extends AppSource {
  XdaDevelopers() {
    name = 'XDA Developers';
    hosts = ['xda-developers.com', 'forum.xda-developers.com'];
    canSearch = false;
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
    return matchedUrl.toLowerCase();
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

    // Find all links to attachments that end in .apk
    final attachmentLinks = document.querySelectorAll('a[href*="attachments/"]');
    
    for (var link in attachmentLinks) {
      final text = link.text.trim().toLowerCase();
      if (text.endsWith('.apk')) {
        String href = link.attributes['href'] ?? '';
        if (href.startsWith('/')) {
          href = 'https://forum.xda-developers.com$href';
        }

        final versionMatch = RegExp(r'v?(\d+\.\d+(\.\d+)?)', caseSensitive: false).firstMatch(text);
        final version = versionMatch?.group(1) ?? text.replaceAll('.apk', '');

        return APKDetails(
          version,
          [MapEntry(text, href)],
          names,
          releaseDate: null,
          changeLog: null,
        );
      }
    }

    throw NoAPKError();
  }

  AppNames getAppNames(String standardUrl) {
    Uri uri = Uri.parse(standardUrl);
    String threadName = uri.pathSegments.length > 1 ? uri.pathSegments[1] : 'Unknown';
    if (threadName.contains('.')) {
      threadName = threadName.substring(0, threadName.lastIndexOf('.'));
    }
    return AppNames('XDA', threadName);
  }
}
