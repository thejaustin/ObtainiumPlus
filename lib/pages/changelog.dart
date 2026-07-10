import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChangelogPage extends StatefulWidget {
  final bool isModal;
  const ChangelogPage({super.key, this.isModal = false});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  late Future<String> _changelogFuture;

  @override
  void initState() {
    super.initState();
    _changelogFuture = _fetchChangelog();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.isModal ? Colors.transparent : colorScheme.surface,
      appBar: widget.isModal ? null : AppBar(title: Text(tr('viewChangelog'))),
      body: FutureBuilder<String>(
        future: _changelogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ExpressiveCircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${tr('error')}: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(tr('noLogs')));
          }

          return Markdown(
            data: snapshot.data!,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrlString(href, mode: LaunchMode.externalApplication);
              }
            },
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
              h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          );
        },
      ),
    );
  }

  /// Builds the changelog from GitHub release bodies (newest first).
  /// Only stable releases are included: drafts, prereleases and non-`v`
  /// tags (e.g. `dev-N` / `build-N`) are skipped.
  Future<String> _fetchChangelog() async {
    try {
      final response = await get(
        Uri.parse(
          'https://api.github.com/repos/thejaustin/ObtainiumPlus/releases?per_page=15',
        ),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final buffer = StringBuffer();
          for (final release in decoded) {
            if (release is! Map) continue;
            final tag = (release['tag_name'] ?? '').toString();
            if (release['draft'] == true ||
                release['prerelease'] == true ||
                !tag.startsWith('v')) {
              continue;
            }
            final name = (release['name'] ?? '').toString();
            final body = (release['body'] ?? '').toString().trim();
            buffer.writeln('# ${name.isNotEmpty ? name : tag}');
            buffer.writeln();
            if (body.isNotEmpty) {
              buffer.writeln(body);
              buffer.writeln();
            }
            buffer.writeln('---');
            buffer.writeln();
          }
          if (buffer.isNotEmpty) {
            return buffer.toString();
          }
        }
      }
    } catch (e) {
      // Ignore network errors and fall back below
    }

    return '# Obtainium+\n\n'
        '${tr('changelogFetchFailed')}\n\n'
        '[GitHub Releases](https://github.com/thejaustin/ObtainiumPlus/releases)\n';
  }
}
