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
import 'package:obtainium/services/app_install_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppListTile extends StatelessWidget {
  final AppInMemory appInMemory;
  final bool isSelected;
  final bool hasUpdate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowChanges;
  final Color? categoryColor;

  const AppListTile({
    super.key,
    required this.appInMemory,
    this.isSelected = false,
    this.hasUpdate = false,
    this.onTap,
    this.onLongPress,
    this.onShowChanges,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.read<AppsProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isCheckingUpdate = context.select<AppsProvider, bool>(
      (p) => p.checkingUpdateIds.contains(appInMemory.app.id),
    );

    Widget getUpdateButton() {
      if (isCheckingUpdate) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: 24,
            height: 24,
            child: ExpressiveCircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return IconButton(
        visualDensity: VisualDensity.compact,
        color: Theme.of(context).colorScheme.primary,
        tooltip: appInMemory.app.additionalSettings['trackOnly'] == true
            ? tr('markUpdated')
            : tr('update'),
        onPressed: appsProvider.areDownloadsRunning()
            ? null
            : () {
                appsProvider
                    .downloadAndInstallLatestApps([
                      appInMemory.app.id,
                    ], context)
                    .catchError((e) {
                      showError(e, context);
                      return <String>[];
                    });
              },
        icon: Icon(
          appInMemory.app.additionalSettings['trackOnly'] == true
              ? Icons.check_circle_outline
              : Icons.install_mobile,
        ),
      );
    }

    Widget getAppIcon() {
      if (appInMemory.icon == null) {
        appsProvider.updateAppIcon(appInMemory.app.id);
      }

      return GestureDetector(
        child: Hero(
          tag: 'app_icon_${appInMemory.app.id}',
          child: appInMemory.icon != null
              ? Image.memory(
                  appInMemory.icon!,
                  gaplessPlayback: true,
                  opacity: AlwaysStoppedAnimation(
                    appInMemory.installedInfo == null ? 0.6 : 1,
                  ),
                )
              : const AppIconShimmer(size: 48),
        ),
        onDoubleTap: () {
          AppInstallService.openApp(appInMemory.app.id);
        },
        onLongPress: () {
          pushRoute(context, AppPage(
            appId: appInMemory.app.id,
            showOppositeOfPreferredView: true,
          ));
        },
      );
    }

    String getVersionText() {
      if (hasUpdate && appInMemory.app.installedVersion != null) {
        return '${appInMemory.app.installedVersion} → ${appInMemory.app.latestVersion}';
      }
      return appInMemory.app.installedVersion ?? tr('notInstalled');
    }

    String getChangesButtonString() {
      return appInMemory.app.releaseDate == null
          ? onShowChanges != null
                ? tr('changes')
                : ''
          : DateFormat(
              'MMM d, yyyy',
            ).format(appInMemory.app.releaseDate!.toLocal());
    }

    Widget trailingRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hasUpdate ? getUpdateButton() : const SizedBox.shrink(),
        hasUpdate ? const SizedBox(width: 5) : const SizedBox.shrink(),
        GestureDetector(
          onTap: onShowChanges,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  settingsProvider.highlightTouchTargets &&
                      onShowChanges != null
                  ? (Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColorLight)
                        .withValues(
                          alpha: Theme.of(context).brightness == Brightness.light
                              ? 20 / 255
                              : 40 / 255,
                        )
                  : null,
            ),
            padding: settingsProvider.highlightTouchTargets
                ? const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0)
                : const EdgeInsetsDirectional.fromSTEB(24, 0, 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (settingsProvider.displayShowVersion)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width / 4,
                        ),
                        child: Text(
                          getVersionText(),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: SourceUtils.isVersionPseudo(appInMemory.app)
                              ? const TextStyle(fontStyle: FontStyle.italic)
                              : null,
                        ),
                      ),
                    ],
                  ),
                if (settingsProvider.displayShowDate)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getChangesButtonString(),
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          decoration: onShowChanges != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    var transparent = Theme.of(context).colorScheme.surface.withValues(alpha: 0.0).value;
    List<double> stops = [
      ...appInMemory.app.categories.asMap().entries.map(
        (e) =>
            ((e.key / (appInMemory.app.categories.length - 1)) -
            0.0001),
      ),
      1,
    ];
    if (stops.length == 2) {
      stops[0] = 0.9999;
    }

    final isCompact = settingsProvider.appListDensity == AppListDensity.compact;
    final categoryColorVal = appInMemory.app.categories.isNotEmpty 
        ? settingsProvider.categories[appInMemory.app.categories.first] 
        : null;
    final displayCategoryColor = categoryColorVal != null ? Color(categoryColorVal) : null;

    final radius = settingsProvider.plusOverrideIndividualCornerRadius 
        ? settingsProvider.plusHomeCornerRadius 
        : settingsProvider.plusGlobalCornerRadius;

    if (!settingsProvider.plusEnableModernAppListTile) {
      // --- LEGACY UI ---
      var transparent = Theme.of(context).colorScheme.surface.withValues(alpha: 0.0).value;
      List<double> stops = [
        ...appInMemory.app.categories.asMap().entries.map(
          (e) =>
              ((e.key / (appInMemory.app.categories.length - 1)) -
              0.0001),
        ),
        1,
      ];
      if (stops.length == 2) {
        stops[0] = 0.9999;
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: stops,
            begin: const Alignment(-1, 0),
            end: const Alignment(-0.97, 0),
            colors: [
              ...appInMemory.app.categories.map(
                (e) => Color(
                  settingsProvider.categories[e] ?? transparent,
                ).withValues(alpha: 1.0),
              ),
              Color(transparent),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: onLongPress,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: ListTile(
                visualDensity: isCompact ? VisualDensity.compact : null,
                contentPadding: isCompact ? const EdgeInsets.symmetric(horizontal: 12) : null,
                dense: isCompact,
                tileColor: appInMemory.app.pinned
                    ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
                selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: appInMemory.app.pinned ? 0.7 : 0.5,
                ),
                selected: isSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
                leading: getAppIcon(),
                title: Text(
                  maxLines: 1,
                  appInMemory.name,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: appInMemory.app.pinned
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: settingsProvider.displayShowAuthor ? Text(
                  tr('byX', args: [appInMemory.author]),
                  maxLines: 1,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: appInMemory.app.pinned
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ) : null,
                trailing: appInMemory.downloadProgress != null
                    ? SizedBox(
                        child: Text(
                          appInMemory.downloadProgress! >= 0
                              ? tr(
                                  'percentProgress',
                                  args: [
                                    appInMemory.downloadProgress!
                                        .toInt()
                                        .toString(),
                                  ],
                                )
                              : tr('installing'),
                          textAlign: (appInMemory.downloadProgress! >= 0)
                              ? TextAlign.start
                              : TextAlign.end,
                        ),
                      )
                    : trailingRow,
              ),
            ),
          ),
        ),
      );
    }

    // --- MODERN UI ---
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: AnimatedContainer(
            duration: Duration(milliseconds: settingsProvider.plusEnableEnhancedAnimations ? 200 : 0),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7)
                  : appInMemory.app.pinned
                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : appInMemory.app.pinned
                        ? Theme.of(context).colorScheme.outlineVariant
                        : Colors.transparent,
                width: isSelected || appInMemory.app.pinned ? 1.5 : 0,
              ),
              boxShadow: isSelected
                  ? AppShadows.glow(color: Theme.of(context).colorScheme.primary, intensity: 0.5)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  // Modern Category Indicator (Vertical bar)
                  if (displayCategoryColor != null)
                    Positioned(
                      left: 0,
                      top: 12,
                      bottom: 12,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: displayCategoryColor,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  
                  ListTile(
                    visualDensity: isCompact ? VisualDensity.compact : null,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 16,
                      vertical: isCompact ? 0 : 4,
                    ),
                    dense: isCompact,
                    leading: Padding(
                      padding: EdgeInsets.only(left: displayCategoryColor != null ? 4 : 0),
                      child: getAppIcon(),
                    ),
                    title: Text(
                      appInMemory.name,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            overflow: TextOverflow.ellipsis,
                            fontWeight: appInMemory.app.pinned
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                    ),
                    subtitle: Row(
                      children: [
                        if (settingsProvider.displayShowAuthor)
                          Expanded(
                            child: Text(
                              appInMemory.author,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        if (settingsProvider.displayShowVersion && !isCompact)
                          Text(
                            ' • ${getVersionText()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: SourceUtils.isVersionPseudo(appInMemory.app)
                                      ? FontStyle.italic
                                      : null,
                                ),
                          ),
                      ],
                    ),
                    trailing: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: appInMemory.downloadProgress != null
                          ? SizedBox(
                              key: const ValueKey('download'),
                              width: 60,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    appInMemory.downloadProgress! >= 0
                                        ? '${appInMemory.downloadProgress!.toInt()}%'
                                        : tr('installing'),
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  ExpressiveProgressIndicator(
                                    value: appInMemory.downloadProgress! >= 0
                                        ? appInMemory.downloadProgress! / 100
                                        : null,
                                    height: 4,
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
    );
  }
}
