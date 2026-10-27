import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/changelog/changelog_parser.dart';

const _badge =
    '[![Co-developed with Antigravity](https://img.shields.io/badge/x)](https://deepmind.google)';

void main() {
  test('CI release body: fix bullet is classified and hash stripped', () {
    const body =
        '''
**Obtainium+ 1.7.1-p28**

## Changes since v1.7.1-p27

### 🐛 Bug Fixes
- fix(ui,perf): stop cold-start empty-state flash and redundant home rebuilds (4496f27c)

---
[Full Changelog](https://github.com/thejaustin/ObtainiumPlus/compare/v1.7.1-p27...v1.7.1-p28)

---
$_badge
''';
    final sections = ChangelogParser.parse(body);
    expect(sections, hasLength(1));
    expect(sections.single.kind, ChangeKind.fix);
    expect(sections.single.items, [
      'Stop cold-start empty-state flash and redundant home rebuilds',
    ]);
  });

  test('plain bullet under a neutral heading falls back to wording', () {
    const body = '''
### 🔧 Improvements & Maintenance
- Hebrew for Obtainium+ (#339) (b44c6084)
''';
    final s = ChangelogParser.parse(body).single;
    expect(s.items, ['Hebrew for Obtainium+ (#339)']);
    // A language name leading the subject is a translation.
    expect(s.kind, ChangeKind.docs);
  });

  test('a body with only the generated compare link has no changes', () {
    const body =
        '**Full Changelog**: https://github.com/thejaustin/ObtainiumPlus/compare/v1.2.9-p18...v1.2.9-p19';
    expect(ChangelogParser.parse(body), isEmpty);
  });

  test('joined commit subjects split and sort into kinds', () {
    const body = '''
## Changes
- feat(nav): live nav badges; fix: crash on cold start; docs: wiki links
- feat: scroll-morphing FAB
''';
    final sections = ChangelogParser.parse(body);
    final byKind = {for (final s in sections) s.kind: s.items};
    expect(byKind[ChangeKind.ui], ['Live nav badges']);
    expect(byKind[ChangeKind.fix], ['Crash on cold start']);
    expect(byKind[ChangeKind.docs], ['Wiki links']);
    expect(byKind[ChangeKind.feature], ['Scroll-morphing FAB']);
    // Sections come out in enum order.
    expect(sections.map((s) => s.kind).toList(), [
      ChangeKind.feature,
      ChangeKind.fix,
      ChangeKind.ui,
      ChangeKind.docs,
    ]);
  });

  test('"build" or "guide" in a heading is not mistaken for UI', () {
    const body = '''
### Build and guide
- tweak gradle cache
''';
    expect(ChangelogParser.parse(body).single.kind, ChangeKind.other);
  });

  test('fromGitHub skips drafts and keeps a null date', () {
    expect(
      ChangelogRelease.fromGitHub({'tag_name': 'v1', 'draft': true}),
      isNull,
    );
    final r = ChangelogRelease.fromGitHub({
      'tag_name': 'v1.2.9-p19',
      'published_at': null,
      'body': '- fix: thing',
    })!;
    expect(r.publishedAt, isNull);
    expect(r.changeCount, 1);
    expect(r.count(ChangeKind.fix), 1);
  });
}
