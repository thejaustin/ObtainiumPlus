/// Release notes for one published version, fetched on demand from the forge
/// an app is tracked from (GitHub, GitLab, Codeberg/Forgejo, Gitea).
class ReleaseNote {
  final String version;
  final DateTime? date;
  final String body;
  final bool isMarkdown;
  final String? htmlUrl;
  final String source;
  final bool isPrerelease;

  /// Release name/title as published (may differ from the tag).
  final String? title;

  const ReleaseNote({
    required this.version,
    this.date,
    required this.body,
    this.isMarkdown = true,
    this.htmlUrl,
    required this.source,
    this.isPrerelease = false,
    this.title,
  });

  ReleaseNote copyWith({String? body, String? version}) => ReleaseNote(
    version: version ?? this.version,
    date: date,
    body: body ?? this.body,
    isMarkdown: isMarkdown,
    htmlUrl: htmlUrl,
    source: source,
    isPrerelease: isPrerelease,
    title: title,
  );

  /// Parses a GitHub or Gitea/Forgejo release object (same shape: tag_name,
  /// name, published_at, body, html_url, prerelease, draft). Returns null for
  /// drafts, malformed entries and, unless [includePrereleases], pre-releases.
  static ReleaseNote? fromGitHubLike(
    Object? json, {
    required String source,
    required bool includePrereleases,
    bool isMarkdown = true,
  }) {
    if (json is! Map) return null;
    if (json['draft'] == true) return null;
    final prerelease = json['prerelease'] == true;
    if (prerelease && !includePrereleases) return null;
    final tag = (json['tag_name'] ?? json['name'] ?? '').toString().trim();
    if (tag.isEmpty) return null;
    final dateStr = (json['published_at'] ?? json['created_at'])?.toString();
    return ReleaseNote(
      version: tag,
      date: dateStr == null ? null : DateTime.tryParse(dateStr),
      body: (json['body'] ?? '').toString().trim(),
      isMarkdown: isMarkdown,
      htmlUrl: json['html_url']?.toString(),
      source: source,
      isPrerelease: prerelease,
      title: json['name']?.toString(),
    );
  }

  /// Parses a GitLab release object (tag_name, released_at, description,
  /// _links.self, upcoming_release).
  static ReleaseNote? fromGitLab(
    Object? json, {
    required String source,
    bool isMarkdown = true,
  }) {
    if (json is! Map) return null;
    final tag = (json['tag_name'] ?? json['name'] ?? '').toString().trim();
    if (tag.isEmpty) return null;
    final dateStr = (json['released_at'] ?? json['created_at'])?.toString();
    final links = json['_links'];
    return ReleaseNote(
      version: tag,
      date: dateStr == null ? null : DateTime.tryParse(dateStr),
      body: (json['description'] ?? '').toString().trim(),
      isMarkdown: isMarkdown,
      htmlUrl: links is Map ? links['self']?.toString() : null,
      source: source,
      isPrerelease: json['upcoming_release'] == true,
      title: json['name']?.toString(),
    );
  }
}
