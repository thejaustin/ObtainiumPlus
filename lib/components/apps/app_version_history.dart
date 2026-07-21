import 'package:flutter/material.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/version_history_entry.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:markdown/markdown.dart' as md;
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

    final appSource = SourceProvider().getSource(
      app.url,
      overrideSource: app.overrideSource,
    );

    return ExpansionTile(
      title: const Text('Version History'),
      children: app.versionHistory
          .map((entry) => _buildEntry(context, entry, appSource))
          .toList(),
    );
  }

  Widget _buildEntry(
    BuildContext context,
    VersionHistoryEntry entry,
    AppSource appSource,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.version,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (entry.releaseDate != null)
                    Text(
                      entry.releaseDate!.toLocal().toString().split('.').first,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (entry.changeLog != null && entry.changeLog!.isNotEmpty)
                    appSource.changeLogIfAnyIsMarkDown
                        ? MarkdownBody(
                            data: entry.changeLog!,
                            onTapLink: (text, href, title) {
                              if (href != null) {
                                launchUrlString(
                                  href.startsWith('http://') ||
                                          href.startsWith('https://')
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
                                ...md
                                    .ExtensionSet
                                    .gitHubFlavored
                                    .inlineSyntaxes,
                              ],
                            ),
                          )
                        : Text(entry.changeLog!),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
