import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Style spec for swipe actions matching the Material 3 Expressive ShizukuPlus pattern
class SwipeActionSpec {
  final String label;
  final IconData icon;
  final Color Function(ColorScheme) containerColor;
  final Color Function(ColorScheme) onContainerColor;

  const SwipeActionSpec({
    required this.label,
    required this.icon,
    required this.containerColor,
    required this.onContainerColor,
  });

  static SwipeActionSpec forAction(AppSwipeAction action) {
    switch (action) {
      case AppSwipeAction.launch:
        return SwipeActionSpec(
          label: 'Launch',
          icon: Icons.launch_rounded,
          containerColor: (c) => c.primaryContainer,
          onContainerColor: (c) => c.onPrimaryContainer,
        );
      case AppSwipeAction.update:
        return SwipeActionSpec(
          label: 'Update',
          icon: Icons.system_update_rounded,
          containerColor: (c) => c.tertiaryContainer,
          onContainerColor: (c) => c.onTertiaryContainer,
        );
      case AppSwipeAction.togglePin:
        return SwipeActionSpec(
          label: 'Pin / Unpin',
          icon: Icons.push_pin_rounded,
          containerColor: (c) => c.secondaryContainer,
          onContainerColor: (c) => c.onSecondaryContainer,
        );
      case AppSwipeAction.share:
        return SwipeActionSpec(
          label: 'Share',
          icon: Icons.share_rounded,
          containerColor: (c) => c.secondaryContainer,
          onContainerColor: (c) => c.onSecondaryContainer,
        );
      case AppSwipeAction.delete:
        return SwipeActionSpec(
          label: 'Remove',
          icon: Icons.delete_outline_rounded,
          containerColor: (c) => c.errorContainer,
          onContainerColor: (c) => c.onErrorContainer,
        );
      case AppSwipeAction.none:
        return SwipeActionSpec(
          label: 'None',
          icon: Icons.close_rounded,
          containerColor: (c) => c.surfaceContainerHighest,
          onContainerColor: (c) => c.onSurfaceVariant,
        );
    }
  }
}

/// Settings preview matching the ShizukuPlus swipe gesture implementation:
/// includes Auto-Preview animation and an interactive Sandbox drag mode with
/// 38% threshold, 3-stage haptics, spring badge pop, and progressive reveal.
class SwipePreviewWidget extends StatefulWidget {
  const SwipePreviewWidget({super.key});

  @override
  State<SwipePreviewWidget> createState() => _SwipePreviewWidgetState();
}

class _SwipePreviewWidgetState extends State<SwipePreviewWidget>
    with TickerProviderStateMixin {
  bool _sandboxMode = false;
  late AnimationController _animController;
  AnimationController? _springController;
  double _dragOffset = 0.0;
  bool _thresholdActivated = false;

  static const double thresholdFraction = 0.38; // 38% ShizukuPlus threshold

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _animController.addListener(_onAutoPreviewTick);
    _startAutoPreview();
  }

  void _startAutoPreview() {
    if (!mounted || _sandboxMode) return;
    if (WidgetsBinding.instance is! WidgetsFlutterBinding) return;
    // Honour the animations setting, and play a few demo loops instead of
    // rebuilding every frame for as long as the settings page is open.
    if (!context.read<PlusSettingsProvider>().plusEnableEnhancedAnimations) {
      return;
    }
    _animController.repeat(count: 3);
  }

  void _onAutoPreviewTick() {
    if (_sandboxMode || !mounted) return;
    final progress = _animController.value;
    final settings = context.read<BehaviorSettingsProvider>();

    // 0.0 -> 0.4: Swipe Right (if enabled)
    // 0.4 -> 0.5: Pause
    // 0.5 -> 0.9: Swipe Left (if enabled)
    // 0.9 -> 1.0: Pause
    double offset = 0.0;
    if (progress < 0.45) {
      if (settings.swipeRightAction != AppSwipeAction.none) {
        final t = progress / 0.45;
        // Swipe out with easeInOut, hold, then return
        if (t < 0.4) {
          offset = Curves.easeOutCubic.transform(t / 0.4) * 140.0;
        } else if (t < 0.7) {
          offset = 140.0;
        } else {
          offset =
              (1.0 - Curves.easeInOutCubic.transform((t - 0.7) / 0.3)) * 140.0;
        }
      }
    } else if (progress < 0.95) {
      if (settings.swipeLeftAction != AppSwipeAction.none) {
        final t = (progress - 0.5) / 0.45;
        if (t < 0.4) {
          offset = -Curves.easeOutCubic.transform(t / 0.4) * 140.0;
        } else if (t < 0.7) {
          offset = -140.0;
        } else {
          offset =
              -(1.0 - Curves.easeInOutCubic.transform((t - 0.7) / 0.3)) * 140.0;
        }
      }
    }

    setState(() {
      _dragOffset = offset;
    });
  }

  void _stopSpringAnimation() {
    _springController?.stop();
    _springController?.dispose();
    _springController = null;
  }

  @override
  void dispose() {
    _animController.removeListener(_onAutoPreviewTick);
    _animController.dispose();
    _stopSpringAnimation();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double totalWidth) {
    if (!_sandboxMode) return;
    _stopSpringAnimation();
    final settings = context.read<BehaviorSettingsProvider>();
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(
        settings.swipeLeftAction != AppSwipeAction.none
            ? -totalWidth * 0.75
            : 0.0,
        settings.swipeRightAction != AppSwipeAction.none
            ? totalWidth * 0.75
            : 0.0,
      );

      final thresholdPx = totalWidth * thresholdFraction;
      final pastThreshold = _dragOffset.abs() >= thresholdPx;

      if (pastThreshold && !_thresholdActivated) {
        _thresholdActivated = true;
        AppHaptics.lightImpact(); // Stage 1: Threshold activate
      } else if (!pastThreshold && _thresholdActivated) {
        _thresholdActivated = false;
        AppHaptics.selectionClick(); // Stage 2: Threshold release
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double totalWidth) {
    if (!_sandboxMode) return;
    final thresholdPx = totalWidth * thresholdFraction;
    final triggered = _dragOffset.abs() >= thresholdPx;

    if (triggered) {
      AppHaptics.success(); // Stage 3: Success completion
    }

    // Spring snap back
    final spring = SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: 400.0,
      ratio: 0.75,
    );
    final sim = SpringSimulation(
      spring,
      _dragOffset,
      0.0,
      details.primaryVelocity ?? 0.0,
    );

    _stopSpringAnimation();
    final ctrl = AnimationController.unbounded(vsync: this);
    _springController = ctrl;
    ctrl.addListener(() {
      if (mounted) {
        setState(() {
          _dragOffset = ctrl.value;
        });
      }
    });
    ctrl.animateWith(sim).whenComplete(() {
      _thresholdActivated = false;
      if (_springController == ctrl) {
        ctrl.dispose();
        _springController = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<BehaviorSettingsProvider>();
    final isRight = _dragOffset >= 0;
    final action = isRight
        ? settings.swipeRightAction
        : settings.swipeLeftAction;
    final spec = SwipeActionSpec.forAction(action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector (Auto-Preview vs Sandbox)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Interactive Preview',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Auto'),
                    icon: Icon(Icons.play_circle_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Sandbox'),
                    icon: Icon(Icons.touch_app_outlined, size: 16),
                  ),
                ],
                selected: {_sandboxMode},
                onSelectionChanged: (val) {
                  AppHaptics.selectionClick();
                  setState(() {
                    _sandboxMode = val.first;
                    _dragOffset = 0.0;
                    _thresholdActivated = false;
                    if (_sandboxMode) {
                      _animController.stop();
                    } else {
                      _startAutoPreview();
                    }
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // The Swipe Canvas / Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final thresholdPx = totalWidth * thresholdFraction;
              final progress = (_dragOffset.abs() / thresholdPx).clamp(
                0.0,
                1.0,
              );
              final isPastThreshold = _dragOffset.abs() >= thresholdPx;

              // Badge pop scale: 0.75 -> 1.0 during drag, springs to 1.15 when past threshold
              final badgeScale =
                  (0.75 + 0.25 * progress) * (isPastThreshold ? 1.15 : 1.0);
              final iconAlpha = (0.35 + 0.65 * progress).clamp(0.0, 1.0);

              return GestureDetector(
                onHorizontalDragUpdate: (d) =>
                    _onHorizontalDragUpdate(d, totalWidth),
                onHorizontalDragEnd: (d) => _onHorizontalDragEnd(d, totalWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background action reveal
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: spec.containerColor(colorScheme),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: isRight
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isRight && isPastThreshold) ...[
                                Text(
                                  spec.label,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: spec.onContainerColor(colorScheme),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Transform.scale(
                                scale: badgeScale,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isPastThreshold
                                        ? spec
                                              .onContainerColor(colorScheme)
                                              .withValues(alpha: 0.22)
                                        : spec
                                              .onContainerColor(colorScheme)
                                              .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    spec.icon,
                                    size: 22,
                                    color: spec
                                        .onContainerColor(colorScheme)
                                        .withValues(alpha: iconAlpha),
                                  ),
                                ),
                              ),
                              if (isRight && isPastThreshold) ...[
                                const SizedBox(width: 10),
                                Text(
                                  spec.label,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: spec.onContainerColor(colorScheme),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Foreground Demo App Row
                      Transform.translate(
                        offset: Offset(_dragOffset, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.android_rounded,
                                  color: colorScheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ObtainiumPlus Demo App',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'v2.4.0 • Swipe to test gestures',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Update',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Helper instruction text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            _sandboxMode
                ? 'Drag left or right past 38% width to feel threshold haptics and trigger actions.'
                : 'Auto-previewing current swipe actions (38% threshold with badge spring).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
