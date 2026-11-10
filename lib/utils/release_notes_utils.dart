import 'package:html/parser.dart' as html_parser;

/// Lowercased, whitespace-collapsed form of a notes body with link-only
/// lines ("Full Changelog: …") and bare URLs removed. Two bodies that are
/// equal under this are treated as the same notes.
String normalizeReleaseNotes(String? body) {
  if (body == null) return '';
  return body
      .split('\n')
      .where((l) => !RegExp(r'^\W*full changelog', caseSensitive: false)
          .hasMatch(l))
      .join('\n')
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
}

/// Play's `recentChangesHtml` is a small HTML fragment (`<br>`-separated
/// lines, entities). Convert it to plain text with the line breaks kept.
String? playNotesHtmlToText(String? html) {
  if (html == null || html.trim().isEmpty) return null;
  final withBreaks = html.replaceAll(
    RegExp(r'<br\s*/?>|</p>|</li>', caseSensitive: false),
    '\n',
  );
  final text = html_parser.parseFragment(withBreaks).text?.trim() ?? '';
  return text.isEmpty ? null : text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
}

/// Returns the section of a whole-project CHANGELOG that belongs to
/// [version], or null when no heading for it can be found.
///
/// A section starts at a Markdown heading (or `[x.y]` / `vX.Y` line) that
/// contains the version and ends at the next heading of the same or a
/// higher level.
String? extractChangelogSection(String changelog, String version) {
  final v = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
  if (v.isEmpty) return null;
  final lines = changelog.split('\n');
  final versionPattern = RegExp(
    '(^|[^0-9A-Za-z.])v?${RegExp.escape(v)}(?![0-9A-Za-z]|\\.[0-9])',
    caseSensitive: false,
  );
  final headingPattern = RegExp(r'^(#{1,6})\s');

  int? start;
  int level = 7;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimRight();
    final h = headingPattern.firstMatch(line);
    final isBareVersionLine =
        h == null && RegExp(r'^\[?v?\d').hasMatch(line) && line.length < 60;
    if ((h != null || isBareVersionLine) && versionPattern.hasMatch(line)) {
      start = i;
      level = h?.group(1)!.length ?? 7;
      break;
    }
  }
  if (start == null) return null;

  var end = lines.length;
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i].trimRight();
    final h = headingPattern.firstMatch(line);
    if (h != null && h.group(1)!.length <= level) {
      end = i;
      break;
    }
    // Bare-version changelogs: the next version line ends the section.
    if (level == 7 &&
        RegExp(r'^\[?v?\d+\.\d').hasMatch(line) &&
        line.length < 60) {
      end = i;
      break;
    }
  }
  final body = lines.sublist(start + 1, end).join('\n').trim();
  return body.isEmpty ? null : body;
}

/// Splits a whole-project CHANGELOG into `(version, body)` sections, in file
/// order (normally newest first). A section starts at a Markdown heading, or
/// a short bare line such as `[1.2.0]` / `v1.2`, that contains a version
/// number, and ends at the next such line. Headings without a version
/// (`## Fixed`) stay inside the current section.
List<(String, String)> splitChangelogSections(String changelog) {
  final versionToken = RegExp(r'v?(\d+(?:\.\d+)+(?:[-+.][0-9A-Za-z.\-+]*)?)');
  final headingPattern = RegExp(r'^(#{1,6})\s+(.*)$');
  final lines = changelog.split('\n');
  final out = <(String, String)>[];
  String? current;
  int currentLevel = 7;
  final body = <String>[];

  void flush() {
    if (current != null) out.add((current!, body.join('\n').trim()));
    body.clear();
  }

  for (final raw in lines) {
    final line = raw.trimRight();
    final h = headingPattern.firstMatch(line);
    final isBare =
        h == null && RegExp(r'^\[?v?\d+\.\d').hasMatch(line) && line.length < 60;
    final text = h?.group(2) ?? (isBare ? line : null);
    final level = h?.group(1)!.length ?? 7;
    final v = text == null ? null : versionToken.firstMatch(text)?.group(1);
    // A version line at the same or a higher level than the current section
    // starts a new one; deeper version-looking headings stay in the body.
    if (v != null && (current == null || level <= currentLevel)) {
      flush();
      current = v;
      currentLevel = level;
      continue;
    }
    if (current != null) body.add(raw);
  }
  flush();
  return out;
}
