<<<<<<< HEAD
import 'package:obtainium/utils/app_utils.dart';
=======
>>>>>>> upstream/main
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/app_sources/gitlab.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/custom_errors.dart';
<<<<<<< HEAD
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';

class FDroid extends AppSource {
  static final Map<String, ({dynamic body, DateTime expiry})> _apiCache = {};

  @override
  Future<Response> sourceRequest(
    String url,
    Map<String, dynamic> additionalSettings, {
    bool followRedirects = true,
    Object? postBody,
  }) async {
    var sp = SettingsProvider();
    await sp.initializeSettings();

    // Cache F-Droid API and Gitlab metadata requests only if enabled
    bool isCacheable =
        sp.plusEnableSmartRetries &&
        (url.contains('f-droid.org/api/') ||
            url.contains('gitlab.com/fdroid/fdroiddata')) &&
        postBody == null;

    if (isCacheable) {
      final cached = _apiCache[url];
      if (cached != null && cached.expiry.isAfter(DateTime.now())) {
        return Response(
          cached.body is String ? cached.body : jsonEncode(cached.body),
          200,
          headers: {'x-from-obtainium-cache': 'true'},
        );
      }
    }

    final res = await super.sourceRequest(
      url,
      additionalSettings,
      followRedirects: followRedirects,
      postBody: postBody,
    );

    if (isCacheable && res.statusCode == 200) {
      try {
        dynamic body = res.body;
        if (url.endsWith('.json') || url.contains('/api/')) {
          body = jsonDecode(res.body);
        }
        _apiCache[url] = (
          body: body,
          expiry: DateTime.now().add(
            const Duration(minutes: 10),
          ), // F-Droid data updates infrequently
        );
      } catch (_) {}
    }

    return res;
  }

=======
import 'package:obtainium/providers/source_provider.dart';

class FDroid extends AppSource {
>>>>>>> upstream/main
  FDroid() {
    hosts = ['f-droid.org'];
    name = tr('fdroid');
    naiveStandardVersionDetection = true;
    canSearch = true;
    additionalSourceAppSpecificSettingFormItems = [
      [
        GeneratedFormTextField(
          'filterVersionsByRegEx',
          label: tr('filterVersionsByRegEx'),
          required: false,
          additionalValidators: [
            (value) {
<<<<<<< HEAD
              return SourceUtils.regExValidator(value);
=======
              return regExValidator(value);
>>>>>>> upstream/main
            },
          ],
        ),
      ],
      [
        GeneratedFormSwitch(
          'trySelectingSuggestedVersionCode',
          label: tr('trySelectingSuggestedVersionCode'),
          defaultValue: true,
        ),
      ],
      [
        GeneratedFormSwitch(
          'autoSelectHighestVersionCode',
          label: tr('autoSelectHighestVersionCode'),
        ),
      ],
    ];
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    RegExp standardUrlRegExB = RegExp(
      '^https?://(www\\.)?${getSourceRegex(hosts)}/+[^/]+/+packages/+[^/]+',
      caseSensitive: false,
    );
    RegExpMatch? match = standardUrlRegExB.firstMatch(url);
    if (match != null) {
      url =
          'https://${Uri.parse(match.group(0)!).host}/packages/${Uri.parse(url).pathSegments.where((s) => s.trim().isNotEmpty).last}';
    }
    RegExp standardUrlRegExA = RegExp(
      '^https?://(www\\.)?${getSourceRegex(hosts)}/+packages/+[^/]+',
      caseSensitive: false,
    );
    match = standardUrlRegExA.firstMatch(url);
    if (match == null) {
      throw InvalidURLError(name);
    }
    return match.group(0)!;
  }

  @override
  Future<String?> tryInferringAppId(
    String standardUrl, {
    Map<String, dynamic> additionalSettings = const {},
  }) async {
    return Uri.parse(standardUrl).pathSegments.last;
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    String? appId = await tryInferringAppId(standardUrl);
    String host = Uri.parse(standardUrl).host;
    var details = getAPKUrlsFromFDroidPackagesAPIResponse(
      await sourceRequest(
        'https://$host/api/v1/packages/$appId',
        additionalSettings,
      ),
      'https://$host/repo/$appId',
      standardUrl,
      name,
      additionalSettings: additionalSettings,
    );
    if (!hostChanged) {
      try {
        var res = await sourceRequest(
          'https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/$appId.yml',
          additionalSettings,
        );
        var lines = res.body.split('\n');
        var authorLines = lines.where((l) => l.startsWith('AuthorName: '));
        if (authorLines.isNotEmpty) {
          details.names.author = authorLines.first
              .split(': ')
              .sublist(1)
              .join(': ');
        }
        var changelogUrls = lines
            .where((l) => l.startsWith('Changelog: '))
            .map((e) => e.split(' ').sublist(1).join(' '));
        if (changelogUrls.isNotEmpty) {
          details.changeLog = changelogUrls.first;
          bool isGitHub = false;
          bool isGitLab = false;
          try {
            GitHub(
              hostChanged: true,
            ).sourceSpecificStandardizeURL(details.changeLog!);
            isGitHub = true;
          } catch (e) {
            //
          }
          try {
            GitLab(
              hostChanged: true,
            ).sourceSpecificStandardizeURL(details.changeLog!);
            isGitLab = true;
          } catch (e) {
            //
          }
<<<<<<< HEAD
          if (details.changeLog != null &&
              (isGitHub || isGitLab) &&
              (details.changeLog!.indexOf('/blob/') >= 0)) {
=======
          if ((isGitHub || isGitLab) &&
              (details.changeLog?.indexOf('/blob/') ?? -1) >= 0) {
>>>>>>> upstream/main
            details.changeLog = (await sourceRequest(
              details.changeLog!.replaceFirst('/blob/', '/raw/'),
              additionalSettings,
            )).body;
          }
        }
      } catch (e) {
        // Fail silently
      }
<<<<<<< HEAD
      if (details.changeLog != null && details.changeLog!.length > 2048) {
=======
      if ((details.changeLog?.length ?? 0) > 2048) {
>>>>>>> upstream/main
        details.changeLog = '${details.changeLog!.substring(0, 2048)}...';
      }
    }
    return details;
  }

  @override
  Future<Map<String, List<String>>> search(
    String query, {
    Map<String, dynamic> querySettings = const {},
  }) async {
    Response res = await sourceRequest(
      'https://search.${hosts[0]}/?q=${Uri.encodeQueryComponent(query)}',
      {},
    );
    if (res.statusCode == 200) {
      Map<String, List<String>> urlsWithDescriptions = {};
      parse(res.body).querySelectorAll('.package-header').forEach((e) {
        String? url = e.attributes['href'];
        if (url != null) {
          try {
            standardizeUrl(url);
          } catch (e) {
            url = null;
          }
        }
        if (url != null) {
          urlsWithDescriptions[url] = [
            e.querySelector('.package-name')?.text.trim() ?? '',
            e.querySelector('.package-summary')?.text.trim() ??
                tr('noDescription'),
          ];
        }
      });
      return urlsWithDescriptions;
    } else {
<<<<<<< HEAD
      throw SourceUtils.getObtainiumHttpError(res);
    }
  }

  Future<({Map<String, List<String>> apps, bool hasMore})> browseCategory(
    String category, {
    int page = 1,
  }) async {
    final pageSegment = page > 1 ? '$page/' : '';
    final res = await sourceRequest(
      'https://f-droid.org/en/categories/$category/${pageSegment}',
      {},
    );
    if (res.statusCode == 200) {
      final doc = parse(res.body);
      final Map<String, List<String>> apps = {};
      for (final e in doc.querySelectorAll('.package-header')) {
        String? href = e.attributes['href'];
        if (href == null) continue;
        if (!href.startsWith('http')) href = 'https://f-droid.org$href';
        String? url;
        try {
          url = standardizeUrl(href);
        } catch (_) {
          continue;
        }
        apps[url] = [
          e.querySelector('.package-name')?.text.trim() ?? '',
          e.querySelector('.package-summary')?.text.trim() ??
              tr('noDescription'),
        ];
      }
      final nextPage = page + 1;
      final hasMore = doc
          .querySelectorAll('a.label')
          .any((e) => (e.attributes['href'] ?? '').contains('/$nextPage/'));
      return (apps: apps, hasMore: hasMore);
    } else {
      throw SourceUtils.getObtainiumHttpError(res);
=======
      throw getObtainiumHttpError(res);
>>>>>>> upstream/main
    }
  }

  APKDetails getAPKUrlsFromFDroidPackagesAPIResponse(
    Response res,
    String apkUrlPrefix,
    String standardUrl,
    String sourceName, {
    Map<String, dynamic> additionalSettings = const {},
  }) {
    var autoSelectHighestVersionCode =
        additionalSettings['autoSelectHighestVersionCode'] == true;
    var trySelectingSuggestedVersionCode =
        additionalSettings['trySelectingSuggestedVersionCode'] == true;
    var filterVersionsByRegEx =
        (additionalSettings['filterVersionsByRegEx'] as String?)?.isNotEmpty ==
            true
        ? additionalSettings['filterVersionsByRegEx']
        : null;
    var apkFilterRegEx =
        (additionalSettings['apkFilterRegEx'] as String?)?.isNotEmpty == true
        ? additionalSettings['apkFilterRegEx']
        : null;
    if (res.statusCode == 200) {
      var response = jsonDecode(res.body);
      List<dynamic> releases = response['packages'] ?? [];
      if (apkFilterRegEx != null) {
        releases = releases.where((rel) {
          String apk = '${apkUrlPrefix}_${rel['versionCode']}.apk';
<<<<<<< HEAD
          return SourceUtils.filterApks(
=======
          return filterApks(
>>>>>>> upstream/main
            [MapEntry(apk, apk)],
            apkFilterRegEx,
            false,
          ).isNotEmpty;
        }).toList();
      }
      if (releases.isEmpty) {
        throw NoReleasesError();
      }
      String? version;
      Iterable<dynamic> releaseChoices = [];
      // Grab the versionCode suggested if the user chose to do that
      // Only do so at this stage if the user has no release filter
      if (trySelectingSuggestedVersionCode &&
          response['suggestedVersionCode'] != null &&
          filterVersionsByRegEx == null) {
        var suggestedReleases = releases.where(
          (element) =>
              element['versionCode'] == response['suggestedVersionCode'],
        );
        if (suggestedReleases.isNotEmpty) {
          releaseChoices = suggestedReleases;
          version = suggestedReleases.first['versionName'];
        }
      }
      // Apply the release filter if any
      if (filterVersionsByRegEx?.isNotEmpty == true) {
        version = null;
        releaseChoices = [];
        for (var i = 0; i < releases.length; i++) {
          if (RegExp(
            filterVersionsByRegEx!,
          ).hasMatch(releases[i]['versionName'])) {
            version = releases[i]['versionName'];
          }
        }
        if (version == null) {
          throw NoVersionError();
        }
      }
      // Default to the highest version
      version ??= releases[0]['versionName'];
      if (version == null) {
        throw NoVersionError();
      }
      // If a suggested release was not already picked, pick all those with the selected version
      if (releaseChoices.isEmpty) {
        releaseChoices = releases.where(
          (element) => element['versionName'] == version,
        );
      }
      // For the remaining releases, use the toggles to auto-select one if possible
      if (releaseChoices.length > 1) {
        if (autoSelectHighestVersionCode) {
          releaseChoices = [releaseChoices.first];
        } else if (trySelectingSuggestedVersionCode &&
            response['suggestedVersionCode'] != null) {
          var suggestedReleases = releaseChoices.where(
            (element) =>
                element['versionCode'] == response['suggestedVersionCode'],
          );
          if (suggestedReleases.isNotEmpty) {
            releaseChoices = suggestedReleases;
          }
        }
      }
      if (releaseChoices.isEmpty) {
        throw NoReleasesError();
      }
      List<String> apkUrls = releaseChoices
          .map((e) => '${apkUrlPrefix}_${e['versionCode']}.apk')
          .toList();
      return APKDetails(
        version,
        getApkUrlsFromUrls(apkUrls.toSet().toList()),
        AppNames(sourceName, Uri.parse(standardUrl).pathSegments.last),
      );
    } else {
<<<<<<< HEAD
      throw SourceUtils.getObtainiumHttpError(res);
=======
      throw getObtainiumHttpError(res);
>>>>>>> upstream/main
    }
  }
}
