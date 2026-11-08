import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/models/version_history_entry.dart';
import 'package:obtainium/providers/source_provider.dart';

App _app(String latest, List<VersionHistoryEntry> history) => App(
  'com.example.app',
  'https://example.com/app.apk',
  'Author',
  'App',
  null,
  latest,
  const [],
  0,
  const {},
  null,
  false,
  versionHistory: history,
);

APKDetails _apk(String version, String? notes) =>
    APKDetails(version, const [], AppNames('Author', 'App'), changeLog: notes);

VersionHistoryEntry _e(String v, String? notes) =>
    VersionHistoryEntry(version: v, changeLog: notes, detectedAt: DateTime(2026));

void main() {
  test('new version with new notes is added on top', () {
    final h = SourceProvider.buildVersionHistory(
      _app('1.0', [_e('1.0', 'old')]),
      _apk('1.1', 'new'),
    );
    expect(h.map((e) => e.version), ['1.1', '1.0']);
    expect(h.first.changeLog, 'new');
  });

  test('new version repeating the previous notes is stored without them', () {
    final h = SourceProvider.buildVersionHistory(
      _app('1.0', [_e('1.0', 'Same notes')]),
      _apk('1.1', ' same   notes '),
    );
    expect(h.first.version, '1.1');
    expect(h.first.changeLog, isNull);
  });

  test('re-checking that version does not write the repeat back', () {
    final h = SourceProvider.buildVersionHistory(
      _app('1.1', [_e('1.1', null), _e('1.0', 'Same notes')]),
      _apk('1.1', 'Same notes'),
    );
    expect(h.length, 2);
    expect(h.first.changeLog, isNull);
  });

  test('notes that arrive late fill the existing entry once', () {
    final h = SourceProvider.buildVersionHistory(
      _app('1.1', [_e('1.1', null), _e('1.0', 'old')]),
      _apk('1.1', 'late notes'),
    );
    expect(h.length, 2);
    expect(h.first.changeLog, 'late notes');
  });

  test('a version seen again (flip back) is not added twice', () {
    final h = SourceProvider.buildVersionHistory(
      _app('1.2-beta', [_e('1.2-beta', 'b'), _e('1.1', 'a')]),
      _apk('1.1', 'a'),
    );
    expect(h.map((e) => e.version), ['1.2-beta', '1.1']);
  });
}
