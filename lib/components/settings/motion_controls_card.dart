import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/morph_switch.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Live preview of the current switch style and icon morph (tap to try
/// it), shown under the switch-style choice in Motion & haptics.
class MotionControlsCard extends StatefulWidget {
  const MotionControlsCard({super.key});

  @override
  State<MotionControlsCard> createState() => _MotionControlsCardState();
}

class _MotionControlsCardState extends State<MotionControlsCard> {
  bool _demo = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (style, morph, shape, morphStyle) = context
        .select<
          PlusSettingsProvider,
          (SettingsSwitchStyle, bool, IconMorphShape, IconMorphStyle)
        >(
          (p) => (
            p.plusSwitchStyle,
            p.plusIconMorphOnToggle,
            p.plusIconMorphShape,
            p.plusIconMorphStyle,
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Text(
              tr('motionControlsPreviewHint'),
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Material(
            color: cs.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() => _demo = !_demo),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    ToggleIconBadge(
                      icon: Icons.animation_rounded,
                      active: _demo,
                      morphOnToggle: morph,
                      fill: style == SettingsSwitchStyle.iconSwitch,
                      shape: shape,
                      style: morphStyle,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr('switchStyleTryIt'),
                        style: text.bodyLarge,
                      ),
                    ),
                    ExcludeSemantics(
                      child: MorphSwitch(
                        value: _demo,
                        onChanged: (v) => setState(() => _demo = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
