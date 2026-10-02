import 'package:flutter/material.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/version_history_entry.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppVersionHistoryWidget extends StatelessWidget {
  final App app;

  const AppVersionHistoryWidget({Key? key, required this.app})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (app.versionHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final settings = context.watch<SettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(radius);

    final appSource = SourceProvider().getSource(
      app.url,
      overrideSource: app.overrideSource,
    );

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
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                'Version History',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${app.versionHistory.length} release${app.versionHistory.length == 1 ? '' : 's'}',
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
                ...app.versionHistory.asMap().entries.map((e) {
                  final isLast = e.key == app.versionHistory.length - 1;
                  return _buildEntry(
                    context,
                    e.value,
                    appSource,
                    isLast: isLast,
                    colorScheme: colorScheme,
                    plusSettings: plusSettings,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context,
    VersionHistoryEntry entry,
    AppSource appSource, {
    required bool isLast,
    required ColorScheme colorScheme,
    required PlusSettingsProvider plusSettings,
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (entry.releaseDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
                            ),
                            child: Text(
                              _formatDate(entry.releaseDate!),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (entry.changeLog != null && entry.changeLog!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      appSource.changeLogIfAnyIsMarkDown
                          ? MarkdownBody(
                              data: entry.changeLog!,
                              styleSheet: MarkdownStyleSheet(
                                p: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                listBullet: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                ),
                                h1: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                h3: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTapLink: (text, href, title) {
                                if (href != null) {
                                  launchUrlString(
                                    href.startsWith('http://') || href.startsWith('https://')
                                        ? href
                                        : '${Uri.parse(app.url).origin}/$href',
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              extensionSet: md.ExtensionSet(
                                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                                [
                                  md.EmojiSyntax(),
                                  ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                                ],
                              ),
                            )
                          : Text(
                              entry.changeLog!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[local.month - 1]} ${local.year}';
  }
}
