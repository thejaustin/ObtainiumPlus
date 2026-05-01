import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/known_issues_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// A skippable "recommended update" dialog pushed via [KnownIssue.forceUpdate].
/// The user can tap "Update Now" to open the releases page, or "Skip" (with an
/// optional "don't show again" toggle) to defer until the next launch.
class ForceUpdateDialog extends StatefulWidget {
  const ForceUpdateDialog({super.key, required this.issue});

  final KnownIssue issue;

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _dontShowAgain = false;

  Future<void> _openReleasesPage() async {
    final uri = Uri.parse(widget.issue.githubIssueUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _skip() async {
    if (_dontShowAgain) {
      await KnownIssuesService.dismissIssue(widget.issue.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(enableGlass ? 0.78 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enableGlass
                ? colorScheme.onSurface.withOpacity(0.18)
                : colorScheme.outline.withOpacity(AppOpacity.subtle),
          ),
          boxShadow: AppShadows.smooth(
            color: Colors.black,
            opacity: enableGlass ? 0.28 : 0.1,
            blurFactor: enableGlass ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ConditionalBlur(sigma: 24, enabled: enableGlass, child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer
                            .withOpacity(enableGlass ? 0.3 : 0.5),
                        colorScheme.primaryContainer
                            .withOpacity(enableGlass ? 0.15 : 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(AppOpacity.low),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.system_update_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('updateRecommended'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (widget.issue.fixedInVersion != null)
                              Text(
                                '${tr('fixedIn')} ${widget.issue.fixedInVersion}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.issue.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.issue.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),

                // Don't show again toggle
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  child: CheckboxListTile.adaptive(
                    value: _dontShowAgain,
                    onChanged: (v) =>
                        setState(() => _dontShowAgain = v ?? false),
                    title: Text(
                      tr('dontShowAgain'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withOpacity(AppOpacity.medium),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _skip,
                        child: Text(tr('skip')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _openReleasesPage,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: Text(tr('update')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
