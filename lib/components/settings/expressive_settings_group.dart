import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
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
  late bool _isExpanded;
  late AnimationController _expandController;
  late Animation<double> _iconTurnAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
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

  void _handleExpansionChange(bool expanded) {
    AppHaptics.selectionClick();
    setState(() => _isExpanded = expanded);
    final animsEnabled = context
        .read<PlusSettingsProvider>()
        .plusEnableEnhancedAnimations;
    if (animsEnabled) {
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
    final plusSettings = Provider.of<PlusSettingsProvider>(context);
    final isCompact = plusSettings.plusUseCompactSettings;
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
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(visualDensity: VisualDensity.compact),
                child: visibleChildren[index],
              )
            else
              visibleChildren[index],
            if (index < visibleChildren.length - 1)
              Divider(
                height: 1,
                indent: isCompact ? 16 : 56,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(
                  alpha: AppOpacity.low,
                ),
              ),
          ],
        );
      }),
    );

    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;

    // Build the leading icon widget (tinted container style)
    Widget? leadingWidget = widget.icon != null
        ? AnimatedContainer(
            duration: Duration(
              milliseconds: plusSettings.plusEnableEnhancedAnimations ? 260 : 0,
            ),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(
                alpha: _isExpanded ? 0.22 : 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: colorScheme.primary,
              size: isCompact ? 18 : 20,
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
        // Non-expandable: section title shown above the card
        if (widget.title != null && !widget.isExpandable)
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              isCompact ? 10 : 16,
              16,
              isCompact ? 4 : 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (widget.icon != null) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            widget.icon,
                            color: colorScheme.primary,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title!,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                            ),
                            if (widget.description != null ||
                                widget.helpText != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.description ?? widget.helpText!,
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
            duration: Duration(
              milliseconds: plusSettings.plusEnableEnhancedAnimations ? 200 : 0,
            ),
            curve: Curves.easeOutCubic,
            child: Card(
              elevation: 0,
              margin: EdgeInsets.symmetric(vertical: isCompact ? 2 : 6),
              color: colorScheme.surfaceContainerLow.withValues(
                alpha: plusSettings.plusEnableGlassmorphism ? 0.7 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
                side: BorderSide(
                  color: _isExpanded
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.35
                              : 0.65,
                        ),
                  width: _isExpanded ? 1.2 : 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ConditionalBlur(
                  enabled: plusSettings.plusEnableGlassmorphism,
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
    final plusSettings = context.watch<PlusSettingsProvider>();

    return Theme(
      // Remove the default ExpansionTile dividers
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(
          'expressive_settings_group:${widget.persistKey ?? widget.title ?? widget.hashCode.toString()}',
        ),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        expansionAnimationStyle: AnimationStyle(
          curve: Easing.emphasizedDecelerate,
          reverseCurve: Easing.emphasizedAccelerate,
          duration: Duration(
            milliseconds: plusSettings.plusEnableEnhancedAnimations ? 300 : 0,
          ),
          reverseDuration: Duration(
            milliseconds: plusSettings.plusEnableEnhancedAnimations ? 220 : 0,
          ),
        ),
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: _handleExpansionChange,
        tilePadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isCompact ? 2 : 4,
        ),
        childrenPadding: EdgeInsets.zero,
        leading: leadingWidget,
        trailing: trailing,
        title: Text(
          widget.title ?? 'Settings',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _isExpanded ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        subtitle: widget.description != null
            ? Text(
                widget.description!,
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
          content,
        ],
      ),
    );
  }
}
