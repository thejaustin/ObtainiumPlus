import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:provider/provider.dart';

/// App behavior and interaction settings section
class AppBehaviorSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const AppBehaviorSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    final plusSettings = context.watch<PlusSettingsProvider>();

    final hasHaptics =
        _matches(tr('enableHapticFeedback')) ||
        _matches(tr('enableUndoForAppRemoval'));
    final hasSwipe =
        _matches(tr('enableSwipeGestures')) ||
        _matches(tr('swipeRightAction')) ||
        _matches(tr('swipeLeftAction'));
    final hasMotion =
        _matches(tr('animations')) ||
        _matches(tr('animationSpeed')) ||
        _matches(tr('disablePageTransitions'), isAdvanced: true) ||
        _matches(tr('reversePageTransitions')) ||
        _matches(tr('highlightTouchTargets'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Interaction & Feedback Grid
        if (hasHaptics)
          GenericBooleanControlGrid<BehaviorSettingsProvider>(
            title: tr('interactionAndHaptics'),
            settings: [
              if (_matches(tr('enableHapticFeedback')))
                (
                  icon: Icons.vibration_outlined,
                  label: tr('enableHapticFeedback'),
                  description: tr('enableHapticFeedbackDescription'),
                  getValue: (s) => s.enableHapticFeedback,
                  setValue: (s, v) => s.enableHapticFeedback = v,
                ),
              if (_matches(tr('enableUndoForAppRemoval')))
                (
                  icon: Icons.undo_outlined,
                  label: tr('enableUndoForAppRemoval'),
                  description: tr('enableUndoForAppRemovalDescription'),
                  getValue: (s) => s.enableUndoForAppRemoval,
                  setValue: (s, v) => s.enableUndoForAppRemoval = v,
                ),
            ],
          ),

        // 2. Swipe Gestures Group
        if (hasSwipe)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('swipeGestures'),
            description: isSearching ? null : tr('swipeGesturesGroupDesc'),
            persistKey: 'swipeGestures',
            icon: Icons.gesture_rounded,
            isExpandable: !isSearching,
            initiallyExpanded: true,
            children: [
              if (_matches(tr('enableSwipeGestures')))
                _buildFeatureToggle(
                  context,
                  icon: Icons.swipe_outlined,
                  title: tr('enableSwipeGestures'),
                  subtitle: tr('enableSwipeGesturesDescription'),
                  value: (s) => s.enableSwipeGestures,
                  onChanged: (s, v) => s.enableSwipeGestures = v,
                ),
              if (_matches(tr('swipeRightAction')) ||
                  _matches(tr('swipeLeftAction')))
                Consumer<BehaviorSettingsProvider>(
                  builder: (context, settings, child) {
                    return AnimatedSize(
                      duration: Duration(
                        milliseconds: plusSettings.plusEnableEnhancedAnimations
                            ? 250
                            : 0,
                      ),
                      curve: Curves.easeInOutCubic,
                      child: settings.enableSwipeGestures
                          ? Column(
                              children: [
                                if (_matches(tr('swipeRightAction')))
                                  _buildSwipeActionDropdown(
                                    context,
                                    isRight: true,
                                  ),
                                if (_matches(tr('swipeLeftAction')))
                                  _buildSwipeActionDropdown(
                                    context,
                                    isRight: false,
                                  ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
            ],
          ),

        // 3. Motion & Page Transitions Group
        if (hasMotion)
          Consumer<BehaviorSettingsProvider>(
            builder: (context, behaviorSettings, child) {
              return ExpressiveSettingsGroup(
                title: isSearching ? null : tr('animations'),
                description: isSearching ? null : tr('animationsGroupDesc'),
                persistKey: 'behaviorMotionTransitions',
                icon: Icons.animation_rounded,
                isExpandable: !isSearching,
                initiallyExpanded: true,
                children: [
                  if (_matches(tr('animationSpeed')))
                    SettingsSliderTile(
                      icon: Icons.speed_outlined,
                      title: tr('animationSpeed'),
                      value: behaviorSettings.animationSpeedMultiplier.clamp(
                        0.25,
                        2.0,
                      ),
                      min: 0.25,
                      max: 2.0,
                      divisions: 7,
                      labelBuilder: (v) => '${(v * 100).round()}%',
                      onChanged: (val) {
                        const steps = [
                          0.25,
                          0.5,
                          0.75,
                          1.0,
                          1.25,
                          1.5,
                          1.75,
                          2.0,
                        ];
                        final nearest = steps.reduce(
                          (a, b) => (a - val).abs() < (b - val).abs() ? a : b,
                        );
                        behaviorSettings.animationSpeedMultiplier = nearest;
                      },
                    ),
                  if (_matches(tr('disablePageTransitions'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      icon: Icons.animation_outlined,
                      title: tr('disablePageTransitions'),
                      subtitle: tr('disablePageTransitionsDescription'),
                      value: (s) => s.disablePageTransitions,
                      onChanged: (s, v) => s.disablePageTransitions = v,
                    ),
                  if (_matches(tr('reversePageTransitions')) &&
                      !behaviorSettings.disablePageTransitions)
                    _buildFeatureToggle(
                      context,
                      icon: Icons.swap_horizontal_circle_outlined,
                      title: tr('reversePageTransitions'),
                      subtitle: tr('reversePageTransitionsDescription'),
                      value: (s) => s.reversePageTransitions,
                      onChanged: (s, v) => s.reversePageTransitions = v,
                    ),
                  if (_matches(tr('highlightTouchTargets')))
                    _buildFeatureToggle(
                      context,
                      icon: Icons.touch_app_outlined,
                      title: tr('highlightTouchTargets'),
                      subtitle: tr('highlightTouchTargetsDescription'),
                      value: (s) => s.highlightTouchTargets,
                      onChanged: (s, v) => s.highlightTouchTargets = v,
                    ),
                ],
              );
            },
          ),

        // 4. Discovery & Safety Group
        _buildDiscoverySafetyGroup(context, isSearching),
      ],
    );
  }

  static const _swipeActionIcons = <AppSwipeAction, IconData>{
    AppSwipeAction.none: Icons.block_outlined,
    AppSwipeAction.update: Icons.system_update_outlined,
    AppSwipeAction.togglePin: Icons.push_pin_outlined,
    AppSwipeAction.share: Icons.share_outlined,
    AppSwipeAction.launch: Icons.launch_outlined,
    AppSwipeAction.delete: Icons.delete_outline_rounded,
  };

  Widget _buildSwipeActionDropdown(
    BuildContext context, {
    required bool isRight,
  }) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        final currentAction = isRight
            ? settings.swipeRightAction
            : settings.swipeLeftAction;
        final colorScheme = Theme.of(context).colorScheme;
        final plusSettings = context.watch<PlusSettingsProvider>();
        final animsEnabled = plusSettings.plusEnableEnhancedAnimations;
        final isCompact = plusSettings.plusUseCompactSettings;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, isCompact ? 4 : 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isRight
                        ? Icons.swipe_right_outlined
                        : Icons.swipe_left_outlined,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isRight ? tr('swipeRightAction') : tr('swipeLeftAction'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              if (!isCompact)
                Padding(
                  padding: const EdgeInsets.only(left: 38, top: 2),
                  child: Text(
                    isRight
                        ? tr('swipeRightActionDescription')
                        : tr('swipeLeftActionDescription'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // 3-column chip grid
              Row(
                children: [
                  for (int col = 0; col < 3; col++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: col < 2 ? 6 : 0),
                        child: Column(
                          children: [
                            for (int row = 0; row < 2; row++)
                              Builder(
                                builder: (context) {
                                  final idx = row * 3 + col;
                                  if (idx >= AppSwipeAction.values.length)
                                    return const SizedBox.shrink();
                                  final action = AppSwipeAction.values[idx];
                                  final isSelected = action == currentAction;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: row == 0 ? 6 : 0,
                                    ),
                                    child: ScaleTouchWrapper(
                                      hapticOnPressDown: true,
                                      scaleDownFactor: 0.92,
                                      child: AnimatedContainer(
                                        duration: Duration(
                                          milliseconds: animsEnabled ? 180 : 0,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        height: isCompact ? 36 : 40,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colorScheme.primaryContainer
                                              : colorScheme.surfaceContainerHigh
                                                    .withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(
                                            plusSettings.plusGlobalCornerRadius
                                                .clamp(8, 20),
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? colorScheme.primary
                                                      .withValues(alpha: 0.5)
                                                : colorScheme.outlineVariant
                                                      .withValues(alpha: 0.3),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            plusSettings.plusGlobalCornerRadius
                                                .clamp(8, 20),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              plusSettings
                                                  .plusGlobalCornerRadius
                                                  .clamp(8, 20),
                                            ),
                                            onTap: () {
                                              AppHaptics.selectionClick();
                                              if (isRight) {
                                                settings.swipeRightAction =
                                                    action;
                                              } else {
                                                settings.swipeLeftAction =
                                                    action;
                                              }
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _swipeActionIcons[action]!,
                                                  size: 14,
                                                  color: isSelected
                                                      ? colorScheme
                                                            .onPrimaryContainer
                                                      : colorScheme
                                                            .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    tr('action_${action.name}'),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.w500,
                                                          color: isSelected
                                                              ? colorScheme
                                                                    .onPrimaryContainer
                                                              : colorScheme
                                                                    .onSurfaceVariant,
                                                        ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoverySafetyGroup(BuildContext context, bool isSearching) {
    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.enableAllPlusFeatures) return const SizedBox.shrink();

        final hasDiscover =
            _matches(tr('plusDiscover')) ||
            _matches(tr('plusDiscoverSuggestions'));
        final hasBanWarnings = _matches(
          tr('plusEnableBanWarnings'),
          isAdvanced: true,
        );

        if (!hasDiscover && !hasBanWarnings) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasDiscover)
              GenericBooleanControlGrid<PlusSettingsProvider>(
                title: tr('plusDiscover'),
                settings: [
                  if (_matches(tr('plusDiscover')))
                    (
                      icon: Icons.explore_outlined,
                      label: tr('plusDiscover'),
                      description: tr('plusDiscoverDescription'),
                      getValue: (s) => s.plusEnableDiscover,
                      setValue: (s, v) => s.plusEnableDiscover = v,
                    ),
                  if (_matches(tr('plusDiscoverSuggestions')))
                    (
                      icon: Icons.auto_awesome_outlined,
                      label: tr('plusDiscoverSuggestions'),
                      description: tr('plusDiscoverSuggestionsDescription'),
                      getValue: (s) => s.plusDiscoverSuggestions,
                      setValue: (s, v) => s.plusDiscoverSuggestions = v,
                    ),
                ],
              ),
            if (hasBanWarnings)
              ExpressiveSettingsGroup(
                title: isSearching ? null : tr('safetyAndRateLimits'),
                description: isSearching
                    ? null
                    : tr('safetyAndRateLimitsGroupDesc'),
                persistKey: 'safetyAndRateLimits',
                icon: Icons.shield_outlined,
                isExpandable: !isSearching,
                initiallyExpanded: true,
                children: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.warning_amber_rounded),
                    title: Text(
                      tr('plusEnableBanWarnings'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(tr('plusEnableBanWarningsDescription')),
                    value: settings.plusEnableBanWarnings,
                    onChanged: (val) async {
                      AppHaptics.selectionClick();
                      if (val) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => GlassDialog(
                            title: tr('plusEnableBanWarnings'),
                            icon: Icons.warning_amber_rounded,
                            content: Text(
                              tr('plusEnableBanWarningsDescription'),
                            ),
                            actions: [
                              ScaleTouchWrapper(
                                hapticOnPressDown: true,
                                scaleDownFactor: 0.94,
                                child: TextButton(
                                  onPressed: () {
                                    AppHaptics.selectionClick();
                                    Navigator.pop(context, false);
                                  },
                                  child: Text(tr('cancel')),
                                ),
                              ),
                              ScaleTouchWrapper(
                                hapticOnPressDown: true,
                                scaleDownFactor: 0.94,
                                child: FilledButton(
                                  onPressed: () {
                                    AppHaptics.selectionClick();
                                    Navigator.pop(context, true);
                                  },
                                  child: Text(tr('enable')),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          settings.plusEnableBanWarnings = true;
                        }
                      } else {
                        settings.plusEnableBanWarnings = false;
                      }
                    },
                  ),
                  AnimatedSize(
                    duration: Duration(
                      milliseconds: settings.plusEnableEnhancedAnimations
                          ? 250
                          : 0,
                    ),
                    curve: Curves.easeInOutCubic,
                    child: settings.plusEnableBanWarnings
                        ? SettingsSliderTile(
                            icon: Icons.warning_amber_outlined,
                            title: tr('plusBanWarningThreshold'),
                            value: settings.plusBanWarningThreshold.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            labelBuilder: (v) => v.toInt().toString(),
                            onChanged: (val) {
                              settings.plusBanWarningThreshold = val.round();
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool Function(BehaviorSettingsProvider) value,
    required void Function(BehaviorSettingsProvider, bool) onChanged,
  }) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(subtitle),
          value: value(settings),
          onChanged: (v) {
            AppHaptics.selectionClick();
            onChanged(settings, v);
          },
        );
      },
    );
  }
}
