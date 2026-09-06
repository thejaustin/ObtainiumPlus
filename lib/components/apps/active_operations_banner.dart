import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// A Material 3 Expressive banner displaying live in-flight background operations
/// (e.g. batch update checks, active app downloads, finishing installations)
/// with squiggly/wavy progress indicators, eliminating reliance solely on notification center.
class ActiveOperationsBanner extends StatelessWidget {
  const ActiveOperationsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final settings = context.watch<SettingsProvider>();

    final bool isCheckingUpdates =
        appsProvider.gettingUpdates || appsProvider.checkingUpdateIds.isNotEmpty;
    final List<AppInMemory> activeDownloads = appsProvider.apps.values
        .where((e) => e.downloadProgress != null)
        .toList();

    if (!isCheckingUpdates && activeDownloads.isEmpty) {
      return const SizedBox.shrink();
    }

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final innerRadius = CardMetrics.inner(radius);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Easing.emphasizedDecelerate,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // In-Flight Update Checks
                if (isCheckingUpdates) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: ExpressiveCircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('checkingForUpdates'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ),
                      ValueListenableBuilder<double?>(
                        valueListenable: appsProvider.refreshProgress,
                        builder: (context, progress, _) {
                          if (progress == null || progress <= 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${(progress * 100).toInt()}%',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<double?>(
                    valueListenable: appsProvider.refreshProgress,
                    builder: (context, progress, _) {
                      return ExpressiveProgressIndicator(
                        value: (progress != null && progress > 0) ? progress : null,
                        height: 4,
                      );
                    },
                  ),
                  if (activeDownloads.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(height: 1),
                    ),
                ],

                // Active Downloads & Finishing Installations
                for (int i = 0; i < activeDownloads.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                  _ActiveDownloadTile(
                    appInMemory: activeDownloads[i],
                    innerRadius: innerRadius,
                    onCancel: () {
                      AppHaptics.selectionClick();
                      appsProvider.cancelDownload(activeDownloads[i].app.id);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveDownloadTile extends StatelessWidget {
  final AppInMemory appInMemory;
  final double innerRadius;
  final VoidCallback onCancel;

  const _ActiveDownloadTile({
    required this.appInMemory,
    required this.innerRadius,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<double?>(
      valueListenable: appInMemory.downloadProgressNotifier,
      builder: (context, downloadProgress, _) {
        final bool isFinishingOrInstalling =
            downloadProgress != null && downloadProgress < 0;
        final double? progressFraction =
            (downloadProgress != null && downloadProgress >= 0)
                ? (downloadProgress / 100.0).clamp(0.0, 1.0)
                : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(innerRadius),
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                  child: appInMemory.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(innerRadius),
                          child: Image.memory(
                            appInMemory.icon!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.downloading_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appInMemory.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        isFinishingOrInstalling
                            ? tr('installing')
                            : downloadProgress != null && downloadProgress >= 0
                                ? '${downloadProgress.toInt()}%'
                                : tr('pleaseWait'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: tr('cancel'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onCancel,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpressiveProgressIndicator(
              value: progressFraction,
              height: 4,
            ),
          ],
        );
      },
    );
  }
}
