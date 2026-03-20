import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// A Material 3 Expressive progress indicator with an optional squiggly animation
class ExpressiveProgressIndicator extends StatelessWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const ExpressiveProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.height = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    if (!settings.plusEnableExpressiveProgress) {
      return SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value,
          color: color,
          backgroundColor: backgroundColor,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: SquigglyProgressIndicator(
        value: value,
        color: color ?? Theme.of(context).colorScheme.primary,
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class SquigglyProgressIndicator extends StatefulWidget {
  final double? value;
  final Color? color;
  final Color backgroundColor;

  const SquigglyProgressIndicator({
    super.key,
    this.value,
    this.color,
    required this.backgroundColor,
  });

  @override
  State<SquigglyProgressIndicator> createState() => _SquigglyProgressIndicatorState();
}

class _SquigglyProgressIndicatorState extends State<SquigglyProgressIndicator> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SquigglyPainter(
            progress: widget.value,
            animationValue: _controller.value,
            color: widget.color,
            backgroundColor: widget.backgroundColor,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final double? progress;
  final double animationValue;
  final Color color;
  final Color backgroundColor;

  _SquigglyPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    // Draw background track
    canvas.drawLine(
      Offset(size.height / 2, size.height / 2),
      Offset(size.width - size.height / 2, size.height / 2),
      paint,
    );

    if (progress == 0.0) return;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double activeWidth = (progress ?? 1.0) * size.width;
    final path = Path();
    
    // Squiggly line parameters
    const double amplitude = 2.0;
    const double frequency = 0.15;
    
    path.moveTo(0, size.height / 2);
    
    for (double x = 0; x <= activeWidth; x += 1.0) {
      // Create wave effect
      final double y = size.height / 2 + 
          math.sin((x * frequency) + (animationValue * math.pi * 2)) * amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, activePaint);
    
    // If indeterminate, we might want a different moving segment, 
    // but for simplicity, we'll just squiggle the whole bar if value is null
  }

  @override
  bool shouldRepaint(covariant _SquigglyPainter oldDelegate) => true;
}
