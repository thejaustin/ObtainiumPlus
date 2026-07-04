import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/providers/source_provider.dart';

abstract class GitSource extends AppSource {
  GitSource({bool hostChanged = false}) {
    this.hostChanged = hostChanged;
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegEx = RegExp(
      '^https?://(www\.)?${getSourceRegex(hosts)}/[^/]+/[^/]+',
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
}
