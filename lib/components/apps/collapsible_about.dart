import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: () {
              AppHaptics.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            icon: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: Duration(milliseconds: anims ? 240 : 0),
              child: const Icon(Icons.expand_more_rounded, size: 20),
            ),
            label: Text(tr(_expanded ? 'aboutShowLess' : 'aboutShowMore')),
          ),
        ),
      ],
    );
  }
}
