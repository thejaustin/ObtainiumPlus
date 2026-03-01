import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Shows a glassmorphic dialog with smooth scale + fade animation.
/// Use this instead of [showDialog] for consistent modern UI.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  double? width,
}) {
  final settings = context.read<SettingsProvider>();
  final speedMultiplier = settings.animationSpeedMultiplier;
  
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Duration(milliseconds: (250 * speedMultiplier).round()),
    pageBuilder: (_, __, ___) => builder(context),
    transitionBuilder: (_, anim, __, child) => ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// A modern glassmorphic dialog widget with backdrop blur effect.
class GlassDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget>? actions;
  final bool scrollable;
  final IconData? icon;
  final double? width;

  const GlassDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions,
    this.scrollable = true,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: enableGlass ? 0.85 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: enableGlass ? 0.2 : 0.1),
              blurRadius: enableGlass ? 20 : 10,
              spreadRadius: enableGlass ? 0 : -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: enableGlass ? 15 : 0,
              sigmaY: enableGlass ? 15 : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(context, enableGlass),
                const Divider(height: 1),
                // Content
                Flexible(
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: content,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: content,
                        ),
                ),
                // Actions
                if (actions != null && actions!.isNotEmpty) _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool enableGlass) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: enableGlass ? 0.5 : 1.0),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions!.map((action) {
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: action,
          );
        }).toList(),
      ),
    );
  }
}

/// Shows a bottom sheet with glassmorphism effect.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  double? height,
}) {
  final settings = context.read<SettingsProvider>();
  final enableGlass = settings.plusEnableGlassmorphism;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: enableGlass ? 0.9 : 1.0),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: enableGlass ? 0.3 : 0.15),
              blurRadius: enableGlass ? 25 : 15,
              spreadRadius: enableGlass ? 0 : -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: enableGlass ? 20 : 0,
              sigmaY: enableGlass ? 20 : 0,
            ),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

/// Modern action button style for dialogs
Widget buildGlassActionButton({
  required BuildContext context,
  required String label,
  required VoidCallback onPressed,
  IconData? icon,
  bool isDestructive = false,
  bool isFilled = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  
  if (isFilled) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
      style: isDestructive
          ? FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            )
          : null,
    );
  }
  
  return TextButton.icon(
    onPressed: onPressed,
    icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
    label: Text(label),
    style: isDestructive
        ? TextButton.styleFrom(
            foregroundColor: colorScheme.error,
          )
        : null,
  );
}
