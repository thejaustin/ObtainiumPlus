import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// A Material 3 Expressive "Wavy" progress indicator
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

    // M3E spec: WaveHeight = ActiveThickness(4dp) + 2×ActiveWaveAmplitude(3dp) = 10dp
    // Extra canvas = 2 × amplitude = 6dp so the wave never clips
    return SizedBox(
      height: height + 6,
      child: SquigglyProgressIndicator(
        value: value,
        trackHeight: height,
        color: color ?? Theme.of(context).colorScheme.primary,
        backgroundColor:
            backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// A Material 3 Expressive "Wavy" circular progress indicator
class ExpressiveCircularProgressIndicator extends StatelessWidget {
  final double? value;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;

  const ExpressiveCircularProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (!settings.plusEnableExpressiveProgress) {
      return CircularProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
      );
    }

    return WavyCircularProgressIndicator(
      value: value,
      color: color ?? Theme.of(context).colorScheme.primary,
      backgroundColor:
          backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      strokeWidth: strokeWidth,
    );
  }
}

class SquigglyProgressIndicator extends StatefulWidget {
  final double? value;
  final Color? color;
  final Color backgroundColor;
  final double trackHeight;

  const SquigglyProgressIndicator({
    super.key,
    this.value,
    this.color,
    required this.backgroundColor,
    this.trackHeight = 4.0,
  });

  @override
  State<SquigglyProgressIndicator> createState() =>
      _SquigglyProgressIndicatorState();
}

class _SquigglyProgressIndicatorState extends State<SquigglyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // M3E spec: waveSpeed = wavelength/s → one full wave cycle per second
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
            trackHeight: widget.trackHeight,
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
  final double trackHeight;

  _SquigglyPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.backgroundColor,
    required this.trackHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // M3E tokens: ActiveWaveAmplitude=3dp, ActiveWaveWavelength=40dp,
    // IndeterminateActiveWaveWavelength=20dp, WaveHeight=10dp, ActiveThickness=4dp
    const double amplitude = 3.0;
    final double strokeWidth = trackHeight;
    final centerY = size.height / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), bgPaint);

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (progress != null) {
      // Determinate: wavelength=40dp, ramp amplitude in/out at 0-10% and 90-100%
      if (progress! <= 0.0) return;
      final double activeWidth = progress! * size.width;
      const double frequency = (2 * math.pi) / 40.0;

      path.moveTo(0, centerY);
      for (double x = 0; x <= activeWidth; x += 1.0) {
        final double progressAtX = x / size.width;
        final double ramp = progressAtX < 0.1
            ? progressAtX / 0.1
            : progressAtX > 0.95
            ? (1.0 - progressAtX) / 0.05
            : 1.0;
        final double y =
            centerY +
            math.sin((x * frequency) - (animationValue * math.pi * 2)) *
                amplitude *
                ramp;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, activePaint);

      // M3E stop indicator at progress end
      final stopPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(activeWidth, centerY),
        strokeWidth / 2,
        stopPaint,
      );
    } else {
      // Indeterminate: wavelength=20dp (more energetic), full-width traveling wave
      const double frequency = (2 * math.pi) / 20.0;
      path.moveTo(0, centerY);
      for (double x = 0; x <= size.width; x += 1.0) {
        final double y =
            centerY +
            math.sin((x * frequency) - (animationValue * math.pi * 2)) *
                amplitude;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SquigglyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.trackHeight != trackHeight;
}

class WavyCircularProgressIndicator extends StatefulWidget {
  final double? value;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  const WavyCircularProgressIndicator({
    super.key,
    this.value,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 4.0,
  });

  @override
  State<WavyCircularProgressIndicator> createState() =>
      _WavyCircularProgressIndicatorState();
}

class _WavyCircularProgressIndicatorState
    extends State<WavyCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
          painter: _WavyCircularPainter(
            progress: widget.value,
            animationValue: _controller.value,
            color: widget.color,
            backgroundColor: widget.backgroundColor,
            strokeWidth: widget.strokeWidth,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _WavyCircularPainter extends CustomPainter {
  final double? progress;
  final double animationValue;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _WavyCircularPainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth * 2) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw background circle
    canvas.drawCircle(center, radius, bgPaint);

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double amplitude = 2.5;
    const int waveCount = 12; // Number of waves around the circle

    final path = Path();

    if (progress != null) {
      // Determinate circular wavy
      final double sweepAngle = progress! * 2 * math.pi;
      if (sweepAngle <= 0) return;

      for (double a = 0; a <= sweepAngle; a += 0.05) {
        final double currentRadius =
            radius +
            math.sin(a * waveCount - (animationValue * 2 * math.pi)) *
                amplitude;
        final x = center.dx + currentRadius * math.cos(a - math.pi / 2);
        final y = center.dy + currentRadius * math.sin(a - math.pi / 2);
        if (a == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, activePaint);

      // End stop dot
      final endAngle = sweepAngle - math.pi / 2;
      final endRadius =
          radius +
          math.sin(sweepAngle * waveCount - (animationValue * 2 * math.pi)) *
              amplitude;
      canvas.drawCircle(
        Offset(
          center.dx + endRadius * math.cos(endAngle),
          center.dy + endRadius * math.sin(endAngle),
        ),
        strokeWidth / 1.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    } else {
      // Indeterminate circular wavy
      const double segmentAngle = math.pi * 0.6;
      final double startAngle = animationValue * 2 * math.pi;

      for (double a = 0; a <= segmentAngle; a += 0.05) {
        final double totalAngle = startAngle + a;
        final double currentRadius =
            radius +
            math.sin(totalAngle * waveCount - (animationValue * 4 * math.pi)) *
                amplitude;
        final x =
            center.dx + currentRadius * math.cos(totalAngle - math.pi / 2);
        final y =
            center.dy + currentRadius * math.sin(totalAngle - math.pi / 2);
        if (a == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavyCircularPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
