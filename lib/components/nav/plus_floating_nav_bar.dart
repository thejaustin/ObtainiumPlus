import 'dart:ui' show lerpDouble;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:provider/provider.dart';

/// Floating pill nav bar with a stretchy morphing indicator and icon bounce.
///
/// Replaces the plain NavigationBar in floating mode. The indicator pill's
/// leading and trailing edges animate independently — the leading edge of
/// the move direction travels first (fast easeOut), the lagging edge follows
/// after a 25% delay, creating a natural stretch-and-snap effect.
class PlusFloatingNavBar extends StatefulWidget {
  final List<NavigationPageItem> pages;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool animationsEnabled;
  final bool alwaysShowLabels;

  const PlusFloatingNavBar({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.animationsEnabled,
    required this.alwaysShowLabels,
  });

  @override
  State<PlusFloatingNavBar> createState() => _PlusFloatingNavBarState();
}

class _PlusFloatingNavBarState extends State<PlusFloatingNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _leftCtrl;
  late final AnimationController _rightCtrl;
  late Animation<double> _leftAnim;
  late Animation<double> _rightAnim;

  late final List<AnimationController> _bounceCtrl;
  late final List<Animation<double>> _bounceAnim;

  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    final n = widget.pages.length;
    final frac = 1.0 / n;
    final initL = widget.currentIndex * frac;
    final initR = (widget.currentIndex + 1) * frac;

    _leftCtrl = AnimationController(vsync: this);
    _rightCtrl = AnimationController(vsync: this);
    _leftAnim = AlwaysStoppedAnimation(initL);
    _rightAnim = AlwaysStoppedAnimation(initR);
    _prevIndex = widget.currentIndex;

    _bounceCtrl = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _bounceAnim = List.generate(n, (i) => AlwaysStoppedAnimation(1.0));
  }

  @override
  void didUpdateWidget(PlusFloatingNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _animatePill(widget.currentIndex);
      _bounce(widget.currentIndex);
    }
  }

  void _animatePill(int newIndex) {
    final n = widget.pages.length;
    final frac = 1.0 / n;
    final curL = _leftAnim.value;
    final curR = _rightAnim.value;
    final newL = newIndex * frac;
    final newR = (newIndex + 1) * frac;
    final goRight = newIndex > _prevIndex;
    final dur = widget.animationsEnabled
        ? AppMotion.spatial.duration
        : const Duration(milliseconds: 120);

    _leftCtrl.duration = dur;
    _rightCtrl.duration = dur;

    // Leading edge rides the M3E spatial spring (slight overshoot); the
    // lagging edge starts later on the same spring, giving the stretch.
    final Curve lead = widget.animationsEnabled
        ? AppMotion.spatial
        : Curves.easeOutCubic;
    final lag = Interval(0.22, 1.0, curve: lead);

    if (goRight) {
      _rightAnim = Tween(
        begin: curR,
        end: newR,
      ).animate(CurvedAnimation(parent: _rightCtrl, curve: lead));
      _leftAnim = Tween(
        begin: curL,
        end: newL,
      ).animate(CurvedAnimation(parent: _leftCtrl, curve: lag));
    } else {
      _leftAnim = Tween(
        begin: curL,
        end: newL,
      ).animate(CurvedAnimation(parent: _leftCtrl, curve: lead));
      _rightAnim = Tween(
        begin: curR,
        end: newR,
      ).animate(CurvedAnimation(parent: _rightCtrl, curve: lag));
    }

    _leftCtrl.forward(from: 0);
    _rightCtrl.forward(from: 0);
    _prevIndex = newIndex;
  }

  void _bounce(int i) {
    if (!widget.animationsEnabled) return;
    _bounceAnim[i] = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.24), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.24, end: 0.88), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 40),
      ],
    ).animate(CurvedAnimation(parent: _bounceCtrl[i], curve: Curves.easeInOut));
    _bounceCtrl[i].forward(from: 0);
  }

  @override
  void dispose() {
    _leftCtrl.dispose();
    _rightCtrl.dispose();
    for (final c in _bounceCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isM3E = context
        .watch<PlusSettingsProvider>()
        .plusEnableMaterialExpressive;
    final n = widget.pages.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        const pillH = 36.0;
        const vPad = 8.0;
        const labelH = 18.0;
        final barH = pillH + vPad * 2 + labelH;

        return AnimatedBuilder(
          animation: Listenable.merge([_leftCtrl, _rightCtrl]),
          builder: (context, _) {
            final lv = _leftAnim.value;
            final rv = _rightAnim.value;
            final pillL = lerpDouble(0, totalW, lv)! + 6;
            final pillR = lerpDouble(0, totalW, rv)! - 6;
            final pillW = (pillR - pillL).clamp(48.0, double.infinity);

            return SizedBox(
              height: barH,
              child: Stack(
                children: [
                  // Stretchy indicator pill
                  // Directional so the pill tracks the mirrored Row in RTL.
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    start: pillL,
                    top: vPad,
                    child: Container(
                      width: pillW,
                      height: pillH,
                      decoration: ShapeDecoration(
                        color: cs.primaryContainer,
                        shape: CardMetrics.shape(18, expressive: isM3E),
                      ),
                    ),
                  ),
                  // Destination row
                  Row(
                    children: List.generate(n, (i) {
                      final sel = i == widget.currentIndex;
                      return Expanded(
                        child: Semantics(
                          label: tr(widget.pages[i].title),
                          selected: sel,
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              AppHaptics.selectionClick();
                              widget.onDestinationSelected(i);
                            },
                            child: SizedBox(
                              height: barH,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: vPad),
                                  AnimatedBuilder(
                                    animation: _bounceCtrl[i],
                                    builder: (context, child) =>
                                        Transform.scale(
                                          scale: _bounceAnim[i].value,
                                          child: child,
                                        ),
                                    child: Icon(
                                      widget.pages[i].icon,
                                      size: 24,
                                      color: sel
                                          ? cs.onPrimaryContainer
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Opacity(
                                    opacity: (sel || widget.alwaysShowLabels)
                                        ? 1.0
                                        : 0.0,
                                    child: AnimatedDefaultTextStyle(
                                      duration: Duration(
                                        milliseconds: widget.animationsEnabled
                                            ? 180
                                            : 0,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                            color: sel
                                                ? cs.onPrimaryContainer
                                                : cs.onSurfaceVariant,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                      child: Text(
                                        tr(widget.pages[i].title),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: vPad),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
