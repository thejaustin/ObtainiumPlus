import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'dart:ui';

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
        hasUpdate && appInMemory.app.additionalSettings['isAmbiguousUpdate'] == true;

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
              builder: (ctx) => AlertDialog(
                title: Text(tr('ambiguousUpdateTitle')),
                content: Text(
                  tr(
                    'ambiguousUpdateMessage',
                    args: [
                      appInMemory.app.installedVersion ?? '',
                      appInMemory.app.latestVersion,
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
      return IconButton.filled(
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
      );
    }

    String getVersionText() {
      if (appInMemory.app.installedVersion == null) return tr('notInstalled');
      if (hasUpdate)
        return '${appInMemory.app.installedVersion} → ${appInMemory.app.latestVersion}';
      return appInMemory.app.installedVersion!;
    }

    Widget getAppIcon() {
      final itemRadius =
          (plusSettings.plusOverrideIndividualCornerRadius
              ? plusSettings.plusHomeCornerRadius
              : plusSettings.plusGlobalCornerRadius) *
          0.5;

      return Hero(
        tag: 'icon_${appInMemory.app.id}',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(itemRadius),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          child: appInMemory.icon != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(itemRadius),
                  child: Image.memory(appInMemory.icon!, fit: BoxFit.cover),
                )
              : Icon(
                  Icons.apps_rounded,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
        ),
      );
    }

    final Color? displayCategoryColor =
        categoryColor ??
        (appInMemory.app.categories.isNotEmpty &&
                viewSettings.categoryIconPosition !=
                    CategoryIconPosition.disabled
            ? viewSettings.categories[appInMemory
                          .app
                          .categories
                          .first] !=
                      null
                  ? Color(
                      viewSettings.categories[appInMemory
                          .app
                          .categories
                          .first]!,
                    )
                  : null
            : null);

    final isCompact =
        viewSettings.appListDensity == AppListDensity.compact;
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
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
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
                title: Text(
                  appInMemory.app.pinned ? tr('unpin') : tr('pin'),
                ),
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
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 8,
            vertical: isCompact ? 2 : 6,
          ),
          child: ConditionalBlur(
            enabled: plusSettings.plusEnableGlassmorphism,
            sigma: 12,
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
                          ).colorScheme.primaryContainer.withOpacity(0.7)
                        : hasUpdate
                        ? Theme.of(context).colorScheme.secondaryContainer
                              .withOpacity(isCompact ? 0.1 : 0.2)
                        : appInMemory.app.pinned
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                              .withOpacity(AppOpacity.moderate)
                        : Theme.of(context).colorScheme.surface.withOpacity(
                            plusSettings.plusEnableGlassmorphism
                                ? 0.45
                                : 1.0,
                          ),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : hasUpdate
                          ? Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(AppOpacity.hint)
                          : appInMemory.app.pinned
                          ? Theme.of(context).colorScheme.outlineVariant
                          : Theme.of(context).colorScheme.outline.withOpacity(
                              plusSettings.plusEnableGlassmorphism
                                  ? 0.1
                                  : 0,
                            ),
                      width:
                          isSelected ||
                              appInMemory.app.pinned ||
                              (hasUpdate && !isCompact)
                          ? 1.5
                          : 0.8,
                    ),
                    boxShadow: isSelected
                        ? AppShadows.glow(
                            color: Theme.of(context).colorScheme.primary,
                            intensity: 0.6,
                          )
                        : hasUpdate && !isCompact
                        ? AppShadows.smooth(
                            color: Theme.of(context).colorScheme.secondary,
                            opacity: 0.1,
                          )
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      children: [
                        if (plusSettings.plusEnableGlassmorphism)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.02),
                                  ],
                                  stops: const [0.0, 0.4, 1.0],
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
                          title: Text(
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
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer
                                                  .withOpacity(0.4),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tag,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
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
                                              .withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              if (viewSettings.displayShowVersion &&
                                  !isCompact)
                                Text(
                                  ' • ${getVersionText()}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: hasUpdate
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondary
                                            : null,
                                        fontWeight: hasUpdate
                                            ? FontWeight.bold
                                            : null,
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
                          trailing: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: appInMemory.downloadProgress != null
                                ? SizedBox(
                                    key: const ValueKey('download'),
                                    width: 65,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          appInMemory.downloadProgress! >= 0
                                              ? '${appInMemory.downloadProgress!.toInt()}%'
                                              : tr('installing'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        ExpressiveProgressIndicator(
                                          value:
                                              appInMemory.downloadProgress! >= 0
                                              ? appInMemory.downloadProgress! /
                                                    100
                                              : null,
                                          height: 5,
                                        ),
                                      ],
                                    ),
                                  )
                                : KeyedSubtree(
                                    key: const ValueKey('info'),
                                    child: trailingRow,
                                  ),
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
}
