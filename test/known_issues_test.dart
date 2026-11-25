import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/services/known_issues_service.dart';

void main() {
  test('the shipped known_issues.json parses', () {
    final decoded =
        jsonDecode(File('known_issues.json').readAsStringSync())
            as Map<String, dynamic>;
    final issues = (decoded['issues'] as List)
        .map((e) => KnownIssue.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(issues, isNotEmpty);
  });

  test('no shipped notice targets the current or any future build', () {
    // An open-ended affectedBuildRange (min without max) would show a
    // critical dialog to every user on every launch from now on.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(
      r'^version:\s*([^+\s]+)\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec)!;
    final version = m.group(1)!;
    final build = int.parse(m.group(2)!);
    final decoded =
        jsonDecode(File('known_issues.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final e in decoded['issues'] as List) {
      final issue = KnownIssue.fromJson(e as Map<String, dynamic>);
      expect(issue.affects(version, build), isFalse, reason: issue.id);
      expect(issue.affects(version, build + 1000), isFalse, reason: issue.id);
    }
  });

  test('affects matches exact versions, then build ranges', () {
    final byVersion = KnownIssue.fromJson({
      'id': 'a',
      'title': 't',
      'description': 'd',
      'githubIssueUrl': 'https://example.com',
      'affectedVersions': ['1.7.0-p3'],
    });
    expect(byVersion.affects('1.7.0-p3', 1), isTrue);
    expect(byVersion.affects('1.7.0-p4', 1), isFalse);

    final byRange = KnownIssue.fromJson({
      'id': 'b',
      'title': 't',
      'description': 'd',
      'githubIssueUrl': 'https://example.com',
      'affectedBuildRange': {'min': 10, 'max': 20},
    });
    expect(byRange.affects('x', 15), isTrue);
    expect(byRange.affects('x', 21), isFalse);
  });

  group('crash-matched notices', () {
    final issue = KnownIssue.fromJson({
      'id': 'c',
      'title': 't',
      'description': 'd',
      'githubIssueUrl': 'https://example.com',
      'fixedInVersion': '1.7.5-p1',
      'errorPatterns': ["'double' is not a subtype of type 'bool?'"],
    });
    const log = "TypeError: type 'double' is not a subtype of type 'bool?'";

    test('shown to an older build whose crash log matches', () {
      expect(issue.matchesCrash('1.7.3-p15', log), isTrue);
      expect(issue.matchesCrash('1.7.1-p31', log), isTrue);
    });

    test('not shown on the fixed or a newer build, or for another error', () {
      expect(issue.matchesCrash('1.7.5-p1', log), isFalse);
      expect(issue.matchesCrash('1.7.5-p30', log), isFalse);
      expect(issue.matchesCrash('1.8.0', log), isFalse);
      expect(issue.matchesCrash('1.7.3-p15', 'Null check operator'), isFalse);
      expect(issue.matchesCrash('weird', log), isFalse);
    });

    test('never affects a launch without a crash', () {
      expect(issue.affects('1.7.3-p15', 25283), isFalse);
    });

    test('compareVersionNames orders by name, not build number', () {
      expect(compareVersionNames('1.7.3-p15', '1.7.5-p1'), lessThan(0));
      expect(compareVersionNames('1.7.5-p10', '1.7.5-p9'), greaterThan(0));
      expect(compareVersionNames('1.7.5', '1.7.5-p0'), 0);
    });
  });

  group('getCrashIssues (seeded cache)', () {
    Future<void> seed({List<String> dismissed = const []}) async {
      SharedPreferences.setMockInitialValues({
        'known_issues_cache': File('known_issues.json').readAsStringSync(),
        'known_issues_cache_ts': DateTime.now().millisecondsSinceEpoch,
        if (dismissed.isNotEmpty) 'dismissed_known_issue_ids': dismissed,
      });
    }

    const log = "TypeError: type 'double' is not a subtype of type 'bool?'";

    test('old build + matching crash gets the shipped notice', () async {
      await seed();
      final out = await KnownIssuesService.getCrashIssues('1.7.3-p15', log);
      expect(out.map((i) => i.id), contains('expansion_tile_cast_p1_7_3'));
    });

    test(
      'fixed build, other error, or dismissed notice gets nothing',
      () async {
        await seed();
        expect(
          await KnownIssuesService.getCrashIssues('1.7.5-p32', log),
          isEmpty,
        );
        expect(
          await KnownIssuesService.getCrashIssues('1.7.3-p15', 'RangeError'),
          isEmpty,
        );
        await seed(dismissed: ['expansion_tile_cast_p1_7_3']);
        expect(
          await KnownIssuesService.getCrashIssues('1.7.3-p15', log),
          isEmpty,
        );
      },
    );
  });
}
