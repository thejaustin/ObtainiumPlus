import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obtainium/utils/motion.dart';

/// Marks which settings section a subtree of search results belongs to, so a
/// tapped result can open the right section.
class SettingsJumpSection extends InheritedWidget {
  final int index;

  const SettingsJumpSection({
    super.key,
    required this.index,
    required super.child,
  });

  static int? maybeOf(Element e) =>
      e.getInheritedWidgetOfExactType<SettingsJumpSection>()?.index;

  @override
  bool updateShouldNotify(SettingsJumpSection old) => index != old.index;
}

/// Search jump (preview). While [enabled], taps on search results do not
/// reach the rows: the tapped row's title and section go to [onJump] instead.
/// Scrolling still works. Disabled, this is just [child].
class SettingsSearchJumpLayer extends StatelessWidget {
  final bool enabled;
  final void Function(int section, String title) onJump;
  final Widget child;

  const SettingsSearchJumpLayer({
    super.key,
    required this.enabled,
    required this.onJump,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Builder(
      builder: (layerContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final hit = findTappedRow(layerContext, d.globalPosition);
          if (hit != null) onJump(hit.section, hit.title);
        },
        child: AbsorbPointer(child: child),
      ),
    );
  }
}

/// Section and title of the row under [globalPosition] inside [root]'s
/// subtree, or null. Prefers the title of a [ListTile] under the tap; falls
/// back to the text nearest the tap vertically.
({int section, String title})? findTappedRow(
  BuildContext root,
  Offset globalPosition,
) {
  final tiles = <Element>[];
  final texts = <Element>[];
  void visit(Element e) {
    final w = e.widget;
    if (w is ListTile) tiles.add(e);
    if (w is Text && w.data != null && w.data!.isNotEmpty) texts.add(e);
    e.visitChildren(visit);
  }

  (root as Element).visitChildren(visit);

  Rect? rectOf(Element e) {
    final ro = e.renderObject;
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  for (final t in tiles) {
    final r = rectOf(t);
    if (r == null || !r.contains(globalPosition)) continue;
    final title = (t.widget as ListTile).title;
    if (title is Text && title.data != null) {
      final section = SettingsJumpSection.maybeOf(t);
      if (section != null) return (section: section, title: title.data!);
    }
  }

  Element? best;
  var bestDist = double.infinity;
  for (final t in texts) {
    final r = rectOf(t);
    if (r == null) continue;
    final dist = r.contains(globalPosition)
        ? 0.0
        : (globalPosition.dy < r.top
              ? r.top - globalPosition.dy
              : (globalPosition.dy > r.bottom
                    ? globalPosition.dy - r.bottom
                    : 0.0));
    if (dist < bestDist) {
      bestDist = dist;
      best = t;
    }
  }
  if (best == null || bestDist > 48) return null;
  final section = SettingsJumpSection.maybeOf(best);
  if (section == null) return null;
  return (section: section, title: (best.widget as Text).data!);
}

/// Finds the row titled [title] under [root] (a [Text] with that exact
/// string), preferring its enclosing [ListTile].
Element? findRowByTitle(BuildContext root, String title) {
  Element? found;
  void visit(Element e) {
    if (found != null) return;
    final w = e.widget;
    if (w is Text && w.data == title) {
      Element target = e;
      e.visitAncestorElements((a) {
        if (a.widget is ListTile) {
          target = a;
          return false;
        }
        return a != root;
      });
      found = target;
      return;
    }
    e.visitChildren(visit);
  }

  (root as Element).visitChildren(visit);
  return found;
}

/// Scrolls [row] into view on the spatial-slow spring, then pulses a
/// secondaryContainer highlight over it on effects-slow. With motion off it
/// still scrolls (instantly) but skips the pulse.
Future<void> revealAndHighlightRow(BuildContext context, Element row) async {
  final colors = Theme.of(context).colorScheme;
  final overlay = Overlay.maybeOf(context);
  final animate = AppMotion.enabledNow(context);
  final scroll = Scrollable.ensureVisible(
    row,
    alignment: 0.3,
    duration: animate ? AppMotion.spatialSlow.duration : Duration.zero,
    curve: animate ? AppMotion.spatialSlow : Curves.linear,
  );
  await scroll;
  if (!animate || overlay == null || !row.mounted) return;
  final ro = row.renderObject;
  final overlayBox = overlay.context.findRenderObject();
  if (ro is! RenderBox || !ro.hasSize || overlayBox is! RenderBox) return;
  final topLeft = overlayBox.globalToLocal(ro.localToGlobal(Offset.zero));
  final rect = topLeft & ro.size;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: _RowPulse(
          color: colors.secondaryContainer,
          duration: AppMotion.effectsSlow.duration,
          onDone: () => entry.remove(),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}

class _RowPulse extends StatefulWidget {
  final Color color;
  final Duration duration;
  final VoidCallback onDone;

  const _RowPulse({
    required this.color,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_RowPulse> createState() => _RowPulseState();
}

class _RowPulseState extends State<_RowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    // Twice the settle time of the spring: up to the highlight, then back.
    _c = AnimationController(vsync: this, duration: widget.duration * 2)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        // Triangle 0 → 1 → 0 shaped by the effects spring.
        final t = _c.value < 0.5 ? _c.value * 2 : (1 - _c.value) * 2;
        final a = AppMotion.effectsSlow.transform(t).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.75 * a),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
