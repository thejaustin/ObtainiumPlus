import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Long app descriptions start as a short preview that fades out, with a
/// button to read the rest. Short ones, or all of them when the setting is
/// off, show in full.
class CollapsibleAbout extends StatefulWidget {
  final String text;
  final Widget child;

  const CollapsibleAbout({super.key, required this.text, required this.child});

  static const double collapsedHeight = 128;

  /// Rough cut-off for "more than about six lines" without laying it out.
  @visibleForTesting
  static bool isLong(String text) =>
      text.length > 360 || '\n'.allMatches(text.trim()).length >= 6;

  @override
  State<CollapsibleAbout> createState() => _CollapsibleAboutState();
}

class _CollapsibleAboutState extends State<CollapsibleAbout> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    if (!plusSettings.plusEnablePopupSlider ||
        !CollapsibleAbout.isLong(widget.text)) {
      return widget.child;
    }
    final anims = plusSettings.plusEnableEnhancedAnimations;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: Duration(milliseconds: anims ? 320 : 0),
          curve: Curves.easeInOutCubicEmphasized,
          alignment: Alignment.topCenter,
          child: _expanded
              ? widget.child
              : ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0, 0.6, 1],
                  ).createShader(rect),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: CollapsibleAbout.collapsedHeight,
                    ),
                    child: ClipRect(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ScaleTouchWrapper(
              scaleDownFactor: 0.94,
              onTap: () {
                AppHaptics.selectionClick();
                setState(() => _expanded = !_expanded);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr(_expanded ? 'aboutShowLess' : 'aboutShowMore'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: Duration(milliseconds: anims ? 240 : 0),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
