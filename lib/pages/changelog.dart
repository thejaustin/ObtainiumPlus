import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/version_constant.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:markdown/markdown.dart' as md;

// ─── Data model ────────────────────────────────────────────────────────────

class _ReleaseItem {
  final String tag;
  final String name;
  final String body;
  final bool isNew;

  const _ReleaseItem({
    required this.tag,
    required this.name,
    required this.body,
    this.isNew = false,
  });
}

// ─── Public entry point ─────────────────────────────────────────────────────

/// Shows the "What's New" bottom sheet. Call from home.dart after a version bump.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  String? targetVersion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    elevation: 0,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _WhatsNewSheet(
            targetVersion: targetVersion ?? currentObtainiumPlusVersion,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

// ─── Page (standalone, non-modal) ───────────────────────────────────────────

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
  late Future<List<_ReleaseItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchReleases(widget.targetVersion ?? currentObtainiumPlusVersion);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isModal) {
      // In modal context just render the inner sheet directly (handled by showWhatsNewSheet)
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(tr('viewChangelog'))),
      body: FutureBuilder<List<_ReleaseItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ExpressiveCircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _ErrorState(
              onRetry: () => setState(() {
                _future = _fetchReleases(widget.targetVersion ?? currentObtainiumPlusVersion);
              }),
            );
          }
          return _ReleaseList(releases: snapshot.data!);
        },
      ),
    );
  }
}

// ─── Bottom-sheet widget ────────────────────────────────────────────────────

class _WhatsNewSheet extends StatefulWidget {
  final String targetVersion;
  final ScrollController scrollController;

  const _WhatsNewSheet({
    required this.targetVersion,
    required this.scrollController,
  });

  @override
  State<_WhatsNewSheet> createState() => _WhatsNewSheetState();
}

class _WhatsNewSheetState extends State<_WhatsNewSheet> {
  late Future<List<_ReleaseItem>> _future;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = _fetchReleases(widget.targetVersion);
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final enableAnims = plusSettings.plusEnableEnhancedAnimations;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = plusSettings.plusGlobalCornerRadius;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 4)),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: AppConstants.glassBlurSigma,
        child: AnimatedContainer(
          duration: Duration(milliseconds: enableAnims ? 260 : 0),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: (isDark
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surface)
                .withValues(
                  alpha: enableGlass ? AppConstants.glassSurfaceAlpha : 1.0,
                ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 4)),
            border: Border.all(
              color: colorScheme.outline.withValues(
                alpha: enableGlass ? AppConstants.glassBorderAlpha : AppOpacity.subtle,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(context, colorScheme),
              _buildHeader(context, colorScheme, enableGlass),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<_ReleaseItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: ExpressiveCircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return _ErrorState(
                        onRetry: () => setState(() {
                          _future = _fetchReleases(widget.targetVersion);
                        }),
                      );
                    }
                    final releases = snapshot.data!;
                    final selected = releases[_selectedIndex.clamp(0, releases.length - 1)];
                    return Column(
                      children: [
                        if (releases.length > 1)
                          _buildVersionChips(context, releases, colorScheme),
                        Expanded(
                          child: _MarkdownBody(
                            body: selected.body,
                            scrollController: widget.scrollController,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildFooter(context, colorScheme, enableGlass),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, bool enableGlass) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: AppOpacity.half),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: cs.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's New in Obtainium+",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version ${widget.targetVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionChips(
    BuildContext context,
    List<_ReleaseItem> releases,
    ColorScheme cs,
  ) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: releases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final release = releases[i];
          final isSelected = i == _selectedIndex;
          return ChoiceChip(
            label: Text(release.tag),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedIndex = i),
            avatar: release.isNew
                ? Icon(Icons.new_releases_rounded, size: 14, color: cs.primary)
                : null,
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme cs, bool enableGlass) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outline.withValues(alpha: AppOpacity.subtle),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('GitHub Releases'),
                onPressed: () {
                  launchUrlString(
                    'https://github.com/thejaustin/ObtainiumPlus/releases',
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('ok')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Markdown body ───────────────────────────────────────────────────────────

class _MarkdownBody extends StatelessWidget {
  final String body;
  final ScrollController scrollController;

  const _MarkdownBody({required this.body, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Markdown(
      controller: scrollController,
      data: body,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      physics: const BouncingScrollPhysics(),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrlString(href, mode: LaunchMode.externalApplication);
        }
      },
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
      ),
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
        blockquoteDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ─── Release list (standalone page) ─────────────────────────────────────────

class _ReleaseList extends StatefulWidget {
  final List<_ReleaseItem> releases;

  const _ReleaseList({required this.releases});

  @override
  State<_ReleaseList> createState() => _ReleaseListState();
}

class _ReleaseListState extends State<_ReleaseList> {
  int _selectedIndex = 0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final releases = widget.releases;
    final selected = releases[_selectedIndex.clamp(0, releases.length - 1)];

    return Column(
      children: [
        if (releases.length > 1)
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: releases.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final release = releases[i];
                final isSelected = i == _selectedIndex;
                return ChoiceChip(
                  label: Text(release.tag),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedIndex = i),
                );
              },
            ),
          ),
        Expanded(
          child: _MarkdownBody(
            body: selected.body,
            scrollController: _scrollController,
          ),
        ),
      ],
    );
  }
}

// ─── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  onPressed: onRetry,
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
}

// ─── Fetch logic ─────────────────────────────────────────────────────────────

Future<List<_ReleaseItem>> _fetchReleases(String targetVersion) async {
  // 1. Try specific release tag first for speed
  try {
    final tag = targetVersion.startsWith('v') ? targetVersion : 'v$targetVersion';
    final res = await get(
      Uri.parse(
        'https://api.github.com/repos/thejaustin/ObtainiumPlus/releases/tags/$tag',
      ),
      headers: {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 5));

    if (res.statusCode == 200) {
      final release = jsonDecode(res.body);
      if (release is Map) {
        final body = _cleanBody((release['body'] ?? '').toString().trim());
        if (body.isNotEmpty) {
          final name = (release['name'] ?? '').toString();
          final items = [
            _ReleaseItem(
              tag: tag,
              name: name.isNotEmpty ? name : tag,
              body: body,
              isNew: true,
            ),
          ];
          // Fetch earlier releases in the background to populate chips
          try {
            final extras = await _fetchRecentList(
              perPage: 6,
              excludeTag: tag,
            );
            return [...items, ...extras];
          } catch (_) {
            return items;
          }
        }
      }
    }
  } catch (_) {}

  // 2. Fall back to listing recent releases
  try {
    final items = await _fetchRecentList(perPage: 10);
    if (items.isNotEmpty) return items;
  } catch (_) {}

  // 3. Offline bundled fallback
  return [
    _ReleaseItem(
      tag: targetVersion.startsWith('v') ? targetVersion : 'v$targetVersion',
      name: 'Obtainium+ $targetVersion',
      body: _bundledFallback(targetVersion),
      isNew: true,
    ),
  ];
}

Future<List<_ReleaseItem>> _fetchRecentList({
  int perPage = 10,
  String? excludeTag,
}) async {
  final response = await get(
    Uri.parse(
      'https://api.github.com/repos/thejaustin/ObtainiumPlus/releases?per_page=$perPage',
    ),
    headers: {'Accept': 'application/vnd.github+json'},
  ).timeout(const Duration(seconds: 6));

  if (response.statusCode != 200) return [];

  final decoded = jsonDecode(response.body);
  if (decoded is! List) return [];

  final items = <_ReleaseItem>[];
  for (final release in decoded) {
    if (release is! Map) continue;
    if (release['draft'] == true || release['prerelease'] == true) continue;
    final tag = (release['tag_name'] ?? '').toString();
    if (excludeTag != null && tag == excludeTag) continue;
    final name = (release['name'] ?? '').toString();
    final body = _cleanBody((release['body'] ?? '').toString().trim());
    if (body.isEmpty && name.isEmpty) continue;
    items.add(_ReleaseItem(
      tag: tag,
      name: name.isNotEmpty ? name : tag,
      body: body,
    ));
  }
  return items;
}

String _cleanBody(String body) {
  var cleaned = body;
  cleaned = cleaned.replaceAll(
    RegExp(r'\n---\n<details>.*?</details>', dotAll: true),
    '',
  );
  cleaned = cleaned.replaceAll(
    RegExp(r'---\s*\[Full Changelog\].*$', multiLine: false, dotAll: true),
    '',
  );
  return cleaned.trim();
}

String _bundledFallback(String version) => '''
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
