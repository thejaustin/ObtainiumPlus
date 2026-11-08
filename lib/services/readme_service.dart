import 'dart:async';
import 'dart:convert';

import 'package:obtainium/app_sources/codeberg.dart';
import 'package:obtainium/app_sources/gitea.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/app_sources/gitlab.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/core/logging/app_logger.dart';

/// A repository README with the bases needed to resolve its relative links
/// (`docs/x.md`) and images (`img/shot.png`).
class ReadmeDoc {
  final String markdown;
  final Uri baseRaw;
  final Uri baseHtml;
  final String? branch;
  final String repoLabel;

  const ReadmeDoc({
    required this.markdown,
    required this.baseRaw,
    required this.baseHtml,
    required this.repoLabel,
    this.branch,
  });

  /// Resolve a link or image path from the README against the repo.
  Uri resolve(String href, {bool image = false}) {
    final u = Uri.tryParse(href);
    if (u == null || u.hasScheme || href.startsWith('#')) {
      return u ?? baseHtml;
    }
    return (image ? baseRaw : baseHtml).resolve(href);
  }
}

/// Fetches READMEs from the forge an app is tracked from. Results (including
/// "no README") are cached per URL for the app session.
class ReadmeService {
  ReadmeService._();
  static final ReadmeService instance = ReadmeService._();

  final Map<String, Future<ReadmeDoc?>> _cache = {};

  Future<ReadmeDoc?> fetch(App app) {
    final key = '${app.overrideSource ?? ''}|${app.url}';
    return _cache.putIfAbsent(key, () async {
      try {
        return await _fetch(app);
      } catch (e) {
        AppLogger.info('README fetch failed for ${app.url}: $e');
        unawaited(_cache.remove(key)); // let a later visit retry
        return null;
      }
    });
  }

  Future<ReadmeDoc?> _fetch(App app) async {
    final AppSource source = SourceProvider().getSource(
      app.url,
      overrideSource: app.overrideSource,
    );
    final uri = Uri.parse(app.url);
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length < 2) return null;
    final settings = app.additionalSettings;

    if (source is GitHub) {
      final o = segs[0], r = segs[1];
      // raw.githubusercontent.com costs no API quota (unauthenticated users
      // only get 60 calls an hour, which update checks need); HEAD resolves
      // to the default branch. The API is the fallback for other file names.
      final raw = await source.sourceRequest(
        'https://raw.githubusercontent.com/$o/$r/HEAD/README.md',
        settings,
      );
      if (raw.statusCode == 200 && raw.body.trim().isNotEmpty) {
        return ReadmeDoc(
          markdown: raw.body,
          baseRaw: Uri.parse('https://raw.githubusercontent.com/$o/$r/HEAD/'),
          baseHtml: Uri.parse('https://github.com/$o/$r/blob/HEAD/'),
          repoLabel: '$o / $r',
        );
      }
      final res = await source.sourceRequest(
        'https://api.github.com/repos/$o/$r/readme',
        settings,
      );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final content = utf8.decode(
        base64.decode((json['content'] as String).replaceAll('\n', '')),
        allowMalformed: true,
      );
      final download = Uri.parse(json['download_url'] as String);
      final html = Uri.parse(json['html_url'] as String);
      // download_url: raw.githubusercontent.com/o/r/<branch>/path/README.md
      final dlSegs = download.pathSegments;
      return ReadmeDoc(
        markdown: content,
        baseRaw: download.resolve('.'),
        baseHtml: html.resolve('.'),
        branch: dlSegs.length > 2 ? dlSegs[2] : null,
        repoLabel: '$o / $r',
      );
    }

    if (source is GitLab) {
      final path = segs.takeWhile((s) => s != '-').join('/');
      final host = '${uri.scheme}://${uri.host}';
      final api = '$host/api/v4/projects/${Uri.encodeComponent(path)}';
      final branch = await _defaultBranch(source, api, settings) ?? 'HEAD';
      final res = await source.sourceRequest(
        '$api/repository/files/README.md/raw?ref=${Uri.encodeComponent(branch)}',
        settings,
      );
      if (res.statusCode != 200 || res.body.trim().isEmpty) return null;
      return ReadmeDoc(
        markdown: res.body,
        baseRaw: Uri.parse('$host/$path/-/raw/$branch/'),
        baseHtml: Uri.parse('$host/$path/-/blob/$branch/'),
        branch: branch == 'HEAD' ? null : branch,
        repoLabel: path.replaceAll('/', ' / '),
      );
    }

    if (source is Codeberg || source is Gitea) {
      final o = segs[0], r = segs[1];
      final host = '${uri.scheme}://${uri.host}';
      final api = '$host/api/v1/repos/$o/$r';
      final branch = await _defaultBranch(source, api, settings);
      final res = await source.sourceRequest(
        '$api/raw/README.md'
        '${branch != null ? '?ref=${Uri.encodeComponent(branch)}' : ''}',
        settings,
      );
      if (res.statusCode != 200 || res.body.trim().isEmpty) return null;
      final ref = branch != null ? 'branch/$branch' : 'branch/main';
      return ReadmeDoc(
        markdown: res.body,
        baseRaw: Uri.parse('$host/$o/$r/raw/$ref/'),
        baseHtml: Uri.parse('$host/$o/$r/src/$ref/'),
        branch: branch,
        repoLabel: '$o / $r',
      );
    }
    return null;
  }

  /// `default_branch` from a GitLab project or Gitea/Forgejo repo endpoint.
  Future<String?> _defaultBranch(
    AppSource source,
    String apiUrl,
    Map<String, dynamic> settings,
  ) async {
    try {
      final res = await source.sourceRequest(apiUrl, settings);
      if (res.statusCode != 200) return null;
      final b = (jsonDecode(res.body) as Map<String, dynamic>)['default_branch'];
      return b is String && b.isNotEmpty ? b : null;
    } catch (_) {
      return null;
    }
  }
}
