import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/version_history_entry.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:obtainium/services/version_ordering.dart';

final _d = DateTime(2026, 10, 1);

VersionHistoryEntry _entry(String v, {int? releasedDay, int detectedDay = 0}) =>
    VersionHistoryEntry(
      version: v,
      releaseDate: releasedDay == null
          ? null
          : _d.add(Duration(days: releasedDay)),
      detectedAt: _d.add(Duration(days: detectedDay)),
    );

App _app(
  String installed,
  String latest, {
  List<VersionHistoryEntry> history = const [],
  int? latestReleasedDay,
  Map<String, dynamic>? settings,
}) => App(
  'com.example.app',
  'https://github.com/example/app',
  'example',
  'Example',
  installed,
  latest,
  const [],
  0,
  settings ?? <String, dynamic>{},
  null,
  false,
  releaseDate: latestReleasedDay == null
      ? null
      : _d.add(Duration(days: latestReleasedDay)),
  versionHistory: history,
);

void main() {
  final cases = <(String, App, int?, VersionOrderBasis)>[
    // Version strings decide when they can.
    ('plain newer', _app('1.2.2', '1.2.3'), -1, VersionOrderBasis.version),
    ('plain older', _app('1.2.3', '1.2.2'), 1, VersionOrderBasis.version),
    // Suffix on one side only: numeric core.
    (
      'gplay suffix, older tag',
      _app('1.4.0-gplay', '1.3.9'),
      1,
      VersionOrderBasis.numericCore,
    ),
    (
      'build suffix, newer tag',
      _app('2.0.1 (201)', '2.0.2'),
      -1,
      VersionOrderBasis.numericCore,
    ),
    // Same core, different labels: only dates can tell.
    (
      'rc then final, dated',
      _app(
        '1.4.0-rc1',
        '1.4.0',
        latestReleasedDay: 9,
        history: [
          _entry('1.4.0', releasedDay: 9),
          _entry('1.4.0-rc1', releasedDay: 2),
        ],
      ),
      -1,
      VersionOrderBasis.releaseDate,
    ),
    (
      'final then hotfix label, dated older',
      _app(
        '1.4.0-hotfix',
        '1.4.0',
        latestReleasedDay: 2,
        history: [
          _entry('1.4.0', releasedDay: 2),
          _entry('1.4.0-hotfix', releasedDay: 5),
        ],
      ),
      1,
      VersionOrderBasis.releaseDate,
    ),
    (
      'rc then final, no dates',
      _app('1.4.0-rc1', '1.4.0'),
      0,
      VersionOrderBasis.version,
    ),
    // Scheme switch: the numbers say downgrade, the timeline says update.
    (
      'date scheme to semver, dated',
      _app(
        '2024.10.5',
        '3.2.0',
        latestReleasedDay: 20,
        history: [
          _entry('3.2.0', releasedDay: 20),
          _entry('2024.10.5', releasedDay: 3),
        ],
      ),
      -1,
      VersionOrderBasis.releaseDate,
    ),
    (
      'date scheme to semver, undated',
      _app('2024.10.5', '3.2.0'),
      1,
      VersionOrderBasis.version,
    ),
    // Installed version not in history: no date signal.
    (
      'unknown history',
      _app(
        'nightly-abc',
        'nightly-def',
        latestReleasedDay: 9,
        history: [_entry('nightly-def', releasedDay: 9)],
      ),
      null,
      VersionOrderBasis.unknown,
    ),
    // Detection dates are used only when neither side has a release date.
    (
      'detection dates only',
      _app(
        'build-a',
        'build-b',
        history: [
          _entry('build-b', detectedDay: 8),
          _entry('build-a', detectedDay: 1),
        ],
      ),
      -1,
      VersionOrderBasis.releaseDate,
    ),
    // Dates within the margin don't decide.
    (
      'same-day re-tag',
      _app(
        'build-a',
        'build-b',
        history: [
          _entry('build-b', detectedDay: 0),
          _entry('build-a', detectedDay: 0),
        ],
      ),
      null,
      VersionOrderBasis.unknown,
    ),
  ];

  for (final (name, app, order, basis) in cases) {
    test('resolveVersionOrdering: $name', () {
      final result = resolveVersionOrdering(
        app,
        app.installedVersion!,
        app.latestVersion,
      );
      expect(result.order, order, reason: result.toString());
      expect(result.basis, basis, reason: result.toString());
    });
  }

  test('the guard offers the scheme-switch update when dated', () {
    final app = _app(
      '2024.10.5',
      '3.2.0',
      latestReleasedDay: 20,
      history: [
        _entry('3.2.0', releasedDay: 20),
        _entry('2024.10.5', releasedDay: 3),
      ],
    );
    expect(
      AppUpdateService.areVersionsDifferent(app, '2024.10.5', '3.2.0'),
      isTrue,
    );
  });

  test('the guard hides an older hotfix-labelled release by date', () {
    final app = _app(
      '1.4.0-hotfix',
      '1.4.0',
      latestReleasedDay: 2,
      history: [
        _entry('1.4.0', releasedDay: 2),
        _entry('1.4.0-hotfix', releasedDay: 5),
      ],
    );
    expect(
      AppUpdateService.areVersionsDifferent(app, '1.4.0-hotfix', '1.4.0'),
      isFalse,
    );
  });
}
