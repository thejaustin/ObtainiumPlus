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
            color: widget.color ?? Theme.of(context).colorScheme.primary,
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

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double amplitude = 2.0;
    const double frequency = 0.15;
    
    if (progress != null) {
      // Determinate state
      if (progress == 0.0) return;
      final double activeWidth = progress! * size.width;
      path.moveTo(0, size.height / 2);
      for (double x = 0; x <= activeWidth; x += 2.0) {
        final double y = size.height / 2 + 
            math.sin((x * frequency) + (animationValue * math.pi * 2)) * amplitude;
        path.lineTo(x, y);
      }
    } else {
      // Indeterminate state - moving segment
      final double segmentWidth = size.width * 0.3;
      final double startX = (animationValue * (size.width + segmentWidth)) - segmentWidth;
      final double endX = startX + segmentWidth;
      
      bool first = true;
      for (double x = startX; x <= endX; x += 2.0) {
        if (x < 0 || x > size.width) continue;
        final double y = size.height / 2 + 
            math.sin((x * frequency) + (animationValue * math.pi * 10)) * amplitude;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, activePaint);
  }

  @override
  bool shouldRepaint(covariant _SquigglyPainter oldDelegate) => true;
}
