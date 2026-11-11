import 'package:flutter/material.dart';
import 'package:obtainium/theme/settings_tokens.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';

/// Choice control for 2–4 options: a connected button group (40 dp, outer
/// corners full, inner 8, pressed 4; the selected segment goes fully round
/// while its neighbours stay still, on the spatialFast spring). Five or
/// more options render a button that opens a radio sheet instead.
class ConnectedChoiceGroup<T> extends StatelessWidget {
  final Map<T, String> options;
  final T value;
  final ValueChanged<T>? onChanged;

  /// Title of the radio sheet used for 5+ options.
  final String? sheetTitle;

  const ConnectedChoiceGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.sheetTitle,
  });

  /// Above this many options the group opens a sheet.
  static const int maxConnected = 4;

  void _select(T v) {
    if (v == value) return;
    AppHaptics.segmentTick();
    onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    if (options.length > maxConnected) return _sheetButton(context);
    final keys = options.keys.toList();
    return SizedBox(
      height: SettingsTokens.choiceHeight,
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: SettingsTokens.segmentGap),
            Expanded(
              child: _Segment(
                label: options[keys[i]]!,
                selected: keys[i] == value,
                isFirst: i == 0,
                isLast: i == keys.length - 1,
                onTap: onChanged == null ? null : () => _select(keys[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sheetButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      value: options[value],
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(SettingsTokens.choiceHeight),
          alignment: AlignmentDirectional.centerStart,
          backgroundColor: cs.surfaceContainerHighest,
          foregroundColor: cs.onSurface,
        ),
        onPressed: onChanged == null ? null : () => _openSheet(context),
        child: Row(
          children: [
            Expanded(
              child: Text(
                options[value] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    AppHaptics.selectionClick();
    final picked = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: RadioGroup<T>(
            groupValue: value,
            onChanged: (v) => Navigator.of(sheetContext).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sheetTitle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Text(
                      sheetTitle!,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                for (final e in options.entries)
                  RadioListTile<T>(value: e.key, title: Text(e.value)),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null) _select(picked);
  }
}

class _Segment extends StatefulWidget {
  final String label;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const full = Radius.circular(SettingsTokens.choiceHeight / 2);
    final inner = Radius.circular(
      _pressed
          ? SettingsTokens.choicePressedRadius
          : SettingsTokens.choiceInnerRadius,
    );
    final radius = widget.selected
        ? const BorderRadius.all(full)
        : BorderRadiusDirectional.horizontal(
            start: widget.isFirst ? full : inner,
            end: widget.isLast ? full : inner,
          ).resolve(Directionality.of(context));
    final target = RoundedRectangleBorder(borderRadius: radius);
    final duration = AppMotion.springDuration(context, AppMotion.spatialFast);
    final bg = widget.selected
        ? cs.secondaryContainer
        : cs.surfaceContainerHighest;
    final fg = widget.selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: widget.selected,
      inMutuallyExclusiveGroup: true,
      child: Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: TweenAnimationBuilder<ShapeBorder?>(
          tween: ShapeBorderTween(end: target),
          duration: duration,
          curve: AppMotion.spatialFast,
          builder: (context, shape, child) => Material(
            color: bg,
            shape: shape ?? target,
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          child: InkWell(
            onTap: widget.onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
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
