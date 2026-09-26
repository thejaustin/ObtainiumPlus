import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';

/// A Material 3 Expressive segmented filter bar featuring fluid shape-morphing
/// selection indicators, capsule geometry, dynamic badge transitions, and responsive layout.
class M3ExpressiveSegmentedFilter extends StatelessWidget {
  final String currentMode; // 'all', 'updates', 'installed'
  final ValueChanged<String> onModeChanged;
  final int totalApps;
  final int updatesCount;
  final int installedCount;
  final double radius;
  final bool isGlass;

  const M3ExpressiveSegmentedFilter({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.totalApps,
    required this.updatesCount,
    required this.installedCount,
    required this.radius,
    this.isGlass = false,
  });

  int get _currentIndex {
    switch (currentMode) {
      case 'updates':
        return 1;
      case 'installed':
        return 2;
      case 'all':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pillRadius = CardMetrics.pill(radius);
    final innerPillRadius = pillRadius - 3.5;

    final segments = [
      _SegmentData(
        mode: 'all',
        label: tr('all'),
        icon: Icons.apps_rounded,
        badgeCount: null,
      ),
      _SegmentData(
        mode: 'updates',
        label: tr('updates'),
        icon: Icons.update_rounded,
        badgeCount: updatesCount > 0 ? updatesCount : null,
      ),
      _SegmentData(
        mode: 'installed',
        label: tr('installed'),
        icon: Icons.install_mobile_rounded,
        badgeCount: null,
      ),
    ];

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const inset = 3.5;
        final trackWidth = (totalWidth - (inset * 2)).clamp(0.0, double.infinity);
        final segmentWidth = trackWidth / segments.length;
        final activeIndex = _currentIndex.clamp(0, segments.length - 1);

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isGlass
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(pillRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: isGlass ? 0.35 : 0.22,
              ),
              width: 1.0,
            ),
          ),
          child: Stack(
            children: [
              // Fluid shape-morphing active indicator pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Easing.emphasizedDecelerate,
                left: inset + (activeIndex * segmentWidth),
                top: inset,
                bottom: inset,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(innerPillRadius),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                ),
              ),

              // Interactive Segment Touch Targets
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(inset),
                  child: Row(
                    children: [
                      for (int i = 0; i < segments.length; i++)
                        Expanded(
                          child: _SegmentItem(
                            data: segments[i],
                            isSelected: i == activeIndex,
                            innerRadius: innerPillRadius,
                            onTap: () {
                              if (segments[i].mode != currentMode) {
                                AppHaptics.selectionClick();
                                onModeChanged(segments[i].mode);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (isGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(pillRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _SegmentData {
  final String mode;
  final String label;
  final IconData icon;
  final int? badgeCount;

  const _SegmentData({
    required this.mode,
    required this.label,
    required this.icon,
    this.badgeCount,
  });
}

class _SegmentItem extends StatelessWidget {
  final _SegmentData data;
  final bool isSelected;
  final double innerRadius;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.data,
    required this.isSelected,
    required this.innerRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fgColor = isSelected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return ScaleTouchWrapper(
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    data.icon,
                    key: ValueKey(isSelected),
                    size: 18,
                    color: fgColor,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: fgColor,
                      fontFamily:
                          Theme.of(context).textTheme.labelLarge?.fontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                    child: Text(
                      data.label,
                      maxLines: 1,
                    ),
                  ),
                ),
                if (data.badgeCount != null) ...[
                  const SizedBox(width: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Easing.emphasizedDecelerate,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${data.badgeCount}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onError,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
