import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:provider/provider.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';

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
    final plusSettings = context.watch<PlusSettingsProvider>();

    if (!plusSettings.plusEnableExpressiveProgress) {
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

  /// Allow the M3E shape-morph indicator for indeterminate waits. Pass false
  /// for per-row/per-tile spinners: many concurrent morphs are costly and the
  /// spec reserves the loading indicator for page/dialog-level waits.
  final bool morph;

  const ExpressiveCircularProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 4.0,
    this.morph = true,
  });

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();

    if (!plusSettings.plusEnableExpressiveProgress) {
      return CircularProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
      );
    }

    // Indeterminate waits use the M3 Expressive morphing loading indicator;
    // the wavy ring is kept for determinate progress, for the developer
    // comparison toggle, and when motion is reduced (it holds still).
    final wavy = WavyCircularProgressIndicator(
      value: value,
      color: color ?? Theme.of(context).colorScheme.primary,
      backgroundColor:
          backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      strokeWidth: strokeWidth,
    );

    if (value != null ||
        !morph ||
        plusSettings.plusDevUseThirdPartyLoadingIndicator ||
        !AppMotion.enabled(context)) {
      return wavy;
    }

    // Below ~32dp the morphing shapes are unreadable; keep the wavy ring.
    // The 48dp box (the indicator's natural size) answers intrinsic-size
    // queries itself: a LayoutBuilder can't, and SliverFillRemaining /
    // IntrinsicHeight parents threw and left the page broken (Logs page).
    // A tighter or larger tight parent still wins.
    return SizedBox.square(
      dimension: 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.biggest.shortestSide < 32) return wavy;
          return FittedBox(
            fit: BoxFit.contain,
            child: LoadingIndicatorM3E(
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
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
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.enabledForDependencies(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
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

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progress != null) {
      final double p = progress!.clamp(0.0, 1.0);
      if (p <= 0.0) {
        canvas.drawLine(
          Offset(0, centerY),
          Offset(size.width, centerY),
          bgPaint,
        );
        return;
      }

      final double activeWidth = p * size.width;
      const double frequency = (2 * math.pi) / 40.0;
      const double gap = 4.0;
      final double trackStart = activeWidth + gap;

      // Inactive track with M3E 4dp gap
      if (trackStart < size.width) {
        canvas.drawLine(
          Offset(trackStart, centerY),
          Offset(size.width, centerY),
          bgPaint,
        );
      }

      final path = Path();
      path.moveTo(0, centerY);
      for (double x = 0; x <= activeWidth; x += 1.0) {
        final double progressAtX = activeWidth > 0 ? x / activeWidth : 0.0;
        final double ramp = progressAtX < 0.1
            ? progressAtX / 0.1
            : progressAtX > 0.85
            ? (1.0 - progressAtX) / 0.15
            : 1.0;

        final double currentAmplitude = amplitude * ramp;
        final double y =
            centerY +
            math.sin(x * frequency - animationValue * 4 * math.pi) *
                currentAmplitude;
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
      // Indeterminate mode: draw full background track
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), bgPaint);

      // M3 Expressive Indeterminate: smooth morphing wave with continuous phase loop
      const double wavelength = 28.0;
      const double frequency = (2 * math.pi) / wavelength;
      final double phase = animationValue * 4 * math.pi;

      // Two overlapping wave segments staggered by half a cycle for seamless flow
      void drawWaveSegment(double startT, double endT) {
        final double startX = size.width * startT;
        final double endX = size.width * endT;
        final double segmentWidth = endX - startX;
        if (segmentWidth <= 1.0) return;

        final segmentPath = Path();
        segmentPath.moveTo(startX, centerY);

        for (double x = startX; x <= endX; x += 1.0) {
          final double t = (x - startX) / segmentWidth;
          // Smoothstep amplitude envelope: sin(pi * t) goes gracefully 0 -> 1 -> 0
          final double envelope = math.sin(math.pi * t);
          final double currentAmplitude = amplitude * envelope;
          final double y =
              centerY + math.sin(x * frequency - phase) * currentAmplitude;
          segmentPath.lineTo(x, y);
        }
        canvas.drawPath(segmentPath, activePaint);
      }

      // Staggered continuous cycles without clamping stutter
      final double t1 = animationValue;
      final double head1 = Curves.easeInOutCubic.transform(
        (t1 * 1.3).clamp(0.0, 1.0),
      );
      final double tail1 = Curves.easeInOutCubic.transform(
        (t1 * 1.3 - 0.4).clamp(0.0, 1.0),
      );

      final double t2 = (animationValue + 0.5) % 1.0;
      final double head2 = Curves.easeInOutCubic.transform(
        (t2 * 1.3).clamp(0.0, 1.0),
      );
      final double tail2 = Curves.easeInOutCubic.transform(
        (t2 * 1.3 - 0.4).clamp(0.0, 1.0),
      );

      drawWaveSegment(tail1, head1);
      drawWaveSegment(tail2, head2);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.enabledForDependencies(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
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
    if (radius <= 0) return;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Adaptive wave count and amplitude based on radius to avoid dense squishing or jitter on compact sizes
    final int waveCount;
    final double amplitude;
    if (radius < 10.0) {
      // Extremely compact (e.g. inside buttons): smooth arc avoids jagged vibrating pixels
      waveCount = 0;
      amplitude = 0.0;
    } else if (radius < 18.0) {
      waveCount = 4;
      amplitude = math.min(1.0, radius * 0.08);
    } else if (radius < 26.0) {
      waveCount = 6;
      amplitude = math.min(1.6, radius * 0.10);
    } else {
      waveCount = 10;
      amplitude = math.min(2.2, radius * 0.12);
    }

    final path = Path();

    if (progress != null) {
      final double clampedProgress = progress!.clamp(0.0, 1.0);
      final double sweepAngle = clampedProgress * 2 * math.pi;

      if (sweepAngle <= 0) {
        canvas.drawCircle(center, radius, bgPaint);
        return;
      }

      // M3E gap between active arc and inactive background track
      final double gapAngle = (4.0 / radius).clamp(0.05, 0.4);
      final double bgSweepAngle = 2 * math.pi - sweepAngle - gapAngle;
      if (bgSweepAngle > 0.05) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          sweepAngle + gapAngle - math.pi / 2,
          bgSweepAngle,
          false,
          bgPaint,
        );
      }

      for (double a = 0; a <= sweepAngle; a += 0.02) {
        final double progressAtA = sweepAngle > 0 ? a / sweepAngle : 0.0;
        final double ramp = progressAtA > 0.85
            ? (1.0 - progressAtA) / 0.15
            : 1.0;
        final double currentAmplitude = amplitude * ramp;
        final double currentRadius =
            radius +
            math.sin(a * waveCount - (animationValue * 2 * math.pi)) *
                currentAmplitude;
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
      final endRadius = radius;
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
      // Draw background circle
      canvas.drawCircle(center, radius, bgPaint);

      // Indeterminate circular wavy (expanding/contracting like Google Play)
      final double cycle = animationValue * 2 * math.pi;
      final double rotation = animationValue * 8 * math.pi;

      final double sweepOscillation =
          (math.sin(cycle - math.pi / 2) + 1.0) / 2.0;
      final double segmentAngle =
          0.1 * math.pi + sweepOscillation * 1.4 * math.pi;

      final double tailOffset = cycle - (math.sin(cycle) + 1.0) * math.pi / 2.0;
      final double startAngle = rotation + tailOffset;

      for (double a = 0; a <= segmentAngle; a += 0.02) {
        final double totalAngle = startAngle + a;
        final double progressInLine = a / segmentAngle;
        final double envelope = math.sin(math.pi * progressInLine);
        final double currentAmplitude = amplitude * envelope;

        final double currentRadius =
            radius +
            math.sin(totalAngle * waveCount - (animationValue * 4 * math.pi)) *
                currentAmplitude;
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
