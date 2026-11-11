import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/morph_switch.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Motion "hero" card: a live preview of the current switch and icon-morph
/// style (tap to try it), the enhanced-animations master toggle and the
/// reduce-shape-morphs option.
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              tr('motionControlsTitle'),
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              tr('motionControlsPreviewHint'),
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Material(
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
                          tr('previewSuffix', args: [tr('switchStyle')]),
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
          ),
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            icon: Icons.auto_awesome_motion_rounded,
            title: tr('plusEnhancedAnimations'),
            subtitle: tr('plusEnhancedAnimationsDescription'),
            value: (s) => s.plusEnableEnhancedAnimations,
            onChanged: (s, v) => s.plusEnableEnhancedAnimations = v,
          ),
          buildFeatureToggle<PlusSettingsProvider>(
            context,
            icon: Icons.speed_rounded,
            title: tr('previewSuffix', args: [tr('reduceShapeMorphs')]),
            subtitle: tr('reduceShapeMorphsDesc'),
            value: (s) => s.plusReduceShapeMorphs,
            onChanged: (s, v) => s.plusReduceShapeMorphs = v,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
