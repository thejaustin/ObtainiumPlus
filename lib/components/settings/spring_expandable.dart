import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:obtainium/components/settings/settings_row.dart';
import 'package:obtainium/theme.dart';
import 'package:obtainium/theme/settings_tokens.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';

/// Collapsible segmented group: a header segment plus body rows. Height
/// runs on the spatialDefault spring (clamped to [0,1]); the chevron rotates
/// on spatialFast (overshoot allowed); content fades with the height.
///
/// Expanded state lives in the nearest [PageStorage] under the explicit
/// identifier `spring_expandable:<storageKey>` and is type-checked on read,
/// so a scroll offset or other value in a shared slot can never be read
/// back as the flag.
class SpringExpandable extends StatefulWidget {
  final String storageKey;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Optional "X / Y on" style pill shown while collapsed.
  final String? badgeLabel;
  final List<Widget> children;
  final bool initiallyExpanded;
  final double outerRadius;
  final double innerRadius;
  final Color? color;
  final ValueChanged<bool>? onExpansionChanged;

  const SpringExpandable({
    super.key,
    required this.storageKey,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.badgeLabel,
    required this.children,
    this.initiallyExpanded = false,
    this.outerRadius = SettingsTokens.outerRadius,
    this.innerRadius = SettingsTokens.innerRadius,
    this.color,
    this.onExpansionChanged,
  });

  @override
  State<SpringExpandable> createState() => SpringExpandableState();
}

class _Clamp01 extends Animatable<double> {
  const _Clamp01();
  @override
  double transform(double t) => t.clamp(0.0, 1.0);
}

class SpringExpandableState extends State<SpringExpandable>
    with TickerProviderStateMixin {
  late final AnimationController _size;
  late final AnimationController _chevron;
  late final Animation<double> _sizeClamped;
  late bool _expanded;
  bool _restored = false;

  bool get expanded => _expanded;

  String get _id => 'spring_expandable:${widget.storageKey}';

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _size = AnimationController(vsync: this, value: _expanded ? 1 : 0);
    _chevron = AnimationController.unbounded(
      vsync: this,
      value: _expanded ? 1 : 0,
    );
    _sizeClamped = _size.drive(const _Clamp01());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    final stored = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: _id);
    if (stored is bool && stored != _expanded) {
      _expanded = stored;
      _size.value = stored ? 1 : 0;
      _chevron.value = stored ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _size.dispose();
    _chevron.dispose();
    super.dispose();
  }

  void toggle() {
    final next = !_expanded;
    setState(() => _expanded = next);
    PageStorage.maybeOf(context)?.writeState(context, next, identifier: _id);
    AppHaptics.expandChanged(next);
    widget.onExpansionChanged?.call(next);
    final target = next ? 1.0 : 0.0;
    if (AppMotion.enabledNow(context)) {
      _size.animateWith(
        SpringSimulation(M3Springs.spatialDefault, _size.value, target, 0),
      );
      _chevron.animateWith(
        SpringSimulation(M3Springs.spatialFast, _chevron.value, target, 0),
      );
    } else {
      _size.value = target;
      _chevron.value = target;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.color ?? SettingsTokens.rowColor(cs);
    final outer = widget.outerRadius;
    final inner = widget.innerRadius.clamp(0.0, outer);
    final rows = widget.children;

    final header = PressMorphSurface(
      radius: positionalTileRadius(
        isFirst: true,
        isLast: !_expanded || rows.isEmpty,
        outer: outer,
        inner: inner,
      ),
      pressedRadius: BorderRadius.circular(outer),
      color: color,
      child: SettingsSegmentScope(
        child: SettingsRow(
          leading: widget.leading,
          title: widget.title,
          summary: widget.subtitle,
          onTap: toggle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_expanded && widget.badgeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: ShapeDecoration(
                    color: cs.secondaryContainer,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.badgeLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),
              ?widget.trailing,
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: ShapeDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: const CircleBorder(),
                ),
                child: AnimatedBuilder(
                  animation: _chevron,
                  builder: (context, child) => Transform.rotate(
                    angle: _chevron.value * 3.141592653589793,
                    child: child,
                  ),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final body = Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          const SizedBox(height: SettingsTokens.segmentGap),
          PressMorphSurface(
            radius: positionalTileRadius(
              isFirst: false,
              isLast: i == rows.length - 1,
              outer: outer,
              inner: inner,
            ),
            pressedRadius: BorderRadius.circular(outer),
            color: color,
            child: SettingsSegmentScope(child: rows[i]),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SizeTransition(
          sizeFactor: _sizeClamped,
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _sizeClamped,
            // Collapsed rows stay out of focus and semantics.
            child: _expanded || _size.isAnimating
                ? body
                : ExcludeSemantics(child: body),
          ),
        ),
      ],
    );
  }
}
