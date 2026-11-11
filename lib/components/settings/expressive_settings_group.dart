import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/app_constants.dart';

class ExpressiveSettingsGroup extends StatefulWidget {
  final String? title;
  final String? description;
  final String? helpText;
  final List<Widget> children;
  final bool isExpandable;
  final bool initiallyExpanded;
  final IconData? icon;
  final VoidCallback? onReset;
  final String? persistKey;

  const ExpressiveSettingsGroup({
    super.key,
    this.title,
    this.description,
    this.helpText,
    required this.children,
    this.isExpandable = false,
    this.initiallyExpanded = true,
    this.icon,
    this.onReset,
    this.persistKey,
  });

  @override
  State<ExpressiveSettingsGroup> createState() =>
      _ExpressiveSettingsGroupState();
}

class _ExpressiveSettingsGroupState extends State<ExpressiveSettingsGroup>
    with SingleTickerProviderStateMixin {
  static const _expandDuration = Duration(milliseconds: 300);
  static const _collapseDuration = Duration(milliseconds: 220);

  late AnimationController _expandController;
  late Animation<double> _iconTurnAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: _expandDuration,
      reverseDuration: _collapseDuration,
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );
    _iconTurnAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: Easing.emphasizedDecelerate,
        reverseCurve: Easing.emphasizedAccelerate,
      ),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  // Motion off jumps the controller (see below), so its durations only apply
  // when motion is on; no listening dependency needed here.
  void _handleExpansionChange(bool expanded) {
    AppHaptics.selectionClick();
    if (AppMotion.enabledNow(context)) {
      if (expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    } else {
      _expandController.value = expanded ? 1.0 : 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (isCompact, isM3E, useGlass, baseRadius, descriptionLines) = context
        .select<PlusSettingsProvider, (bool, bool, bool, double, int)>(
          (p) => (
            p.plusUseCompactSettings,
            p.plusEnableMaterialExpressive,
            p.plusEnableGlassmorphism,
            p.plusOverrideIndividualCornerRadius
                ? p.plusSettingsCornerRadius
                : p.plusGlobalCornerRadius,
            // Visual Lab description-lines knob (default 2 = shipped). Compact
            // density still hides group descriptions entirely.
            p.plusLabCompactDescriptionLines,
          ),
        );
    final cardAnimDuration = AppMotion.duration(
      context,
      const Duration(milliseconds: 200),
    );
    final colorScheme = Theme.of(context).colorScheme;

    final visibleChildren = widget.children.where((child) {
      if (child is SizedBox && child.child == null) return false;
      if (child is Visibility && !child.visible) return false;
      return true;
    }).toList();

    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    Widget content = Column(
      children: List.generate(visibleChildren.length, (index) {
        return Column(
          children: [
            if (isCompact)
              // Compact applies to every row in the group, including plain
              // ListTiles that don't check the setting themselves.
              Theme(data: _compactTheme(context), child: visibleChildren[index])
            else
              visibleChildren[index],
            if (index < visibleChildren.length - 1)
              Divider(
                height: 1,
                indent: isCompact ? 58 : 66,
                endIndent: isCompact ? 14 : 16,
                color: colorScheme.outlineVariant.withValues(
                  alpha: AppOpacity.low,
                ),
              ),
          ],
        );
      }),
    );

    final radius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(radius);
    final badgeSize = isCompact ? 30.0 : 36.0;

    // Build the leading icon widget (tinted container style)
    Widget? leadingWidget = widget.icon != null
        ? Container(
            width: badgeSize,
            height: badgeSize,
            decoration: ShapeDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: CardMetrics.shape(innerRadius, expressive: isM3E),
            ),
            child: Icon(
              widget.icon,
              color: colorScheme.primary,
              size: isCompact ? 16 : 20,
            ),
          )
        : null;

    // Custom trailing arrow with animation
    Widget trailingArrow = RotationTransition(
      turns: _iconTurnAnimation,
      child: Icon(
        Icons.expand_more_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
    );

    // For expandable groups, onReset has no header of its own to live in
    // (that header is only built for non-expandable groups below), so give
    // it a spot next to the expand arrow instead of dropping it silently.
    Widget trailing = widget.isExpandable && widget.onReset != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTouchWrapper(
                hapticOnPressDown: true,
                scaleDownFactor: 0.88,
                child: IconButton(
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  onPressed: widget.onReset,
                  tooltip: tr('resetToDefault'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              trailingArrow,
            ],
          )
        : trailingArrow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Non-expandable: section title shown above the card with identical icon axis
        if (widget.title != null && !widget.isExpandable)
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 14 : 16,
              isCompact ? 8 : 14,
              isCompact ? 14 : 16,
              isCompact ? 4 : 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (widget.icon != null) ...[
                        Container(
                          width: badgeSize,
                          height: badgeSize,
                          decoration: ShapeDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            shape: CardMetrics.shape(
                              innerRadius,
                              expressive: isM3E,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: colorScheme.primary,
                            size: isCompact ? 16 : 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title!,
                              style: _headerTitleStyle(context, colorScheme),
                            ),
                            if (!isCompact &&
                                (widget.description != null ||
                                    widget.helpText != null)) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.description ?? widget.helpText!,
                                maxLines: descriptionLines,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onReset != null)
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.88,
                    child: IconButton(
                      icon: const Icon(Icons.restore_rounded, size: 20),
                      onPressed: widget.onReset,
                      tooltip: tr('resetToDefault'),
                    ),
                  ),
              ],
            ),
          ),
        RepaintBoundary(
          child: AnimatedContainer(
            duration: cardAnimDuration,
            curve: Easing.emphasizedDecelerate,
            child: Card(
              elevation: 0,
              margin: EdgeInsets.symmetric(vertical: isCompact ? 2 : 6),
              color: colorScheme.surfaceContainerLow.withValues(
                alpha: useGlass ? 0.7 : 1.0,
              ),
              shape: CardMetrics.shape(
                radius,
                expressive: isM3E,
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.35
                        : 0.65,
                  ),
                ),
              ),
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: CardMetrics.shape(radius, expressive: isM3E),
                ),
                child: ConditionalBlur(
                  enabled: useGlass,
                  sigma: AppConstants.glassBlurSigmaSoft,
                  child: _buildCardContent(
                    context,
                    content,
                    trailing,
                    radius,
                    isCompact,
                    colorScheme,
                    leadingWidget: leadingWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ThemeData _compactTheme(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = theme.listTileTheme;
    return theme.copyWith(
      visualDensity: VisualDensity.compact,
      listTileTheme: tiles.copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        // Badges are 30-36px; a fixed slot keeps every title on one edge.
        minLeadingWidth: 36,
        titleTextStyle: tiles.titleTextStyle?.copyWith(fontSize: 14),
        subtitleTextStyle: tiles.subtitleTextStyle?.copyWith(fontSize: 12),
      ),
    );
  }

  /// Every group header uses this, expandable or not, so section titles read
  /// as one level above the rows inside them.
  TextStyle? _headerTitleStyle(BuildContext context, ColorScheme colorScheme) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      );

  Widget _buildCardContent(
    BuildContext context,
    Widget content,
    Widget trailing,
    double radius,
    bool isCompact,
    ColorScheme colorScheme, {
    Widget? leadingWidget,
  }) {
    if (!widget.isExpandable) return content;
    final animate = AppMotion.enabled(context);

    return Theme(
      // Remove the default ExpansionTile dividers
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey<String>(
          'expressive_settings_group:${widget.persistKey ?? widget.title ?? widget.hashCode.toString()}',
        ),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        expansionAnimationStyle: AnimationStyle(
          curve: Easing.emphasizedDecelerate,
          reverseCurve: Easing.emphasizedAccelerate,
          duration: animate ? _expandDuration : Duration.zero,
          reverseDuration: animate ? _collapseDuration : Duration.zero,
        ),
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: _handleExpansionChange,
        tilePadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 16,
          vertical: isCompact ? 0 : 4,
        ),
        childrenPadding: EdgeInsets.zero,
        leading: leadingWidget,
        trailing: trailing,
        title: Text(
          widget.title ?? tr('settings'),
          style: _headerTitleStyle(context, colorScheme),
        ),
        subtitle: (!isCompact && widget.description != null)
            ? Text(
                widget.description!,
                maxLines: context.select<PlusSettingsProvider, int>(
                  (p) => p.plusLabCompactDescriptionLines,
                ),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        children: [
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          PageStorage(bucket: PageStorageBucket(), child: content),
        ],
      ),
    );
  }
}
