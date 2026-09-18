import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'dart:ui';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

class AppListTile extends StatelessWidget {
  final AppInMemory appInMemory;
  final bool hasUpdate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowChanges;
  final Color? categoryColor;

  const AppListTile({
    super.key,
    required this.appInMemory,
    this.hasUpdate = false,
    this.onTap,
    this.onLongPress,
    this.onShowChanges,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.read<AppsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final viewSettings = context.watch<ViewSettingsProvider>();
    final isSelected = context.select<AppsProvider, bool>(
      (p) => p.selectedAppIds.contains(appInMemory.app.id),
    );
    final isCheckingUpdate = context.select<AppsProvider, bool>(
      (p) => p.checkingUpdateIds.contains(appInMemory.app.id),
    );

    final isAmbiguous =
        hasUpdate &&
        appInMemory.app.additionalSettings['isAmbiguousUpdate'] == true;

    Widget getUpdateButton() {
      if (isCheckingUpdate) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: ExpressiveCircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      if (isAmbiguous) {
        return IconButton.filled(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () {
            AppHaptics.heavyImpact();
            showDialog(
              context: context,
              builder: (ctx) => GlassDialog(
                icon: Icons.help_outline_rounded,
                title: tr('ambiguousUpdateTitle'),
                content: Text(
                  tr(
                    'ambiguousUpdateMessage',
                    args: [
                      appInMemory.app.latestVersion,
                      appInMemory.app.installedVersion ?? '',
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      appInMemory.app.installedVersion =
                          appInMemory.app.latestVersion;
                      appsProvider.saveApps([appInMemory.app]);
                      Navigator.pop(ctx);
                    },
                    child: Text(tr('markAsSame')),
                  ),
                  FilledButton(
                    onPressed: () {
                      appsProvider.downloadAndInstallLatestApps([
                        appInMemory.app.id,
                      ], context);
                      Navigator.pop(ctx);
                    },
                    child: Text(tr('installAnyway')),
                  ),
                ],
              ),
            );
          },
          tooltip: tr('ambiguousUpdate'),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        );
      }
      return ScaleTouchWrapper(
        child: IconButton.filled(
          icon: const Icon(Icons.download_rounded),
          onPressed: () {
            AppHaptics.selectionClick();
            appsProvider.downloadAndInstallLatestApps([
              appInMemory.app.id,
            ], context);
          },
          tooltip: tr('installUpdate'),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      );
    }

    String getVersionText() {
      if (appInMemory.app.installedVersion == null) return tr('notInstalled');
      if (hasUpdate)
        return '${appInMemory.app.installedVersion} → ${appInMemory.app.latestVersion}';
      return appInMemory.app.installedVersion!;
    }

    Widget getAppIcon() {
      final itemRadius = CardMetrics.inner(
        plusSettings.plusOverrideIndividualCornerRadius
            ? plusSettings.plusHomeCornerRadius
            : plusSettings.plusGlobalCornerRadius,
      );

      return Hero(
        tag: 'icon_${appInMemory.app.id}',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(itemRadius),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            boxShadow: AppShadows.smooth(
              color: Colors.black,
              opacity: 0.08,
              blurFactor: 0.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: appInMemory.icon != null
                ? ClipRRect(
                    key: ValueKey('icon_${appInMemory.app.id}'),
                    borderRadius: BorderRadius.circular(itemRadius),
                    child: Image.memory(
                      appInMemory.icon!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                : Icon(
                    key: const ValueKey('placeholder'),
                    Icons.apps_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
          ),
        ),
      );
    }

    Widget getSourceBadge() {
      final url = appInMemory.app.url.toLowerCase();
      IconData iconData = Icons.link_rounded;
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      Color brandColor = colorScheme.primary;
      if (url.contains('github.com')) {
        iconData = Icons.terminal_rounded;
        brandColor = const Color(0xFF24292E);
      } else if (url.contains('f-droid.org')) {
        iconData = Icons.android_rounded;
        brandColor = const Color(0xFF1976D2);
      } else if (url.contains('gitlab.com')) {
        iconData = Icons.account_tree_rounded;
        brandColor = const Color(0xFFFC6D26);
      } else if (url.contains('codeberg.org')) {
        iconData = Icons.code_rounded;
        brandColor = const Color(0xFF2185D0);
      }

      // Use theme primary in dark mode so raw dark brand hex (#24292E) stays visible
      final color = isDark ? colorScheme.primary.withValues(alpha: 0.85) : brandColor;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Icon(iconData, size: 10, color: color),
      );
    }

    final Color? displayCategoryColor =
        categoryColor ??
        (appInMemory.app.categories.isNotEmpty &&
                viewSettings.categoryIconPosition !=
                    CategoryIconPosition.disabled
            ? viewSettings.categories[appInMemory.app.categories.first] != null
                  ? Color(
                      viewSettings.categories[appInMemory
                          .app
                          .categories
                          .first]!,
                    )
                  : null
            : null);

    final isCompact = viewSettings.appListDensity == AppListDensity.compact;
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;

    final trailingRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onShowChanges != null && hasUpdate)
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: onShowChanges,
            tooltip: tr('viewChanges'),
          ),
        if (hasUpdate) getUpdateButton(),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          onSelected: (value) {
            AppHaptics.selectionClick();
            switch (value) {
              case 'togglePin':
                appInMemory.app.pinned = !appInMemory.app.pinned;
                appsProvider.saveApps([appInMemory.app]);
                break;
              case 'settings':
                appsProvider.openAppSettings(appInMemory.app.id);
                break;
              case 'copyUrl':
                Clipboard.setData(ClipboardData(text: appInMemory.app.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('copiedToClipboard'))),
                );
                break;
              case 'share':
                Share.share(appInMemory.app.url);
                break;
              case 'remove':
                appsProvider.removeAppsWithModal(context, [appInMemory.app]);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'togglePin',
              child: ListTile(
                leading: Icon(
                  appInMemory.app.pinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                ),
                title: Text(appInMemory.app.pinned ? tr('unpin') : tr('pin')),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(tr('settings')),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'copyUrl',
              child: ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(tr('copyAppURL')),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(Icons.share_rounded),
                title: Text(tr('share')),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  tr('remove'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );

    // --- MODERN UI ---
    return RepaintBoundary(
      child: Semantics(
        label:
            '${appInMemory.name}${viewSettings.displayShowAuthor ? ' ${tr('byX', args: [appInMemory.author])}' : ''}. ${hasUpdate ? tr('updateAvailable') : ''} ${appInMemory.app.installedVersion ?? tr('notInstalled')}',
        button: true,
        onTap: onTap,
        onLongPress: onLongPress,
        child: ScaleTouchWrapper(
          onTap: onTap,
          onLongPress: onLongPress,
          scaleDownFactor: 0.98,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 4 : 8,
              vertical: isCompact ? 2 : 6,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onLongPress: onLongPress,
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: AnimatedContainer(
                  duration: Duration(
                    milliseconds: plusSettings.plusEnableEnhancedAnimations
                        ? 250
                        : 0,
                  ),
                  curve: AppConstants.expressiveStandard,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.7)
                        : hasUpdate
                        ? Theme.of(context).colorScheme.secondaryContainer
                              .withValues(
                                alpha: plusSettings.plusEnableGlassmorphism
                                    ? 0.35
                                    : (isCompact ? 0.15 : 0.25),
                              )
                        : appInMemory.app.pinned
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                              .withValues(
                                alpha: plusSettings.plusEnableGlassmorphism
                                    ? 0.45
                                    : AppOpacity.moderate,
                              )
                        : plusSettings.plusEnableGlassmorphism
                        ? Theme.of(context).colorScheme.surface.withValues(
                            alpha: AppConstants.glassSurfaceAlpha,
                          )
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : hasUpdate
                          ? Theme.of(context).colorScheme.secondary.withValues(
                              alpha: 0.45,
                            )
                          : appInMemory.app.pinned
                          ? Theme.of(context).colorScheme.outlineVariant
                          : plusSettings.plusEnableGlassmorphism
                          ? Theme.of(context).colorScheme.onSurface.withValues(
                              alpha: AppConstants.glassBorderAlpha,
                            )
                          : Theme.of(context).colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                      width:
                          isSelected ||
                              appInMemory.app.pinned ||
                              (hasUpdate && !isCompact)
                          ? 1.5
                          : 1.0,
                    ),
                    boxShadow: isSelected
                        ? AppShadows.glow(
                            color: Theme.of(context).colorScheme.primary,
                            intensity: 0.6,
                          )
                        : hasUpdate && !isCompact
                        ? AppShadows.smooth(
                            color: Theme.of(context).colorScheme.secondary,
                            opacity: 0.08,
                          )
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      children: [
                        if (plusSettings.plusEnableGlassmorphism)
                          Positioned.fill(
                            child: ConditionalBlur(
                              enabled: true,
                              sigma: AppConstants.glassBlurSigma,
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        if (plusSettings.plusEnableGlassmorphism)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? [
                                          Colors.white.withValues(alpha: 0.08),
                                          Colors.white.withValues(alpha: 0.02),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.04),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.35),
                                          Colors.white.withValues(alpha: 0.10),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.02),
                                        ],
                                  stops: const [0.0, 0.3, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),

                        if (plusSettings.plusEnableGlassmorphism)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1.0,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        if (displayCategoryColor != null)
                          Positioned(
                            left: 0,
                            top: 14,
                            bottom: 14,
                            child: Container(
                              width: 5,
                              decoration: BoxDecoration(
                                color: displayCategoryColor,
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),


                        ListTile(
                          visualDensity: isCompact
                              ? VisualDensity.compact
                              : VisualDensity.standard,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 12 : 18,
                            vertical: isCompact ? 0 : 6,
                          ),
                          dense: isCompact,
                          leading: Padding(
                            padding: EdgeInsets.only(
                              left: displayCategoryColor != null ? 6 : 0,
                            ),
                            child: Transform.scale(
                              scale: isCompact ? 0.9 : 1.0,
                              child: getAppIcon(),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  appInMemory.name,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight:
                                            appInMemory.app.pinned || hasUpdate
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              getSourceBadge(),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              if (plusSettings.plusShowTagsInList &&
                                  appInMemory.app.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: appInMemory.app.tags
                                        .take(2)
                                        .map(
                                          (tag) => Container(
                                            margin: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer
                                                  .withValues(alpha: 0.35),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withValues(alpha: 0.18),
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              tag,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.1,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSecondaryContainer
                                                        .withValues(alpha: 0.85),
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              if (viewSettings.displayShowAuthor)
                                Expanded(
                                  child: Text(
                                    appInMemory.author,
                                    maxLines: 1,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          overflow: TextOverflow.ellipsis,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              if (viewSettings.displayShowVersion && !isCompact)
                                hasUpdate
                                    ? _buildVersionUpdatePill(
                                        context,
                                        appInMemory.app.installedVersion ?? '?',
                                        appInMemory.app.latestVersion ?? '?',
                                      )
                                    : Text(
                                        ' • ${getVersionText()}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color: null,
                                          fontStyle:
                                              SourceUtils.isVersionPseudo(
                                                appInMemory.app,
                                              )
                                              ? FontStyle.italic
                                              : null,
                                        ),
                                      ),
                            ],
                          ),
                          trailing: ValueListenableBuilder<double?>(
                            valueListenable:
                                appInMemory.downloadProgressNotifier,
                            builder: (context, downloadProgress, child) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: downloadProgress != null
                                    ? SizedBox(
                                        key: const ValueKey('download'),
                                        width: downloadProgress >= 0
                                            ? (appInMemory.downloadSpeedBytesPerSec != null
                                                ? 114.0
                                                : 96.0)
                                            : 70.0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Builder(
                                                      builder: (context) {
                                                        if (downloadProgress < 0) {
                                                          return Text(
                                                            tr('installing'),
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                ),
                                                          );
                                                        }
                                                        final speed = formatSpeed(
                                                          appInMemory
                                                              .downloadSpeedBytesPerSec,
                                                        );
                                                        final label = speed != null
                                                            ? '${downloadProgress.toInt()}% • $speed'
                                                            : '${downloadProgress.toInt()}%';
                                                        return Text(
                                                          label,
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight.bold,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ExpressiveProgressIndicator(
                                                    value: downloadProgress >= 0
                                                        ? downloadProgress / 100
                                                        : null,
                                                    height: 5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (downloadProgress >= 0) ...[
                                              const SizedBox(width: 4),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 24,
                                                  minHeight: 24,
                                                ),
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                ),
                                                tooltip: tr('cancel'),
                                                onPressed: () {
                                                  context
                                                      .read<AppsProvider>()
                                                      .cancelDownload(
                                                        appInMemory.app.id,
                                                      );
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      )
                                    : KeyedSubtree(
                                        key: const ValueKey('info'),
                                        child: trailingRow,
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact pill widget showing the version transition when an update is available.
  Widget _buildVersionUpdatePill(
    BuildContext context,
    String inst,
    String latest,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.28),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              size: 8,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 3),
            Text(
              '$inst → $latest',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colorScheme.secondary,
                fontFamily: 'monospace',
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
