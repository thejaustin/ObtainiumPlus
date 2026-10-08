import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      // Expressive spring-back: slightly longer for overshooting feel
      reverseDuration: const Duration(milliseconds: 360),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownFactor)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeIn,
            // M3E spring: overshoots past 1.0 on release for a physical bounce
            reverseCurve: AppConstants.expressiveDecelerate,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
    if (widget.hapticOnPressDown) AppHaptics.tapDown();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

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
    final plusEnableAnimations = context.select<PlusSettingsProvider, bool>(
      (p) => p.plusEnableEnhancedAnimations,
    );

    if (!plusEnableAnimations) return _withGestures(widget.child);

    return _withGestures(
      Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          child: widget.child,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
        ),
      ),
    );
  }
}
