import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
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

  const AppGridTile({
    super.key,
    required this.appInMemory,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.hasUpdate = false,
    this.isAmbiguous = false,
    this.categoryColor,
  });

  @override
  State<AppGridTile> createState() => _AppGridTileState();
}

class _AppGridTileState extends State<AppGridTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.hasUpdate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AppGridTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasUpdate && !oldWidget.hasUpdate) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasUpdate && oldWidget.hasUpdate) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptive horizontal layout detection (e.g. tablet landscape rows or 1-column grids)
        final bool isHorizontal =
            constraints.maxWidth / constraints.maxHeight > 1.5;

        final double availableWidth = constraints.maxWidth - 20;

        // Adaptive icon sizing proportional to tile width
        final double iconSize = isHorizontal
            ? (constraints.maxHeight * 0.65).clamp(38.0, 80.0)
            : (availableWidth * 0.52).clamp(38.0, 68.0);

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
        final double padding = (availableWidth * 0.08).clamp(6.0, 12.0);
        final double badgeSize = (iconSize * 0.28).clamp(14.0, 20.0);

        if (widget.appInMemory.icon == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.appInMemory.icon == null) {
              context.read<AppsProvider>().updateAppIcon(widget.appInMemory.app.id);
            }
          });
        }

        // Resolve category color for M3E accent ribbon
        final Color? resolvedCategoryColor = widget.categoryColor ??
            (widget.appInMemory.app.categories.isNotEmpty &&
                    viewSettings.categories[widget.appInMemory.app.categories.first] != null
                ? Color(viewSettings.categories[widget.appInMemory.app.categories.first]!)
                : null);

        final curve = plusSettings.plusEnableEnhancedAnimations
            ? (plusSettings.plusEnableMaterialExpressive
                  ? AppConstants.expressiveStandard
                  : AppConstants.standardStandard)
            : Curves.easeInOut;

        // Surface color tokens aligned with Material 3 Expressive
        Color cardColor;
        if (widget.isSelected) {
          cardColor = colorScheme.primaryContainer.withValues(alpha: 0.85);
        } else if (plusSettings.plusEnableGlassmorphism) {
          cardColor = colorScheme.surface.withValues(
            alpha: AppConstants.glassSurfaceAlpha,
          );
        } else if (widget.hasUpdate) {
          cardColor = colorScheme.surfaceContainer;
        } else {
          cardColor = colorScheme.surfaceContainerLow;
        }

        // Border styling with M3E stroke hierarchy
        Border cardBorder;
        if (widget.isSelected) {
          cardBorder = Border.all(color: colorScheme.primary, width: 2.0);
        } else if (widget.appInMemory.app.pinned && plusSettings.plusPinnedBorderAccent) {
          cardBorder = Border.all(
            color: colorScheme.primary.withValues(alpha: 0.65),
            width: 1.5,
          );
        } else if (widget.hasUpdate) {
          cardBorder = Border.all(
            color: (widget.isAmbiguous ? colorScheme.tertiary : colorScheme.primary)
                .withValues(alpha: 0.45),
            width: 1.2,
          );
        } else if (plusSettings.plusEnableGlassmorphism) {
          cardBorder = Border.all(
            color: colorScheme.onSurface.withValues(
              alpha: AppConstants.glassBorderAlpha,
            ),
            width: 0.8,
          );
        } else {
          cardBorder = Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.8,
          );
        }

        List<BoxShadow>? cardShadow;
        if (widget.isSelected) {
          cardShadow = AppShadows.glow(
            color: colorScheme.primary,
            intensity: 0.5,
          );
        } else if (widget.hasUpdate) {
          cardShadow = AppShadows.smooth(
            color: widget.isAmbiguous ? colorScheme.tertiary : colorScheme.primary,
            opacity: isDark ? 0.2 : 0.08,
            blurFactor: 0.8,
          );
        } else if (!isDark) {
          cardShadow = [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ];
        }

        return AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: curve,
          child: AnimatedContainer(
            duration: Duration(
              milliseconds: plusSettings.plusEnableEnhancedAnimations
                  ? AppConstants.shortAnimationMs
                  : 200,
            ),
            curve: plusSettings.plusEnableEnhancedAnimations
                ? Curves.easeOutCubic
                : Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardBorderRadius),
              color: cardColor,
              border: cardBorder,
              boxShadow: cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cardBorderRadius),
              child: Stack(
                children: [
                  // 1. Backdrop blur (clipped inside card)
                  if (plusSettings.plusEnableGlassmorphism)
                    Positioned.fill(
                      child: ConditionalBlur(
                        enabled: true,
                        sigma: AppConstants.glassBlurSigma,
                        child: const SizedBox.expand(),
                      ),
                    ),

                  // 2. Glass sheen gradient
                  if (plusSettings.plusEnableGlassmorphism)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getSourceColor(context).withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.05),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.03),
                            ],
                            stops: const [0.0, 0.2, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),

                  // 3. Top specular highlight streak
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
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 4. Category Accent Ribbon (M3E)
                  if (plusSettings.plusCategoryAccentRibbon &&
                      resolvedCategoryColor != null)
                    Positioned(
                      top: 0,
                      left: cardBorderRadius * 0.5,
                      right: cardBorderRadius * 0.5,
                      child: Container(
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: resolvedCategoryColor,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: resolvedCategoryColor.withValues(alpha: 0.4),
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            AppHaptics.selectionClick();
                            widget.onTap();
                          },
                          onLongPress: () {
                            AppHaptics.mediumImpact();
                            widget.onLongPress();
                          },
                          onHighlightChanged: (highlighted) {
                            setState(() => _isPressed = highlighted);
                          },
                          borderRadius: BorderRadius.circular(cardBorderRadius),
                          splashColor: colorScheme.primary.withValues(alpha: 0.12),
                          highlightColor:
                              colorScheme.primary.withValues(alpha: 0.06),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: padding,
                              vertical: padding + 2,
                            ),
                            child: isHorizontal
                                ? _buildHorizontalContent(
                                    iconSize,
                                    iconBorderRadius,
                                    badgeSize,
                                    plusSettings,
                                    viewSettings,
                                  )
                                : _buildVerticalContent(
                                    iconSize,
                                    iconBorderRadius,
                                    badgeSize,
                                    plusSettings,
                                    viewSettings,
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
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 11,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                  // 7. Repo Renamed Indicator
                  if (widget.appInMemory.app.hasPendingRepoRename)
                    Positioned(
                      top: 6,
                      left: (widget.appInMemory.app.pinned && !widget.isSelected)
                          ? 30
                          : 6,
                      child: Tooltip(
                        message: tr('repoRenamed'),
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.error.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 11,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),

                  // 8. Multi-Select Checkmark OR 3-Dots Menu (Top-Right)
                  if (widget.isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.transparent,
                        child: PopupMenuButton<String>(
                          tooltip: tr('more'),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 150),
                          onSelected: (value) {
                            AppHaptics.selectionClick();
                            final appsProvider = context.read<AppsProvider>();
                            switch (value) {
                              case 'togglePin':
                                widget.appInMemory.app.pinned =
                                    !widget.appInMemory.app.pinned;
                                appsProvider.saveApps([widget.appInMemory.app]);
                                break;
                              case 'settings':
                                appsProvider.openAppSettings(
                                  widget.appInMemory.app.id,
                                );
                                break;
                              case 'copyUrl':
                                Clipboard.setData(
                                  ClipboardData(text: widget.appInMemory.app.url),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr('copiedToClipboard')),
                                  ),
                                );
                                break;
                              case 'remove':
                                appsProvider.removeAppsWithModal(context, [
                                  widget.appInMemory.app,
                                ]);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'togglePin',
                              child: ListTile(
                                leading: Icon(
                                  widget.appInMemory.app.pinned
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: 20,
                                ),
                                title: Text(
                                  widget.appInMemory.app.pinned
                                      ? tr('unpin')
                                      : tr('pin'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                dense: true,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'settings',
                              child: ListTile(
                                leading: const Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                ),
                                title: Text(
                                  tr('settings'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                dense: true,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'copyUrl',
                              child: ListTile(
                                leading: const Icon(Icons.copy_rounded, size: 20),
                                title: Text(
                                  tr('copyAppURL'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                dense: true,
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete_outline_rounded,
                                  color: colorScheme.error,
                                  size: 20,
                                ),
                                title: Text(
                                  tr('remove'),
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                                dense: true,
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
      },
    );
  }

  Widget _buildVerticalContent(
    double iconSize,
    double iconBorderRadius,
    double badgeSize,
    PlusSettingsProvider plusSettings,
    ViewSettingsProvider viewSettings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconStack(
          iconSize,
          iconBorderRadius,
          badgeSize,
          plusSettings,
        ),
        const SizedBox(height: 7),
        // App name: up to 2 lines, centered with expressive typography
        Text(
          widget.appInMemory.name,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: (widget.appInMemory.app.pinned || widget.hasUpdate)
                ? FontWeight.w700
                : FontWeight.w600,
            letterSpacing: -0.2,
            height: 1.15,
            color: colorScheme.onSurface,
          ),
        ),
        // Metadata / Version Pill / Status
        if (widget.hasUpdate) ...[
          const SizedBox(height: 4),
          _buildUpdateVersionPill(colorScheme),
        ] else if (viewSettings.displayShowVersion || viewSettings.displayShowAuthor) ...[
          const SizedBox(height: 3),
          _buildMetadataLine(colorScheme, viewSettings),
        ],
        // Tag chips
        if (plusSettings.plusShowTagsInList &&
            widget.appInMemory.app.tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildTagChips(colorScheme),
        ],
        // Download / checking progress indicator
        _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildHorizontalContent(
    double iconSize,
    double iconBorderRadius,
    double badgeSize,
    PlusSettingsProvider plusSettings,
    ViewSettingsProvider viewSettings,
  ) {
    return Row(
      children: [
        _buildIconStack(
          iconSize,
          iconBorderRadius,
          badgeSize,
          plusSettings,
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
                  fontWeight:
                      widget.appInMemory.app.pinned || widget.hasUpdate
                          ? FontWeight.w700
                          : FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (widget.hasUpdate) ...[
                const SizedBox(height: 4),
                _buildUpdateVersionPill(Theme.of(context).colorScheme),
              ] else if (viewSettings.displayShowVersion || viewSettings.displayShowAuthor) ...[
                const SizedBox(height: 3),
                _buildMetadataLine(
                  Theme.of(context).colorScheme,
                  viewSettings,
                ),
              ],
              _buildProgressIndicator(),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildIconStack(
    double iconSize,
    double iconBorderRadius,
    double badgeSize,
    PlusSettingsProvider plusSettings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // App icon container with layered depth shadow
        Hero(
          tag: 'app_icon_${widget.appInMemory.app.id}',
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(iconBorderRadius),
              border: plusSettings.plusIconRimBorder
                  ? Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1.0,
                    )
                  : Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
              boxShadow: widget.hasUpdate
                  ? AppShadows.smooth(
                      color: widget.isAmbiguous
                          ? colorScheme.tertiary
                          : colorScheme.primary,
                      opacity: 0.16,
                      blurFactor: 0.8,
                    )
                  : AppShadows.smooth(
                      color: Colors.black,
                      opacity: 0.08,
                      blurFactor: 0.6,
                    ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: widget.appInMemory.icon != null
                  ? ClipRRect(
                      key: ValueKey('icon_${widget.appInMemory.app.id}'),
                      borderRadius: BorderRadius.circular(iconBorderRadius),
                      child: Image.memory(
                        widget.appInMemory.icon!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
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
        // Update badge — pulsing glow circle on icon
        if (widget.hasUpdate)
          Positioned(
            right: -4,
            top: -4,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      color: widget.isAmbiguous
                          ? colorScheme.tertiary
                          : colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: AppShadows.glow(
                        color: widget.isAmbiguous
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                        intensity: (_pulseAnimation.value - 1.0) * 2,
                      ),
                    ),
                    child: Center(
                      child: widget.isAmbiguous
                          ? Icon(
                              Icons.help_outline_rounded,
                              size: badgeSize * 0.6,
                              color: colorScheme.onTertiary,
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              size: badgeSize * 0.6,
                              color: colorScheme.onPrimary,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _getVersionText() {
    final app = widget.appInMemory.app;
    final inst = app.installedVersion;
    final latest = app.latestVersion;
    if (widget.hasUpdate) {
      return latest ?? inst ?? '';
    }
    return inst ?? tr('notInstalled');
  }

  /// Interactive update pill with 1-tap download & install action
  Widget _buildUpdateVersionPill(ColorScheme colorScheme) {
    final app = widget.appInMemory.app;
    final version = app.latestVersion?.isNotEmpty == true
        ? '↓ ${app.latestVersion!}'
        : tr('update');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppHaptics.selectionClick();
          context.read<AppsProvider>().downloadAndInstallLatestApps([
            widget.appInMemory.app.id,
          ], context);
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: (widget.isAmbiguous
                    ? colorScheme.tertiaryContainer
                    : colorScheme.primaryContainer)
                .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.isAmbiguous
                      ? colorScheme.tertiary
                      : colorScheme.primary)
                  .withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isAmbiguous
                    ? Icons.help_outline_rounded
                    : Icons.download_rounded,
                size: 10,
                color: widget.isAmbiguous
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  version,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: widget.isAmbiguous
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onPrimaryContainer,
                    fontFamily: 'monospace',
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataLine(
    ColorScheme colorScheme,
    ViewSettingsProvider viewSettings,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSourceBadge(context),
        if (viewSettings.displayShowVersion &&
            (widget.appInMemory.app.installedVersion != null ||
                widget.appInMemory.installedInfo != null)) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _getVersionText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ] else if (viewSettings.displayShowAuthor) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tr('byX', args: [widget.appInMemory.author]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                letterSpacing: 0.1,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ],
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
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.15),
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
                        Text(
                          downloadProgress >= 0
                              ? '${downloadProgress.toInt()}%'
                              : tr('installing'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
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
                      value: downloadProgress >= 0 ? downloadProgress / 100 : null,
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
