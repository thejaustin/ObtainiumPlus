import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';

/// A Material 3 Expressive banner displaying live in-flight background operations
/// (e.g. batch update checks, active app downloads, finishing installations)
/// with squiggly/wavy progress indicators, eliminating reliance solely on notification center.
class ActiveOperationsBanner extends StatelessWidget {
  const ActiveOperationsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();

    // Single-app checks are already shown by the per-tile spinner.
    final bool isCheckingUpdates = appsProvider.gettingUpdates;
    final List<AppInMemory> activeDownloads = appsProvider.apps.values
        .where((e) => e.downloadProgress != null)
        .toList();

    final bool isActive = isCheckingUpdates || activeDownloads.isNotEmpty;
    final bool animationsEnabled = plusSettings.plusEnableEnhancedAnimations;
    final bool glassEnabled = plusSettings.plusEnableGlassmorphism;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
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
                shape: CardMetrics.shape(
                  CardMetrics.card(radius),
                  expressive: plusSettings.plusEnableMaterialExpressive,
                  side: BorderSide(
                    color: glassEnabled
                        ? colorScheme.primary.withValues(alpha: 0.22)
                        : colorScheme.primary.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                color: glassEnabled
                    ? colorScheme.surface.withValues(
                        alpha: AppConstants.glassSurfaceAlpha,
                      )
                    : colorScheme.primaryContainer.withValues(alpha: 0.10),
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
                              _UpdateCheckProgress(
                                appsProvider: appsProvider,
                                animate:
                                    animationsEnabled &&
                                    !MediaQuery.disableAnimationsOf(context),
                              ),
                              if (activeDownloads.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Divider(height: 1),
                                ),
                            ],

                            // Active Downloads & Finishing Installations
                            if (activeDownloads.length > 2) ...[
                              _BulkSummaryRow(
                                total: activeDownloads.length,
                                bulkTotal: appsProvider.bulkUpdateTotal,
                                bulkDone: appsProvider.bulkUpdateDone,
                                onCancelAll: () {
                                  AppHaptics.selectionClick();
                                  appsProvider.cancelAllDownloads();
                                },
                                fraction: () {
                                  double sum = 0;
                                  for (final d in activeDownloads) {
                                    final p = d.downloadProgress;
                                    sum += (p == null || p < 0)
                                        ? 1.0
                                        : (p / 100.0).clamp(0.0, 1.0);
                                  }
                                  return sum / activeDownloads.length;
                                }(),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Divider(height: 1),
                              ),
                            ],
                            for (
                              int i = 0;
                              i < activeDownloads.length && i < 2;
                              i++
                            ) ...[
                              if (i > 0)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(height: 1),
                                ),
                              ScaleTouchWrapper(
                                hapticOnPressDown: true,
                                scaleDownFactor: 0.98,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    innerRadius,
                                  ),
                                  onTap: () {
                                    AppHaptics.selectionClick();
                                    final appId = activeDownloads[i].app.id;
                                    showAdaptiveDetailSheet(
                                      context: context,
                                      builder: (context, controller) => AppPage(
                                        appId: appId,
                                        isModal: true,
                                        scrollController: controller,
                                      ),
                                    );
                                  },
                                  child: _ActiveDownloadTile(
                                    appInMemory: activeDownloads[i],
                                    innerRadius: innerRadius,
                                    onCancel: () {
                                      AppHaptics.selectionClick();
                                      appsProvider.cancelDownload(
                                        activeDownloads[i].app.id,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                            if (activeDownloads.length > 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  tr(
                                    'activeMoreCount',
                                    args: [
                                      (activeDownloads.length - 2).toString(),
                                    ],
                                  ),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
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

/// Batch update-check header: count, a pill tallying updates found so far,
/// and the progress bar. Progress arrives in per-app steps; tweening it keeps
/// the bar and counter gliding instead of jumping as each check finishes.
class _UpdateCheckProgress extends StatelessWidget {
  final AppsProvider appsProvider;
  final bool animate;

  const _UpdateCheckProgress({
    required this.appsProvider,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = Duration(milliseconds: animate ? 450 : 0);
    return ListenableBuilder(
      listenable: Listenable.merge([
        appsProvider.refreshProgress,
        appsProvider.refreshTotal,
        appsProvider.refreshFound,
      ]),
      builder: (context, _) {
        final progress = appsProvider.refreshProgress.value;
        final total = appsProvider.refreshTotal.value;
        final found = appsProvider.refreshFound.value;
        final determinate = progress != null && progress > 0;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: determinate ? progress : 0.0),
          duration: duration,
          curve: Easing.emphasizedDecelerate,
          builder: (context, shown, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (determinate)
                      Text(
                        total > 0
                            ? '${(shown * total).round()} / $total'
                            : '${(shown * 100).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          // Fixed-width digits so the counter doesn't jitter.
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: Easing.emphasizedDecelerate,
                  switchOutCurve: Easing.emphasizedAccelerate,
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.9,
                          end: 1,
                        ).animate(animation),
                        alignment: Alignment.centerLeft,
                        child: child,
                      ),
                    ),
                  ),
                  child: found > 0
                      ? Padding(
                          key: const ValueKey('found'),
                          padding: const EdgeInsets.only(top: 8),
                          child: _FoundUpdatesPill(count: found),
                        )
                      : const SizedBox(key: ValueKey('none'), width: 0),
                ),
                const SizedBox(height: 10),
                ExpressiveProgressIndicator(
                  value: determinate ? shown : null,
                  height: 4,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FoundUpdatesPill extends StatelessWidget {
  final int count;

  const _FoundUpdatesPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: colorScheme.secondaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upgrade_rounded,
              size: 14,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              plural('updatesFound', count),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSecondaryContainer,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
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
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: appInMemory.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(innerRadius),
                          child: Image.memory(
                            appInMemory.icon!,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            cacheWidth:
                                (34 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            cacheHeight:
                                (34 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
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
                            Flexible(
                              child: Text(
                                () {
                                  final total = appInMemory.downloadTotalBytes;
                                  return total != null && total > 0
                                      ? '${tr('installing')} · ${formatBytes(total)}'
                                      : tr('installing');
                                }(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              tr('pleaseWait'),
                              style: Theme.of(context).textTheme.bodySmall
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
            ExpressiveProgressIndicator(value: progressFraction, height: 4),
          ],
        );
      },
    );
  }
}

/// Aggregate row shown when many apps are updating at once.
class _BulkSummaryRow extends StatelessWidget {
  final int total;
  final double fraction;
  final int bulkTotal;
  final int bulkDone;
  final VoidCallback onCancelAll;

  const _BulkSummaryRow({
    required this.total,
    required this.fraction,
    required this.bulkTotal,
    required this.bulkDone,
    required this.onCancelAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.downloading_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bulkTotal > 0
                    ? tr(
                        'bulkUpdatingApps',
                        args: [bulkTotal.toString(), bulkDone.toString()],
                      )
                    : plural('apps', total),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${(fraction * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Whole apps finishing move the aggregate in big steps; glide them.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: fraction),
          duration: Duration(
            milliseconds:
                context.select<PlusSettingsProvider, bool>(
                      (p) => p.plusEnableEnhancedAnimations,
                    ) &&
                    !MediaQuery.disableAnimationsOf(context)
                ? 450
                : 0,
          ),
          curve: Easing.emphasizedDecelerate,
          builder: (context, shown, _) =>
              ExpressiveProgressIndicator(value: shown, height: 4),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onCancelAll,
            child: Text(tr('cancelAll')),
          ),
        ),
      ],
    );
  }
}
