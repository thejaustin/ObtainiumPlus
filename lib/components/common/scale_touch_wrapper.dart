import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const ScaleTouchWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDownFactor = 0.96,
    this.hapticOnTap = false,
    this.hapticOnLongPress = true,
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
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.forward();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
    // We let the inner GestureDetector or InkWell handle the actual onTap 
    // callback so we don't fire twice, but we can do haptics here if we want.
    // However, if we do haptics here, we'll fire haptics even if the tap was cancelled
    // by scrolling. It's better to let the widget itself handle taps, or only
    // trigger animation via Listener.
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    
    if (!plusSettings.plusEnableEnhancedAnimations || (widget.onTap == null && widget.onLongPress == null)) {
      // Just return child if animation disabled. We assume the child has its own onTap logic (like InkWell).
      return widget.child;
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
