import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Route for settings subpages when "Predictive back" (preview) is on.
///
/// Gesture pops get Android's predictive-back transition
/// ([PredictiveBackPageTransitionsBuilder]); pushes and button pops keep the
/// shared-axis slide of [pushRoute]. Both transition widgets stay mounted all
/// the time (the inactive one gets a static animation), so the back-gesture
/// listener inside the predictive builder is not recreated when the gesture
/// starts.
class SettingsPageRoute<T> extends MaterialPageRoute<T> {
  SettingsPageRoute({
    required super.builder,
    required this.fillColor,
    this.speed = 1.0,
  });

  final Color fillColor;
  final double speed;

  @override
  Duration get transitionDuration =>
      Duration(milliseconds: (300 * speed).round());

  @override
  Duration get reverseTransitionDuration =>
      Duration(milliseconds: (250 * speed).round());

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final notifier = navigator!.userGestureInProgressNotifier;
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      child: child,
      builder: (context, gesture, child) {
        final axis = SharedAxisTransition(
          animation: gesture ? kAlwaysCompleteAnimation : animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: fillColor,
          child: child,
        );
        return const PredictiveBackPageTransitionsBuilder().buildTransitions(
          this,
          context,
          gesture ? animation : kAlwaysCompleteAnimation,
          gesture ? secondaryAnimation : kAlwaysDismissedAnimation,
          axis,
        );
      },
    );
  }
}
