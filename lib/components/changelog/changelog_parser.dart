// Splits Obtainium+ GitHub release bodies into categorised changes for the
// timeline changelog. Pure Dart so it can be unit-tested without widgets.

enum ChangeKind { feature, fix, ui, docs, other }

class ChangeSection {
  final ChangeKind kind;
  final List<String> items;

  const ChangeSection(this.kind, this.items);
}

class ChangelogRelease {
  final String tag;
  final DateTime? publishedAt;
  final bool isPrerelease;
  final List<ChangeSection> sections;

  const ChangelogRelease({
    required this.tag,
    required this.publishedAt,
    required this.sections,
    this.isPrerelease = false,
  });

  int get changeCount => sections.fold(0, (n, s) => n + s.items.length);

  int count(ChangeKind kind) => sections
      .where((s) => s.kind == kind)
      .fold(0, (n, s) => n + s.items.length);

  /// Builds a release from one GitHub API release object, or null for
  /// drafts and malformed entries.
  static ChangelogRelease? fromGitHub(Object? json) {
    if (json is! Map) return null;
    if (json['draft'] == true) return null;
    final tag = (json['tag_name'] ?? '').toString().trim();
    if (tag.isEmpty) return null;
    return ChangelogRelease(
      tag: tag,
      publishedAt: DateTime.tryParse((json['published_at'] ?? '').toString()),
      isPrerelease: json['prerelease'] == true,
      sections: ChangelogParser.parse((json['body'] ?? '').toString()),
    );
  }
}

class ChangelogParser {
  ChangelogParser._();

  static final _heading = RegExp(r'^#{2,4}\s+(.+?)\s*$');
  static final _bullet = RegExp(r'^\s*[-*]\s+(.+)$');
  static final _commitHash = RegExp(r'\s*\(([0-9a-f]{7,40})\)\s*$');
  static const _ccTypes =
      'fix|feat|chore|refactor|perf|test|docs|build|ci|style|revert|i18n';
  static final _ccPrefix = RegExp(
    '^($_ccTypes)(\\([^)]+\\))?!?:\\s*',
    caseSensitive: false,
  );
  static final _splitBeforeCommit = RegExp(
    ';\\s+(?=(?:$_ccTypes)(?:\\([^)]+\\))?!?:)',
    caseSensitive: false,
  );
  static final _uiScope = RegExp(
    r'\b(ui|ux|icons?|theme|m3e?|style|design|layout|animations?|widget|dialogs?|grid|nav)\b',
  );
  static final _fixWords = RegExp(
    r'^(fix|fixed|fixes|resolve[sd]?|repair|patch|prevent|stop|avoid|handle|correct|restore)\b|\bcrash|\bregression|\bbug\b|not working|broken|no longer',
  );
  static final _uiWords = RegExp(
    r'\b(ui|ux|themes?|theming|icons?|animations?|haptics?|layout|dialogs?|colou?rs?|typography|m3e?|expressive|design|polish|cards?|chips?|buttons?|dark mode|fonts?|navigation|nav bar|grid)\b',
  );
  static final _featureWords = RegExp(
    r'^(add|added|adds|new|introduce[sd]?|support|supports|implement(ed)?|enable[sd]?|allow|improve[sd]?)\b',
  );
  static final _docsWords = RegExp(
    r'\b(readme|docs?|documentation|changelog|wiki|translat\w*|i18n|locali[sz]\w*)\b',
  );
  // Community translation PRs are often titled just "<Language> for ...".
  static final _languageWords = RegExp(
    r'^(arabic|bengali|catalan|chinese|czech|danish|dutch|farsi|persian|finnish|french|german|greek|hebrew|hindi|hungarian|indonesian|italian|japanese|korean|norwegian|polish|portuguese|romanian|russian|spanish|swedish|thai|turkish|ukrainian|vietnamese)\b',
  );
  static final _readmeOnly = RegExp(r'\breadme(\.md)?\b', caseSensitive: false);

  /// Removes everything that isn't a change: HTML comments, the
  /// "Full Changelog" link (both GitHub's generated and our CI's form),
  /// co-developed badges and `<details>` wrappers.
  static String cleanBody(String body) {
    var s = body.replaceAll('\r\n', '\n');
    s = s.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
    s = s.replaceAll(RegExp(r'</?details>', caseSensitive: false), '');
    s = s.replaceAll(
      RegExp(r'<summary>.*?</summary>', caseSensitive: false, dotAll: true),
      '',
    );
    s = s.replaceAll(
      RegExp(r'^\s*\*\*Full Changelog\*\*:.*$', multiLine: true),
      '',
    );
    s = s.replaceAll(
      RegExp(r'^\s*\[Full Changelog\]\(.*?\)\s*$', multiLine: true),
      '',
    );
    s = s.replaceAll(RegExp(r'^\s*\[!\[.*$', multiLine: true), '');
    return s.trim();
  }

  static List<ChangeSection> parse(String body) {
    final lines = cleanBody(body).split('\n');
    final classified = <(ChangeKind, String)>[];
    String heading = '';
    var items = <String>[];
    StringBuffer? pending;

    void flushPending() {
      final t = pending?.toString().trim();
      if (t != null && t.isNotEmpty) items.add(t);
      pending = null;
    }

    void flushSection() {
      flushPending();
      final headingKind = _kindOfHeading(heading);
      for (final raw in items) {
        for (final piece in _splitCommits(raw)) {
          // README edits are repo housekeeping, not user-facing changes.
          if (_readmeOnly.hasMatch(piece)) continue;
          final text = _clean(piece);
          if (text.isEmpty) continue;
          classified.add((_classify(piece, headingKind), text));
        }
      }
      items = [];
    }

    for (final line in lines) {
      final h = _heading.firstMatch(line);
      if (h != null) {
        flushSection();
        heading = h.group(1)!;
        continue;
      }
      if (line.startsWith('# ')) continue;
      final b = _bullet.firstMatch(line);
      if (b != null) {
        flushPending();
        pending = StringBuffer(b.group(1)!);
      } else if (pending != null &&
          line.trim().isNotEmpty &&
          line.startsWith('  ')) {
        pending!
          ..write(' ')
          ..write(line.trim());
      } else if (line.trim().isEmpty) {
        flushPending();
      }
    }
    flushSection();

    final grouped = <ChangeKind, List<String>>{};
    for (final (kind, text) in classified) {
      final list = grouped.putIfAbsent(kind, () => []);
      if (!list.contains(text)) list.add(text);
    }
    return [
      for (final kind in ChangeKind.values)
        if (grouped[kind] != null) ChangeSection(kind, grouped[kind]!),
    ];
  }

  /// Older notes join several commit subjects with ";" in one bullet.
  static List<String> _splitCommits(String raw) {
    final body = raw.trim().replaceFirst(_commitHash, '');
    final parts = body
        .split(_splitBeforeCommit)
        .map((p) => p.trim().replaceFirst(RegExp(r';$'), '').trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isEmpty ? [body] : parts;
  }

  /// Its own conventional-commit prefix first, then the heading, then wording.
  static ChangeKind _classify(String text, ChangeKind? headingKind) {
    final m = _ccPrefix.firstMatch(text.trim());
    if (m != null) {
      final type = m.group(1)!.toLowerCase();
      final uiScope = _uiScope.hasMatch((m.group(2) ?? '').toLowerCase());
      switch (type) {
        case 'fix':
        case 'revert':
        case 'perf':
          return ChangeKind.fix;
        case 'feat':
          return uiScope ? ChangeKind.ui : ChangeKind.feature;
        case 'style':
          return ChangeKind.ui;
        case 'docs':
        case 'i18n':
          return ChangeKind.docs;
        default:
          return uiScope ? ChangeKind.ui : ChangeKind.other;
      }
    }
    if (headingKind != null && headingKind != ChangeKind.other) {
      return headingKind;
    }
    final t = text.toLowerCase();
    if (_fixWords.hasMatch(t)) return ChangeKind.fix;
    if (_docsWords.hasMatch(t) || _languageWords.hasMatch(t)) {
      return ChangeKind.docs;
    }
    if (_uiWords.hasMatch(t)) return ChangeKind.ui;
    if (_featureWords.hasMatch(t)) return ChangeKind.feature;
    return ChangeKind.other;
  }

  static ChangeKind? _kindOfHeading(String heading) {
    if (heading.trim().isEmpty) return null;
    final h = heading.toLowerCase();
    bool word(String w) => RegExp('\\b$w').hasMatch(h);
    if (word('fix') || word('bug') || word('crash') || h.contains('🐛')) {
      return ChangeKind.fix;
    }
    if (word('feat') ||
        word('added') ||
        word('new') ||
        word('highlights') ||
        h.contains('✨')) {
      return ChangeKind.feature;
    }
    if (RegExp(r'\b(ui|ux|visual|design|polish)\b').hasMatch(h) ||
        h.contains('🎨')) {
      return ChangeKind.ui;
    }
    if (word('doc') || word('translation') || h.contains('🌐')) {
      return ChangeKind.docs;
    }
    return null;
  }

  static String _clean(String text) {
    var s = text.trim().replaceFirst(_commitHash, '');
    s = s.replaceFirst(_ccPrefix, '').trim();
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
