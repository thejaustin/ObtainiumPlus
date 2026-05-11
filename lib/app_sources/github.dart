import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:obtainium/app_sources/html.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
<<<<<<< HEAD
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:obtainium/app_sources/git_source.dart';

class GitHub extends GitSource {
  static final Map<String, ({String etag, dynamic body, DateTime expiry})>
  _apiCache = {};

  @override
  Future<Response> sourceRequest(
    String url,
    Map<String, dynamic> additionalSettings, {
    bool followRedirects = true,
    Object? postBody,
  }) async {
    var sp = SettingsProvider();
    await sp.initializeSettings();

    // Only cache GET requests to the API if smart retries/caching is enabled
    if (postBody != null ||
        !url.contains('api.github.com') ||
        !sp.plusEnableSmartRetries) {
      return super.sourceRequest(
        url,
        additionalSettings,
        followRedirects: followRedirects,
        postBody: postBody,
      );
    }

    final cached = _apiCache[url];
    if (cached != null && cached.expiry.isAfter(DateTime.now())) {
      // Use cached response if still fresh (GitHub suggests 60s for frequent checks)
      return Response(
        jsonEncode(cached.body),
        200,
        headers: {'x-from-obtainium-cache': 'true'},
      );
    }

    var sourceConfigSettingValues = await getSourceConfigValues(
      additionalSettings,
      sp,
    );
    Map<String, String> headers =
        await getRequestHeaders(additionalSettings, url) ?? {};

    if (cached != null) {
      headers['If-None-Match'] = cached.etag;
    }

    final res = await SourceUtils.httpRequest(
      url,
      method: 'GET',
      headers: headers,
      sourceConfigSettingValues: sourceConfigSettingValues,
      followRedirects: followRedirects,
      allowInsecure: additionalSettings['allowInsecure'] == true,
    );

    if (res.statusCode == 304 && cached != null) {
      // Not modified, refresh expiry and return cached body
      _apiCache[url] = (
        etag: cached.etag,
        body: cached.body,
        expiry: DateTime.now().add(const Duration(minutes: 5)),
      );
      return Response(jsonEncode(cached.body), 200, headers: res.headers);
    }

    if (res.statusCode == 200 && res.headers.containsKey('etag')) {
      // Success, cache the new response
      try {
        final body = jsonDecode(res.body);
        _apiCache[url] = (
          etag: res.headers['etag']!,
          body: body,
          expiry: DateTime.now().add(const Duration(minutes: 5)),
        );
      } catch (_) {}
    }

    return res;
  }

  GitHub({bool hostChanged = false}) : super(hostChanged: hostChanged) {
    hosts = ['github.com'];
    appIdInferIsOptional = true;
    showReleaseDateAsVersionToggle = true;
=======
import 'package:obtainium/providers/source_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GitHub extends AppSource {
  GitHub({hostChanged = false}) {
    hosts = ['github.com'];
    appIdInferIsOptional = true;
    showReleaseDateAsVersionToggle = true;
    this.hostChanged = hostChanged;
>>>>>>> upstream/main
    allowIncludeZips = true;

    sourceConfigSettingFormItems = [
      GeneratedFormTextField(
        'github-creds',
<<<<<<< HEAD
        label: tr('githubToken'),
        tooltip: tr('githubTokenTooltip'),
=======
        label: tr('githubPATLabel'),
>>>>>>> upstream/main
        password: true,
        required: false,
        belowWidgets: [
          const SizedBox(height: 4),
<<<<<<< HEAD
          GestureDetector(
=======
          InkWell(
>>>>>>> upstream/main
            onTap: () {
              launchUrlString(
                'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token',
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text(
              tr('about'),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
      GeneratedFormTextField(
        'GHReqPrefix',
<<<<<<< HEAD
        label: tr('githubProxy'),
        tooltip: tr('githubProxyTooltip'),
=======
        label: tr('GHReqPrefix'),
>>>>>>> upstream/main
        hint: 'gh-proxy.org',
        required: false,
        additionalValidators: [
          (value) {
            try {
              if (value != null && Uri.parse(value).scheme.isNotEmpty) {
                throw true;
              }
              if (value != null) {
                Uri.parse('https://${value}/api.github.com');
              }
            } catch (e) {
              return tr('invalidInput');
            }
            return null;
          },
        ],
        belowWidgets: [
          const SizedBox(height: 4),
<<<<<<< HEAD
          GestureDetector(
=======
          InkWell(
>>>>>>> upstream/main
            onTap: () {
              launchUrlString(
                'https://github.com/sky22333/hubproxy',
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text(
              tr('about'),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
<<<<<<< HEAD
=======
      GeneratedFormSwitch(
        'checkRepoRename',
        label: tr('repoRenamedCheck'),
        defaultValue: false,
      ),
>>>>>>> upstream/main
    ];

    additionalSourceAppSpecificSettingFormItems = [
      [
        GeneratedFormSwitch(
          'includePrereleases',
          label: tr('includePrereleases'),
<<<<<<< HEAD
          tooltip: tr('includePrereleasesTooltip'),
=======
>>>>>>> upstream/main
          defaultValue: false,
        ),
      ],
      [
        GeneratedFormSwitch(
          'fallbackToOlderReleases',
          label: tr('fallbackToOlderReleases'),
<<<<<<< HEAD
          tooltip: tr('fallbackToOlderReleasesTooltip'),
=======
>>>>>>> upstream/main
          defaultValue: true,
        ),
      ],
      [
        GeneratedFormTextField(
          'filterReleaseTitlesByRegEx',
<<<<<<< HEAD
          label: tr('filterReleaseTitlesByRegExLabel'),
          tooltip: tr('filterReleaseTitlesByRegExTooltip'),
          required: false,
          additionalValidators: [
            (value) {
              return SourceUtils.regExValidator(value);
=======
          label: tr('filterReleaseTitlesByRegEx'),
          required: false,
          additionalValidators: [
            (value) {
              return regExValidator(value);
>>>>>>> upstream/main
            },
          ],
        ),
      ],
      [
        GeneratedFormTextField(
          'filterReleaseNotesByRegEx',
<<<<<<< HEAD
          label: tr('filterReleaseNotesByRegExLabel'),
          tooltip: tr('filterReleaseNotesByRegExTooltip'),
          required: false,
          additionalValidators: [
            (value) {
              return SourceUtils.regExValidator(value);
=======
          label: tr('filterReleaseNotesByRegEx'),
          required: false,
          additionalValidators: [
            (value) {
              return regExValidator(value);
>>>>>>> upstream/main
            },
          ],
        ),
      ],
<<<<<<< HEAD
      [
        GeneratedFormSwitch(
          'verifyLatestTag',
          label: tr('verifyLatestTag'),
          tooltip: tr('verifyLatestTagTooltip'),
        ),
      ],
=======
      [GeneratedFormSwitch('verifyLatestTag', label: tr('verifyLatestTag'))],
>>>>>>> upstream/main
      [
        GeneratedFormDropdown(
          'sortMethodChoice',
          [
            MapEntry('date', tr('releaseDate')),
            MapEntry('smartname', tr('smartname')),
            MapEntry('none', tr('none')),
            MapEntry(
              'smartname-datefallback',
              '${tr('smartname')} x ${tr('releaseDate')}',
            ),
            MapEntry('name', tr('name')),
          ],
          label: tr('sortMethod'),
<<<<<<< HEAD
          tooltip: tr('sortMethodTooltip'),
=======
>>>>>>> upstream/main
          defaultValue: 'date',
        ),
      ],
      [
        GeneratedFormSwitch(
          'useLatestAssetDateAsReleaseDate',
<<<<<<< HEAD
          label: tr('useLatestAssetDateAsReleaseDateLabel'),
          tooltip: tr('useLatestAssetDateAsReleaseDateTooltip'),
=======
          label: tr('useLatestAssetDateAsReleaseDate'),
>>>>>>> upstream/main
          defaultValue: false,
        ),
      ],
      [
        GeneratedFormSwitch(
          'releaseTitleAsVersion',
<<<<<<< HEAD
          label: tr('releaseTitleAsVersionLabel'),
          tooltip: tr('releaseTitleAsVersionTooltip'),
=======
          label: tr('releaseTitleAsVersion'),
>>>>>>> upstream/main
          defaultValue: false,
        ),
      ],
    ];

    canSearch = true;
    searchQuerySettingFormItems = [
      GeneratedFormTextField(
        'minStarCount',
        label: tr('minStarCount'),
        defaultValue: '0',
        additionalValidators: [
          (value) {
            try {
              int.parse(value ?? '0');
            } catch (e) {
              return tr('invalidInput');
            }
            return null;
          },
        ],
      ),
<<<<<<< HEAD
      GeneratedFormSwitch(
        'includeForks',
        label: tr('includeForks'),
        defaultValue: true,
      ),
=======
>>>>>>> upstream/main
    ];
  }

  @override
  Future<String?> tryInferringAppId(
    String standardUrl, {
    Map<String, dynamic> additionalSettings = const {},
  }) async {
    const possibleBuildGradleLocations = [
      '/app/build.gradle',
      'android/app/build.gradle',
      'src/app/build.gradle',
    ];
    for (var path in possibleBuildGradleLocations) {
      try {
        var res = await sourceRequest(
          '${await convertStandardUrlToAPIUrl(standardUrl, additionalSettings)}/contents/$path',
          additionalSettings,
        );
        if (res.statusCode == 200) {
          try {
            var body = jsonDecode(res.body);
            var trimmedLines = utf8
                .decode(
                  base64.decode(
                    body['content'].toString().split('\n').join(''),
                  ),
                )
                .split('\n')
                .map((e) => e.trim());
            var appIds = trimmedLines.where(
              (l) =>
                  l.startsWith('applicationId "') ||
                  l.startsWith('applicationId \''),
            );
            appIds = appIds.map(
              (appId) => appId.split(
                appId.startsWith('applicationId "') ? '"' : '\'',
              )[1],
            );
            appIds = appIds
                .map((appId) {
                  if (appId.startsWith('\${') && appId.endsWith('}')) {
                    appId = trimmedLines
                        .where(
                          (l) => l.startsWith(
                            'def ${appId.substring(2, appId.length - 1)}',
                          ),
                        )
                        .first;
                    appId = appId.split(appId.contains('"') ? '"' : '\'')[1];
                  }
                  return appId;
                })
                .where((appId) => appId.isNotEmpty);
            if (appIds.length == 1) {
              return appIds.first;
            }
          } catch (err) {
            LogsProvider().add(
              'Error parsing build.gradle from ${res.request!.url.toString()}: ${err.toString()}',
            );
          }
        }
      } catch (err) {
        // Ignore - ID will be extracted from the APK
      }
    }
    return null;
  }

  @override
<<<<<<< HEAD
=======
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
>>>>>>> upstream/main
  Future<Map<String, String>?> getRequestHeaders(
    Map<String, dynamic> additionalSettings,
    String url, {
    bool forAPKDownload = false,
  }) async {
    var token = await getTokenIfAny(additionalSettings);
    var headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Token $token';
    }
    if (forAPKDownload == true) {
      headers[HttpHeaders.acceptHeader] = 'application/octet-stream';
    }
    if (headers.isNotEmpty) {
      return headers;
    } else {
      return null;
    }
  }

  Future<String?> getTokenIfAny(Map<String, dynamic> additionalSettings) async {
    SettingsProvider settingsProvider = SettingsProvider();
    await settingsProvider.initializeSettings();
    var sourceConfig = await getSourceConfigValues(
      additionalSettings,
      settingsProvider,
    );
    String? creds = sourceConfig['github-creds'];
    if ((additionalSettings['GHReqPrefix'] as String? ?? '').isNotEmpty) {
      creds = null;
    }
    if (creds != null) {
      var userNameEndIndex = creds.indexOf(':');
      if (userNameEndIndex > 0) {
        creds = creds.substring(
          userNameEndIndex + 1,
        ); // For old username-included token inputs
      }
      return creds;
    } else {
      return null;
    }
  }

  @override
  Future<String?> getSourceNote() async {
    if (!hostChanged && (await getTokenIfAny({})) == null) {
      return '${tr('githubSourceNote')} ${hostChanged ? tr('addInfoBelow') : tr('addInfoInSettings')}';
    }
    return null;
  }

  @override
  Future<String> generalReqPrefetchModifier(
    String reqUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    if ((additionalSettings['GHReqPrefix'] as String? ?? '').isNotEmpty) {
      var uri = Uri.parse(reqUrl);
      return 'https://${additionalSettings['GHReqPrefix']}/${uri.toString().substring('https://'.length)}';
    }
    return reqUrl;
  }

<<<<<<< HEAD
  Future<String> getAPIHost(Map<String, dynamic> additionalSettings) async {
    // Always use the official GitHub API endpoint, regardless of user input host
    // This fixes issues when users enter www.github.com instead of github.com
    return 'https://api.github.com';
  }
=======
  Future<String> getAPIHost(Map<String, dynamic> additionalSettings) async =>
      'https://api.${hosts[0]}';
>>>>>>> upstream/main

  Future<String> convertStandardUrlToAPIUrl(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
<<<<<<< HEAD
  ) async {
    // Parse the standard URL to extract the user/repo path
    Uri uri = Uri.parse(standardUrl);

    // Extract the path part after the host (e.g., from /user/repo/path to /user/repo)
    List<String> pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      throw InvalidURLError(name);
    }

    // Take only the first two segments (user and repo) to form the API path
    String userRepoPath = '/${pathSegments[0]}/${pathSegments[1]}';

    return '${await getAPIHost(additionalSettings)}/repos$userRepoPath';
  }

=======
  ) async =>
      '${await getAPIHost(additionalSettings)}/repos${standardUrl.substring('https://${hosts[0]}'.length)}';

  /// Checks if the repository has been renamed or transferred.
  ///
  /// This method explicitly disables automatic redirect following to detect when
  /// GitHub returns a redirect (indicating the repository has moved). A redirect
  /// from the GitHub API for a repository endpoint definitively indicates that
  /// the repository has been renamed or transferred to a different owner.
  ///
  /// Throws [RepositoryRenamedError] if a redirect is detected.
  Future<void> checkForRepositoryRename(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
    Map<String, String> sourceConfigSettingValues,
  ) async {
    if (sourceConfigSettingValues['checkRepoRename'] == "false") {
      return;
    }
    var uri = Uri.tryParse(standardUrl);
    var host = uri?.host.toLowerCase() ?? '';
    // Guard against non-GitHub URLs
    if (host != hosts[0] && host != 'www.${hosts[0]}') {
      return;
    }
    var apiUrl = await convertStandardUrlToAPIUrl(
      standardUrl,
      additionalSettings,
    );
    Response res = await sourceRequest(
      apiUrl,
      additionalSettings,
      followRedirects: false,
    );
    if (res.statusCode >= 300 && res.statusCode < 400) {
      String? location = res.headers[HttpHeaders.locationHeader.toLowerCase()];
      if (location != null) {
        Response res2 = await sourceRequest(
          location,
          additionalSettings,
          followRedirects: false,
        );
        String? newUrl;
        try {
          newUrl = jsonDecode(res2.body)['html_url'];
        } catch (e) {
          // Unexpected - ignore (keep old URL)
        }
        if (newUrl != null) {
          throw RepositoryRenamedError(standardUrl, newUrl);
        }
      }
    }
  }

  @override
  String? changeLogPageFromStandardUrl(String standardUrl) =>
      '$standardUrl/releases';

>>>>>>> upstream/main
  Future<APKDetails> getLatestAPKDetailsCommon(
    String requestUrl,
    String standardUrl,
    Map<String, dynamic> additionalSettings, {
    Function(Response)? onHttpErrorCode,
  }) async {
    SettingsProvider settingsProvider = SettingsProvider();
    await settingsProvider.initializeSettings();
    var sourceConfigSettingValues = await getSourceConfigValues(
      additionalSettings,
      settingsProvider,
    );
<<<<<<< HEAD
=======
    await checkForRepositoryRename(
      standardUrl,
      additionalSettings,
      sourceConfigSettingValues,
    );
>>>>>>> upstream/main
    bool includePrereleases = additionalSettings['includePrereleases'] == true;
    bool fallbackToOlderReleases =
        additionalSettings['fallbackToOlderReleases'] == true;
    String? regexFilter =
        (additionalSettings['filterReleaseTitlesByRegEx'] as String?)
                ?.isNotEmpty ==
            true
        ? additionalSettings['filterReleaseTitlesByRegEx']
        : null;
    String? regexNotesFilter =
        (additionalSettings['filterReleaseNotesByRegEx'] as String?)
                ?.isNotEmpty ==
            true
        ? additionalSettings['filterReleaseNotesByRegEx']
        : null;
    bool verifyLatestTag = additionalSettings['verifyLatestTag'] == true;
    bool useLatestAssetDateAsReleaseDate =
        additionalSettings['useLatestAssetDateAsReleaseDate'] == true;
    String sortMethod =
        additionalSettings['sortMethodChoice'] ?? 'smartname-datefallback';
    bool includeZips = additionalSettings['includeZips'] == true;
    dynamic latestRelease;
    if (verifyLatestTag) {
      var temp = requestUrl.split('?');
      Response res = await sourceRequest(
        '${temp[0]}/latest${temp.length > 1 ? '?${temp.sublist(1).join('?')}' : ''}',
        additionalSettings,
      );
      if (res.statusCode != 200) {
        if (onHttpErrorCode != null) {
          onHttpErrorCode(res);
        }
<<<<<<< HEAD
        throw SourceUtils.getObtainiumHttpError(res);
=======
        throw getObtainiumHttpError(res);
>>>>>>> upstream/main
      }
      latestRelease = jsonDecode(res.body);
    }
    Response res = await sourceRequest(requestUrl, additionalSettings);
    if (res.statusCode == 200) {
      var releases = jsonDecode(res.body) as List<dynamic>;
      if (latestRelease != null) {
        var latestTag = latestRelease['tag_name'] ?? latestRelease['name'];
        if (releases
            .where(
              (element) =>
                  (element['tag_name'] ?? element['name']) == latestTag,
            )
            .isEmpty) {
          releases = [latestRelease, ...releases];
        }
      }

      findReleaseAssetUrls(dynamic release) =>
          (release['assets'] as List<dynamic>?)?.map((e) {
            var ext = e['name'].toString().toLowerCase().split('.').last;
            var url =
                !(ext == 'apk' ||
                    ext == 'xapk' ||
                    (includeZips && ext == 'zip'))
                ? (e['browser_download_url'] ?? e['url'])
                : (e['url'] ?? e['browser_download_url']);
            url = undoGHProxyMod(url, sourceConfigSettingValues);
            e['final_url'] = (e['name'] != null) && (url != null)
                ? MapEntry(e['name'] as String, url as String)
                : const MapEntry('', '');
            return e;
          }).toList() ??
          [];

<<<<<<< HEAD
      DateTime? getPublishDateFromRelease(dynamic rel) {
        DateTime? date = null;
        if (rel?['published_at'] != null) {
          date = tryParseDateTime(rel['published_at']);
          LogsProvider().add(
            'GitHub API published_at: ${rel['published_at']} → Parsed: $date',
            level: LogLevels.debug,
          );
        }
        if (date == null && rel?['commit']?['created'] != null) {
          date = tryParseDateTime(rel['commit']['created']);
          LogsProvider().add(
            'GitHub API commit created: ${rel['commit']['created']} → Parsed: $date',
            level: LogLevels.debug,
          );
        }
        return date;
      }

=======
      DateTime? getPublishDateFromRelease(dynamic rel) =>
          rel?['published_at'] != null
          ? DateTime.parse(rel['published_at'])
          : rel?['commit']?['created'] != null
          ? DateTime.parse(rel['commit']['created'])
          : null;
>>>>>>> upstream/main
      DateTime? getNewestAssetDateFromRelease(dynamic rel) {
        var allAssets = rel['assets'] as List<dynamic>?;
        var filteredAssets = rel['filteredAssets'] as List<dynamic>?;
        var t = (filteredAssets ?? allAssets)
            ?.map((e) {
              return e?['updated_at'] != null
<<<<<<< HEAD
                  ? tryParseDateTime(e['updated_at'])
                  : null;
            })
            .whereType<DateTime>()
            .toList();
        if (t != null && t.isNotEmpty) {
          t.sort((a, b) => b.compareTo(a));
          return t.first;
=======
                  ? DateTime.parse(e['updated_at'])
                  : null;
            })
            .where((e) => e != null)
            .toList();
        t?.sort((a, b) => b!.compareTo(a!));
        if (t?.isNotEmpty == true) {
          return t!.first;
>>>>>>> upstream/main
        }
        return null;
      }

      DateTime? getReleaseDateFromRelease(dynamic rel, bool useAssetDate) =>
          !useAssetDate
          ? getPublishDateFromRelease(rel)
          : getNewestAssetDateFromRelease(rel);

      if (sortMethod == 'none') {
        releases = releases.reversed.toList();
      } else {
        releases.sort((a, b) {
          // See #478 and #534
          if (a == b) {
            return 0;
          } else if (a == null) {
            return -1;
          } else if (b == null) {
            return 1;
          } else {
            var nameA = a['tag_name'] ?? a['name'];
            var nameB = b['tag_name'] ?? b['name'];
            var stdFormats = findStandardFormatsForVersion(
              nameA,
              false,
            ).intersection(findStandardFormatsForVersion(nameB, false));
            if (sortMethod == 'date' ||
                (sortMethod == 'smartname-datefallback' &&
                    stdFormats.isEmpty)) {
              return (getReleaseDateFromRelease(
                        a,
                        useLatestAssetDateAsReleaseDate,
                      ) ??
                      DateTime(1))
                  .compareTo(
                    getReleaseDateFromRelease(
                          b,
                          useLatestAssetDateAsReleaseDate,
                        ) ??
                        DateTime(0),
                  );
            } else {
              if (sortMethod != 'name' && stdFormats.isNotEmpty) {
                var reg = RegExp(stdFormats.last);
                var matchA = reg.firstMatch(nameA);
                var matchB = reg.firstMatch(nameB);
<<<<<<< HEAD
                if (matchA != null && matchB != null) {
                  return compareAlphaNumeric(
                    (nameA as String).substring(matchA.start, matchA.end),
                    (nameB as String).substring(matchB.start, matchB.end),
                  );
                } else {
                  return compareAlphaNumeric(nameA as String, nameB as String);
                }
=======
                return compareAlphaNumeric(
                  (nameA as String).substring(matchA!.start, matchA.end),
                  (nameB as String).substring(matchB!.start, matchB.end),
                );
>>>>>>> upstream/main
              } else {
                // 'name'
                return compareAlphaNumeric(
                  (nameA as String),
                  (nameB as String),
                );
              }
            }
          }
        });
      }
      if (latestRelease != null &&
          (latestRelease['tag_name'] ?? latestRelease['name']) != null &&
          releases.isNotEmpty &&
          latestRelease !=
              (releases[releases.length - 1]['tag_name'] ??
                  releases[0]['name'])) {
        var ind = releases.indexWhere(
          (element) =>
              (latestRelease['tag_name'] ?? latestRelease['name']) ==
              (element['tag_name'] ?? element['name']),
        );
        if (ind >= 0) {
          releases.add(releases.removeAt(ind));
        }
      }
      releases = releases.reversed.toList();
      dynamic targetRelease;
      var prerrelsSkipped = 0;
      for (int i = 0; i < releases.length; i++) {
        if (!fallbackToOlderReleases && i > prerrelsSkipped) break;
        if (!includePrereleases && releases[i]['prerelease'] == true) {
          prerrelsSkipped++;
          continue;
        }
        if (releases[i]['draft'] == true) {
          // Draft releases not supported
          continue;
        }
        var nameToFilter = releases[i]['name'] as String?;
        if (nameToFilter == null || nameToFilter.trim().isEmpty) {
          // Some leave titles empty so tag is used
          nameToFilter = releases[i]['tag_name'] as String;
        }
        if (regexFilter != null &&
            !RegExp(regexFilter).hasMatch(nameToFilter.trim())) {
          continue;
        }
        if (regexNotesFilter != null &&
            !RegExp(
              regexNotesFilter,
            ).hasMatch(((releases[i]['body'] as String?) ?? '').trim())) {
          continue;
        }
        var allAssetsWithUrls = findReleaseAssetUrls(releases[i]);
        List<MapEntry<String, String>> allAssetUrls = allAssetsWithUrls
            .map((e) => e['final_url'] as MapEntry<String, String>)
            .toList();
        var apkAssetsWithUrls = allAssetsWithUrls.where((element) {
          var ext = (element['final_url'] as MapEntry<String, String>).key
              .toLowerCase()
              .split('.')
              .last;
          return ext == 'apk' || ext == 'xapk' || (includeZips && ext == 'zip');
        }).toList();

<<<<<<< HEAD
        var filteredApkUrls = SourceUtils.filterApks(
=======
        var filteredApkUrls = filterApks(
>>>>>>> upstream/main
          apkAssetsWithUrls
              .map((e) => e['final_url'] as MapEntry<String, String>)
              .toList(),
          additionalSettings['apkFilterRegEx'],
          additionalSettings['invertAPKFilter'],
        );
        var filteredApks = apkAssetsWithUrls
            .where(
              (e) => filteredApkUrls
                  .where(
                    (e2) =>
                        e2.key ==
                        (e['final_url'] as MapEntry<String, String>).key,
                  )
                  .isNotEmpty,
            )
            .toList();

        if (filteredApks.isEmpty && additionalSettings['trackOnly'] != true) {
          continue;
        }
        targetRelease = releases[i];
        targetRelease['apkUrls'] = filteredApkUrls;
        targetRelease['filteredAssets'] = filteredApks;
        targetRelease['version'] =
            additionalSettings['releaseTitleAsVersion'] == true
            ? nameToFilter
            : targetRelease['tag_name'] ?? targetRelease['name'];
        if (targetRelease['tarball_url'] != null) {
          allAssetUrls.add(
            MapEntry(
              (targetRelease['version'] ?? 'source') + '.tar.gz',
              undoGHProxyMod(
                targetRelease['tarball_url'],
                sourceConfigSettingValues,
              ),
            ),
          );
        }
        if (targetRelease['zipball_url'] != null) {
          allAssetUrls.add(
            MapEntry(
              (targetRelease['version'] ?? 'source') + '.zip',
              undoGHProxyMod(
                targetRelease['zipball_url'],
                sourceConfigSettingValues,
              ),
            ),
          );
        }
        targetRelease['allAssetUrls'] = allAssetUrls;
        break;
      }
      if (targetRelease == null) {
        throw NoReleasesError();
      }
      String? version = targetRelease['version'];

      DateTime? releaseDate = getReleaseDateFromRelease(
        targetRelease,
        useLatestAssetDateAsReleaseDate,
      );
<<<<<<< HEAD
      LogsProvider().add(
        'GitHub final releaseDate for $standardUrl: $releaseDate',
        level: LogLevels.debug,
      );
=======
>>>>>>> upstream/main
      if (version == null) {
        throw NoVersionError();
      }
      var changeLog = (targetRelease['body'] ?? '').toString();
      return APKDetails(
        version,
        targetRelease['apkUrls'] as List<MapEntry<String, String>>,
        getAppNames(standardUrl),
        releaseDate: releaseDate,
        changeLog: changeLog.isEmpty ? null : changeLog,
        allAssetUrls:
            targetRelease['allAssetUrls'] as List<MapEntry<String, String>>,
      );
    } else {
      if (onHttpErrorCode != null) {
        onHttpErrorCode(res);
      }
<<<<<<< HEAD
      throw SourceUtils.getObtainiumHttpError(res);
=======
      throw getObtainiumHttpError(res);
>>>>>>> upstream/main
    }
  }

  Future<APKDetails> getLatestAPKDetailsCommon2(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
    Future<String> Function(bool) reqUrlGenerator,
    dynamic Function(Response)? onHttpErrorCode,
  ) async {
    try {
      return await getLatestAPKDetailsCommon(
        await reqUrlGenerator(false),
        standardUrl,
        additionalSettings,
        onHttpErrorCode: onHttpErrorCode,
      );
    } catch (err) {
      if (err is NoReleasesError && additionalSettings['trackOnly'] == true) {
        return await getLatestAPKDetailsCommon(
          await reqUrlGenerator(true),
          standardUrl,
          additionalSettings,
          onHttpErrorCode: onHttpErrorCode,
        );
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    return await getLatestAPKDetailsCommon2(
      standardUrl,
      additionalSettings,
      (bool useTagUrl) async {
        return '${await convertStandardUrlToAPIUrl(standardUrl, additionalSettings)}/${useTagUrl ? 'tags' : 'releases'}?per_page=100';
      },
      (Response res) {
        rateLimitErrorCheck(res);
      },
    );
  }

  AppNames getAppNames(String standardUrl) {
    String temp = standardUrl.substring(standardUrl.indexOf('://') + 3);
    List<String> names = temp.substring(temp.indexOf('/') + 1).split('/');
    return AppNames(names[0], names.sublist(1).join('/'));
  }

  Future<Map<String, List<String>>> searchCommon(
    String query,
    String requestUrl,
    String rootProp, {
    Function(Response)? onHttpErrorCode,
    Map<String, dynamic> querySettings = const {},
  }) async {
    Response res = await sourceRequest(requestUrl, {});
    if (res.statusCode == 200) {
      int minStarCount = querySettings['minStarCount'] != null
          ? int.parse(querySettings['minStarCount'])
          : 0;
      Map<String, List<String>> urlsWithDescriptions = {};
      for (var e in (jsonDecode(res.body)[rootProp] as List<dynamic>)) {
        if ((e['stargazers_count'] ?? e['stars_count'] ?? 0) >= minStarCount) {
          urlsWithDescriptions.addAll({
            e['html_url'] as String: [
              e['full_name'] as String,
              ((e['archived'] == true ? '[ARCHIVED] ' : '') +
                  (e['description'] != null
                      ? e['description'] as String
                      : tr('noDescription'))),
            ],
          });
        }
      }
      return urlsWithDescriptions;
    } else {
      if (onHttpErrorCode != null) {
        onHttpErrorCode(res);
      }
<<<<<<< HEAD
      throw SourceUtils.getObtainiumHttpError(res);
=======
      throw getObtainiumHttpError(res);
>>>>>>> upstream/main
    }
  }

  undoGHProxyMod(
    String reqUrl,
    Map<String, String> sourceConfigSettingValues,
  ) => reqUrl.replaceFirst(
    'https://${sourceConfigSettingValues['GHReqPrefix']}/',
    '',
  );

  @override
  Future<Map<String, List<String>>> search(
    String query, {
    Map<String, dynamic> querySettings = const {},
  }) async {
    var sp = SettingsProvider();
    await sp.initializeSettings();
    var sourceConfigSettingValues = await getSourceConfigValues({}, sp);
<<<<<<< HEAD
    bool includeForks =
        querySettings['includeForks'] == true ||
        querySettings['includeForks'] == 'true';
    String forkParam = includeForks ? '+fork:true' : '';
    var results = await searchCommon(
      query,
      '${await getAPIHost({})}/search/repositories?q=${Uri.encodeQueryComponent(query)}$forkParam&per_page=100',
=======
    var results = await searchCommon(
      query,
      '${await getAPIHost({})}/search/repositories?q=${Uri.encodeQueryComponent(query)}&per_page=100',
>>>>>>> upstream/main
      'items',
      onHttpErrorCode: (Response res) {
        rateLimitErrorCheck(res);
      },
      querySettings: querySettings,
    );
    if ((sourceConfigSettingValues['GHReqPrefix'] ?? '').isNotEmpty) {
      Map<String, List<String>> results2 = {};
      results.forEach((k, v) {
        results2[undoGHProxyMod(k, sourceConfigSettingValues)] = v;
      });
      return results2;
    } else {
      return results;
    }
  }

  void rateLimitErrorCheck(Response res) {
    if (res.headers['x-ratelimit-remaining'] == '0') {
<<<<<<< HEAD
      int resetTime = 1800000000;
      try {
        resetTime = int.parse(res.headers['x-ratelimit-reset'] ?? '1800000000');
      } catch (e) {
        // ignore
      }
      throw RateLimitError((resetTime / 60000000).round());
=======
      throw RateLimitError(
        (int.parse(res.headers['x-ratelimit-reset'] ?? '1800000000') / 60000000)
            .round(),
      );
>>>>>>> upstream/main
    }
  }
}
