import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
