import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/theme/settings_tokens.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:provider/provider.dart';

/// Tells a [SettingsRow] that a segmented group already draws its surface
/// (colour, positional corners and press morph), so the row only lays out
/// its slots.
class SettingsSegmentScope extends InheritedWidget {
  const SettingsSegmentScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsSegmentScope>() !=
      null;

  @override
  bool updateShouldNotify(SettingsSegmentScope oldWidget) => false;
}

/// A [Material] surface whose corners squeeze to [pressedRadius] (and whose
/// scale dips to 0.985) while a pointer is down. The shape animates through
/// `TweenAnimationBuilder<ShapeBorder?>`, resolving a null shape first.
/// In: effectsFast; out: spatialFast. Instant when motion is off.
class PressMorphSurface extends StatefulWidget {
  final BorderRadius radius;
  final BorderRadius? pressedRadius;
  final Color color;
  final Widget child;
  final bool enabled;

  const PressMorphSurface({
    super.key,
    required this.radius,
    this.pressedRadius,
    required this.color,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PressMorphSurface> createState() => _PressMorphSurfaceState();
}

class _PressMorphSurfaceState extends State<PressMorphSurface> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final animate = AppMotion.enabled(context);
    final pressed = _pressed && widget.enabled;
    final curve = pressed ? AppMotion.effectsFast : AppMotion.spatialFast;
    final duration = animate ? curve.duration : Duration.zero;
    final target = RoundedRectangleBorder(
      borderRadius: pressed
          ? (widget.pressedRadius ?? widget.radius)
          : widget.radius,
    );
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: pressed ? SettingsTokens.pressedScale : 1.0,
        duration: duration,
        curve: curve,
        child: TweenAnimationBuilder<ShapeBorder?>(
          tween: ShapeBorderTween(end: target),
          duration: duration,
          curve: curve,
          child: widget.child,
          builder: (context, shape, child) {
            final resolved = shape ?? target;
            return Material(
              color: widget.color,
              shape: resolved,
              clipBehavior: Clip.antiAlias,
              child: child,
            );
          },
        ),
      ),
    );
  }
}

/// One settings row with leading / title / summary / trailing slots. The
/// whole row is the tap target. Inside a segmented group it draws only its
/// content; standalone it brings its own [PressMorphSurface].
class SettingsRow extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? summary;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Dimmed to 0.38 and untappable when false (dependent child rows).
  final bool enabled;

  /// Semantics: set for toggle rows so the whole row reads as a switch.
  final bool? toggled;

  /// Standalone surface colour and corners (ignored inside a segment).
  final Color? color;
  final BorderRadius? radius;

  const SettingsRow({
    super.key,
    this.leading,
    required this.title,
    this.summary,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.toggled,
    this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.select<PlusSettingsProvider, bool>(
      (p) => p.plusUseCompactSettings,
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fade = AppMotion.duration(context, AppMotion.effects.duration);

    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: isCompact
            ? SettingsTokens.rowMinHeightCompact
            : SettingsTokens.rowMinHeight,
      ),
      child: Padding(
        padding: isCompact
            ? SettingsTokens.rowPadding.copyWith(top: 6, bottom: 6)
            : SettingsTokens.rowPadding,
        child: Row(
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(
                  size: isCompact
                      ? SettingsTokens.leadingIconSizeCompact
                      : SettingsTokens.leadingIconSize,
                  color: cs.onSurfaceVariant,
                ),
                child: leading!,
              ),
              const SizedBox(width: SettingsTokens.rowSlotGap),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style:
                        (isCompact
                                ? theme.textTheme.bodyMedium
                                : theme.textTheme.bodyLarge)
                            ?.copyWith(color: cs.onSurface),
                    child: title,
                  ),
                  if (summary != null)
                    DefaultTextStyle.merge(
                      style:
                          (isCompact
                                  ? theme.textTheme.bodySmall
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(color: cs.onSurfaceVariant),
                      child: summary!,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: SettingsTokens.rowSlotGap),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: SettingsTokens.trailingSlotWidth,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 1,
                  child: trailing!,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // One merged node: TalkBack reads the row (title, summary, state) as a
    // single switch / button with the row's tap action.
    Widget row = MergeSemantics(
      child: Semantics(
        toggled: toggled,
        enabled: enabled,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: content,
        ),
      ),
    );
    row = AnimatedOpacity(
      opacity: enabled ? 1 : SettingsTokens.disabledOpacity,
      duration: fade,
      child: row,
    );

    if (SettingsSegmentScope.of(context)) return row;
    return PressMorphSurface(
      radius: radius ?? BorderRadius.circular(SettingsTokens.outerRadius),
      pressedRadius: radius == null
          ? null
          : BorderRadius.circular(SettingsTokens.outerRadius),
      color: color ?? Colors.transparent,
      enabled: enabled && onTap != null,
      child: row,
    );
  }
}
