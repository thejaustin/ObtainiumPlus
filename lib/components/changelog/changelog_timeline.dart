import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:obtainium/components/changelog/changelog_parser.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

const _repo = 'thejaustin/ObtainiumPlus';
const releasesPageUrl = 'https://github.com/$_repo/releases';

/// Releases with more changes than this start collapsed to a preview.
const _collapseAbove = 5;
const _previewCount = 3;
const _perPage = 30;

/// Session cache so reopening the sheet doesn't spend the unauthenticated
/// GitHub quota (60 requests/hour) again.
class _ReleaseCache {
  static final List<ChangelogRelease> releases = [];
  static int nextPage = 1;
  static bool exhausted = false;
  static DateTime? fetchedAt;

  static bool get fresh =>
      releases.isNotEmpty &&
      fetchedAt != null &&
      DateTime.now().difference(fetchedAt!) < const Duration(minutes: 20);

  static void reset() {
    releases.clear();
    nextPage = 1;
    exhausted = false;
    fetchedAt = null;
  }
}

Future<List<Object?>> _fetchPage(int page) async {
  final override = ChangelogTimeline.debugFetchPage;
  if (override != null) return override(page);
  final res = await get(
    Uri.parse(
      'https://api.github.com/repos/$_repo/releases?per_page=$_perPage&page=$page',
    ),
    headers: {'Accept': 'application/vnd.github+json'},
  ).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw Exception('GitHub returned ${res.statusCode}');
  }
  final decoded = jsonDecode(res.body);
  if (decoded is! List) throw const FormatException('Unexpected response');
  return decoded;
}

String _bare(String v) => v.trim().replaceFirst(RegExp(r'^[vV]'), '');

/// Vertical timeline of every Obtainium+ release, newest first, paging in
/// older releases as you scroll. Each release lists its changes grouped by
/// kind; filter chips narrow the whole history to one kind.
/// Inspired by Morphe Manager's timeline changelog.
class ChangelogTimeline extends StatefulWidget {
  /// Pass the [DraggableScrollableSheet] controller when hosted in a sheet.
  final ScrollController? scrollController;
  final String installedVersion;

  /// The version the user last saw; releases after it are marked "New".
  final String? sinceVersion;
  final Widget? header;

  /// Test hook: replaces the GitHub request for one page of releases.
  @visibleForTesting
  static Future<List<Object?>> Function(int page)? debugFetchPage;

  /// Test hook: drops the session cache.
  @visibleForTesting
  static void debugResetCache() => _ReleaseCache.reset();

  const ChangelogTimeline({
    super.key,
    required this.installedVersion,
    this.sinceVersion,
    this.scrollController,
    this.header,
  });

  @override
  State<ChangelogTimeline> createState() => _ChangelogTimelineState();
}

enum _LoadState { idle, loading, failed }

class _ChangelogTimelineState extends State<ChangelogTimeline> {
  ScrollController? _ownController;
  ScrollController get _controller =>
      widget.scrollController ?? (_ownController ??= ScrollController());

  _LoadState _state = _LoadState.idle;
  final Set<ChangeKind> _filter = {};
  final Set<String> _toggled = {}; // releases flipped from their default

  List<ChangelogRelease> get _releases => _ReleaseCache.releases;

  @override
  void initState() {
    super.initState();
    if (!_ReleaseCache.fresh) {
      _ReleaseCache.reset();
      _loadMore();
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_state == _LoadState.loading || _ReleaseCache.exhausted) return;
    setState(() => _state = _LoadState.loading);
    try {
      final page = await _fetchPage(_ReleaseCache.nextPage);
      final known = _releases.map((r) => r.tag).toSet();
      final fresh = page
          .map(ChangelogRelease.fromGitHub)
          .whereType<ChangelogRelease>()
          .where((r) => !known.contains(r.tag))
          .toList();
      _releases
        ..addAll(fresh)
        // The API orders by creation, not publish date; undated entries last.
        ..sort((a, b) {
          final ad = a.publishedAt, bd = b.publishedAt;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
      _ReleaseCache.nextPage++;
      _ReleaseCache.fetchedAt = DateTime.now();
      if (page.length < _perPage) _ReleaseCache.exhausted = true;
      if (mounted) setState(() => _state = _LoadState.idle);
    } catch (_) {
      if (mounted) setState(() => _state = _LoadState.failed);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.extentAfter < 900 &&
        _state == _LoadState.idle) {
      _loadMore();
    }
    return false;
  }

  bool _isInstalled(ChangelogRelease r) =>
      _bare(r.tag) == _bare(widget.installedVersion);

  bool _isNew(ChangelogRelease r) {
    final since = widget.sinceVersion;
    if (since == null || since.isEmpty) return false;
    final tag = _bare(r.tag);
    final afterSeen = compareVersionStrings(tag, _bare(since));
    final upToInstalled = compareVersionStrings(
      tag,
      _bare(widget.installedVersion),
    );
    return afterSeen != null &&
        afterSeen > 0 &&
        (upToInstalled == null || upToInstalled <= 0);
  }

  /// Releases worth showing: something user-facing, or the one installed.
  List<ChangelogRelease> get _meaningful =>
      _releases.where((r) => r.sections.isNotEmpty || _isInstalled(r)).toList();

  @override
  Widget build(BuildContext context) {
    final plus = context.watch<PlusSettingsProvider>();
    final anims = plus.plusEnableEnhancedAnimations;
    final radius = plus.plusGlobalCornerRadius;
    final meaningful = _meaningful;
    final latestTag = meaningful.isNotEmpty ? meaningful.first.tag : null;

    final shown = <ChangelogRelease>[];
    for (final r in meaningful) {
      if (_filter.isEmpty) {
        shown.add(r);
        continue;
      }
      final kept = r.sections.where((s) => _filter.contains(s.kind)).toList();
      if (kept.isNotEmpty) {
        shown.add(
          ChangelogRelease(
            tag: r.tag,
            publishedAt: r.publishedAt,
            isPrerelease: r.isPrerelease,
            sections: kept,
          ),
        );
      }
    }

    if (_releases.isEmpty) {
      return switch (_state) {
        _LoadState.failed => _ErrorState(
          onRetry: () {
            AppHaptics.selectionClick();
            _loadMore();
          },
        ),
        _ => const Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: ExpressiveCircularProgressIndicator(),
          ),
        ),
      };
    }

    final footerOpen = _state != _LoadState.idle || !_ReleaseCache.exhausted;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        controller: _controller,
        physics: plus.scrollPhysics,
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverToBoxAdapter(
            child: _SummaryCard(
              releases: meaningful,
              installedVersion: widget.installedVersion,
              isNew: _isNew,
              radius: radius,
            ),
          ),
          SliverToBoxAdapter(child: _buildFilters(context, meaningful)),
          if (shown.isEmpty && _state == _LoadState.idle)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  tr('changelogNoMatches'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final r = shown[i];
                final collapsible = r.changeCount > _collapseAbove;
                final defaultOpen =
                    !collapsible || r.tag == latestTag || _isNew(r);
                final open = _toggled.contains(r.tag)
                    ? !defaultOpen
                    : defaultOpen;
                return _ReleaseRow(
                  key: ValueKey(r.tag),
                  release: r,
                  isFirst: i == 0,
                  isLast: i == shown.length - 1 && !footerOpen,
                  isLatest: r.tag == latestTag,
                  isInstalled: _isInstalled(r),
                  isNew: _isNew(r),
                  expanded: open,
                  collapsible: collapsible,
                  animsEnabled: anims,
                  radius: radius,
                  onToggle: () {
                    AppHaptics.segmentTick();
                    setState(() {
                      if (!_toggled.remove(r.tag)) _toggled.add(r.tag);
                    });
                  },
                );
              }, childCount: shown.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
              child: _buildFooter(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, List<ChangelogRelease> all) {
    final present = ChangeKind.values
        .where((k) => all.any((r) => r.count(k) > 0))
        .toList();
    if (present.length < 2) return const SizedBox(height: 8);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: Text(tr('changelogFilterAll')),
            selected: _filter.isEmpty,
            showCheckmark: false,
            onSelected: (_) {
              AppHaptics.segmentTick();
              setState(_filter.clear);
            },
          ),
          for (final k in present) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(kindIcon(k), size: 16),
              label: Text(kindLabel(k)),
              selected: _filter.contains(k),
              showCheckmark: false,
              onSelected: (_) {
                AppHaptics.segmentTick();
                setState(() {
                  if (!_filter.remove(k)) _filter.add(k);
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (_state) {
      case _LoadState.loading:
        return const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: ExpressiveCircularProgressIndicator(),
          ),
        );
      case _LoadState.failed:
        return Column(
          children: [
            Text(
              tr('changelogLoadOlderFailed'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(tr('retry')),
              onPressed: () {
                AppHaptics.selectionClick();
                _loadMore();
              },
            ),
          ],
        );
      case _LoadState.idle:
        if (!_ReleaseCache.exhausted) {
          return Center(
            child: TextButton.icon(
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(tr('changelogLoadOlder')),
              onPressed: () {
                AppHaptics.selectionClick();
                _loadMore();
              },
            ),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              tr('changelogAllLoaded'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        );
    }
  }
}

String kindLabel(ChangeKind k) => switch (k) {
  ChangeKind.feature => tr('changelogKindFeatures'),
  ChangeKind.fix => tr('changelogKindFixes'),
  ChangeKind.ui => tr('changelogKindDesign'),
  ChangeKind.docs => tr('changelogKindDocs'),
  ChangeKind.other => tr('changelogKindOther'),
};

IconData kindIcon(ChangeKind k) => switch (k) {
  ChangeKind.feature => Icons.bolt_rounded,
  ChangeKind.fix => Icons.build_circle_outlined,
  ChangeKind.ui => Icons.palette_outlined,
  ChangeKind.docs => Icons.translate_rounded,
  ChangeKind.other => Icons.tune_rounded,
};

(Color, Color) _kindColors(ColorScheme cs, ChangeKind k) => switch (k) {
  ChangeKind.feature => (cs.primaryContainer, cs.onPrimaryContainer),
  ChangeKind.fix => (cs.tertiaryContainer, cs.onTertiaryContainer),
  ChangeKind.ui => (cs.secondaryContainer, cs.onSecondaryContainer),
  _ => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
};

String relativeReleaseDate(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final age = DateTime.now().difference(local);
  if (age.isNegative || age.inMinutes < 1) return tr('changelogJustNow');
  if (age.inHours < 1) {
    return tr('changelogTimeAgo', args: [plural('minute', age.inMinutes)]);
  }
  if (age.inDays < 1) {
    return tr('changelogTimeAgo', args: [plural('hour', age.inHours)]);
  }
  if (age.inDays < 7) {
    return tr('changelogTimeAgo', args: [plural('day', age.inDays)]);
  }
  return DateFormat.yMMMd(context.locale.toLanguageTag()).format(local);
}

// ─── Summary ────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<ChangelogRelease> releases;
  final String installedVersion;
  final bool Function(ChangelogRelease) isNew;
  final double radius;

  const _SummaryCard({
    required this.releases,
    required this.installedVersion,
    required this.isNew,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    if (releases.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final latest = releases.first;
    final newOnes = releases.where(isNew).toList();
    final pool = newOnes.isEmpty ? [latest] : newOnes;

    final tally = [
      for (final k in [ChangeKind.feature, ChangeKind.fix, ChangeKind.ui])
        if (pool.fold(0, (n, r) => n + r.count(k)) > 0)
          '${pool.fold(0, (n, r) => n + r.count(k))} ${kindLabel(k)}',
    ].join(' · ');

    final installed = _bare(installedVersion);
    final cmp = compareVersionStrings(installed, _bare(latest.tag));
    final behind = cmp != null && cmp < 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.75),
              cs.tertiaryContainer.withValues(alpha: 0.45),
            ],
          ),
          shape: CardMetrics.shape(CardMetrics.card(radius)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (behind) ...[
                  _VersionPill(
                    label: 'v$installed',
                    bg: cs.surface.withValues(alpha: 0.7),
                    fg: cs.onSurface,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
                _VersionPill(
                  label: latest.tag,
                  bg: cs.primary,
                  fg: cs.onPrimary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              newOnes.isNotEmpty
                  ? plural('changelogNewReleaseCount', newOnes.length)
                  : (behind ? latest.tag : tr('changelogUpToDate')),
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
              ),
            ),
            if (tally.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                tally,
                style: text.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _VersionPill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Release row ────────────────────────────────────────────────────────────

const double _railWidth = 28;
const double _nodeY = 24;

class _ReleaseRow extends StatelessWidget {
  final ChangelogRelease release;
  final bool isFirst;
  final bool isLast;
  final bool isLatest;
  final bool isInstalled;
  final bool isNew;
  final bool expanded;
  final bool collapsible;
  final bool animsEnabled;
  final double radius;
  final VoidCallback onToggle;

  const _ReleaseRow({
    super.key,
    required this.release,
    required this.isFirst,
    required this.isLast,
    required this.isLatest,
    required this.isInstalled,
    required this.isNew,
    required this.expanded,
    required this.collapsible,
    required this.animsEnabled,
    required this.radius,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final active = isLatest || isInstalled || isNew;
    final node = active ? cs.primary : cs.outline;
    final r = release;

    final meta = [
      relativeReleaseDate(context, r.publishedAt),
      if (r.changeCount > 0) plural('changelogChangeCount', r.changeCount),
    ].where((s) => s.isNotEmpty).join(' · ');

    final card = Material(
      color: active
          ? cs.surfaceContainer
          : cs.surfaceContainerLow.withValues(alpha: 0.9),
      shape: CardMetrics.shape(
        CardMetrics.card(radius),
        side: BorderSide(
          color: active
              ? cs.primary.withValues(alpha: 0.35)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: collapsible ? onToggle : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              r.tag,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                              ),
                            ),
                            ..._badges(cs),
                          ],
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            meta,
                            style: text.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (collapsible)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: Duration(milliseconds: animsEnabled ? 220 : 0),
                      curve: AppConstants.expressiveDecelerate,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: animsEnabled ? 260 : 0),
            curve: AppConstants.expressiveDecelerate,
            alignment: Alignment.topCenter,
            child: _buildBody(context, cs, text),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _railWidth,
          child: CustomPaint(
            painter: _RailPainter(
              rail: cs.outlineVariant,
              node: node,
              filled: active,
              isFirst: isFirst,
              isLast: isLast,
            ),
          ),
        ),
        if (isLatest && animsEnabled)
          const Positioned(
            left: 0,
            top: _nodeY - _railWidth / 2,
            width: _railWidth,
            height: _railWidth,
            child: _PulseHalo(),
          ),
        Padding(
          padding: const EdgeInsets.only(left: _railWidth + 8, bottom: 12),
          child: card,
        ),
      ],
    );
  }

  List<Widget> _badges(ColorScheme cs) {
    final wanted = <(String, Color, Color)>[
      if (isInstalled)
        (
          tr('changelogBadgeInstalled'),
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
        ),
      if (isLatest)
        (tr('changelogBadgeLatest'), cs.primary, cs.onPrimary)
      else if (isNew)
        (
          tr('changelogBadgeNew'),
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        ),
      if (release.isPrerelease)
        (
          tr('changelogBadgePrerelease'),
          cs.errorContainer,
          cs.onErrorContainer,
        ),
    ];
    return [
      for (final (label, bg, fg) in wanted.take(2))
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
    ];
  }

  Widget _buildBody(BuildContext context, ColorScheme cs, TextTheme text) {
    final r = release;
    if (r.sections.isEmpty) return const SizedBox(width: double.infinity);
    var budget = expanded ? 1 << 30 : _previewCount;
    final children = <Widget>[];
    for (final s in r.sections) {
      if (budget <= 0) break;
      final items = s.items.take(budget).toList();
      budget -= items.length;
      final (bg, fg) = _kindColors(cs, s.kind);
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: ShapeDecoration(
                  color: bg,
                  shape: CardMetrics.shape(8),
                ),
                child: Icon(kindIcon(s.kind), size: 13, color: fg),
              ),
              const SizedBox(width: 8),
              Text(
                kindLabel(s.kind),
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${s.items.length}',
                style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
      for (final item in items) {
        children.add(
          _ChangeLine(
            text: item,
            dot: fg == cs.onSurfaceVariant ? cs.outline : cs.primary,
          ),
        );
      }
    }
    final hidden = r.changeCount - (expanded ? r.changeCount : _previewCount);
    if (collapsible) {
      children.add(
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: onToggle,
            child: Text(
              expanded
                  ? tr('changelogShowLess')
                  : tr('changelogShowMore', args: ['${hidden.clamp(0, 9999)}']),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, collapsible ? 4 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// One change, with `**bold**`, `` `code` `` and `#123` issue references
/// rendered inline; issue references open on GitHub.
class _ChangeLine extends StatelessWidget {
  final String text;
  final Color dot;

  const _ChangeLine({required this.text, required this.dot});

  static final _tokens = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|#(\d+)\b');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.4, color: cs.onSurface);
    final spans = <InlineSpan>[];
    var last = 0;
    String? firstIssue;
    for (final m in _tokens.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(2) != null) {
        spans.add(
          TextSpan(
            text: m.group(2),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: (base?.fontSize ?? 14) - 1,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        );
      } else {
        firstIssue ??= m.group(3);
        spans.add(
          TextSpan(
            text: '#${m.group(3)}',
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    final line = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 6, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text.rich(TextSpan(style: base, children: spans)),
          ),
        ],
      ),
    );
    if (firstIssue == null) return line;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        AppHaptics.selectionClick();
        launchUrlString(
          'https://github.com/$_repo/issues/$firstIssue',
          mode: LaunchMode.externalApplication,
        );
      },
      child: line,
    );
  }
}

class _RailPainter extends CustomPainter {
  final Color rail;
  final Color node;
  final bool filled;
  final bool isFirst;
  final bool isLast;

  _RailPainter({
    required this.rail,
    required this.node,
    required this.filled,
    required this.isFirst,
    required this.isLast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = isFirst ? _nodeY : 0.0;
    final bottom = isLast ? _nodeY : size.height;
    if (bottom > top) {
      canvas.drawLine(
        Offset(cx, top),
        Offset(cx, bottom),
        Paint()
          ..color = rail
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      Offset(cx, _nodeY),
      10,
      Paint()..color = node.withValues(alpha: 0.18),
    );
    if (filled) {
      canvas.drawCircle(Offset(cx, _nodeY), 6, Paint()..color = node);
    } else {
      canvas.drawCircle(
        Offset(cx, _nodeY),
        5,
        Paint()
          ..color = node
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.rail != rail ||
      old.node != node ||
      old.filled != filled ||
      old.isFirst != isFirst ||
      old.isLast != isLast;
}

/// Breathing halo on the latest release's node. Only built when animations
/// are enabled.
class _PulseHalo extends StatefulWidget {
  const _PulseHalo();

  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return Center(
            child: Container(
              width: 20 + 10 * t,
              height: 20 + 10 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.22 * (1 - t) + 0.04),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              tr('changelogFetchFailed'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.94,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(tr('retry')),
                    onPressed: onRetry,
                  ),
                ),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.94,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('GitHub'),
                    onPressed: () => launchUrlString(
                      releasesPageUrl,
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
