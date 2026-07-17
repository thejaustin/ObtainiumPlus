import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
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
                  : Theme.of(context).colorScheme.surface.withValues(
                      alpha: plusSettings.plusEnableGlassmorphism ? 0.45 : 1.0,
                    ),
              border: Border.all(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : widget.hasUpdate
                    ? Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: AppOpacity.low)
                    : widget.appInMemory.app.pinned
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outline.withValues(
                        alpha: plusSettings.plusEnableGlassmorphism ? 0.1 : 0,
                      ),
                width:
                    widget.isSelected ||
                        widget.appInMemory.app.pinned ||
                        widget.hasUpdate
                    ? 1.5
                    : 0.8,
              ),
              boxShadow: widget.isSelected
                  ? AppShadows.glow(
                      color: Theme.of(context).colorScheme.primary,
                      intensity: 0.6,
                    )
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
                        sigma: 10,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  // Glass sheen
                  if (plusSettings.plusEnableGlassmorphism)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.02),
                            ],
                            stops: const [0.0, 0.4, 1.0],
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

                  Semantics(
                    label: _buildSemanticLabel(),
                    button: true,
                    selected: widget.isSelected,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) {
                        setState(() => _isPressed = false);
                        widget.onTap();
                      },
                      onTapCancel: () => setState(() => _isPressed = false),
                      onLongPressStart: (_) {
                        setState(() => _isPressed = true);
                        AppHaptics.mediumImpact();
                      },
                      onLongPressEnd: (_) {
                        setState(() => _isPressed = false);
                        widget.onLongPress();
                      },
                      child: InkWell(
                        onTap: null, // Handled by GestureDetector
                        onLongPress: null, // Handled by GestureDetector
                        borderRadius: BorderRadius.circular(cardBorderRadius),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconStack(iconSize, iconBorderRadius, badgeSize),
        const SizedBox(height: 10),
        _buildAppInfo(plusSettings, viewSettings, TextAlign.center),
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
        _buildIconStack(iconSize, iconBorderRadius, badgeSize),
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
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Hero(
          tag: 'app_icon_${widget.appInMemory.app.id}',
          child: Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(iconBorderRadius),
              boxShadow: widget.hasUpdate
                  ? AppShadows.smooth(
                      color: Theme.of(context).colorScheme.error,
                      opacity: 0.1,
                    )
                  : null,
            ),
            child: widget.appInMemory.icon != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(iconBorderRadius),
                    child: Image.memory(
                      widget.appInMemory.icon!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                : AppIconShimmer(
                    size: iconSize,
                    borderRadius: iconBorderRadius,
                  ),
          ),
        ),
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
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: AppShadows.glow(
                        color: widget.isAmbiguous
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.primary,
                        intensity: (_pulseAnimation.value - 1.0) * 2,
                      ),
                    ),
                    child: widget.isAmbiguous
                        ? Icon(
                            Icons.help_outline_rounded,
                            size: badgeSize * 0.7,
                            color: Theme.of(context).colorScheme.onTertiary,
                          )
                        : null,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: textAlign == TextAlign.start
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: textAlign == TextAlign.start
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                widget.appInMemory.name,
                maxLines: 1,
                textAlign: textAlign,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.appInMemory.app.pinned || widget.hasUpdate
                      ? FontWeight.bold
                      : FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildSourceBadge(context),
          ],
        ),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        if (viewSettings.displayShowVersion)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _getVersionText(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: TextStyle(
                fontSize: 10,
                color: widget.hasUpdate
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: widget.hasUpdate
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        if (plusSettings.plusShowTagsInList &&
            widget.appInMemory.app.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              alignment: textAlign == TextAlign.start
                  ? WrapAlignment.start
                  : WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: widget.appInMemory.app.tags
                  .take(2)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        // Checking / Progress logic...
        _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    final url = widget.appInMemory.app.url.toLowerCase();
    IconData iconData = Icons.link_rounded;
    Color color = Theme.of(context).colorScheme.primary;

    if (url.contains('github.com')) {
      iconData = Icons.terminal_rounded;
      color = const Color(0xFF24292E);
    } else if (url.contains('f-droid.org')) {
      iconData = Icons.android_rounded;
      color = const Color(0xFF1976D2);
    } else if (url.contains('gitlab.com')) {
      iconData = Icons.account_tree_rounded;
      color = const Color(0xFFFC6D26);
    } else if (url.contains('codeberg.org')) {
      iconData = Icons.code_rounded;
      color = const Color(0xFF2185D0);
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(iconData, size: 8, color: color),
    );
  }

  Widget _buildProgressIndicator() {
    return Builder(
      builder: (ctx) {
        final isChecking = ctx.select<AppsProvider, bool>(
          (p) => p.checkingUpdateIds.contains(widget.appInMemory.app.id),
        );
        if (widget.appInMemory.downloadProgress != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ExpressiveProgressIndicator(
              value: widget.appInMemory.downloadProgress! >= 0
                  ? widget.appInMemory.downloadProgress! / 100
                  : null,
              height: 4,
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
