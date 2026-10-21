import 'dart:async';
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

  /// Fire [AppHaptics.tapDown] when the pointer makes contact.
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
  /// Tracks the innermost [ScaleTouchWrapper] that claimed the current
  /// [PointerDownEvent] so ancestor wrappers (e.g. a parent card containing an
  /// interactive icon button or action pill) do not simultaneously scale down
  /// or fire duplicate haptics on the same touch.
  static int? _lastClaimedPointer;
  static Duration? _lastClaimedTimeStamp;

  // 0 = resting, 1 = fully pressed. Unbounded so the release spring can
  // overshoot past rest (scale briefly > 1) for the expressive pop-back.
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );

  Offset? _downPosition;
  bool _isPressed = false;
  Timer? _pressHapticTimer;
  bool _pendingPressHaptic = false;

  static const double _scrollSlopSquared = 64.0; // 8px movement cancels press

  @override
  void dispose() {
    _pressHapticTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_lastClaimedPointer == event.pointer &&
        _lastClaimedTimeStamp == event.timeStamp) {
      return;
    }
    _lastClaimedPointer = event.pointer;
    _lastClaimedTimeStamp = event.timeStamp;

    _downPosition = event.position;
    _isPressed = true;
    _pressHapticTimer?.cancel();

    if (widget.hapticOnPressDown) {
      _pendingPressHaptic = true;
      _pressHapticTimer = Timer(const Duration(milliseconds: 35), () {
        if (_isPressed && _pendingPressHaptic && mounted) {
          _pendingPressHaptic = false;
          AppHaptics.tapDown();
        }
      });
    }

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

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPressed || _downPosition == null) return;
    if ((event.position - _downPosition!).distanceSquared >
        _scrollSlopSquared) {
      _cancelPressHaptic();
      _release();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPressed && _pendingPressHaptic) {
      _pressHapticTimer?.cancel();
      _pendingPressHaptic = false;
      AppHaptics.tapDown();
    }
    _release();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _cancelPressHaptic();
    _release();
  }

  void _cancelPressHaptic() {
    _pressHapticTimer?.cancel();
    _pendingPressHaptic = false;
  }

  void _release() {
    if (!_isPressed && _controller.value == 0) return;
    _isPressed = false;
    _downPosition = null;
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
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
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
