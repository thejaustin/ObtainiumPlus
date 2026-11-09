import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/release_note.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/release_notes_service.dart';

ReleaseNote _note(String v, String body) =>
    ReleaseNote(version: v, body: body, source: 'test');

App _app(String url) => App(
  'id',
  url,
  'author',
  'name',
  null,
  '1.0.0',
  const [],
  0,
  const {},
  null,
  false,
);

void main() {
  group('dedupe', () {
    test('blanks a body repeated from the next-older release', () {
      final out = ReleaseNotesService.dedupe([
        _note('1.3', 'Fixed crash\n\nFull Changelog: https://x/compare/a...b'),
        _note('1.2', 'fixed   crash'),
        _note('1.1', 'Added dark mode'),
      ]);
      expect(out.map((n) => n.version), ['1.3', '1.2', '1.1']);
      expect(out[0].body, '');
      expect(out[1].body, 'fixed   crash');
      expect(out[2].body, 'Added dark mode');
    });

    test(
      'keeps rows with empty bodies and never treats them as duplicates',
      () {
        final out = ReleaseNotesService.dedupe([
          _note('3', ''),
          _note('2', ''),
          _note('1', 'notes'),
        ]);
        expect(out.length, 3);
        expect(out.map((n) => n.body), ['', '', 'notes']);
      },
    );

    test('non-adjacent repeats are kept', () {
      final out = ReleaseNotesService.dedupe([
        _note('3', 'A'),
        _note('2', 'B'),
        _note('1', 'A'),
      ]);
      expect(out.map((n) => n.body), ['A', 'B', 'A']);
    });
  });

  group('version matching', () {
    test('v-prefixed tags match stored versions', () {
      expect(
        ReleaseNotesService.tagMatchesVersion('v1.7.3-p15', '1.7.3-p15'),
        isTrue,
      );
      expect(
        ReleaseNotesService.tagMatchesVersion('1.7.3-p15', 'v1.7.3-p15'),
        isTrue,
      );
      expect(
        ReleaseNotesService.tagMatchesVersion('v1.7.3-p15', '1.7.3-p14'),
        isFalse,
      );
      expect(ReleaseNotesService.tagMatchesVersion('v1.7.3', null), isFalse);
    });

    test('installed build with packaging suffix matches its tag', () {
      expect(
        ReleaseNotesService.tagMatchesInstalled('v1.6.15', '1.6.15-debug'),
        isTrue,
      );
      expect(
        ReleaseNotesService.tagMatchesInstalled('v1.6.16', '1.6.15'),
        isFalse,
      );
      expect(ReleaseNotesService.tagMatchesInstalled('v1.6.15', null), isFalse);
    });

    test('findForVersion picks the matching tag', () {
      final notes = [_note('v2.0.0', 'two'), _note('v1.0.0', 'one')];
      expect(ReleaseNotesService.findForVersion(notes, '1.0.0')?.body, 'one');
      expect(ReleaseNotesService.findForVersion(notes, '3.0.0'), isNull);
    });
  });

  group('GitHub-like parsing', () {
    final json = [
      {'tag_name': 'v3', 'draft': true, 'body': 'draft'},
      {
        'tag_name': 'v2-beta',
        'prerelease': true,
        'body': 'beta',
        'published_at': '2026-01-02T00:00:00Z',
      },
      {
        'tag_name': 'v1',
        'body': 'stable',
        'published_at': '2026-01-01T00:00:00Z',
        'html_url': 'https://github.com/o/r/releases/tag/v1',
      },
    ];

    test('skips drafts and, by default, pre-releases', () {
      final notes = GitHub.releaseNotesFromGitHubLikeJson(
        json,
        source: 'GitHub',
        includePrereleases: false,
      );
      expect(notes.map((n) => n.version), ['v1']);
      expect(notes.single.date, DateTime.utc(2026, 1, 1));
      expect(notes.single.htmlUrl, contains('/tag/v1'));
    });

    test('includes pre-releases when the app opts in', () {
      final notes = GitHub.releaseNotesFromGitHubLikeJson(
        json,
        source: 'GitHub',
        includePrereleases: true,
      );
      expect(notes.map((n) => n.version), ['v2-beta', 'v1']);
      expect(notes.first.isPrerelease, isTrue);
    });

    test('non-list responses yield nothing', () {
      expect(
        GitHub.releaseNotesFromGitHubLikeJson(
          {'message': 'Not Found'},
          source: 'GitHub',
          includePrereleases: false,
        ),
        isEmpty,
      );
    });

    test('GitLab objects map description and _links.self', () {
      final n = ReleaseNote.fromGitLab({
        'tag_name': 'v5',
        'released_at': '2026-02-01T00:00:00Z',
        'description': 'gl notes',
        '_links': {'self': 'https://gitlab.com/o/r/-/releases/v5'},
      }, source: 'GitLab')!;
      expect(n.body, 'gl notes');
      expect(n.htmlUrl, 'https://gitlab.com/o/r/-/releases/v5');
    });
  });

  group('fetch', () {
    tearDown(() {
      ReleaseNotesService.fetchOverride = null;
      ReleaseNotesService.clock = DateTime.now;
      ReleaseNotesService.instance.clearCache();
    });

    test('dedupes, caches within the TTL and refetches after it', () async {
      var calls = 0;
      var now = DateTime(2026, 1, 1, 12);
      ReleaseNotesService.clock = () => now;
      ReleaseNotesService.fetchOverride = (app, limit) async {
        calls++;
        return [_note('v2', 'same'), _note('v1', 'Same')];
      };
      final app = _app('https://github.com/o/r');
      final first = await ReleaseNotesService.instance.fetch(app);
      expect(first.map((n) => n.body), ['', 'Same']);
      await ReleaseNotesService.instance.fetch(app);
      expect(calls, 1);
      now = now.add(const Duration(minutes: 16));
      await ReleaseNotesService.instance.fetch(app);
      expect(calls, 2);
    });

    test(
      'errors (including rate limits) return empty and are not cached',
      () async {
        var calls = 0;
        ReleaseNotesService.fetchOverride = (app, limit) async {
          calls++;
          throw RateLimitError(5);
        };
        final app = _app('https://github.com/o/r');
        expect(await ReleaseNotesService.instance.fetch(app), isEmpty);
        expect(await ReleaseNotesService.instance.fetch(app), isEmpty);
        expect(calls, 2);
      },
    );
  });
}
