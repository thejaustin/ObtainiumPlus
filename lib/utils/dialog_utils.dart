import 'package:flutter/material.dart';

/// Shows a dialog with a combined scale (0.85→1.0) + fade entrance animation.
/// Drop-in replacement for [showDialog] at call sites that warrant a polished transition.
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
}) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => builder(context),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
