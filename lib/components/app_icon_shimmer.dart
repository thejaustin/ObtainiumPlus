import 'package:flutter/material.dart';

/// Lightweight shimmer loading widget for app icons
/// Displays animated gradient sweep while icon loads
class AppIconShimmer extends StatefulWidget {
  final double size;
  final double borderRadius;

  const AppIconShimmer({
    super.key,
    required this.size,
    this.borderRadius = 12.0,
  });

  @override
  State<AppIconShimmer> createState() => _AppIconShimmerState();
}

class _AppIconShimmerState extends State<AppIconShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                0.0,
                0.3 + (_animation.value * 0.15),
                0.5 + (_animation.value * 0.15),
                1.0,
              ],
              colors: [
                baseColor,
                highlightColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}
