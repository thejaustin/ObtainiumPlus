import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart';
import 'package:obtainium/utils/version_constant.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChangelogPage extends StatefulWidget {
  final bool isModal;
  final String? targetVersion;

  const ChangelogPage({
    super.key,
    this.isModal = false,
    this.targetVersion,
  });

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

  void _retry() {
    setState(() {
      _changelogFuture = _fetchChangelog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = FutureBuilder<String>(
      future: _changelogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ExpressiveCircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error?.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(tr('noLogs')));
        }

        return Markdown(
          data: snapshot.data!,
          physics: const BouncingScrollPhysics(),
          onTapLink: (text, href, title) {
            if (href != null) {
              launchUrlString(href, mode: LaunchMode.externalApplication);
            }
          },
          styleSheet: MarkdownStyleSheet(
            h1: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            h2: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            h3: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
            listBullet: TextStyle(color: colorScheme.primary),
          ),
        );
      },
    );

    if (widget.isModal) {
      return content;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text(tr('viewChangelog'))),
      body: content,
    );
  }

  Widget _buildErrorState(BuildContext context, String? error) {
    final colorScheme = Theme.of(context).colorScheme;
    final ver = widget.targetVersion ?? currentObtainiumPlusVersion;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Obtainium+ $ver',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('changelogFetchFailed'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(tr('retry')),
                  onPressed: _retry,
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('GitHub'),
                  onPressed: () {
                    launchUrlString(
                      'https://github.com/thejaustin/ObtainiumPlus/releases',
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the changelog. For modal mode, focuses on the target/latest version.
  Future<String> _fetchChangelog() async {
    final targetVer = widget.targetVersion ?? currentObtainiumPlusVersion;

    // 1. If in modal mode, first attempt to fetch the specific release notes for targetVer
    if (widget.isModal) {
      try {
        final tag = targetVer.startsWith('v') ? targetVer : 'v$targetVer';
        final res = await get(
          Uri.parse(
            'https://api.github.com/repos/thejaustin/ObtainiumPlus/releases/tags/$tag',
          ),
          headers: {'Accept': 'application/vnd.github+json'},
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final release = jsonDecode(res.body);
          if (release is Map) {
            final body = (release['body'] ?? '').toString().trim();
            if (body.isNotEmpty) {
              return _cleanReleaseBody(body);
            }
          }
        }
      } catch (_) {
        // Fall back to listing releases below
      }
    }

    // 2. Fetch recent releases list
    try {
      final response = await get(
        Uri.parse(
          'https://api.github.com/repos/thejaustin/ObtainiumPlus/releases?per_page=10',
        ),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final buffer = StringBuffer();
          int count = 0;
          final maxCount = widget.isModal ? 2 : 10;

          for (final release in decoded) {
            if (release is! Map) continue;
            final tag = (release['tag_name'] ?? '').toString();
            if (release['draft'] == true || release['prerelease'] == true) {
              continue;
            }
            final name = (release['name'] ?? '').toString();
            final body = (release['body'] ?? '').toString().trim();

            if (widget.isModal && count == 0 && body.isNotEmpty) {
              // For modal, clean and display the latest release notes directly
              return _cleanReleaseBody(body);
            }

            final title = name.isNotEmpty ? name : tag;
            buffer.writeln('# $title\n');
            if (body.isNotEmpty) {
              buffer.writeln(_cleanReleaseBody(body));
              buffer.writeln();
            }
            count++;
            if (count >= maxCount) break;
            buffer.writeln('---\n');
          }
          if (buffer.isNotEmpty) {
            return buffer.toString().trim();
          }
        }
      }
    } catch (_) {
      // Fallback below
    }

    // 3. Clean fallback when offline or rate limited
    return _buildBundledFallback(targetVer);
  }

  String _cleanReleaseBody(String body) {
    var cleaned = body;
    // Strip trailing compare links / separators if they make the dialog messy
    cleaned = cleaned.replaceAll(RegExp(r'---\s*\[Full Changelog\].*$'), '');
    return cleaned.trim();
  }

  String _buildBundledFallback(String version) {
    return '''
**Obtainium+ $version**

### ✨ Highlights & New Features
- **Samsung OneUI Reachability Header**: Collapsible header with smooth title shift on pull-down and contextual app & update counts.
- **Material 3 Expressive Theming**: Wallpaper dynamic scheme variants, curated palette presets, and spatial scale transitions.
- **Floating Navigation Dock**: Modern frosted island dock with rounded corners and ambient shadow (with classic flat bar option).
- **Floating Action Capsule**: Frosted install/update capsule on the App Detail screen.
- **Customizable App Tile Styling**: Highlighted pinned app borders, category accent ribbons, expressive version update pills (↓ 2.4.0), and icon rim borders across List and Grid views.
- **Stadium Pill Filter Chips**: Fully rounded tag and category filter chips.
- **Performance & Stability**: Fixed PageStorage key collisions in Settings, isolated dialog barriers, optimized PMS install locks, and resolved tab switch edge cases.

---
[View All Releases on GitHub](https://github.com/thejaustin/ObtainiumPlus/releases)
'''.trim();
  }
}
