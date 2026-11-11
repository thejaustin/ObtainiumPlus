import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/components/apps/update_health_note.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _rel(
  String tag, {
  bool prerelease = false,
  bool draft = false,
  String? apk = 'app.apk',
  String name = '',
}) => {
  'tag_name': tag,
  'name': name.isEmpty ? tag : name,
  'prerelease': prerelease,
  'draft': draft,
  'body': '',
  'published_at': '2026-01-01T00:00:00Z',
  'assets': [
    if (apk != null)
      <String, dynamic>{
        'name': apk,
        'url': 'https://example.com/$tag/$apk',
        'browser_download_url': 'https://example.com/$tag/$apk',
      },
  ],
};

dynamic _select(
  List<dynamic> releases, {
  bool fallback = false,
  bool pre = false,
  String? titleRegex,
}) => GitHub().selectGitHubTargetRelease(
  releases: releases,
  fallbackToOlderReleases: fallback,
  includePrereleases: pre,
  regexFilter: titleRegex,
  regexNotesFilter: null,
  includeZips: false,
  includeTarballs: false,
  useLatestAssetDateAsReleaseDate: false,
  minAgeDays: 0,
  additionalSettings: <String, dynamic>{},
  sourceConfigSettingValues: <String, String>{},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('newerReleasesFilteredOut', () {
    test('is 0 when the newest release is picked', () {
      final r = _select([_rel('v2'), _rel('v1')]);
      expect(r['tag_name'], 'v2');
      expect(r['newerReleasesFilteredOut'], 0);
    });

    test('counts newer prereleases skipped by the prerelease filter', () {
      final r = _select([
        _rel('v3-rc', prerelease: true),
        _rel('v2'),
      ], fallback: true);
      expect(r['tag_name'], 'v2');
      expect(r['newerReleasesFilteredOut'], 1);
    });

    test('counts releases removed by the title filter and drafts do not', () {
      final r = _select(
        [_rel('v4-nightly', draft: true), _rel('v3-nightly'), _rel('v2')],
        fallback: true,
        titleRegex: r'^v\d$',
      );
      expect(r['tag_name'], 'v2');
      expect(r['newerReleasesFilteredOut'], 1);
    });

    test('counts newer releases without a matching APK', () {
      final r = _select([_rel('v3', apk: null), _rel('v2')], fallback: true);
      expect(r['tag_name'], 'v2');
      expect(r['newerReleasesFilteredOut'], 1);
    });
  });

  group('update health app note (opt-in)', () {
    App app({bool archived = false, bool disabled = false}) => App(
      'a.b',
      'https://github.com/a/b',
      'a',
      'b',
      null,
      '1',
      const [],
      0,
      const {},
      null,
      false,
      isArchived: archived,
      disabled: disabled,
    );

    Future<SettingsProvider> settings({required bool noteOn}) async {
      SharedPreferences.setMockInitialValues({
        'showUpdateHealthAppNote': noteOn,
        'updateHealthArchivedEnabled': true,
      });
      final s = SettingsProvider();
      await s.initializeSettings();
      return s;
    }

    test('is off by default', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsProvider();
      await s.initializeSettings();
      expect(s.showUpdateHealthAppNote, isFalse);
    });

    test('hidden while the setting is off, even with issues', () async {
      expect(
        shouldShowUpdateHealthNote(
          app(archived: true),
          await settings(noteOn: false),
        ),
        isFalse,
      );
    });

    test('shown for an archived app once enabled; not for disabled', () async {
      final s = await settings(noteOn: true);
      expect(shouldShowUpdateHealthNote(app(archived: true), s), isTrue);
      expect(shouldShowUpdateHealthNote(app(), s), isFalse);
      expect(
        shouldShowUpdateHealthNote(app(archived: true, disabled: true), s),
        isFalse,
      );
    });
  });
}
