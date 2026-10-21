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
import 'package:obtainium/components/app_grid_tile.dart'
    show AppIconActionBadge;
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'dart:ui';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

class AppListTile extends StatefulWidget {
  final AppInMemory appInMemory;
  final bool hasUpdate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowChanges;
  final Color? categoryColor;
  // When provided, overrides the AppsProvider-based selection check.
  // Use this when the caller manages selection state locally (e.g. CategorySections).
  final bool? selected;
  final Duration entranceDelay;

  const AppListTile({
    super.key,
    required this.appInMemory,
    this.hasUpdate = false,
    this.onTap,
    this.onLongPress,
    this.onShowChanges,
    this.categoryColor,
    this.selected,
    this.entranceDelay = Duration.zero,
  });

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _scheduleIconLoadIfNeeded();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: AppConstants.expressiveDecelerate,
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animsEnabled = context
          .read<PlusSettingsProvider>()
          .plusEnableEnhancedAnimations;
      if (!animsEnabled) {
        _entranceController.value = 1.0;
        return;
      }
      if (widget.entranceDelay == Duration.zero) {
        _entranceController.forward();
      } else {
        Future.delayed(widget.entranceDelay, () {
          if (mounted) _entranceController.forward();
        });
      }
    });
  }

  @override
  void didUpdateWidget(AppListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appInMemory.icon == null &&
        (oldWidget.appInMemory.icon != null ||
            oldWidget.appInMemory.app.id != widget.appInMemory.app.id)) {
      _scheduleIconLoadIfNeeded();
    }
  }

  void _scheduleIconLoadIfNeeded() {
    if (widget.appInMemory.icon == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.appInMemory.icon == null) {
          context.read<AppsProvider>().updateAppIcon(widget.appInMemory.app.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  AppInMemory get appInMemory => widget.appInMemory;
  bool get hasUpdate => !appInMemory.app.disabled && widget.hasUpdate;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onLongPress => widget.onLongPress;
  VoidCallback? get onShowChanges => widget.onShowChanges;
  Color? get categoryColor => widget.categoryColor;
  bool? get selected => widget.selected;

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.read<AppsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final viewSettings = context.watch<ViewSettingsProvider>();
    final isSelected =
        selected ??
        context.select<AppsProvider, bool>(
          (p) => p.selectedAppIds.contains(appInMemory.app.id),
        );
    final isCompact = viewSettings.appListDensity == AppListDensity.compact;
    final isAmbiguous =
        hasUpdate &&
        appInMemory.app.additionalSettings['isAmbiguousUpdate'] == true;

    final needsInstall =
        appInMemory.app.installedVersion == null &&
        appInMemory.app.additionalSettings['trackOnly'] != true;

    void showAmbiguousDialog() {
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
    }

    String getVersionText() {
      if (appInMemory.app.disabled) return tr('disabled');
      final isTrackOnly =
          appInMemory.app.additionalSettings['trackOnly'] == true;
      final installed = appInMemory.app.installedVersion;
      final latest = appInMemory.app.latestVersion;
      if (installed == null) {
        if (latest.isNotEmpty) {
          return isTrackOnly ? latest : '${tr('notInstalled')} ($latest)';
        }
        return tr('notInstalled');
      }
      if (hasUpdate) {
        return '$installed → $latest';
      }
      return installed;
    }

    String? getDateText() {
      final date =
          appInMemory.app.releaseDate ?? appInMemory.app.lastUpdateCheck;
      if (date == null) return null;
      return DateFormat('yyyy-MM-dd').format(date.toLocal());
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

    Widget getAppIcon() {
      final itemRadius = CardMetrics.inner(
        plusSettings.plusOverrideIndividualCornerRadius
            ? plusSettings.plusHomeCornerRadius
            : plusSettings.plusGlobalCornerRadius,
      );

      final iconShape = CardMetrics.shape(
        itemRadius,
        expressive: plusSettings.plusEnableMaterialExpressive,
        side: plusSettings.plusIconRimBorder
            ? BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                width: 1.0,
              )
            : BorderSide.none,
      );

      final iconWidget = Hero(
        tag: 'app_icon_${appInMemory.app.id}',
        child: Container(
          width: 44,
          height: 44,
          decoration: ShapeDecoration(
            shape: iconShape,
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shadows: AppShadows.smooth(
              color: Colors.black,
              opacity: 0.08,
              blurFactor: 0.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: Duration(
              milliseconds: plusSettings.plusEnableEnhancedAnimations
                  ? 350
                  : 180,
            ),
            switchInCurve: plusSettings.plusEnableEnhancedAnimations
                ? AppConstants.expressiveDecelerate
                : Curves.easeOut,
            switchOutCurve: plusSettings.plusEnableEnhancedAnimations
                ? AppConstants.expressiveAccelerate
                : Curves.easeIn,
            transitionBuilder: (child, animation) =>
                plusSettings.plusEnableEnhancedAnimations
                ? FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.82,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  )
                : FadeTransition(opacity: animation, child: child),
            child: appInMemory.icon != null
                ? ClipPath(
                    key: ValueKey('icon_${appInMemory.app.id}'),
                    clipper: ShapeBorderClipper(
                      shape: CardMetrics.shape(
                        itemRadius,
                        expressive: plusSettings.plusEnableMaterialExpressive,
                      ),
                    ),
                    child: Image.memory(
                      appInMemory.icon!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      cacheWidth: (48 * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                      cacheHeight: (48 * MediaQuery.devicePixelRatioOf(context))
                          .round(),
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

      final haloColor =
          displayCategoryColor ?? Theme.of(context).colorScheme.primary;
      final useExpressivePillAction =
          plusSettings.plusUpdateExpressiveBadge &&
          hasUpdate &&
          !needsInstall &&
          viewSettings.displayShowVersion;

      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (plusSettings.plusGridAmbientIconHalo)
              Positioned(
                width: 60,
                height: 60,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          haloColor.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.24
                                : 0.16,
                          ),
                          haloColor.withValues(alpha: 0.0),
                        ],
                        stops: const [0.15, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            iconWidget,
            if (!useExpressivePillAction ||
                appInMemory.downloadProgress != null)
              Positioned(
                right: -8,
                bottom: -8,
                child: AppIconActionBadge(
                  appInMemory: appInMemory,
                  hasUpdate: hasUpdate,
                  needsInstall: needsInstall,
                  isAmbiguous: isAmbiguous,
                  iconSize: 44,
                  onPressed: () {
                    appsProvider.downloadAndInstallLatestApps([
                      appInMemory.app.id,
                    ], context);
                  },
                  onAmbiguous: showAmbiguousDialog,
                ),
              ),
          ],
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
      final color = isDark
          ? colorScheme.primary.withValues(alpha: 0.85)
          : brandColor;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Icon(iconData, size: 10, color: color),
      );
    }

    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;

    final trailingRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onShowChanges != null)
          ScaleTouchWrapper(
            hapticOnPressDown: true,
            scaleDownFactor: 0.88,
            child: IconButton(
              visualDensity: isCompact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
              icon: Icon(
                Icons.history_rounded,
                size: 20,
                color: hasUpdate
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              onPressed: onShowChanges,
              tooltip: tr('changes'),
            ),
          ),
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          scaleDownFactor: 0.88,
          child: PopupMenuButton<String>(
            tooltip: tr('more'),
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
                  AppHaptics.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('copiedToClipboard')),
                      behavior: SnackBarBehavior.floating,
                    ),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // --- MODERN UI ---
    final tile = FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: RepaintBoundary(
          child: Semantics(
            label:
                '${appInMemory.name}${viewSettings.displayShowAuthor ? ' ${tr('byX', args: [appInMemory.author])}' : ''}. ${hasUpdate ? tr('updateAvailable') : ''} ${appInMemory.app.installedVersion ?? tr('notInstalled')}',
            button: true,
            onTap: onTap,
            onLongPress: onLongPress,
            child: ScaleTouchWrapper(
              scaleDownFactor: 0.98,
              hapticOnPressDown: true,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 4 : 8,
                  vertical: isCompact ? 2 : 6,
                ),
                child: AnimatedContainer(
                  duration: Duration(
                    milliseconds: plusSettings.plusEnableEnhancedAnimations
                        ? 250
                        : 0,
                  ),
                  curve: AppConstants.expressiveStandard,
                  decoration: ShapeDecoration(
                    shape: CardMetrics.shape(
                      radius,
                      expressive: plusSettings.plusEnableMaterialExpressive,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : hasUpdate
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.42)
                            : appInMemory.app.pinned &&
                                  plusSettings.plusPinnedBorderAccent
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.55)
                            : appInMemory.app.pinned
                            ? Theme.of(context).colorScheme.outlineVariant
                            : plusSettings.plusEnableGlassmorphism
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(
                                alpha: AppConstants.glassBorderAlpha,
                              )
                            : Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).colorScheme.outlineVariant
                                  .withValues(alpha: 0.65)
                            : Theme.of(context).colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                        width:
                            isSelected ||
                                (appInMemory.app.pinned &&
                                    plusSettings.plusPinnedBorderAccent) ||
                                (hasUpdate && !isCompact)
                            ? 1.5
                            : 1.0,
                      ),
                    ),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.7)
                        : hasUpdate
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(
                            alpha: plusSettings.plusEnableGlassmorphism
                                ? 0.35
                                : (isCompact ? 0.15 : 0.25),
                          )
                        : appInMemory.app.pinned
                        ? Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withValues(
                            alpha: plusSettings.plusEnableGlassmorphism
                                ? 0.45
                                : 1.0,
                          )
                        : plusSettings.plusEnableGlassmorphism
                        ? Theme.of(context).colorScheme.surface.withValues(
                            alpha: AppConstants.glassSurfaceAlpha,
                          )
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    shadows: isSelected && plusSettings.plusEnableGlassmorphism
                        ? AppShadows.glow(
                            color: Theme.of(context).colorScheme.primary,
                            intensity: 0.7,
                          )
                        : hasUpdate &&
                              !isCompact &&
                              plusSettings.plusEnableGlassmorphism
                        ? AppShadows.smooth(
                            color: Theme.of(context).colorScheme.shadow,
                            opacity: 0.12,
                          )
                        : null,
                  ),
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: CardMetrics.shape(
                        radius,
                        expressive: plusSettings.plusEnableMaterialExpressive,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onLongPress: onLongPress,
                        onTap: onTap,
                        customBorder: CardMetrics.shape(
                          radius,
                          expressive: plusSettings.plusEnableMaterialExpressive,
                        ),
                        splashColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.06),
                        child: Stack(
                          children: [
                            if (plusSettings.plusEnableGlassmorphism)
                              Positioned.fill(
                                child: ConditionalBlur(
                                  enabled: true,
                                  sigma: AppConstants.glassBlurSigmaSoft,
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
                                      colors:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? [
                                              Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.02,
                                              ),
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                            ]
                                          : [
                                              Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.10,
                                              ),
                                              Colors.transparent,
                                              Colors.black.withValues(
                                                alpha: 0.02,
                                              ),
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
                                        Colors.white.withValues(
                                          alpha:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? 0.18
                                              : 0.50,
                                        ),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            if (displayCategoryColor != null &&
                                plusSettings.plusCategoryAccentRibbon)
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
                                  left:
                                      (displayCategoryColor != null &&
                                          plusSettings.plusCategoryAccentRibbon)
                                      ? 6
                                      : 0,
                                ),
                                child: Transform.scale(
                                  scale: isCompact ? 0.9 : 1.0,
                                  child: getAppIcon(),
                                ),
                              ),
                              title: Row(
                                children: [
                                  if (appInMemory.app.pinned) ...[
                                    Icon(
                                      Icons.push_pin_rounded,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      appInMemory.name,
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            overflow: TextOverflow.ellipsis,
                                            fontWeight:
                                                appInMemory.app.pinned ||
                                                    hasUpdate
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                  ),
                                  if (appInMemory
                                          .app
                                          .additionalSettings['trackOnly'] ==
                                      true) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: tr('trackOnly'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer
                                              .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            CardMetrics.pillRadius,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.visibility_outlined,
                                          size: 11,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onTertiaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (plusSettings.plusGridShowSourceBadge) ...[
                                    const SizedBox(width: 6),
                                    getSourceBadge(),
                                  ],
                                ],
                              ),
                              subtitle: Builder(
                                builder: (context) {
                                  final colorScheme = Theme.of(
                                    context,
                                  ).colorScheme;
                                  final showAuthor =
                                      viewSettings.displayShowAuthor &&
                                      appInMemory.author.isNotEmpty;
                                  final showVersion =
                                      viewSettings.displayShowVersion;
                                  final dateText = viewSettings.displayShowDate
                                      ? getDateText()
                                      : null;
                                  final showDate =
                                      dateText != null && dateText.isNotEmpty;

                                  final hasSecondaryPills =
                                      appInMemory.app.hasPendingRepoRename ||
                                      appInMemory.app.categories.isNotEmpty ||
                                      (plusSettings.plusShowTagsInList &&
                                          appInMemory.app.tags.isNotEmpty);

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showAuthor ||
                                          showVersion ||
                                          showDate) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (showAuthor)
                                              Flexible(
                                                child: Text(
                                                  appInMemory.author,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                            if (showAuthor &&
                                                showVersion &&
                                                !hasUpdate)
                                              Text(
                                                ' • ',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                              ),
                                            if (showVersion)
                                              Flexible(
                                                child: hasUpdate
                                                    ? _buildVersionUpdatePill(
                                                        context,
                                                        appInMemory
                                                                .app
                                                                .installedVersion ??
                                                            '?',
                                                        appInMemory
                                                                .app
                                                                .latestVersion
                                                                .isNotEmpty
                                                            ? appInMemory
                                                                  .app
                                                                  .latestVersion
                                                            : '?',
                                                        expressiveAction:
                                                            plusSettings
                                                                .plusUpdateExpressiveBadge &&
                                                            !needsInstall,
                                                        isAmbiguous:
                                                            isAmbiguous,
                                                        onTriggerUpdate: () {
                                                          if (isAmbiguous) {
                                                            showAmbiguousDialog();
                                                          } else {
                                                            appsProvider
                                                                .downloadAndInstallLatestApps(
                                                                  [
                                                                    appInMemory
                                                                        .app
                                                                        .id,
                                                                  ],
                                                                  context,
                                                                );
                                                          }
                                                        },
                                                      )
                                                    : Text(
                                                        getVersionText(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                              fontStyle:
                                                                  SourceUtils.isVersionPseudo(
                                                                    appInMemory
                                                                        .app,
                                                                  )
                                                                  ? FontStyle
                                                                        .italic
                                                                  : null,
                                                            ),
                                                      ),
                                              ),
                                            if (showDate &&
                                                (showAuthor || showVersion))
                                              Text(
                                                ' • ',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                              ),
                                            if (showDate)
                                              Text(
                                                dateText,
                                                maxLines: 1,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontSize: 11,
                                                      color: colorScheme
                                                          .onSurfaceVariant
                                                          .withValues(
                                                            alpha: 0.75,
                                                          ),
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      if (hasSecondaryPills && !isCompact) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (appInMemory
                                                .app
                                                .hasPendingRepoRename)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.info_outline_rounded,
                                                    color: colorScheme.primary,
                                                    size: 13,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    tr('repoRenamed'),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: colorScheme
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 10,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ...appInMemory.app.categories.take(2).map((
                                              cat,
                                            ) {
                                              final catColorVal =
                                                  viewSettings.categories[cat];
                                              final catColor =
                                                  catColorVal != null
                                                  ? Color(catColorVal)
                                                  : colorScheme.primary;
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(
                                                    alpha: 0.14,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        CardMetrics.pillRadius,
                                                      ),
                                                  border: Border.all(
                                                    color: catColor.withValues(
                                                      alpha: 0.3,
                                                    ),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 5,
                                                      height: 5,
                                                      decoration: BoxDecoration(
                                                        color: catColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      cat,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            fontSize: 9.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  alpha: 0.85,
                                                                ),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                            if (plusSettings
                                                    .plusShowTagsInList &&
                                                appInMemory.app.tags.isNotEmpty)
                                              ...appInMemory.app.tags
                                                  .take(2)
                                                  .map(
                                                    (tag) => Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 1.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .secondaryContainer
                                                            .withValues(
                                                              alpha: 0.35,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              CardMetrics
                                                                  .pillRadius,
                                                            ),
                                                        border: Border.all(
                                                          color: colorScheme
                                                              .secondary
                                                              .withValues(
                                                                alpha: 0.18,
                                                              ),
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
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  0.1,
                                                              color: colorScheme
                                                                  .onSecondaryContainer
                                                                  .withValues(
                                                                    alpha: 0.85,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              trailing: ValueListenableBuilder<double?>(
                                valueListenable:
                                    appInMemory.downloadProgressNotifier,
                                builder: (context, downloadProgress, child) {
                                  return AnimatedSwitcher(
                                    duration: Duration(
                                      milliseconds:
                                          plusSettings
                                              .plusEnableEnhancedAnimations
                                          ? 300
                                          : 150,
                                    ),
                                    switchInCurve:
                                        plusSettings
                                            .plusEnableEnhancedAnimations
                                        ? AppConstants.expressiveDecelerate
                                        : Curves.easeOut,
                                    switchOutCurve:
                                        plusSettings
                                            .plusEnableEnhancedAnimations
                                        ? AppConstants.expressiveAccelerate
                                        : Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      if (!plusSettings
                                          .plusEnableEnhancedAnimations) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      }
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position:
                                              Tween<Offset>(
                                                begin: const Offset(0.12, 0),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: AppConstants
                                                      .expressiveDecelerate,
                                                ),
                                              ),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: downloadProgress != null
                                        ? SizedBox(
                                            key: const ValueKey('download'),
                                            width: downloadProgress >= 0
                                                ? (appInMemory.downloadSpeedBytesPerSec !=
                                                          null
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
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Builder(
                                                          builder: (context) {
                                                            if (downloadProgress <
                                                                0) {
                                                              final total =
                                                                  appInMemory
                                                                      .downloadTotalBytes;
                                                              final label =
                                                                  total !=
                                                                          null &&
                                                                      total > 0
                                                                  ? '${tr('installing')} · ${formatBytes(total)}'
                                                                  : tr(
                                                                      'installing',
                                                                    );
                                                              return Text(
                                                                label,
                                                                style: Theme.of(context)
                                                                    .textTheme
                                                                    .labelSmall
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              );
                                                            }
                                                            final speed =
                                                                formatSpeed(
                                                                  appInMemory
                                                                      .downloadSpeedBytesPerSec,
                                                                );
                                                            final safePercent =
                                                                (downloadProgress
                                                                        .isNaN ||
                                                                    downloadProgress
                                                                        .isInfinite)
                                                                ? 0
                                                                : downloadProgress
                                                                      .toInt();
                                                            final label =
                                                                speed != null
                                                                ? '$safePercent% • $speed'
                                                                : '$safePercent%';
                                                            return Text(
                                                              label,
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .labelSmall
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      ExpressiveProgressIndicator(
                                                        value:
                                                            downloadProgress >=
                                                                0
                                                            ? downloadProgress /
                                                                  100
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
        ),
      ),
    );
    return appInMemory.app.disabled ? Opacity(opacity: 0.5, child: tile) : tile;
  }

  /// Compact pill widget showing the version transition when an update is available.
  Widget _buildVersionUpdatePill(
    BuildContext context,
    String inst,
    String latest, {
    bool expressiveAction = false,
    bool isAmbiguous = false,
    VoidCallback? onTriggerUpdate,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: expressiveAction ? 9 : 7,
        vertical: expressiveAction ? 3.5 : 2,
      ),
      decoration: BoxDecoration(
        color: expressiveAction
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
        border: Border.all(
          color: expressiveAction
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.30),
          width: 0.6,
        ),
        boxShadow: expressiveAction
            ? AppShadows.smooth(
                color: colorScheme.primary,
                opacity: 0.25,
                blurFactor: 0.5,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expressiveAction
                ? (isAmbiguous
                      ? Icons.help_outline_rounded
                      : Icons.download_rounded)
                : Icons.arrow_upward_rounded,
            size: expressiveAction ? 11 : 9,
            color: expressiveAction
                ? colorScheme.onPrimary
                : colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '$inst → $latest',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: expressiveAction ? 10 : 9.5,
                fontWeight: FontWeight.w700,
                color: expressiveAction
                    ? colorScheme.onPrimary
                    : colorScheme.primary,
                fontFamily: 'monospace',
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: expressiveAction && onTriggerUpdate != null
          ? ScaleTouchWrapper(
              scaleDownFactor: 0.92,
              hapticOnPressDown: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptics.mediumImpact();
                  onTriggerUpdate();
                },
                child: pill,
              ),
            )
          : pill,
    );
  }
}
