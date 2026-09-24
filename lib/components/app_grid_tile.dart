import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'dart:ui';

class AppGridTile extends StatefulWidget {
  final AppInMemory appInMemory;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool hasUpdate;
  final bool isAmbiguous;

  const AppGridTile({
    super.key,
    required this.appInMemory,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    this.hasUpdate = false,
    this.isAmbiguous = false,
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
        // --- ADAPTIVE LAYOUT DETECTION ---
        final bool isHorizontal =
            constraints.maxWidth / constraints.maxHeight > 1.5;

        // Calculate responsive sizes based on available width
        double availableWidth =
            constraints.maxWidth - 24; // Account for padding

        // Icon size: adaptive
        double iconSize = isHorizontal
            ? (constraints.maxHeight * 0.7).clamp(40.0, 100.0)
            : (availableWidth * 0.65).clamp(40.0, 80.0);

        final plusSettings = context.watch<PlusSettingsProvider>();
        final viewSettings = context.watch<ViewSettingsProvider>();
        final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
            ? plusSettings.plusHomeCornerRadius
            : plusSettings.plusGlobalCornerRadius;
        // Radii follow the user's corner-radius setting like every other
        // card (previously derived from icon size and ignored it).
        double cardBorderRadius = CardMetrics.cardFor(
          baseRadius,
          constraints.maxWidth,
        );
        double iconBorderRadius = CardMetrics.inner(baseRadius);
        double padding = (availableWidth * 0.1).clamp(8.0, 12.0);
        double badgeSize = (iconSize * 0.25).clamp(12.0, 18.0);

        if (widget.appInMemory.icon == null) {
          context.read<AppsProvider>().updateAppIcon(widget.appInMemory.app.id);
        }

        final curve = plusSettings.plusEnableEnhancedAnimations
            ? (plusSettings.plusEnableMaterialExpressive
                  ? AppConstants.expressiveStandard
                  : AppConstants.standardStandard)
            : Curves.easeInOut;

        return AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
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
              color: widget.isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.7)
                  : widget.hasUpdate
                  ? Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.12)
                  : plusSettings.plusEnableGlassmorphism
                  ? Theme.of(context).colorScheme.surface.withValues(
                      alpha: AppConstants.glassSurfaceAlpha,
                    )
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : widget.hasUpdate
                    ? Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: AppOpacity.low)
                    : widget.appInMemory.app.pinned &&
                          plusSettings.plusPinnedBorderAccent
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.55)
                    : widget.appInMemory.app.pinned
                    ? Theme.of(context).colorScheme.outlineVariant
                    : plusSettings.plusEnableGlassmorphism
                    ? Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: AppConstants.glassBorderAlpha,
                      )
                    : Theme.of(context).colorScheme.outline.withValues(
                        alpha: 0.1,
                      ),
                width: widget.isSelected ||
                        (widget.appInMemory.app.pinned &&
                            plusSettings.plusPinnedBorderAccent) ||
                        widget.hasUpdate
                    ? 1.5
                    : 0.8,
              ),
              boxShadow: widget.isSelected
                  ? AppShadows.glow(
                      color: Theme.of(context).colorScheme.primary,
                      intensity: 0.6,
                    )
                  : widget.hasUpdate
                  ? AppShadows.smooth(
                      color: Theme.of(context).colorScheme.error,
                      opacity: 0.08,
                    )
                  : Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cardBorderRadius),
              child: Stack(
                children: [
                  // Backdrop blur clipped to the card — must stay inside
                  // ClipRRect or it blurs the whole screen behind the tile
                  if (plusSettings.plusEnableGlassmorphism)
                    Positioned.fill(
                      child: ConditionalBlur(
                        enabled: true,
                        sigma: AppConstants.glassBlurSigma,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  // Glass sheen — top-left source-color tint, fading to transparent
                  if (plusSettings.plusEnableGlassmorphism)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getSourceColor(context).withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.06),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.04),
                            ],
                            stops: const [0.0, 0.2, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),

                  // Top-left specular highlight streak
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

                  // Quick Actions Menu
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.transparent,
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                                color: Theme.of(context).colorScheme.error,
                                size: 20,
                              ),
                              title: Text(
                                tr('remove'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
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

                  // Pinned indicator overlay — top-left corner pin icon
                  if (widget.appInMemory.app.pinned && !widget.isSelected)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),

                  // Repo moved warning indicator
                  if (widget.appInMemory.app.hasPendingRepoRename)
                    Positioned(
                      top: 6,
                      left: widget.appInMemory.app.pinned && !widget.isSelected
                          ? 28
                          : 6,
                      child: Tooltip(
                        message: tr('repoRenamed'),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 10,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),

                  Semantics(
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
                        splashColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        highlightColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.06),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
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
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconStack(
            iconSize,
            iconBorderRadius,
            badgeSize,
            plusSettings,
          ),
          const SizedBox(height: 8),
          _buildAppInfo(plusSettings, viewSettings, TextAlign.center),
        ],
      ),
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
        const SizedBox(width: 20),
        Expanded(
          child: _buildAppInfo(plusSettings, viewSettings, TextAlign.start),
        ),
        Icon(
          Icons.chevron_right_rounded,
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
        // Icon with layered depth shadow and subtle squircle container
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
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                      width: 1.0,
                    )
                  : Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
              boxShadow: widget.hasUpdate
                  ? AppShadows.smooth(
                      color: colorScheme.error,
                      opacity: 0.14,
                    )
                  : AppShadows.smooth(
                      color: Colors.black,
                      opacity: 0.1,
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
        // Update badge — pulsing glow dot with arrow accent
        if (widget.hasUpdate)
          Positioned(
            right: -5,
            top: -5,
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
      return '${inst ?? '?'} → ${latest ?? '?'}';
    }
    return inst ?? tr('notInstalled');
  }

  Widget _buildAppInfo(
    PlusSettingsProvider plusSettings,
    ViewSettingsProvider viewSettings,
    TextAlign textAlign,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCentered = textAlign == TextAlign.center;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // App name row with source badge
        Row(
          mainAxisAlignment:
              isCentered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                widget.appInMemory.name,
                maxLines: 1,
                textAlign: textAlign,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.appInMemory.app.pinned || widget.hasUpdate
                          ? FontWeight.w700
                          : FontWeight.w600,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildSourceBadge(context),
          ],
        ),
        // Author line
        if (viewSettings.displayShowAuthor)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              tr('byX', args: [widget.appInMemory.author]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.1,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        // Version — pill styling when update available, plain otherwise
        if (viewSettings.displayShowVersion)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: widget.hasUpdate
                ? _buildUpdateVersionPill(colorScheme, isCentered)
                : Text(
                    _getVersionText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: textAlign,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.65,
                      ),
                      fontFamily: 'monospace',
                    ),
                  ),
          ),
        // Tag chips
        if (plusSettings.plusShowTagsInList &&
            widget.appInMemory.app.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              alignment: isCentered ? WrapAlignment.center : WrapAlignment.start,
              spacing: 3,
              runSpacing: 3,
              children: widget.appInMemory.app.tags
                  .take(2)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
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
                          fontSize: 9,
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
            ),
          ),
        // Progress / checking indicator
        _buildProgressIndicator(),
      ],
    );
  }

  /// Styled pill showing the version transition when an update is available.
  Widget _buildUpdateVersionPill(ColorScheme colorScheme, bool isCentered) {
    final app = widget.appInMemory.app;
    final inst = app.installedVersion ?? '?';
    final latest = app.latestVersion ?? '?';
    return Align(
      alignment: isCentered ? Alignment.center : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_upward_rounded,
              size: 8,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '$inst → $latest',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  fontFamily: 'monospace',
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
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

    // Use theme-aware color for dark mode legibility
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.8)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
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
                padding: const EdgeInsets.only(top: 6),
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
                            fontSize: 10,
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
                              child: Icon(Icons.close_rounded, size: 14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ExpressiveProgressIndicator(
                      value: downloadProgress >= 0 ? downloadProgress / 100 : null,
                      height: 4,
                    ),
                  ],
                ),
              );
            }
            if (isChecking) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ExpressiveProgressIndicator(value: null, height: 2),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  /// Builds a semantic label for screen readers
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
