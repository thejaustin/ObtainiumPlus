import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/settings/connected_settings_bar.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/motion.dart';

/// Representation of a sibling subpage in a group (e.g. Appearance hub sections).
class SettingsSubpageSibling {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final Widget child;

  const SettingsSubpageSibling({
    required this.title,
    this.subtitle,
    required this.icon,
    this.accentColor,
    required this.child,
  });
}

/// A dedicated Material 3 Expressive subpage for settings sections
/// (replacing slide-up bottom sheets) with adaptive width centering,
/// one-handed mode integration, lateral sibling navigation, and native predictive back navigation.
class SettingsSubpage extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final List<SettingsSubpageSibling>? siblings;
  final int? currentSiblingIndex;
  final List<ConnectedSettingItem>? connectedItems;
  final List<Widget>? actions;
  final VoidCallback? onReset;
  final Widget child;

  const SettingsSubpage({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.siblings,
    this.currentSiblingIndex,
    this.connectedItems,
    this.actions,
    this.onReset,
    required this.child,
  });

  @override
  State<SettingsSubpage> createState() => _SettingsSubpageState();
}

class _SettingsSubpageState extends State<SettingsSubpage> {
  late final ScrollController _siblingScrollController;
  final List<GlobalKey> _siblingKeys = [];
  late int _currentIndex;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _siblingScrollController = ScrollController();
    _currentIndex = widget.currentSiblingIndex ?? 0;
    _previousIndex = _currentIndex;
    if (widget.siblings != null && widget.siblings!.isNotEmpty) {
      _siblingKeys.addAll(
        List.generate(widget.siblings!.length, (_) => GlobalKey()),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveSibling();
      });
    }
  }

  void _scrollToActiveSibling() {
    if (!mounted || _currentIndex >= _siblingKeys.length) {
      return;
    }
    final key = _siblingKeys[_currentIndex];
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: AppMotion.enabledNow(context)
            ? const Duration(milliseconds: 240)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _siblingScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final isCompact = plusSettings.plusUseCompactSettings;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);
    final innerRadius = CardMetrics.inner(cardRadius);

    final hasSiblings = widget.siblings != null && widget.siblings!.isNotEmpty;
    final currentSibling =
        hasSiblings && _currentIndex < widget.siblings!.length
        ? widget.siblings![_currentIndex]
        : null;
    final activeTitle = currentSibling?.title ?? widget.title;
    final activeSubtitle = currentSibling?.subtitle ?? widget.subtitle;
    final activeIcon = currentSibling?.icon ?? widget.icon;
    final resolvedAccent =
        currentSibling?.accentColor ??
        widget.accentColor ??
        colorScheme.primary;
    final activeChild = currentSibling?.child ?? widget.child;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double hPadding = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;

    final effectiveActions = <Widget>[
      if (widget.onReset != null)
        IconButton(
          icon: const Icon(Icons.restore_rounded),
          tooltip: tr('resetToDefault'),
          onPressed: widget.onReset,
        ),
      if (widget.actions != null) ...widget.actions!,
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: plusSettings.scrollPhysics,
        slivers: [
          CustomAppBar(
            title: activeTitle,
            subtitle: activeSubtitle,
            actions: effectiveActions.isNotEmpty ? effectiveActions : null,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // M3 Expressive Masthead Card
                  if (activeIcon != null) ...[
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
                      color: plusSettings.plusEnableGlassmorphism
                          ? colorScheme.surfaceContainerLow.withValues(
                              alpha: 0.75,
                            )
                          : colorScheme.surfaceContainerLow,
                      shape: CardMetrics.shape(
                        cardRadius,
                        expressive: isM3E,
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.35
                                : 0.65,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -16,
                            right: -16,
                            child: IgnorePointer(
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      resolvedAccent.withValues(alpha: 0.18),
                                      resolvedAccent.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(isCompact ? 12 : 16),
                            child: Row(
                              children: [
                                Container(
                                  width: isCompact ? 38 : 46,
                                  height: isCompact ? 38 : 46,
                                  decoration: ShapeDecoration(
                                    color: resolvedAccent.withValues(
                                      alpha: 0.16,
                                    ),
                                    shape: CardMetrics.shape(
                                      innerRadius,
                                      expressive: isM3E,
                                    ),
                                  ),
                                  child: Icon(
                                    activeIcon,
                                    size: isCompact ? 20 : 24,
                                    color: resolvedAccent,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeTitle,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      if (activeSubtitle != null &&
                                          activeSubtitle.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          activeSubtitle,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                height: 1.25,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Lateral Sibling Navigation Bar
                  if (widget.siblings != null &&
                      widget.siblings!.length > 1) ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: isCompact ? 8 : 12),
                      child: SingleChildScrollView(
                        controller: _siblingScrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: List.generate(widget.siblings!.length, (
                            index,
                          ) {
                            final sibling = widget.siblings![index];
                            final isCurrent = index == _currentIndex;
                            final siblingAccent =
                                sibling.accentColor ?? resolvedAccent;
                            final chipRadius = CardMetrics.inner(cardRadius);
                            final chipKey = index < _siblingKeys.length
                                ? _siblingKeys[index]
                                : null;

                            return Padding(
                              key: chipKey,
                              padding: EdgeInsets.only(
                                right: index < widget.siblings!.length - 1
                                    ? 8.0
                                    : 0.0,
                              ),
                              child: ScaleTouchWrapper(
                                hapticOnPressDown: true,
                                scaleDownFactor: 0.94,
                                child: Material(
                                  color: isCurrent
                                      ? siblingAccent.withValues(
                                          alpha: isM3E ? 0.22 : 0.16,
                                        )
                                      : (plusSettings.plusEnableGlassmorphism
                                            ? colorScheme.surfaceContainerLow
                                                  .withValues(alpha: 0.72)
                                            : colorScheme.surfaceContainerLow),
                                  shape: CardMetrics.shape(
                                    chipRadius,
                                    expressive: isM3E,
                                    side: BorderSide(
                                      color: isCurrent
                                          ? siblingAccent.withValues(alpha: 0.6)
                                          : colorScheme.outlineVariant
                                                .withValues(
                                                  alpha:
                                                      theme.brightness ==
                                                          Brightness.dark
                                                      ? 0.35
                                                      : 0.65,
                                                ),
                                      width: isCurrent ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: InkWell(
                                    customBorder: CardMetrics.shape(
                                      chipRadius,
                                      expressive: isM3E,
                                    ),
                                    onTap: isCurrent
                                        ? null
                                        : () {
                                            AppHaptics.selectionClick();
                                            setState(() {
                                              _previousIndex = _currentIndex;
                                              _currentIndex = index;
                                            });
                                            _scrollToActiveSibling();
                                          },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompact ? 12.0 : 14.0,
                                        vertical: isCompact ? 8.0 : 9.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            sibling.icon,
                                            size: isCompact ? 16 : 18,
                                            color: isCurrent
                                                ? siblingAccent
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            sibling.title,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  color: isCurrent
                                                      ? (theme.brightness ==
                                                                Brightness.dark
                                                            ? siblingAccent
                                                            : colorScheme
                                                                  .onSurface)
                                                      : colorScheme
                                                            .onSurfaceVariant,
                                                  fontWeight: isCurrent
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                  AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: plusSettings.plusEnableEnhancedAnimations
                          ? 260
                          : 0,
                    ),
                    switchInCurve: Easing.emphasizedDecelerate,
                    switchOutCurve: Easing.emphasizedAccelerate,
                    layoutBuilder:
                        (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                    transitionBuilder: (child, animation) {
                      final bool slideForward = _currentIndex >= _previousIndex;
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Easing.emphasizedDecelerate,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(slideForward ? 0.04 : -0.04, 0.0),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentIndex),
                      child: activeChild,
                    ),
                  ),
                  // Connected Settings Strip at subpage bottom
                  if (widget.connectedItems != null &&
                      widget.connectedItems!.isNotEmpty) ...[
                    SizedBox(height: isCompact ? 8 : 12),
                    ConnectedSettingsBar(
                      items: widget.connectedItems!,
                      isCompact: isCompact,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 36),
          ),
        ],
      ),
    );
  }
}
