import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/app_sources/gitlab.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GitLab starts the releases request before the project lookup returns, so
/// the lookup's failure must surface cleanly and the early request must never
/// leak an unhandled async error.
class _FakeGitLab extends GitLab {
  _FakeGitLab({required this.projectStatus, required this.releasesError});
  final int projectStatus;
  final bool releasesError;
  final List<String> urls = [];

  @override
  Future<http.Response> sourceRequest(
    String url,
    Map<String, dynamic> additionalSettings, {
    bool followRedirects = true,
    Object? postBody,
    Map<String, String>? extraHeaders,
  }) async {
    urls.add(url);
    if (url.contains('/releases') || url.contains('/repository/tags')) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (releasesError) throw StateError('releases boom');
      return http.Response('[]', 200);
    }
    return http.Response(
      projectStatus == 200 ? '{"id": 7, "archived": false}' : 'nope',
      projectStatus,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'project 404 fails cleanly and still issued the releases request',
    () async {
      final source = _FakeGitLab(projectStatus: 404, releasesError: true);
      final errors = <Object>[];
      await runZonedGuarded(() async {
        await expectLater(
          source.getLatestAPKDetails('https://gitlab.com/o/r', {}),
          throwsA(anything),
        );
        // Let the early releases future (which errors) settle.
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }, (e, _) => errors.add(e));
      expect(errors, isEmpty, reason: 'no unhandled async error');
      expect(source.urls.any((u) => u.contains('/releases')), isTrue);
    },
  );

  test('both requests are started before either response is awaited', () async {
    final source = _FakeGitLab(projectStatus: 200, releasesError: false);
    try {
      await source.getLatestAPKDetails('https://gitlab.com/o/r', {});
    } catch (_) {
      // An empty release list is a NoReleasesError; only the calls matter.
    }
    expect(source.urls, hasLength(2));
    expect(source.urls.first, contains('/releases'));
  });

  test('a releases failure surfaces after a good project lookup', () async {
    final source = _FakeGitLab(projectStatus: 200, releasesError: true);
    await expectLater(
      source.getLatestAPKDetails('https://gitlab.com/o/r', {}),
      throwsA(anything),
    );
  });
}
