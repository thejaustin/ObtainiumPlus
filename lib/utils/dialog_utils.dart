import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Shows a dialog with a combined scale (0.85→1.0) + fade entrance animation.
/// Drop-in replacement for [showDialog] at call sites that warrant a polished transition.
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
}) {
  final settings = context.read<SettingsProvider>();
  final speedMultiplier = settings.animationSpeedMultiplier;
  
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Duration(milliseconds: (200 * speedMultiplier).round()),
    pageBuilder: (_, __, ___) => builder(context),
    transitionBuilder: (_, anim, __, child) => ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}
