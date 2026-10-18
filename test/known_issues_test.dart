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
