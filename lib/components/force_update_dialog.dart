import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/main.dart' show globalNavigatorKey;
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/known_issues_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/core/logging/app_logger.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// A skippable "recommended update" dialog pushed via [KnownIssue.forceUpdate].
/// The user can tap "Update Now" to trigger the in-app updater (or view the releases
/// page in browser), or "Skip" (with an optional "don't show again" toggle) to defer.
class ForceUpdateDialog extends StatefulWidget {
  const ForceUpdateDialog({super.key, required this.issue});

  final KnownIssue issue;

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _dontShowAgain = false;
  bool _isUpdating = false;

  Future<void> _handleUpdate() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    final scaffoldContext = globalNavigatorKey.currentContext ?? context;
    try {
      final appsProvider = context.read<AppsProvider>();
      // Ensure Obtainium is registered in appsProvider
      if (!appsProvider.apps.containsKey(obtainiumId)) {
        final info = await AppInstallService.getInstalledInfo(
          obtainiumId,
          printErr: false,
        );
        final currentVersion = info?.versionName ?? '1.7.1';
        final obtApp = App(
          obtainiumId,
          obtainiumUrl,
          'thejaustin',
          'Obtainium+',
          currentVersion,
          currentVersion,
          [],
          0,
          {
            'versionDetection': true,
            'apkFilterRegEx': 'fdroid',
            'invertAPKFilter': true,
          },
          null,
          false,
        );
        await appsProvider.saveApps([obtApp]);
      }

      // Check update for Obtainium to fetch latest release metadata
      await appsProvider
          .checkUpdates(
            specificIds: [obtainiumId],
            ignoreAppsCheckedAfter: DateTime.now(),
          )
          .catchError((_) => <App>[]);

      if (!mounted) return;

      // Close dialog and let the in-app downloader run
      Navigator.of(context).pop();
      showMessage(tr('downloadingX', args: ['Obtainium+']), scaffoldContext);

      // Trigger download and install in-app
      await appsProvider.downloadAndInstallLatestApps(
        [obtainiumId],
        scaffoldContext,
      );
    } catch (e) {
      AppLogger.error(e, message: 'In-app update failed, opening releases page');
      if (mounted) {
        setState(() => _isUpdating = false);
      }
      await _openReleasesPage();
    }
  }

  Future<void> _openReleasesPage() async {
    final uri = Uri.parse(widget.issue.githubIssueUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      AppLogger.error(e, message: 'Could not open releases URL: $uri');
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
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: enableGlass
              ? colorScheme.surface.withValues(alpha: 0.78)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enableGlass
                ? colorScheme.onSurface.withValues(alpha: 0.18)
                : colorScheme.outline.withValues(alpha: AppOpacity.subtle),
          ),
          boxShadow: AppShadows.smooth(
            color: Colors.black,
            opacity: enableGlass ? 0.28 : 0.1,
            blurFactor: enableGlass ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ConditionalBlur(
            sigma: 24,
            enabled: enableGlass,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(
                          alpha: enableGlass ? 0.3 : 0.5,
                        ),
                        colorScheme.primaryContainer.withValues(
                          alpha: enableGlass ? 0.15 : 0.25,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: AppOpacity.low,
                          ),
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (widget.issue.fixedInVersion != null)
                              Text(
                                tr(
                                  'fixedIn',
                                  args: [widget.issue.fixedInVersion!],
                                ),
                                style: Theme.of(context).textTheme.bodySmall
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
                        style: Theme.of(context).textTheme.titleMedium
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
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
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: AppOpacity.medium,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ScaleTouchWrapper(
                        hapticOnPressDown: true,
                        scaleDownFactor: 0.94,
                        child: TextButton(
                          onPressed: _isUpdating ? null : _skip,
                          child: Text(tr('skip')),
                        ),
                      ),
                      const Spacer(),
                      ScaleTouchWrapper(
                        hapticOnPressDown: true,
                        scaleDownFactor: 0.94,
                        child: IconButton.outlined(
                          tooltip: tr('openReleasePage'),
                          onPressed: _openReleasesPage,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ScaleTouchWrapper(
                        hapticOnPressDown: true,
                        scaleDownFactor: 0.94,
                        child: FilledButton.icon(
                          onPressed: _isUpdating ? null : _handleUpdate,
                          icon: _isUpdating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: ExpressiveCircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            _isUpdating ? tr('loading') : tr('update'),
                          ),
                        ),
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
