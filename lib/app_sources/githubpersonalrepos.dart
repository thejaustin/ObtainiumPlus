import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/utils/source_utils.dart';

class GitHubPersonalRepos implements MassAppUrlSource {
  @override
  late String name = tr('githubPersonalRepos');

  @override
  late List<String> requiredArgs = [tr('uname')];

  /// Fetches one page of repos for [username].
  ///
  /// If the saved GitHub token authenticates as [username] (or if username is 'me'),
  /// the GitHub API /user/repos endpoint is used to include private and organization
  /// repos. Public-only repos are returned when unauthenticated or querying other users.
  Future<Map<String, List<String>>> _getOnePage(
    String username,
    int page, {
    bool isAuthenticatedUser = false,
  }) async {
    // Sort by updated so the most recently active repos appear first in the
    // selection list.
    final String resUrl;
    if (isAuthenticatedUser) {
      resUrl =
          'https://api.github.com/user/repos'
          '?per_page=100&page=$page&sort=updated&affiliation=owner,collaborator,organization_member';
    } else {
      resUrl =
          'https://api.github.com/users/$username/repos'
          '?per_page=100&page=$page&sort=updated&type=all';
    }
    Response res = await get(
      Uri.parse(resUrl),
      headers: await GitHub().getRequestHeaders({}, resUrl),
    );
    if (res.statusCode == 200) {
      final repos = jsonDecode(res.body) as List<dynamic>;
      final Map<String, List<String>> urlsWithDescriptions = {};
      for (final repo in repos) {
        final htmlUrl = repo['html_url'] as String;
        final fullName = repo['full_name'] as String;
        final description = (repo['description'] as String?)?.trim() ?? '';
        final stars = repo['stargazers_count'] as int? ?? 0;
        final language = (repo['language'] as String?) ?? '';
        final isFork = repo['fork'] as bool? ?? false;
        final isArchived = repo['archived'] as bool? ?? false;
        final isPrivate = repo['private'] as bool? ?? false;

        // Build a rich two-line description shown in the selection modal.
        final badges = [
          if (stars > 0) '⭐$stars',
          if (language.isNotEmpty) language,
          if (isFork) tr('fork'),
          if (isArchived) tr('archived'),
          if (isPrivate) tr('private'),
        ].join(' · ');

        final descLine = [
          if (description.isNotEmpty) description,
          if (badges.isNotEmpty) badges,
        ].join('\n');

        urlsWithDescriptions[htmlUrl] = [fullName, descLine];
      }
      return urlsWithDescriptions;
    } else {
      final gh = GitHub();
      gh.rateLimitErrorCheck(res);
      throw SourceUtils.getObtainiumHttpError(res);
    }
  }

  @override
  Future<Map<String, List<String>>> getUrlsWithDescriptions(
    List<String> args,
  ) async {
    if (args.length != requiredArgs.length) {
      throw ObtainiumError(tr('wrongArgNum'));
    }
    var username = args[0].trim();
    if (username.startsWith('@')) {
      username = username.substring(1).trim();
    }
    if (username.contains('github.com/')) {
      final uri = Uri.tryParse(
        username.startsWith('http') ? username : 'https://$username',
      );
      if (uri != null && uri.pathSegments.isNotEmpty) {
        username = uri.pathSegments.first;
      }
    }

    final gh = GitHub();
    final token = await gh.getTokenIfAny({});
    bool isAuthenticatedUser = false;
    if (token != null) {
      try {
        final userRes = await get(
          Uri.parse('https://api.github.com/user'),
          headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': 'Obtainium',
          },
        );
        if (userRes.statusCode == 200) {
          final authUser = jsonDecode(userRes.body)['login'] as String?;
          if (authUser != null) {
            final lowerUser = username.toLowerCase();
            if (username.isEmpty ||
                lowerUser == authUser.toLowerCase() ||
                lowerUser == 'me' ||
                lowerUser == 'self') {
              isAuthenticatedUser = true;
              username = authUser;
            }
          }
        }
      } catch (_) {}
    }

    if (username.isEmpty) {
      throw ObtainiumError(tr('invalidInput'));
    }
    final Map<String, List<String>> urlsWithDescriptions = {};
    var page = 1;
    while (true) {
      final pageUrls = await _getOnePage(
        username,
        page++,
        isAuthenticatedUser: isAuthenticatedUser,
      );
      urlsWithDescriptions.addAll(pageUrls);
      if (pageUrls.length < 100) {
        break;
      }
    }
    return urlsWithDescriptions;
  }
}
