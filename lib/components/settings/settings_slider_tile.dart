import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Expressive slider tile: icon + title + animated value badge + slider.
/// Shape of the value badge morphs from rounded rect to squircle while dragging.
/// If [defaultValue] is provided and the slider is moved, an undo button appears
/// to quickly reset the slider back to its default value with tactile haptic feedback.
class SettingsSliderTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final double? defaultValue;
  final String Function(double) labelBuilder;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const SettingsSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.defaultValue,
    required this.labelBuilder,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<SettingsSliderTile> {
  bool _isDragging = false;
  double? _lastSnappedIndex;
  int _rollDirection = 1;

  @override
  void didUpdateWidget(covariant SettingsSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _rollDirection = widget.value >= oldWidget.value ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final animsEnabled = plusSettings.plusEnableEnhancedAnimations;
    final isCompact = plusSettings.plusUseCompactSettings;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final badgeRadius = _isDragging
        ? (baseRadius * 0.5).clamp(6.0, 14.0)
        : (baseRadius * 0.7).clamp(10.0, 20.0);

    final bool isModifiedFromDefault =
        widget.defaultValue != null &&
        (widget.value - widget.defaultValue!).abs() > 0.001;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final innerRadius = CardMetrics.inner(CardMetrics.card(baseRadius));
    final badgeSize = isCompact ? 30.0 : 36.0;
    final labelText = widget.labelBuilder(widget.value);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 14 : 16,
        isCompact ? 4 : 8,
        isCompact ? 14 : 16,
        isCompact ? 0 : 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: animsEnabled ? 220 : 0),
                curve: Curves.easeOutCubic,
                width: badgeSize,
                height: badgeSize,
                decoration: ShapeDecoration(
                  color: _isDragging
                      ? colorScheme.primary.withValues(alpha: 0.18)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: isM3E ? 0.50 : 0.30,
                        ),
                  shape: CardMetrics.shape(innerRadius, expressive: isM3E),
                ),
                child: Icon(
                  widget.icon,
                  size: isCompact ? 16 : 19,
                  color: _isDragging
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: isCompact
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (isModifiedFromDefault)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message:
                        '${tr('resetToDefault')} (${widget.labelBuilder(widget.defaultValue!)})',
                    child: IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        AppHaptics.mediumImpact();
                        widget.onChanged(widget.defaultValue!);
                        widget.onChangeEnd?.call(widget.defaultValue!);
                      },
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: Duration(milliseconds: animsEnabled ? 220 : 0),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: _isDragging
                      ? (isCompact ? 8 : 10)
                      : (isCompact ? 10 : 12),
                  vertical: isCompact ? 2.5 : 4,
                ),
                decoration: ShapeDecoration(
                  color: _isDragging
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHigh,
                  shape: CardMetrics.shape(
                    badgeRadius,
                    expressive: isM3E,
                    side: BorderSide(
                      color: _isDragging
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.35
                                  : 0.65,
                            ),
                      width: _isDragging ? 1.5 : 1.0,
                    ),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: animsEnabled ? 150 : 0),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final isEntering = child.key == ValueKey<String>(labelText);
                    final dy = isEntering
                        ? 0.38 * _rollDirection
                        : -0.38 * _rollDirection;
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, dy),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    labelText,
                    key: ValueKey<String>(labelText),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontSize: isCompact ? 11 : null,
                      fontWeight: _isDragging
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: _isDragging
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // The morphing badge above already shows the value; keep `label`
          // for semantics but suppress the theme's drag bubble.
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              showValueIndicator: ShowValueIndicator.never,
              trackHeight: isCompact ? 3.5 : 5.0,
            ),
            child: Slider(
              value: widget.value,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: labelText,
              onChangeStart: (_) {
                AppHaptics.tapDown();
                setState(() {
                  _isDragging = true;
                  _lastSnappedIndex = null;
                });
              },
              onChanged: (v) {
                if (widget.divisions != null) {
                  final step = (widget.max - widget.min) / widget.divisions!;
                  final idx = ((v - widget.min) / step).round().toDouble();
                  if (idx != _lastSnappedIndex) {
                    _lastSnappedIndex = idx;
                    AppHaptics.segmentTick();
                  }
                }
                widget.onChanged(v);
              },
              onChangeEnd: (v) {
                setState(() => _isDragging = false);
                AppHaptics.lightImpact();
                widget.onChangeEnd?.call(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
