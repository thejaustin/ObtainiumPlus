import 'dart:ui';
import 'package:flutter/material.dart';

/// Wraps [child] in a [BackdropFilter] only when [enabled] is true.
///
/// Using BackdropFilter with sigma=0 still creates a compositing layer,
/// wasting GPU resources. This widget skips instantiation entirely when
/// blur is disabled, which is the correct pattern per Flutter docs.
class ConditionalBlur extends StatelessWidget {
  final Widget child;
  final double sigma;
  final bool enabled;

  const ConditionalBlur({
    super.key,
    required this.child,
    required this.sigma,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    // A BackdropFilter blurs everything behind it up to the nearest clip;
    // without its own clip, one unclipped use blurred the whole screen
    // (e.g. the app page's action bar turned the details into a blur).
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
        ),
      ),
    );
  }
}
