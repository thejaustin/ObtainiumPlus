import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:material_new_shapes/material_new_shapes.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:provider/provider.dart';

/// Scales a path from a normalized (unit-square) shape into [size] and
/// centres it on [center] (the `_processPath` approach of
/// loading_indicator_m3e).
Path _fitPath(Path unit, double size, Offset center) {
  final scaled = unit.transform(Matrix4.diagonal3Values(size, size, 1).storage);
  return scaled.shift(center - scaled.getBounds().center);
}

/// A settings switch in one of four styles (`plusSwitchStyle`):
/// - [SettingsSwitchStyle.classic]: the SDK [Switch] with the theme's
///   check / close `thumbIcon` — exactly today's switch (the default).
/// - [SettingsSwitchStyle.expressive]: 52×32 track, thumb 16 off / 24 on /
///   28 pressed; position on the spatialDefault spring (drag velocity
///   carried), size on spatialFast, colour on effectsFast; the check fades
///   in after 60 % of travel.
/// - [SettingsSwitchStyle.shapeThumb]: as expressive, the thumb morphs from
///   a circle to a 4-sided cookie (static [thumbMorph]).
/// - [SettingsSwitchStyle.iconSwitch]: no track — an "On" / "Off" label;
///   the row's leading icon carries the state.
///
/// Fires the toggle haptic itself for its own taps and drags ([haptics]).
class MorphSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Null follows `plusSwitchStyle`.
  final SettingsSwitchStyle? style;
  final bool haptics;

  const MorphSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.style,
    this.haptics = true,
  });

  /// Built once; never in `build`.
  static final Morph thumbMorph = Morph(
    MaterialShapes.circle,
    MaterialShapes.cookie4Sided,
  );

  @override
  Widget build(BuildContext context) {
    final resolved =
        style ??
        context.select<PlusSettingsProvider, SettingsSwitchStyle>(
          (p) => p.plusSwitchStyle,
        );
    final enabled = onChanged != null;
    void change(bool v) {
      if (haptics) AppHaptics.toggled(v);
      onChanged?.call(v);
    }

    switch (resolved) {
      case SettingsSwitchStyle.classic:
        return Switch(value: value, onChanged: enabled ? change : null);
      case SettingsSwitchStyle.iconSwitch:
        return _OnOffLabel(value: value, onChanged: enabled ? change : null);
      case SettingsSwitchStyle.expressive:
      case SettingsSwitchStyle.shapeThumb:
        return _PaintedSwitch(
          value: value,
          onChanged: enabled ? change : null,
          shapeThumb: resolved == SettingsSwitchStyle.shapeThumb,
        );
    }
  }
}

class _OnOffLabel extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _OnOffLabel({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: value ? cs.primary : cs.onSurfaceVariant,
      fontWeight: value ? FontWeight.w700 : FontWeight.w500,
    );
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              child: AnimatedDefaultTextStyle(
                style: style ?? const TextStyle(),
                duration: AppMotion.duration(
                  context,
                  AppMotion.effectsFast.duration,
                ),
                child: Text(value ? tr('switchStateOn') : tr('switchStateOff')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaintedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool shapeThumb;

  const _PaintedSwitch({
    required this.value,
    required this.onChanged,
    required this.shapeThumb,
  });

  @override
  State<_PaintedSwitch> createState() => _PaintedSwitchState();
}

class _PaintedSwitchState extends State<_PaintedSwitch>
    with TickerProviderStateMixin {
  static const double _trackW = 52;
  static const double _trackH = 32;
  static const double _travel = _trackW - _trackH; // thumb centre travel

  late final AnimationController _pos;
  late final AnimationController _press;
  late final AnimationController _color;
  late final AnimationController _morph;
  late bool _target;

  @override
  void initState() {
    super.initState();
    _target = widget.value;
    final v = widget.value ? 1.0 : 0.0;
    _pos = AnimationController.unbounded(vsync: this, value: v);
    _press = AnimationController.unbounded(vsync: this, value: 0);
    _color = AnimationController(vsync: this, value: v);
    _morph = AnimationController.unbounded(vsync: this, value: v);
  }

  @override
  void didUpdateWidget(covariant _PaintedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shapeThumb != oldWidget.shapeThumb) {
      _morph.value = _target ? 1 : 0;
    }
    if (widget.value != _target) _animateTo(widget.value);
  }

  @override
  void dispose() {
    _pos.dispose();
    _press.dispose();
    _color.dispose();
    _morph.dispose();
    super.dispose();
  }

  bool get _reduceMorphs =>
      context.read<PlusSettingsProvider>().plusReduceShapeMorphs;

  void _spring(
    AnimationController c,
    SpringDescription spring,
    double target, {
    double velocity = 0,
    required bool animate,
  }) {
    if (animate) {
      c.animateWith(SpringSimulation(spring, c.value, target, velocity));
    } else {
      c.value = target;
    }
  }

  void _animateTo(bool on, {double velocity = 0}) {
    _target = on;
    final animate = AppMotion.enabledNow(context);
    final t = on ? 1.0 : 0.0;
    _spring(
      _pos,
      M3Springs.spatialDefault,
      t,
      velocity: velocity,
      animate: animate,
    );
    _spring(_color, M3Springs.effectsFast, t, animate: animate);
    // Always track the target so switching style / reduce-morphs at
    // runtime never shows a stale shape; only spring it when it is drawn.
    _spring(
      _morph,
      M3Springs.spatialFast,
      t,
      animate: animate && widget.shapeThumb && !_reduceMorphs,
    );
  }

  void _setPressed(bool pressed) {
    _spring(
      _press,
      M3Springs.spatialFast,
      pressed ? 1 : 0,
      animate: AppMotion.enabledNow(context),
    );
  }

  void _commit(bool on, {double velocity = 0}) {
    final changed = on != widget.value;
    if (changed &&
        widget.shapeThumb &&
        AppHaptics.intensity == HapticIntensity.strong) {
      AppHaptics.morphCue();
    }
    _animateTo(on, velocity: velocity);
    if (changed) widget.onChanged?.call(on);
  }

  double get _dir =>
      Directionality.of(context) == ui.TextDirection.rtl ? -1.0 : 1.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.onChanged != null;
    final reduce = context.select<PlusSettingsProvider, bool>(
      (p) => p.plusReduceShapeMorphs,
    );
    final painter = _SwitchPainter(
      pos: _pos,
      press: _press,
      color: _color,
      morph: _morph,
      shapeThumb: widget.shapeThumb && !reduce,
      rtl: _dir < 0,
      trackOff: cs.surfaceContainerHighest,
      trackOn: cs.primary,
      outline: cs.outline,
      thumbOff: cs.outline,
      thumbOn: cs.onPrimary,
      thumbPressedOn: cs.primaryContainer,
      thumbPressedOff: cs.onSurfaceVariant,
      icon: cs.primary,
    );
    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      onTap: enabled ? () => _commit(!widget.value) : null,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.38,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => _setPressed(true) : null,
            onTapCancel: enabled ? () => _setPressed(false) : null,
            onTap: enabled
                ? () {
                    _setPressed(false);
                    _commit(!widget.value);
                  }
                : null,
            onHorizontalDragStart: enabled
                ? (_) {
                    _pos.stop();
                    _setPressed(true);
                  }
                : null,
            onHorizontalDragUpdate: enabled
                ? (d) {
                    _pos.value = (_pos.value + _dir * d.delta.dx / _travel)
                        .clamp(0.0, 1.0);
                    _color.value = _pos.value;
                  }
                : null,
            onHorizontalDragEnd: enabled
                ? (d) {
                    _setPressed(false);
                    final v = _dir * (d.primaryVelocity ?? 0) / _travel;
                    final on = v.abs() > 2 ? v > 0 : _pos.value > 0.5;
                    _commit(on, velocity: v);
                  }
                : null,
            onHorizontalDragCancel: enabled
                ? () {
                    _setPressed(false);
                    _animateTo(widget.value);
                  }
                : null,
            child: SizedBox(
              width: _trackW + 8,
              height: 48,
              child: Center(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(_trackW, _trackH),
                    painter: painter,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchPainter extends CustomPainter {
  final Animation<double> pos;
  final Animation<double> press;
  final Animation<double> color;
  final Animation<double> morph;
  final bool shapeThumb;
  final bool rtl;
  final Color trackOff, trackOn, outline, thumbOff, thumbOn;
  final Color thumbPressedOn, thumbPressedOff, icon;

  _SwitchPainter({
    required this.pos,
    required this.press,
    required this.color,
    required this.morph,
    required this.shapeThumb,
    required this.rtl,
    required this.trackOff,
    required this.trackOn,
    required this.outline,
    required this.thumbOff,
    required this.thumbOn,
    required this.thumbPressedOn,
    required this.thumbPressedOff,
    required this.icon,
  }) : super(repaint: Listenable.merge([pos, press, color, morph]));

  static const IconData _check = Icons.check_rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final c = color.value.clamp(0.0, 1.0);
    final p = pos.value;
    final s = press.value;
    final h = size.height;
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(h / 2),
    );
    canvas.drawRRect(track, Paint()..color = Color.lerp(trackOff, trackOn, c)!);
    final outlineW = 2 * (1 - c);
    if (outlineW > 0.01) {
      canvas.drawRRect(
        track.deflate(outlineW / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineW
          ..color = outline,
      );
    }

    final travel = size.width - h;
    final x = h / 2 + travel * (rtl ? 1 - p : p);
    final center = Offset(x, h / 2);
    final base = 16 + 8 * p.clamp(0.0, 1.0);
    final diameter = base + (28 - base) * s;
    final thumbBase = Color.lerp(thumbOff, thumbOn, c)!;
    final thumbPressed = Color.lerp(thumbPressedOff, thumbPressedOn, c)!;
    final thumbPaint = Paint()
      ..color = Color.lerp(thumbBase, thumbPressed, s.clamp(0.0, 1.0))!;

    final m = morph.value;
    if (shapeThumb && m.abs() > 0.001) {
      final unit = MorphSwitch.thumbMorph.toPath(progress: m.clamp(0.0, 1.0));
      canvas.drawPath(_fitPath(unit, diameter, center), thumbPaint);
    } else {
      canvas.drawCircle(center, diameter / 2, thumbPaint);
    }

    // Check icon fades in over the last 40 % of travel.
    final iconAlpha = ((p - 0.6) / 0.4).clamp(0.0, 1.0);
    if (iconAlpha > 0) {
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(_check.codePoint),
          style: TextStyle(
            fontSize: 16,
            fontFamily: _check.fontFamily,
            package: _check.fontPackage,
            color: icon.withValues(alpha: iconAlpha),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      old.shapeThumb != shapeThumb ||
      old.rtl != rtl ||
      old.trackOff != trackOff ||
      old.trackOn != trackOn ||
      old.outline != outline ||
      old.thumbOff != thumbOff ||
      old.thumbOn != thumbOn ||
      old.thumbPressedOn != thumbPressedOn ||
      old.thumbPressedOff != thumbPressedOff ||
      old.icon != icon ||
      old.pos != pos;
}

/// Leading icon of a toggle row for the expressive kit.
/// - [morphOnToggle] (`plusIconMorphOnToggle`): circle → [shape] in
///   `primaryContainer` when on ([style]: morph / spin / pop); dims to
///   alpha 0.6 and scale 0.9 when off.
/// - [fill] (Icon-is-the-switch style): the container fills with `primary`
///   when on.
/// Shape progress and scale run on spatialFast, colour and alpha on
/// effectsFast; `plusReduceShapeMorphs` snaps the shape.
class ToggleIconBadge extends StatefulWidget {
  final IconData icon;
  final bool active;
  final bool morphOnToggle;
  final bool fill;
  final IconMorphShape shape;
  final IconMorphStyle style;
  final double size;

  const ToggleIconBadge({
    super.key,
    required this.icon,
    required this.active,
    this.morphOnToggle = false,
    this.fill = false,
    this.shape = IconMorphShape.squircle,
    this.style = IconMorphStyle.morph,
    this.size = 36,
  });

  static final Map<IconMorphShape, Morph> _morphs = {};

  /// Number of [Morph]s ever built (one per shape at most).
  @visibleForTesting
  static int get morphsBuilt => _morphs.length;

  /// Circle → [shape] morph, built once per shape and cached.
  static Morph morphFor(IconMorphShape shape) => _morphs.putIfAbsent(
    shape,
    () => Morph(MaterialShapes.circle, switch (shape) {
      IconMorphShape.squircle => MaterialShapes.square,
      IconMorphShape.cookie => MaterialShapes.cookie6Sided,
      IconMorphShape.clover => MaterialShapes.clover4Leaf,
      IconMorphShape.sunny => MaterialShapes.sunny,
      IconMorphShape.softBurst => MaterialShapes.softBurst,
    }),
  );

  @override
  State<ToggleIconBadge> createState() => _ToggleIconBadgeState();
}

class _ToggleIconBadgeState extends State<ToggleIconBadge>
    with TickerProviderStateMixin {
  late final AnimationController _shape;
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    final v = widget.active ? 1.0 : 0.0;
    _shape = AnimationController.unbounded(vsync: this, value: v);
    _fill = AnimationController(vsync: this, value: v);
  }

  @override
  void didUpdateWidget(covariant ToggleIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    final t = widget.active ? 1.0 : 0.0;
    final animate = AppMotion.enabledNow(context);
    final reduce = context.read<PlusSettingsProvider>().plusReduceShapeMorphs;
    if (!animate) {
      _shape.value = t;
      _fill.value = t;
      return;
    }
    if (reduce) {
      _shape.value = t;
    } else {
      // Pop starts small and springs past full size.
      final from = widget.style == IconMorphStyle.pop && widget.active
          ? 0.4
          : _shape.value;
      _shape.animateWith(SpringSimulation(M3Springs.spatialFast, from, t, 0));
    }
    _fill.animateWith(
      SpringSimulation(M3Springs.effectsFast, _fill.value, t, 0),
    );
  }

  @override
  void dispose() {
    _shape.dispose();
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final morph = widget.morphOnToggle
        ? ToggleIconBadge.morphFor(widget.shape)
        : null;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_shape, _fill]),
        builder: (context, _) {
          final f = _fill.value.clamp(0.0, 1.0);
          final m = _shape.value;
          final Color bg;
          final Color fg;
          if (widget.fill) {
            bg = Color.lerp(cs.surfaceContainerHighest, cs.primary, f)!;
            fg = Color.lerp(cs.onSurfaceVariant, cs.onPrimary, f)!;
          } else if (morph != null) {
            bg = Color.lerp(
              cs.surfaceContainerHighest,
              cs.primaryContainer,
              f,
            )!;
            fg = Color.lerp(cs.onSurfaceVariant, cs.onPrimaryContainer, f)!;
          } else {
            bg = cs.surfaceContainerHighest;
            fg = Color.lerp(cs.onSurfaceVariant, cs.primary, f)!;
          }
          final dim = morph != null;
          final scale = dim ? 0.9 + 0.1 * m : 1.0;
          final alpha = dim ? 0.6 + 0.4 * f : 1.0;
          final angle = widget.style == IconMorphStyle.spin && morph != null
              ? m * math.pi / 2
              : 0.0;
          final progress = widget.style == IconMorphStyle.pop
              ? (m > 0.5 ? 1.0 : 0.0)
              : m.clamp(0.0, 1.0);
          return Opacity(
            opacity: alpha,
            child: Transform.scale(
              scale: scale,
              child: SizedBox.square(
                dimension: widget.size,
                child: CustomPaint(
                  painter: _BadgePainter(
                    morph: morph,
                    progress: progress,
                    angle: angle,
                    color: bg,
                  ),
                  child: Icon(widget.icon, size: widget.size * 0.53, color: fg),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final Morph? morph;
  final double progress;
  final double angle;
  final Color color;

  _BadgePainter({
    required this.morph,
    required this.progress,
    required this.angle,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = size.center(Offset.zero);
    if (morph == null || progress <= 0.001) {
      canvas.drawCircle(center, size.shortestSide / 2, paint);
      return;
    }
    var path = _fitPath(
      morph!.toPath(progress: progress),
      size.shortestSide,
      center,
    );
    if (angle != 0) {
      final m = Matrix4.identity()
        ..translateByDouble(center.dx, center.dy, 0, 1)
        ..rotateZ(angle)
        ..translateByDouble(-center.dx, -center.dy, 0, 1);
      path = path.transform(m.storage);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.morph != morph ||
      old.progress != progress ||
      old.angle != angle ||
      old.color != color;
}
