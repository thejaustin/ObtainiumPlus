import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Material 3 Expressive motion-scheme springs (same damping/stiffness as the
/// Compose `MotionScheme.expressive()` tokens). Spatial springs move position,
/// size and scale and may overshoot; effects springs drive colour/opacity and
/// never overshoot.
abstract final class M3Springs {
  static SpringDescription _spring(double ratio, double stiffness) =>
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: stiffness,
        ratio: ratio,
      );

  static final SpringDescription spatialFast = _spring(0.6, 800);
  static final SpringDescription spatialDefault = _spring(0.8, 380);
  static final SpringDescription spatialSlow = _spring(0.8, 200);

  static final SpringDescription effectsFast = _spring(1.0, 3800);
  static final SpringDescription effectsDefault = _spring(1.0, 1600);
  static final SpringDescription effectsSlow = _spring(1.0, 800);
}

/// A spring sampled as a [Curve], for duration-based APIs (AnimatedFoo,
/// CurvedAnimation). Use [duration] so the curve spans the spring's settle
/// time; a shorter duration truncates the motion, a longer one stretches it.
class SpringCurve extends Curve {
  SpringCurve(this.spring)
    : _simulation = SpringSimulation(spring, 0, 1, 0),
      _settleSeconds = _settleTime(spring);

  final SpringDescription spring;
  final SpringSimulation _simulation;
  final double _settleSeconds;

  Duration get duration =>
      Duration(microseconds: (_settleSeconds * 1e6).round());

  static double _settleTime(SpringDescription spring) {
    final sim = SpringSimulation(
      spring,
      0,
      1,
      0,
      tolerance: const Tolerance(distance: 0.002, velocity: 0.02),
    );
    var t = 0.0;
    while (t < 3 && !sim.isDone(t)) {
      t += 1 / 120;
    }
    return t.clamp(1 / 60, 3.0);
  }

  @override
  double transformInternal(double t) => _simulation.x(t * _settleSeconds);
}

/// Single source of truth for whether decorative motion runs: the in-app
/// "enhanced animations" toggle AND the OS "remove animations" accessibility
/// setting must both allow it.
abstract final class AppMotion {
  static final SpringCurve spatialFast = SpringCurve(M3Springs.spatialFast);
  static final SpringCurve spatial = SpringCurve(M3Springs.spatialDefault);
  static final SpringCurve spatialSlow = SpringCurve(M3Springs.spatialSlow);
  static final SpringCurve effects = SpringCurve(M3Springs.effectsDefault);

  /// Call from `build` only; rebuilds when either setting changes.
  static bool enabled(BuildContext context) {
    final inApp = context.select<PlusSettingsProvider, bool>(
      (p) => p.plusEnableEnhancedAnimations,
    );
    return inApp && !MediaQuery.disableAnimationsOf(context);
  }

  /// Non-listening variant for callbacks and `initState`-time decisions.
  static bool enabledNow(BuildContext context) {
    final inApp = context
        .read<PlusSettingsProvider>()
        .plusEnableEnhancedAnimations;
    final media = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return inApp && !media;
  }

  /// Listening variant for `didChangeDependencies`, so looping controllers
  /// start/stop when either setting changes (context.read would not).
  static bool enabledForDependencies(BuildContext context) {
    final inApp = Provider.of<PlusSettingsProvider>(
      context,
    ).plusEnableEnhancedAnimations;
    return inApp && !MediaQuery.disableAnimationsOf(context);
  }

  static Duration duration(BuildContext context, Duration base) =>
      enabled(context) ? base : Duration.zero;
}
