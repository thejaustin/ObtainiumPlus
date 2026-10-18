import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';

class ScaleTouchWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDownFactor;
  final bool hapticOnTap;
  final bool hapticOnLongPress;

  /// Fire [AppHaptics.tapDown] immediately when the pointer makes contact.
  /// This is the M3E pattern: haptics feel physical when fired on touch, not release.
  final bool hapticOnPressDown;

  const ScaleTouchWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDownFactor = 0.96,
    this.hapticOnTap = false,
    this.hapticOnLongPress = true,
    this.hapticOnPressDown = false,
  });

  @override
  State<ScaleTouchWrapper> createState() => _ScaleTouchWrapperState();
}

class _ScaleTouchWrapperState extends State<ScaleTouchWrapper>
    with SingleTickerProviderStateMixin {
  // 0 = resting, 1 = fully pressed. Unbounded so the release spring can
  // overshoot past rest (scale briefly > 1) for the expressive pop-back.
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.hapticOnPressDown) AppHaptics.tapDown();
    if (!_animate) return;
    _controller.animateWith(
      SpringSimulation(
        M3Springs.effectsFast,
        _controller.value,
        1,
        _controller.velocity,
      ),
    );
  }

  void _release() {
    if (!_animate) return;
    _controller.animateWith(
      SpringSimulation(
        M3Springs.spatialFast,
        _controller.value,
        0,
        _controller.velocity,
      ),
    );
  }

  bool _animate = true;

  Widget _withGestures(Widget inner) {
    if (widget.onTap == null && widget.onLongPress == null) return inner;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.hapticOnTap) AppHaptics.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.hapticOnLongPress) AppHaptics.mediumImpact();
              widget.onLongPress!();
            },
      child: inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    _animate = AppMotion.enabled(context);
    if (!_animate && _controller.value != 0) _controller.value = 0;

    // The Listener stays even with motion off so press-down haptics still
    // fire; haptics are feedback, not decoration.
    return _withGestures(
      Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: !_animate
            ? widget.child
            : AnimatedBuilder(
                animation: _controller,
                child: widget.child,
                builder: (context, child) => Transform.scale(
                  scale: 1 + (widget.scaleDownFactor - 1) * _controller.value,
                  child: child,
                ),
              ),
      ),
    );
  }
}
