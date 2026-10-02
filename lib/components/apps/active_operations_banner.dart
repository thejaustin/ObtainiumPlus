import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
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
    final plusSettings = context.watch<PlusSettingsProvider>();

    final bool isCheckingUpdates =
        appsProvider.gettingUpdates || appsProvider.checkingUpdateIds.isNotEmpty;
    final List<AppInMemory> activeDownloads = appsProvider.apps.values
        .where((e) => e.downloadProgress != null)
        .toList();

    final bool isActive = isCheckingUpdates || activeDownloads.isNotEmpty;
    final bool animationsEnabled = plusSettings.plusEnableEnhancedAnimations;
    final bool glassEnabled = plusSettings.plusEnableGlassmorphism;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final innerRadius = CardMetrics.inner(radius);
    final colorScheme = Theme.of(context).colorScheme;

    // Outer AnimatedSize animates the banner sliding in/out of the list
    return AnimatedSize(
      duration: Duration(milliseconds: animationsEnabled ? 380 : 0),
      curve: Easing.emphasizedDecelerate,
      child: !isActive
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                  side: BorderSide(
                    color: glassEnabled
                        ? colorScheme.onSurface
                            .withValues(alpha: AppConstants.glassBorderAlpha)
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                color: glassEnabled
                    ? colorScheme.surface
                        .withValues(alpha: AppConstants.glassSurfaceAlpha)
                    : colorScheme.surfaceContainerLow,
                child: Stack(
                  children: [
                    // Glass blur layer
                    if (glassEnabled)
                      Positioned.fill(
                        child: ConditionalBlur(
                          enabled: true,
                          sigma: AppConstants.glassBlurSigmaSoft,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    // Glass sheen gradient
                    if (glassEnabled)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      Colors.white.withValues(alpha: 0.07),
                                      Colors.white.withValues(alpha: 0.02),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.03),
                                    ]
                                  : [
                                      Colors.white.withValues(alpha: 0.32),
                                      Colors.white.withValues(alpha: 0.08),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.02),
                                    ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    // Content (AnimatedSize handles tile count changes)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: AnimatedSize(
                        duration: Duration(
                          milliseconds: animationsEnabled ? 300 : 0,
                        ),
                        curve: Easing.emphasizedDecelerate,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                  ValueListenableBuilder<double?>(
                                    valueListenable:
                                        appsProvider.refreshProgress,
                                    builder: (context, progress, _) {
                                      if (progress == null || progress <= 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        '${(progress * 100).toInt()}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
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
                                    value:
                                        (progress != null && progress > 0)
                                            ? progress
                                            : null,
                                    height: 4,
                                  );
                                },
                              ),
                              if (activeDownloads.isNotEmpty)
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 10.0),
                                  child: Divider(height: 1),
                                ),
                            ],

                            // Active Downloads & Finishing Installations
                            for (int i = 0;
                                i < activeDownloads.length;
                                i++) ...[
                              if (i > 0)
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(height: 1),
                                ),
                              _ActiveDownloadTile(
                                appInMemory: activeDownloads[i],
                                innerRadius: innerRadius,
                                onCancel: () {
                                  AppHaptics.selectionClick();
                                  appsProvider.cancelDownload(
                                    activeDownloads[i].app.id,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
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

        final speedStr = formatSpeed(appInMemory.downloadSpeedBytesPerSec);
        final sizeStr = formatDownloadSize(
          appInMemory.downloadReceivedBytes,
          appInMemory.downloadTotalBytes,
        );
        final remainingBytes =
            (appInMemory.downloadTotalBytes != null &&
                    appInMemory.downloadReceivedBytes != null)
                ? appInMemory.downloadTotalBytes! -
                    appInMemory.downloadReceivedBytes!
                : null;
        final etaStr = formatEta(
          remainingBytes,
          appInMemory.downloadSpeedBytesPerSec,
        );

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
                          isFinishingOrInstalling
                              ? Icons.install_mobile_rounded
                              : Icons.downloading_rounded,
                          size: 20,
                          color: isFinishingOrInstalling
                              ? colorScheme.secondary
                              : colorScheme.primary,
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
                      Row(
                        children: [
                          if (isFinishingOrInstalling) ...[
                            SizedBox(
                              width: 11,
                              height: 11,
                              child: ExpressiveCircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tr('installing'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ] else if (downloadProgress != null &&
                              downloadProgress >= 0) ...[
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 13,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                [
                                  '${downloadProgress.toInt()}%',
                                  if (speedStr != null) speedStr,
                                  if (sizeStr != null) sizeStr,
                                  if (etaStr != null) '$etaStr left',
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              tr('pleaseWait'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isFinishingOrInstalling)
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
