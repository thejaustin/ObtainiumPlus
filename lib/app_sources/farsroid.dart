<<<<<<< HEAD
import 'package:obtainium/utils/app_utils.dart';
=======
>>>>>>> upstream/main
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:html/parser.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/custom_errors.dart';
<<<<<<< HEAD
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
=======
>>>>>>> upstream/main
import 'package:obtainium/providers/source_provider.dart';

class Farsroid extends AppSource {
  Farsroid() {
    hosts = ['farsroid.com'];
    name = 'Farsroid';
<<<<<<< HEAD
    naiveStandardVersionDetection = true;
=======
>>>>>>> upstream/main

    additionalSourceAppSpecificSettingFormItems = [
      [
        GeneratedFormSwitch(
          'useFirstApkOfVersion',
          label: tr('useFirstApkOfVersion'),
          defaultValue: true,
        ),
      ],
<<<<<<< HEAD
=======
      [
        GeneratedFormSwitch(
          'releaseTitleAsVersion',
          label: tr('releaseTitleAsVersion'),
          defaultValue: false,
        ),
      ],
>>>>>>> upstream/main
    ];
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegEx = RegExp(
      '^https?://([^\\.]+\\.)${getSourceRegex(hosts)}/[^/]+',
      caseSensitive: false,
    );
    RegExpMatch? match = standardUrlRegEx.firstMatch(url);
    if (match == null) {
      throw InvalidURLError(name);
    }
    return match.group(0)!;
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    String appName = Uri.parse(standardUrl).pathSegments.last;

    var res = await sourceRequest(standardUrl, additionalSettings);
    if (res.statusCode != 200) {
<<<<<<< HEAD
      throw SourceUtils.getObtainiumHttpError(res);
=======
      throw getObtainiumHttpError(res);
>>>>>>> upstream/main
    }
    var html = parse(res.body);
    var dlinks = html.querySelectorAll('.download-links');
    if (dlinks.isEmpty) {
      throw NoReleasesError();
    }
    var postId = dlinks.first.attributes['data-post-id'] ?? '';
    var version = dlinks.first.attributes['data-post-version'] ?? '';

    if (postId.isEmpty || version.isEmpty) {
      throw NoVersionError();
    }

    var res2 = await sourceRequest(
      Uri.encodeFull(
        'https://${hosts[0]}/api/download-box/?post_id=$postId&post_version=$version',
      ),
      additionalSettings,
    );
    var html2 = jsonDecode(res2.body)?['data']?['content'] as String? ?? '';
    if (html2.isEmpty) {
      throw NoAPKError();
    }
    var apkLinks = (await grabLinksCommon(
      html2,
      res2.request!.url,
<<<<<<< HEAD
      additionalSettings,
    )).map((l) => MapEntry(Uri.parse(l.key).pathSegments.last, l.key)).toList();

    if (additionalSettings['useFirstApkOfVersion'] == true) {
      apkLinks = apkLinks
          .where(
            (l) => l.key.toLowerCase().startsWith(
              '$appName-$version'.toLowerCase(),
            ),
          )
          .toList();
    }

    if (apkLinks.isEmpty) {
      throw NoAPKError();
    }
=======
      {
        ...additionalSettings,
        'skipSort': true,
      },
    )).map((l) => MapEntry(Uri.parse(l.key).pathSegments.last, l.key)).toList();

    apkLinks = filterApks(
      apkLinks,
      additionalSettings['apkFilterRegEx'],
      additionalSettings['invertAPKFilter'],
    );
    if (apkLinks.isEmpty) {
      throw NoAPKError();
    }
    if (additionalSettings['autoApkFilterByArch'] == true) {
      apkLinks = await filterApksByArch(apkLinks);
    }
    if (additionalSettings['useFirstApkOfVersion'] == true) {
      apkLinks = [apkLinks.first];
    }

    if (additionalSettings['releaseTitleAsVersion'] == true) {
      if (apkLinks.length != 1) {
        throw NoVersionError();
      }
      version = apkLinks.single.key;
    }
>>>>>>> upstream/main

    return APKDetails(version, apkLinks, AppNames(name, appName));
  }
}
