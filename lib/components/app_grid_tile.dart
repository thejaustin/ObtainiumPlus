import 'dart:async';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// A Material 3 Expressive grid tile for displaying apps with tonal elevation,
/// dynamic spring-scale feedback, contextual action capsule, and rich metadata.
class AppGridTile extends StatefulWidget {
  final AppInMemory appInMemory;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool hasUpdate;
  final bool isAmbiguous;
  final Color? categoryColor;
  final Duration entranceDelay;

  const AppGridTile({
    super.key,
    required this.appInMemory,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.hasUpdate = false,
    this.isAmbiguous = false,
    this.categoryColor,
    this.entranceDelay = Duration.zero,
  });

  @override
  State<AppGridTile> createState() => _AppGridTileState();
}

class _AppGridTileState extends State<AppGridTile>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  Timer? _entranceTimer;

  @override
  void initState() {
    super.initState();
    _scheduleIconLoadIfNeeded();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
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
        _entranceTimer = Timer(widget.entranceDelay, () {
          if (mounted) _entranceController.forward();
        });
      }
    });
  }

  @override
  void didUpdateWidget(AppGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appInMemory.icon == null &&
        widget.appInMemory.installedInfo != null &&
        (oldWidget.appInMemory.icon != null ||
            oldWidget.appInMemory.app.id != widget.appInMemory.app.id)) {
      _scheduleIconLoadIfNeeded();
    }
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _scheduleIconLoadIfNeeded() {
    if (widget.appInMemory.icon == null &&
        widget.appInMemory.installedInfo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.appInMemory.icon == null) {
          context.read<AppsProvider>().updateAppIcon(widget.appInMemory.app.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive horizontal layout detection (e.g. tablet landscape rows or 1-column grids)
            final bool isHorizontal =
                constraints.maxWidth / constraints.maxHeight > 1.5;

            final double availableWidth = constraints.maxWidth - 16;
            final bool isCompactTile = constraints.maxHeight < 128;

            // Adaptive icon sizing proportional to a 1:1 square tile
            final double maxIconFromHeight =
                (constraints.maxHeight * (isCompactTile ? 0.35 : 0.38)).clamp(
                  24.0,
                  68.0,
                );
            final double iconSize = isHorizontal
                ? (constraints.maxHeight * 0.65).clamp(36.0, 80.0)
                : (availableWidth * 0.42).clamp(24.0, maxIconFromHeight);

            final plusSettings = context.watch<PlusSettingsProvider>();
            final viewSettings = context.watch<ViewSettingsProvider>();
            final colorScheme = Theme.of(context).colorScheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
                ? plusSettings.plusHomeCornerRadius
                : plusSettings.plusGlobalCornerRadius;
            final double cardBorderRadius = CardMetrics.cardFor(
              baseRadius,
              constraints.maxWidth,
            );
            final double iconBorderRadius = CardMetrics.inner(baseRadius);
            final double padding = (availableWidth * 0.065).clamp(5.0, 10.0);
            final double badgeSize = (iconSize * 0.28).clamp(13.0, 20.0);

            // Resolve category color for M3E accent ribbon
            final Color? resolvedCategoryColor =
                widget.categoryColor ??
                (widget.appInMemory.app.categories.isNotEmpty &&
                        viewSettings.categories[widget
                                .appInMemory
                                .app
                                .categories
                                .first] !=
                            null
                    ? Color(
                        viewSettings.categories[widget
                            .appInMemory
                            .app
                            .categories
                            .first]!,
                      )
                    : null);

            final curve = plusSettings.plusEnableEnhancedAnimations
                ? (plusSettings.plusEnableMaterialExpressive
                      ? AppConstants.expressiveStandard
                      : AppConstants.standardStandard)
                : Curves.easeInOut;

            final bool isCardless =
                plusSettings.plusGridCardlessStyle &&
                !widget.isSelected &&
                !widget.hasUpdate;

            // Surface color tokens aligned with Material 3 Expressive
            Color cardColor;
            if (isCardless) {
              cardColor = Colors.transparent;
            } else if (widget.isSelected) {
              cardColor = colorScheme.primaryContainer.withValues(alpha: 0.85);
            } else if (plusSettings.plusEnableGlassmorphism) {
              cardColor = colorScheme.surface.withValues(
                alpha: AppConstants.glassSurfaceAlpha,
              );
            } else if (widget.hasUpdate) {
              cardColor = colorScheme.primaryContainer.withValues(
                alpha: isDark ? 0.22 : 0.14,
              );
            } else if (widget.appInMemory.app.pinned) {
              cardColor = colorScheme.surfaceContainerHighest;
            } else {
              cardColor = colorScheme.surfaceContainerLow;
            }

            // Border styling with M3E stroke hierarchy
            BorderSide cardBorderSide;
            if (isCardless) {
              cardBorderSide = BorderSide.none;
            } else if (widget.isSelected) {
              cardBorderSide = BorderSide(
                color: colorScheme.primary,
                width: 2.0,
              );
            } else if (widget.appInMemory.app.pinned &&
                plusSettings.plusPinnedBorderAccent) {
              cardBorderSide = BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.65),
                width: 1.5,
              );
            } else if (widget.hasUpdate) {
              cardBorderSide = BorderSide(
                color:
                    (widget.isAmbiguous
                            ? colorScheme.tertiary
                            : colorScheme.secondary)
                        .withValues(alpha: 0.45),
                width: 1.2,
              );
            } else if (plusSettings.plusEnableGlassmorphism) {
              cardBorderSide = BorderSide(
                color: colorScheme.onSurface.withValues(
                  alpha: AppConstants.glassBorderAlpha,
                ),
                width: 0.8,
              );
            } else {
              cardBorderSide = BorderSide(
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.35 : 0.65,
                ),
                width: 1.0,
              );
            }

            List<BoxShadow>? cardShadow;
            if (isCardless) {
              cardShadow = null;
            } else if (widget.isSelected &&
                plusSettings.plusEnableGlassmorphism) {
              // Glow only when glass is on — border+background already signal
              // selection when glass is off, and glow without clipping bleeds.
              cardShadow = AppShadows.glow(
                color: colorScheme.primary,
                intensity: 0.6,
              );
            } else if (widget.hasUpdate &&
                plusSettings.plusEnableGlassmorphism) {
              cardShadow = AppShadows.smooth(
                color: widget.isAmbiguous
                    ? colorScheme.tertiary
                    : colorScheme.secondary,
                opacity: isDark ? 0.18 : 0.10,
                blurFactor: 0.7,
              );
            } else {
              cardShadow = [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                  blurRadius: isDark ? 6 : 8,
                  offset: const Offset(0, 2),
                ),
              ];
            }

            return AnimatedScale(
              scale: _isPressed ? 0.96 : 1.0,
              duration: Duration(milliseconds: _isPressed ? 80 : 320),
              curve: _isPressed ? Curves.easeIn : AppConstants.expressiveSpring,
              child: AnimatedContainer(
                duration: Duration(
                  milliseconds: plusSettings.plusEnableEnhancedAnimations
                      ? AppConstants.shortAnimationMs
                      : 200,
                ),
                curve: curve,
                decoration: ShapeDecoration(
                  shape: CardMetrics.shape(
                    cardBorderRadius,
                    expressive: plusSettings.plusEnableMaterialExpressive,
                    side: cardBorderSide,
                  ),
                  color: cardColor,
                  shadows: cardShadow,
                ),
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: CardMetrics.shape(
                      cardBorderRadius,
                      expressive: plusSettings.plusEnableMaterialExpressive,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 1. Glass sheen gradient (no per-tile BackdropFilter over flat
                      // Scaffold surface — eliminates 12-24 offscreen GPU saveLayer
                      // passes per frame while preserving the translucent surface tint,
                      // diagonal specular sheen, and top-edge highlight)
                      if (plusSettings.plusEnableGlassmorphism && !isCardless)
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
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.02),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.04),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.38),
                                        Colors.white.withValues(alpha: 0.12),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.02),
                                      ],
                                stops: const [0.0, 0.2, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),

                      // 3. Top specular highlight streak
                      if (plusSettings.plusEnableGlassmorphism && !isCardless)
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

                      // 3.5 Smart Launcher 6-inspired ambient radial icon halo
                      if (plusSettings.plusGridAmbientIconHalo)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: isHorizontal
                                      ? const Alignment(-0.65, 0.0)
                                      : const Alignment(0.0, -0.35),
                                  radius: isHorizontal ? 0.65 : 0.72,
                                  colors: [
                                    (resolvedCategoryColor ??
                                            (widget.hasUpdate
                                                ? colorScheme.primary
                                                : colorScheme.primary))
                                        .withValues(
                                          alpha: isDark ? 0.16 : 0.10,
                                        ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 4. Category Accent Ribbon (M3E)
                      if (plusSettings.plusCategoryAccentRibbon &&
                          resolvedCategoryColor != null)
                        isHorizontal
                            ? Positioned(
                                top: cardBorderRadius * 0.45,
                                bottom: cardBorderRadius * 0.45,
                                left: 0,
                                child: Container(
                                  width: 3.5,
                                  decoration: BoxDecoration(
                                    color: resolvedCategoryColor,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: resolvedCategoryColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(1, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Positioned(
                                top: 0,
                                left: cardBorderRadius * 0.45,
                                right: cardBorderRadius * 0.45,
                                child: Container(
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: resolvedCategoryColor,
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: resolvedCategoryColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                      // 5. Main Card Tap Target & Interactive Surface (InkWell)
                      Positioned.fill(
                        child: Semantics(
                          label: _buildSemanticLabel(),
                          button: true,
                          selected: widget.isSelected,
                          child: Listener(
                            onPointerDown: (_) => AppHaptics.tapDown(),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onTap,
                                onLongPress: () {
                                  AppHaptics.mediumImpact();
                                  widget.onLongPress();
                                },
                                onHighlightChanged: (highlighted) {
                                  setState(() => _isPressed = highlighted);
                                },
                                customBorder: CardMetrics.shape(
                                  cardBorderRadius,
                                  expressive:
                                      plusSettings.plusEnableMaterialExpressive,
                                ),
                                splashColor: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                highlightColor: colorScheme.primary.withValues(
                                  alpha: 0.06,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: padding,
                                    vertical: isCompactTile
                                        ? 5.0
                                        : (padding + 1),
                                  ),
                                  child: isHorizontal
                                      ? _buildHorizontalContent(
                                          iconSize,
                                          iconBorderRadius,
                                          badgeSize,
                                          plusSettings,
                                          viewSettings,
                                          cardColor,
                                        )
                                      : _buildVerticalContent(
                                          iconSize,
                                          iconBorderRadius,
                                          badgeSize,
                                          plusSettings,
                                          viewSettings,
                                          cardColor,
                                          constraints.maxHeight,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 6. Pinned Indicator (Top-Left)
                      if (widget.appInMemory.app.pinned && !widget.isSelected)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: _buildOverlayBadge(
                            icon: Icons.push_pin_rounded,
                            backgroundColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.9),
                            iconColor: colorScheme.primary,
                            borderColor: colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),

                      // 7. Repo Renamed Indicator
                      if (widget.appInMemory.app.hasPendingRepoRename)
                        Positioned(
                          top: 6,
                          left:
                              (widget.appInMemory.app.pinned &&
                                  !widget.isSelected)
                              ? 30
                              : 6,
                          child: _buildOverlayBadge(
                            icon: Icons.info_outline_rounded,
                            backgroundColor: colorScheme.errorContainer
                                .withValues(alpha: 0.9),
                            iconColor: colorScheme.onErrorContainer,
                            borderColor: colorScheme.error.withValues(
                              alpha: 0.4,
                            ),
                            tooltip: tr('repoRenamed'),
                          ),
                        ),

                      // 8. Update badge (Top-Right) — mirrors the pinned badge;
                      // tap updates, shows progress while downloading.
                      if (widget.hasUpdate &&
                          !widget.isSelected &&
                          !plusSettings.plusUpdateExpressiveBadge)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: _TileUpdateBadge(
                            appInMemory: widget.appInMemory,
                            isAmbiguous: widget.isAmbiguous,
                            animsEnabled:
                                plusSettings.plusEnableEnhancedAnimations,
                          ),
                        ),

                      // 9. Multi-Select Checkmark (Top-Right)
                      if (widget.isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _buildOverlayBadge(
                            icon: Icons.check_rounded,
                            backgroundColor: colorScheme.primary,
                            iconColor: colorScheme.onPrimary,
                            circle: true,
                            shadow: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerticalContent(
    double iconSize,
    double iconBorderRadius,
    double badgeSize,
    PlusSettingsProvider plusSettings,
    ViewSettingsProvider viewSettings,
    Color cardColor,
    double maxHeight,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isCompactTile = maxHeight < 128;
    final bool isUltraCompactTile = maxHeight < 96;
    final bool isDownloading = widget.appInMemory.downloadProgress != null;

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: isCompactTile ? 1 : 2),
              _buildIconStack(
                iconSize,
                iconBorderRadius,
                badgeSize,
                plusSettings,
                cardColor,
              ),
              SizedBox(height: isCompactTile ? 3 : 5),
              // App name: 1 line on compact square tiles, up to 2 lines on standard square tiles
              Flexible(
                child: Text(
                  widget.appInMemory.name,
                  maxLines: (isCompactTile || isDownloading) ? 1 : 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isUltraCompactTile
                        ? 10.5
                        : (isCompactTile ? 11.5 : 12.2),
                    fontWeight:
                        (widget.appInMemory.app.pinned || widget.hasUpdate)
                        ? FontWeight.w700
                        : FontWeight.w600,
                    letterSpacing: -0.2,
                    height: 1.18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Footer: Action Pill or Status Pill
            if (!isUltraCompactTile || widget.hasUpdate) ...[
              if (widget.hasUpdate) ...[
                _buildUpdateVersionPill(colorScheme, plusSettings),
              ] else if (viewSettings.displayShowVersion ||
                  viewSettings.displayShowAuthor ||
                  viewSettings.displayShowDate ||
                  plusSettings.plusGridShowSourceBadge) ...[
                _buildUpToDatePill(colorScheme, viewSettings, plusSettings),
              ],
            ],
            // Tag chips (shown on roomy square tiles when not actively downloading)
            if (plusSettings.plusShowTagsInList &&
                widget.appInMemory.app.tags.isNotEmpty &&
                !isCompactTile &&
                !isDownloading) ...[
              const SizedBox(height: 2),
              _buildTagChips(colorScheme),
            ],
            // Download / checking progress indicator
            _buildProgressIndicator(),
            SizedBox(height: isCompactTile ? 0 : 1),
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalContent(
    double iconSize,
    double iconBorderRadius,
    double badgeSize,
    PlusSettingsProvider plusSettings,
    ViewSettingsProvider viewSettings,
    Color cardColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _buildIconStack(
          iconSize,
          iconBorderRadius,
          badgeSize,
          plusSettings,
          cardColor,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.appInMemory.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.appInMemory.app.pinned || widget.hasUpdate
                      ? FontWeight.w700
                      : FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (widget.hasUpdate) ...[
                const SizedBox(height: 4),
                _buildUpdateVersionPill(colorScheme, plusSettings),
              ] else if (viewSettings.displayShowVersion ||
                  viewSettings.displayShowAuthor ||
                  viewSettings.displayShowDate ||
                  plusSettings.plusGridShowSourceBadge) ...[
                const SizedBox(height: 3),
                _buildUpToDatePill(colorScheme, viewSettings, plusSettings),
              ],
              _buildProgressIndicator(),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildIconStack(
    double iconSize,
    double iconBorderRadius,
    double badgeSize,
    PlusSettingsProvider plusSettings,
    Color cardColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // App icon container — no background fill, icon renders directly on card surface
        Hero(
          tag: 'app_icon_${widget.appInMemory.app.id}',
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: ShapeDecoration(
              shape: CardMetrics.shape(
                iconBorderRadius,
                expressive: plusSettings.plusEnableMaterialExpressive,
              ),
              shadows: AppShadows.smooth(
                color: Colors.black,
                opacity: 0.10,
                blurFactor: 0.7,
              ),
            ),
            foregroundDecoration: plusSettings.plusIconRimBorder
                ? ShapeDecoration(
                    shape: CardMetrics.shape(
                      iconBorderRadius,
                      expressive: plusSettings.plusEnableMaterialExpressive,
                      side: BorderSide(
                        color: colorScheme.outline.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.25,
                        ),
                        width: 1.2,
                      ),
                    ),
                  )
                : null,
            child: AnimatedSwitcher(
              duration: Duration(
                milliseconds: plusSettings.plusEnableEnhancedAnimations
                    ? 350
                    : 0,
              ),
              switchInCurve: AppConstants.expressiveDecelerate,
              switchOutCurve: AppConstants.expressiveAccelerate,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.82,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: widget.appInMemory.icon != null
                  ? ClipPath(
                      key: ValueKey('icon_${widget.appInMemory.app.id}'),
                      clipper: ShapeBorderClipper(
                        shape: CardMetrics.shape(
                          iconBorderRadius,
                          expressive: plusSettings.plusEnableMaterialExpressive,
                        ),
                      ),
                      child: Image.memory(
                        widget.appInMemory.icon!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                        cacheWidth:
                            (iconSize * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        cacheHeight:
                            (iconSize * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                      ),
                    )
                  : AppIconShimmer(
                      key: const ValueKey('shimmer'),
                      size: iconSize,
                      borderRadius: iconBorderRadius,
                    ),
            ),
          ),
        ),
        // Update / install / progress action attached to the icon corner
        // (When plusUpdateExpressiveBadge is enabled, updates use the bottom
        // version capsule button instead of covering the icon corner, unless
        // a download is actively running or the app needs initial installation.)
        // Updates live in the top-right badge (or the expressive pill); the
        // icon corner keeps install / in-progress states.
        if (!widget.hasUpdate ||
            (plusSettings.plusUpdateExpressiveBadge &&
                widget.appInMemory.downloadProgress != null))
          Positioned(
            right: -(40 - (iconSize * 0.46).clamp(20.0, 28.0)) / 2 - 2,
            bottom: -(40 - (iconSize * 0.46).clamp(20.0, 28.0)) / 2 - 2,
            child: AppIconActionBadge(
              appInMemory: widget.appInMemory,
              hasUpdate: widget.hasUpdate,
              needsInstall:
                  widget.appInMemory.app.installedVersion == null &&
                  widget.appInMemory.app.additionalSettings['trackOnly'] !=
                      true,
              isAmbiguous: widget.isAmbiguous,
              iconSize: iconSize,
              ringColor: cardColor == Colors.transparent
                  ? colorScheme.surface
                  : cardColor,
              onPressed: () {
                context.read<AppsProvider>().downloadAndInstallLatestApps([
                  widget.appInMemory.app.id,
                ], context);
              },
            ),
          ),
      ],
    );
  }

  String _getVersionText() {
    final app = widget.appInMemory.app;
    if (app.disabled) return tr('disabled');
    final isTrackOnly = app.additionalSettings['trackOnly'] == true;
    final inst = app.installedVersion;
    final latest = app.latestVersion;
    if (widget.hasUpdate) {
      return latest.isNotEmpty ? latest : (inst ?? '');
    }
    if (inst == null) {
      if (latest.isNotEmpty) {
        return isTrackOnly ? latest : '${tr('notInstalled')} ($latest)';
      }
      return tr('notInstalled');
    }
    return inst;
  }

  String? _getDateText() {
    final app = widget.appInMemory.app;
    final date = app.releaseDate ?? app.lastUpdateCheck;
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date.toLocal());
  }

  /// Shows the update target version; when [plusUpdateExpressiveBadge] is enabled,
  /// renders as an interactive M3E action capsule with a download icon that triggers
  /// updating directly on tap.
  Widget _buildUpdateVersionPill(
    ColorScheme colorScheme,
    PlusSettingsProvider plusSettings,
  ) {
    if (!plusSettings.plusUpdateExpressiveBadge) {
      return _buildUpdateVersionLine(colorScheme);
    }
    final app = widget.appInMemory.app;
    final version = app.latestVersion.isNotEmpty
        ? app.latestVersion
        : tr('update');
    final isExpressivePill = plusSettings.plusUpdateExpressiveBadge;
    final bg = widget.isAmbiguous
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final fg = widget.isAmbiguous
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    final pillContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpressivePill ? 9 : 8,
        vertical: isExpressivePill ? 3.5 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
        border: isExpressivePill
            ? Border.all(color: fg.withValues(alpha: 0.25), width: 0.8)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExpressivePill) ...[
            Icon(
              widget.isAmbiguous
                  ? Icons.help_outline_rounded
                  : Icons.arrow_downward_rounded,
              size: 11,
              color: fg,
            ),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              version,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: 'monospace',
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isExpressivePill) return pillContent;

    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      scaleDownFactor: 0.90,
      onTap: () {
        AppHaptics.selectionClick();
        context.read<AppsProvider>().downloadAndInstallLatestApps([
          widget.appInMemory.app.id,
        ], context);
      },
      child: pillContent,
    );
  }

  /// Quiet "installed → latest" line; the top-right badge is the action.
  Widget _buildUpdateVersionLine(ColorScheme colorScheme) {
    final app = widget.appInMemory.app;
    final latest = app.latestVersion;
    final installed = app.installedVersion;
    final accent = widget.isAmbiguous
        ? colorScheme.tertiary
        : colorScheme.primary;
    const mono = TextStyle(
      fontSize: 10,
      fontFamily: 'monospace',
      letterSpacing: 0.1,
      height: 1.2,
    );
    return Text.rich(
      TextSpan(
        style: mono,
        children: [
          if (installed != null && installed.isNotEmpty && installed != latest)
            TextSpan(
              text: '$installed ',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          TextSpan(
            text: '→ ',
            style: TextStyle(color: accent.withValues(alpha: 0.8)),
          ),
          TextSpan(
            text: latest.isNotEmpty ? latest : tr('update'),
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      // Version strings read left-to-right even in RTL locales.
      textDirection: ui.TextDirection.ltr,
    );
  }

  Widget _buildUpToDatePill(
    ColorScheme colorScheme,
    ViewSettingsProvider viewSettings,
    PlusSettingsProvider plusSettings,
  ) {
    final parts = <String>[];
    if (viewSettings.displayShowVersion) {
      parts.add(_getVersionText());
    }
    if (viewSettings.displayShowAuthor &&
        widget.appInMemory.author.isNotEmpty) {
      parts.add(
        parts.isEmpty
            ? tr('byX', args: [widget.appInMemory.author])
            : widget.appInMemory.author,
      );
    }
    if (viewSettings.displayShowDate) {
      final d = _getDateText();
      if (d != null) parts.add(d);
    }
    final summaryText = parts.join(' • ');
    final showSource = plusSettings.plusGridShowSourceBadge;

    if (!showSource && summaryText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSource) _buildSourceBadge(context),
          if (summaryText.isNotEmpty) ...[
            if (showSource) const SizedBox(width: 4),
            Flexible(
              child: Text(
                summaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontFamily: viewSettings.displayShowVersion
                      ? 'monospace'
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChips(ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      runSpacing: 3,
      children: widget.appInMemory.app.tags
          .take(2)
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: Text(
                tag,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.85,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Shared factory for the small overlay badges (pinned, repo-renamed, selected).
  Widget _buildOverlayBadge({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    Color? borderColor,
    bool circle = false,
    bool shadow = false,
    String? tooltip,
  }) {
    final badge = Container(
      width: circle ? 22 : null,
      height: circle ? 22 : null,
      padding: circle ? null : const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 0.5)
            : null,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(icon, size: circle ? 14 : 11, color: iconColor),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: badge) : badge;
  }

  Color _getSourceColor(BuildContext context) {
    final url = widget.appInMemory.app.url.toLowerCase();
    if (url.contains('github.com')) return const Color(0xFF24292E);
    if (url.contains('f-droid.org')) return const Color(0xFF1976D2);
    if (url.contains('gitlab.com')) return const Color(0xFFFC6D26);
    if (url.contains('codeberg.org')) return const Color(0xFF2185D0);
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildSourceBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = widget.appInMemory.app.url.toLowerCase();
    IconData iconData = Icons.link_rounded;
    Color color = _getSourceColor(context);

    if (url.contains('github.com')) {
      iconData = Icons.terminal_rounded;
    } else if (url.contains('f-droid.org')) {
      iconData = Icons.android_rounded;
    } else if (url.contains('gitlab.com')) {
      iconData = Icons.account_tree_rounded;
    } else if (url.contains('codeberg.org')) {
      iconData = Icons.code_rounded;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.85)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Icon(iconData, size: 9, color: badgeColor),
    );
  }

  Widget _buildProgressIndicator() {
    return Builder(
      builder: (ctx) {
        final isChecking = ctx.select<AppsProvider, bool>(
          (p) => p.checkingUpdateIds.contains(widget.appInMemory.app.id),
        );
        return ValueListenableBuilder<double?>(
          valueListenable: widget.appInMemory.downloadProgressNotifier,
          builder: (context, downloadProgress, child) {
            if (downloadProgress != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            () {
                              if (downloadProgress < 0) {
                                final total =
                                    widget.appInMemory.downloadTotalBytes;
                                return total != null && total > 0
                                    ? '${tr('installing')} · ${formatBytes(total)}'
                                    : tr('installing');
                              }
                              final speed = formatSpeed(
                                widget.appInMemory.downloadSpeedBytesPerSec,
                              );
                              final safePercent =
                                  (downloadProgress.isNaN ||
                                      downloadProgress.isInfinite)
                                  ? 0
                                  : downloadProgress.toInt();
                              return speed != null
                                  ? '$safePercent% · $speed'
                                  : '$safePercent%';
                            }(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (downloadProgress >= 0)
                          GestureDetector(
                            onTap: () {
                              context.read<AppsProvider>().cancelDownload(
                                widget.appInMemory.app.id,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(Icons.close_rounded, size: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ExpressiveProgressIndicator(
                      value: downloadProgress >= 0
                          ? downloadProgress / 100
                          : null,
                      height: 3.5,
                    ),
                  ],
                ),
              );
            }
            if (isChecking) {
              return const Padding(
                padding: EdgeInsets.only(top: 6),
                child: ExpressiveProgressIndicator(value: null, height: 2),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  String _buildSemanticLabel() {
    final StringBuffer label = StringBuffer(widget.appInMemory.name);

    if (widget.hasUpdate) {
      label.write(', ${tr('updateAvailable')}');
    }

    if (widget.appInMemory.installedInfo != null) {
      label.write(', ${tr('installed')}');
    } else {
      label.write(', ${tr('notInstalled')}');
    }

    if (widget.appInMemory.app.pinned) {
      label.write(', pinned');
    }

    if (widget.appInMemory.app.tags.isNotEmpty) {
      label.write(', tags: ${widget.appInMemory.app.tags.join(", ")}');
    }

    if (widget.isSelected) {
      label.write(', selected');
    }

    if (widget.appInMemory.downloadProgress != null) {
      final progress = widget.appInMemory.downloadProgress! >= 0
          ? tr(
              'percentProgress',
              args: [widget.appInMemory.downloadProgress!.toInt().toString()],
            )
          : tr('installing');
      label.write(', $progress');
    }

    return label.toString();
  }
}

/// Update / install / progress action that lives on the corner of an app icon.
/// Tap starts the update (or opens the ambiguous-update flow); while a download
/// is running it shows a progress ring and tapping cancels it.
class AppIconActionBadge extends StatelessWidget {
  final AppInMemory appInMemory;
  final bool hasUpdate;
  final bool needsInstall;
  final bool isAmbiguous;
  final double iconSize;
  final VoidCallback? onPressed;
  final VoidCallback? onAmbiguous;
  final Color? ringColor;

  const AppIconActionBadge({
    super.key,
    required this.appInMemory,
    required this.hasUpdate,
    required this.needsInstall,
    required this.iconSize,
    this.isAmbiguous = false,
    this.onPressed,
    this.onAmbiguous,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final animate = context
        .watch<PlusSettingsProvider>()
        .plusEnableEnhancedAnimations;
    final checking = context.select<AppsProvider, bool>(
      (p) => p.checkingUpdateIds.contains(appInMemory.app.id),
    );
    final appId = appInMemory.app.id;
    final border = ringColor ?? cs.surfaceContainerLow;

    return ValueListenableBuilder<double?>(
      valueListenable: appInMemory.downloadProgressNotifier,
      builder: (ctx, progress, _) {
        final downloading = progress != null && progress >= 0;
        final installing = progress != null && progress < 0;
        if (!(progress != null || checking || hasUpdate || needsInstall)) {
          return const SizedBox.shrink();
        }
        final d = (iconSize * 0.46).clamp(20.0, 28.0).toDouble();
        final installStyle = needsInstall && !isAmbiguous;
        final Color bg = isAmbiguous
            ? cs.tertiaryContainer
            : (installStyle ? cs.primaryContainer : cs.secondaryContainer);
        final Color fg = isAmbiguous
            ? cs.onTertiaryContainer
            : (installStyle ? cs.onPrimaryContainer : cs.onSecondaryContainer);

        final String stateName;
        final Widget face;
        final String label;
        VoidCallback? tap;
        if (downloading) {
          stateName = 'download';
          label = tr('cancel');
          face = Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: d - 6,
                height: d - 6,
                child: ExpressiveCircularProgressIndicator(
                  value: (progress / 100).clamp(0.0, 1.0),
                  strokeWidth: 2.5,
                  color: fg,
                  backgroundColor: fg.withValues(alpha: 0.2),
                ),
              ),
              Icon(Icons.close_rounded, size: d * 0.4, color: fg),
            ],
          );
          tap = () {
            AppHaptics.selectionClick();
            context.read<AppsProvider>().cancelDownload(appId);
          };
        } else if (installing || checking) {
          stateName = 'busy';
          label = installing ? tr('installing') : tr('update');
          face = SizedBox(
            width: d - 6,
            height: d - 6,
            child: ExpressiveCircularProgressIndicator(
              strokeWidth: 2.5,
              color: fg,
              morph: false,
            ),
          );
          tap = null;
        } else {
          stateName = isAmbiguous ? 'ambiguous' : 'idle';
          label = isAmbiguous
              ? tr('ambiguousUpdate')
              : (needsInstall ? tr('install') : tr('update'));
          face = Icon(
            isAmbiguous ? Icons.help_outline_rounded : Icons.download_rounded,
            size: d * 0.6,
            color: fg,
          );
          if (isAmbiguous && onAmbiguous != null) {
            tap = () {
              AppHaptics.heavyImpact();
              onAmbiguous!();
            };
          } else if (onPressed != null) {
            final cb = onPressed!;
            tap = () {
              AppHaptics.selectionClick();
              cb();
            };
          }
        }

        return ScaleTouchWrapper(
          hapticOnPressDown: tap != null,
          scaleDownFactor: 0.85,
          child: Semantics(
            button: true,
            label: label,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                type: MaterialType.transparency,
                child: InkResponse(
                  onTap: tap,
                  customBorder: const CircleBorder(),
                  radius: 22,
                  child: Center(
                    child: Tooltip(
                      message: label,
                      child: Container(
                        width: d,
                        height: d,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: border, width: 2),
                        ),
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: animate ? 250 : 0),
                          child: KeyedSubtree(
                            key: ValueKey(stateName),
                            child: face,
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
      },
    );
  }
}

/// Top-right update action on grid tiles, shaped like the pinned badge.
/// Idle: up arrow (tap to update). Downloading: progress ring (tap cancels).
/// Installing / checking: spinner.
class _TileUpdateBadge extends StatelessWidget {
  final AppInMemory appInMemory;
  final bool isAmbiguous;
  final bool animsEnabled;

  const _TileUpdateBadge({
    required this.appInMemory,
    required this.isAmbiguous,
    required this.animsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appId = appInMemory.app.id;
    final checking = context.select<AppsProvider, bool>(
      (p) => p.checkingUpdateIds.contains(appId),
    );
    final bg = isAmbiguous ? cs.tertiary : cs.primary;
    final fg = isAmbiguous ? cs.onTertiary : cs.onPrimary;

    return ValueListenableBuilder<double?>(
      valueListenable: appInMemory.downloadProgressNotifier,
      builder: (context, progress, _) {
        final downloading = progress != null && progress >= 0;
        final busy = (progress != null && progress < 0) || checking;
        final String state;
        final Widget face;
        final String label;
        VoidCallback? tap;
        if (downloading) {
          state = 'download';
          label = tr('cancel');
          face = SizedBox(
            width: 14,
            height: 14,
            child: ExpressiveCircularProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              strokeWidth: 2,
              color: fg,
              backgroundColor: fg.withValues(alpha: 0.25),
            ),
          );
          tap = () {
            AppHaptics.selectionClick();
            context.read<AppsProvider>().cancelDownload(appId);
          };
        } else if (busy) {
          state = 'busy';
          label = progress != null ? tr('installing') : tr('update');
          face = SizedBox(
            width: 14,
            height: 14,
            child: ExpressiveCircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
              morph: false,
            ),
          );
        } else {
          state = 'idle';
          label = isAmbiguous ? tr('ambiguousUpdate') : tr('update');
          face = Icon(
            isAmbiguous
                ? Icons.help_outline_rounded
                : Icons.arrow_upward_rounded,
            size: 14,
            color: fg,
          );
          tap = () {
            AppHaptics.selectionClick();
            context.read<AppsProvider>().downloadAndInstallLatestApps([
              appId,
            ], context);
          };
        }

        return Semantics(
          button: tap != null,
          label: label,
          child: Tooltip(
            message: label,
            child: ScaleTouchWrapper(
              hapticOnPressDown: tap != null,
              scaleDownFactor: 0.85,
              onTap: tap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: bg.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: animsEnabled ? 220 : 0),
                      child: KeyedSubtree(key: ValueKey(state), child: face),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
