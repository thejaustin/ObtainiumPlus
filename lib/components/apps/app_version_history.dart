import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/release_note.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:obtainium/components/apps/app_changelog.dart'
    show resolveChangeLogLink;
import 'package:obtainium/services/release_notes_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppVersionHistoryWidget extends StatelessWidget {
  final App app;

  const AppVersionHistoryWidget({Key? key, required this.app})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppSource? appSource;
    try {
      appSource = SourceProvider().getSource(
        app.url,
        overrideSource: app.overrideSource,
      );
    } catch (_) {}
    final canFetch = appSource?.supportsReleaseNotes == true;
    if (app.versionHistory.isEmpty && !canFetch) {
      return const SizedBox.shrink();
    }

    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(radius);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey<String>('version_history:${app.id}'),
              onExpansionChanged: (_) => AppHaptics.selectionClick(),
              expansionAnimationStyle: AnimationStyle(
                curve: Easing.emphasizedDecelerate,
                reverseCurve: Easing.emphasizedAccelerate,
                duration: Duration(
                  milliseconds: plusSettings.plusEnableEnhancedAnimations
                      ? 300
                      : 0,
                ),
              ),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                tr('versionHistory'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                app.versionHistory.isEmpty
                    ? appSource!.name
                    : '${app.versionHistory.length} release${app.versionHistory.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              children: [
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                // Children are only built while expanded, so the fetch
                // starts on first expand (including a PageStorage-restored
                // expanded state), never on page open.
                _VersionHistoryBody(
                  app: app,
                  isMarkdown: appSource?.changeLogIfAnyIsMarkDown ?? true,
                  canFetch: canFetch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of the timeline, from fetched release notes or stored history.
class _HistoryRow {
  final String version;
  final DateTime? date;
  final String? body;
  final bool isMarkdown;
  final bool isPrerelease;
  final bool isLatest;
  final bool isInstalled;

  const _HistoryRow({
    required this.version,
    this.date,
    this.body,
    required this.isMarkdown,
    this.isPrerelease = false,
    this.isLatest = false,
    this.isInstalled = false,
  });
}

class _VersionHistoryBody extends StatefulWidget {
  final App app;
  final bool isMarkdown;
  final bool canFetch;

  const _VersionHistoryBody({
    required this.app,
    required this.isMarkdown,
    required this.canFetch,
  });

  @override
  State<_VersionHistoryBody> createState() => _VersionHistoryBodyState();
}

class _VersionHistoryBodyState extends State<_VersionHistoryBody> {
  Future<List<ReleaseNote>>? _notes;

  @override
  void initState() {
    super.initState();
    if (widget.canFetch) {
      _notes = ReleaseNotesService.instance.fetch(widget.app);
    }
  }

  List<_HistoryRow> _rowsFromNotes(List<ReleaseNote> notes) {
    final app = widget.app;
    return notes
        .map(
          (n) => _HistoryRow(
            version: n.version,
            date: n.date,
            body: n.body,
            isMarkdown: n.isMarkdown,
            isPrerelease: n.isPrerelease,
            isLatest: ReleaseNotesService.tagMatchesVersion(
              n.version,
              app.latestVersion,
            ),
            isInstalled: ReleaseNotesService.tagMatchesInstalled(
              n.version,
              app.installedVersion,
            ),
          ),
        )
        .toList();
  }

  List<_HistoryRow> _rowsFromStored() {
    final app = widget.app;
    return app.versionHistory
        .map(
          (e) => _HistoryRow(
            version: e.version,
            date: e.releaseDate,
            body: e.changeLog,
            isMarkdown: widget.isMarkdown,
            isLatest: ReleaseNotesService.tagMatchesVersion(
              e.version,
              app.latestVersion,
            ),
            isInstalled: ReleaseNotesService.tagMatchesInstalled(
              e.version,
              app.installedVersion,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = _notes;
    if (notes == null) {
      return _buildRows(context, _rowsFromStored(), colorScheme);
    }
    return FutureBuilder<List<ReleaseNote>>(
      future: notes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final fetched = snapshot.data ?? const <ReleaseNote>[];
        return _buildRows(
          context,
          fetched.isNotEmpty ? _rowsFromNotes(fetched) : _rowsFromStored(),
          colorScheme,
        );
      },
    );
  }

  Widget _buildRows(
    BuildContext context,
    List<_HistoryRow> rows,
    ColorScheme colorScheme,
  ) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          tr('noVersionHistory'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++)
          _buildEntry(
            context,
            rows[i],
            isLast: i == rows.length - 1,
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  Widget _badge(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context,
    _HistoryRow entry, {
    required bool isLast,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.4),
                              colorScheme.outlineVariant.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.version,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                        if (entry.isPrerelease)
                          _badge(
                            context,
                            tr('changelogBadgePrerelease'),
                            colorScheme.tertiaryContainer,
                            colorScheme.onTertiaryContainer,
                          ),
                        if (entry.isLatest)
                          _badge(
                            context,
                            tr('latest'),
                            colorScheme.primaryContainer,
                            colorScheme.onPrimaryContainer,
                          ),
                        if (entry.isInstalled)
                          _badge(
                            context,
                            tr('installed'),
                            colorScheme.secondaryContainer,
                            colorScheme.onSecondaryContainer,
                          ),
                        if (entry.date != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(
                                CardMetrics.pillRadius,
                              ),
                            ),
                            child: Text(
                              _formatDate(entry.date!),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    if (entry.body != null && entry.body!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      entry.isMarkdown
                          ? MarkdownBody(
                              data: entry.body!,
                              styleSheet: MarkdownStyleSheet(
                                p: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                listBullet: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                ),
                                h1: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                h2: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                h3: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              onTapLink: (text, href, title) {
                                if (href != null) {
                                  launchUrlString(
                                    resolveChangeLogLink(widget.app.url, href),
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              extensionSet: md.ExtensionSet(
                                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                                [
                                  md.EmojiSyntax(),
                                  ...md
                                      .ExtensionSet
                                      .gitHubFlavored
                                      .inlineSyntaxes,
                                ],
                              ),
                            )
                          : Text(
                              entry.body!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()}mo ago';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.year}';
  }
}
