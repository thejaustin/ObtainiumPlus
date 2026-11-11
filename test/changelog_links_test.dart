import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/apps/app_changelog.dart'
    show resolveChangeLogLink;

// Cases from upstream's changelog_links_test (#3470/#3471), adapted to the
// fork's (appUrl, href, {releaseUrl}) signature.
void main() {
  const repo = 'https://github.com/chenxiaolong/BasicSync';
  const release = '$repo/releases/tag/v3.27';
  const blob = '$repo/blob/v3.27';

  test('resolves GitHub release links against the release tag', () {
    final cases = {
      'CHANGELOG.md': '$blob/CHANGELOG.md',
      './README.md#verifying-digital-signatures':
          '$blob/README.md#verifying-digital-signatures',
      '/chenxiaolong/BasicSync/issues/42': '$repo/issues/42',
      'docs/../CHANGELOG.md': '$blob/CHANGELOG.md',
      '../CHANGELOG.md': '$blob/CHANGELOG.md',
      '//example.org/notes': 'https://example.org/notes',
      '#changes': '$release#changes',
      'https://example.org/notes?raw=1#changes':
          'https://example.org/notes?raw=1#changes',
    };
    for (final entry in cases.entries) {
      expect(
        resolveChangeLogLink(repo, entry.key, releaseUrl: release),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('preserves encoded tags and filenames', () {
    expect(
      resolveChangeLogLink(
        repo,
        './Release%20notes.md',
        releaseUrl: '$repo/releases/tag/release%2Fv3.27%2B1',
      ),
      '$repo/blob/release%2Fv3.27%2B1/Release%20notes.md',
    );
  });

  test('without a release URL, falls back to the source origin', () {
    expect(
      resolveChangeLogLink(repo, 'CHANGELOG.md'),
      'https://github.com/CHANGELOG.md',
    );
    expect(
      resolveChangeLogLink(
        'https://git.example.org/owner/repo',
        'CHANGELOG.md',
        releaseUrl: 'https://git.example.org/owner/repo/releases/v1',
      ),
      'https://git.example.org/CHANGELOG.md',
    );
  });
}
