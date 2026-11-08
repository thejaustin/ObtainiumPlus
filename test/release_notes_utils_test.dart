import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/release_notes_utils.dart';

void main() {
  group('extractChangelogSection', () {
    const changelog = '''
# Changelog

## [2.1.0] - 2026-10-01
- New thing
- Another

### Fixed
- A bug

## [2.0.9] - 2026-09-01
- Old thing
''';

    test('returns only the matching section, keeping sub-headings', () {
      final s = extractChangelogSection(changelog, '2.1.0')!;
      expect(s, contains('New thing'));
      expect(s, contains('A bug'));
      expect(s, isNot(contains('Old thing')));
    });

    test('accepts a v-prefixed version and does not match a prefix', () {
      expect(extractChangelogSection(changelog, 'v2.0.9'), '- Old thing');
      expect(extractChangelogSection(changelog, '2.1'), isNull);
    });

    test('bare version lines', () {
      const bare = 'v3.2\n* a\n* b\nv3.1\n* c\n';
      expect(extractChangelogSection(bare, '3.2'), '* a\n* b');
    });

    test('null when absent', () {
      expect(extractChangelogSection(changelog, '9.9.9'), isNull);
    });
  });

  test('playNotesHtmlToText keeps line breaks and decodes entities', () {
    expect(
      playNotesHtmlToText('Fixes &amp; tweaks<br>New <b>UI</b><br/>'),
      'Fixes & tweaks\nNew UI',
    );
    expect(playNotesHtmlToText('  '), isNull);
  });

  test('normalizeReleaseNotes ignores links and whitespace', () {
    expect(
      normalizeReleaseNotes('- Fix A\n\n**Full Changelog**: https://x/y'),
      normalizeReleaseNotes('-  Fix A '),
    );
  });
}
