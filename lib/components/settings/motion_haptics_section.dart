import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/motion_controls_card.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// Look & motion → Motion & haptics: animations and page transitions,
/// haptic feedback, and the (preview) control styles.
class MotionHapticsSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const MotionHapticsSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  bool _matches(String text, {bool isAdvanced = false, String? desc}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    final q = searchQuery!.toLowerCase();
    return text.toLowerCase().contains(q) ||
        (desc != null && desc.toLowerCase().contains(q));
  }

  static String preview(String key) => tr('previewSuffix', args: [tr(key)]);

  @override
  Widget build(BuildContext context) {
    final isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    final plus = context.watch<PlusSettingsProvider>();
    final behavior = context.watch<BehaviorSettingsProvider>();
    String? label(String key) => isSearching ? null : tr(key);
    // Rows inside the "Controls (preview)" group: the group header already
    // says preview, so the suffix only shows in search results.
    String inPreviewGroup(String key) => isSearching ? preview(key) : tr(key);

    // ── Motion ──────────────────────────────────────────────────────────
    final motionChildren = <Widget>[
      if (_matches(tr('animationSpeed')))
        SettingsSliderTile(
          icon: Icons.speed_outlined,
          title: tr('animationSpeed'),
          value: behavior.animationSpeedMultiplier.clamp(0.25, 2.0),
          defaultValue: 1.0,
          min: 0.25,
          max: 2.0,
          divisions: 7,
          labelBuilder: (v) => '${(v * 100).round()}%',
          onChanged: (val) {
            const steps = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
            final nearest = steps.reduce(
              (a, b) => (a - val).abs() < (b - val).abs() ? a : b,
            );
            behavior.animationSpeedMultiplier = nearest;
          },
        ),
      if (_matches(
            tr('reversePageTransitions'),
            desc: tr('reversePageTransitionsDescription'),
          ) &&
          !behavior.disablePageTransitions)
        buildFeatureToggle<BehaviorSettingsProvider>(
          context,
          icon: Icons.swap_horizontal_circle_outlined,
          title: tr('reversePageTransitions'),
          subtitle: tr('reversePageTransitionsDescription'),
          value: (s) => s.reversePageTransitions,
          onChanged: (s, v) => s.reversePageTransitions = v,
        ),
      if (_matches(
        tr('disablePageTransitions'),
        desc: tr('disablePageTransitionsDescription'),
        isAdvanced: true,
      ))
        buildFeatureToggle<BehaviorSettingsProvider>(
          context,
          icon: Icons.animation_outlined,
          title: tr('disablePageTransitions'),
          subtitle: tr('disablePageTransitionsDescription'),
          value: (s) => s.disablePageTransitions,
          onChanged: (s, v) => s.disablePageTransitions = v,
        ),
    ];
    final showMotionMaster = _matches(
      tr('plusEnhancedAnimations'),
      desc: tr('plusEnhancedAnimationsDescription'),
    );
    final motionWidgets = <Widget>[
      if (showMotionMaster)
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.auto_awesome_motion_rounded,
          title: tr('plusEnhancedAnimations'),
          subtitle: tr('plusEnhancedAnimationsDescription'),
          value: (s) => s.plusEnableEnhancedAnimations,
          onChanged: (s, v) => s.plusEnableEnhancedAnimations = v,
        ),
      if (motionChildren.isNotEmpty)
        // Speed and transitions only apply while animations are on.
        SettingsChildRows(
          enabled: plus.plusEnableEnhancedAnimations,
          children: motionChildren,
        ),
      if (_matches(
        tr('plusBouncyPhysics'),
        desc: tr('plusBouncyPhysicsDescription'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.unfold_more_rounded,
          title: tr('plusBouncyPhysics'),
          subtitle: tr('plusBouncyPhysicsDescription'),
          value: (s) => s.plusEnableBouncyPhysics,
          onChanged: (s, v) => s.plusEnableBouncyPhysics = v,
        ),
      if (_matches(
        tr('plusExpressiveProgress'),
        desc: tr('plusExpressiveProgressDescription'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.auto_mode_rounded,
          title: tr('plusExpressiveProgress'),
          subtitle: tr('plusExpressiveProgressDescription'),
          value: (s) => s.plusEnableExpressiveProgress,
          onChanged: (s, v) => s.plusEnableExpressiveProgress = v,
        ),
    ];

    // ── Haptics ─────────────────────────────────────────────────────────
    final hapticChildren = <Widget>[
      if (plus.enableAllPlusFeatures &&
          _matches(preview('hapticIntensity'), desc: tr('hapticIntensityDesc')))
        SettingsChoiceRow<HapticIntensity>(
          icon: Icons.graphic_eq_rounded,
          title: preview('hapticIntensity'),
          description: tr('hapticIntensityDesc'),
          value: plus.plusHapticIntensity,
          connected: true,
          options: {
            HapticIntensity.subtle: tr('hapticIntensitySubtle'),
            HapticIntensity.standard: tr('hapticIntensityStandard'),
            HapticIntensity.strong: tr('hapticIntensityStrong'),
          },
          onChanged: (v) => plus.plusHapticIntensity = v,
        ),
      if (_matches(
        preview('hapticFollowSystem'),
        desc: tr('hapticFollowSystemDesc'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.settings_suggest_rounded,
          title: preview('hapticFollowSystem'),
          subtitle: tr('hapticFollowSystemDesc'),
          value: (s) => s.plusHapticFollowSystem,
          onChanged: (s, v) => s.plusHapticFollowSystem = v,
        ),
      if (_matches(preview('nativeHaptics'), desc: tr('nativeHapticsDesc')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.vibration_rounded,
          title: preview('nativeHaptics'),
          subtitle: tr('nativeHapticsDesc'),
          value: (s) => s.plusNativeHaptics,
          onChanged: (s, v) => s.plusNativeHaptics = v,
        ),
    ];
    final hapticWidgets = <Widget>[
      if (_matches(
        tr('enableHapticFeedback'),
        desc: tr('enableHapticFeedbackDescription'),
      ))
        buildFeatureToggle<BehaviorSettingsProvider>(
          context,
          icon: Icons.vibration_outlined,
          title: tr('enableHapticFeedback'),
          subtitle: tr('enableHapticFeedbackDescription'),
          value: (s) => s.enableHapticFeedback,
          onChanged: (s, v) => s.enableHapticFeedback = v,
        ),
      if (hapticChildren.isNotEmpty)
        SettingsChildRows(
          enabled: behavior.enableHapticFeedback,
          children: hapticChildren,
        ),
    ];

    // ── Controls (preview) ──────────────────────────────────────────────
    final morphChildren = <Widget>[
      if (_matches(preview('iconMorphShape')))
        SettingsChoiceRow<IconMorphShape>(
          icon: Icons.category_rounded,
          title: inPreviewGroup('iconMorphShape'),
          value: plus.plusIconMorphShape,
          connected: true,
          options: {
            IconMorphShape.squircle: tr('iconShapeSquircle'),
            IconMorphShape.cookie: tr('iconShapeCookie'),
            IconMorphShape.clover: tr('iconShapeClover'),
            IconMorphShape.sunny: tr('iconShapeSunny'),
            IconMorphShape.softBurst: tr('iconShapeSoftBurst'),
          },
          onChanged: (v) => plus.plusIconMorphShape = v,
        ),
      if (_matches(preview('iconMorphStyle')))
        SettingsChoiceRow<IconMorphStyle>(
          icon: Icons.motion_photos_on_rounded,
          title: inPreviewGroup('iconMorphStyle'),
          value: plus.plusIconMorphStyle,
          connected: true,
          options: {
            IconMorphStyle.morph: tr('iconMorphStyleMorph'),
            IconMorphStyle.spin: tr('iconMorphStyleSpin'),
            IconMorphStyle.pop: tr('iconMorphStylePop'),
          },
          onChanged: (v) => plus.plusIconMorphStyle = v,
        ),
    ];
    final showSwitchStyle = _matches(
      preview('switchStyle'),
      desc: tr('switchStyleDesc'),
    );
    final controlWidgets = <Widget>[
      if (showSwitchStyle) ...[
        SettingsChoiceRow<SettingsSwitchStyle>(
          icon: Icons.toggle_on_outlined,
          title: inPreviewGroup('switchStyle'),
          description: tr('switchStyleDesc'),
          value: plus.plusSwitchStyle,
          connected: true,
          options: {
            SettingsSwitchStyle.classic: tr('switchStyleClassic'),
            SettingsSwitchStyle.expressive: tr('switchStyleExpressive'),
            SettingsSwitchStyle.shapeThumb: tr('switchStyleShapeThumb'),
            SettingsSwitchStyle.iconSwitch: tr('switchStyleIconSwitch'),
          },
          onChanged: (v) => plus.plusSwitchStyle = v,
        ),
        // Live preview of the chosen switch and icon style.
        if (!isSearching) const MotionControlsCard(),
      ],
      if (_matches(
        preview('iconMorphOnToggle'),
        desc: tr('iconMorphOnToggleDesc'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.interests_rounded,
          title: inPreviewGroup('iconMorphOnToggle'),
          subtitle: tr('iconMorphOnToggleDesc'),
          value: (s) => s.plusIconMorphOnToggle,
          onChanged: (s, v) => s.plusIconMorphOnToggle = v,
        ),
      if (morphChildren.isNotEmpty)
        SettingsChildRows(
          enabled: plus.plusIconMorphOnToggle,
          children: morphChildren,
        ),
      if (_matches(
        preview('reduceShapeMorphs'),
        desc: tr('reduceShapeMorphsDesc'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.speed_rounded,
          title: inPreviewGroup('reduceShapeMorphs'),
          subtitle: tr('reduceShapeMorphsDesc'),
          value: (s) => s.plusReduceShapeMorphs,
          onChanged: (s, v) => s.plusReduceShapeMorphs = v,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (motionWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: label('motionControlsTitle'),
            persistKey: 'look.motion',
            icon: Icons.animation_rounded,
            children: motionWidgets,
          ),
        if (hapticWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: label('settingsGroupHaptics'),
            persistKey: 'look.haptics',
            icon: Icons.vibration_rounded,
            children: hapticWidgets,
          ),
        // The control styles are Obtainium+ previews.
        if (plus.enableAllPlusFeatures && controlWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : preview('settingsGroupControls'),
            description: isSearching ? null : tr('expressiveKitGroupDesc'),
            persistKey: 'look.controls',
            icon: Icons.toggle_on_rounded,
            children: controlWidgets,
          ),
      ],
    );
  }
}
