import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/utils/haptic_utils.dart';
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

    final hasHaptics = _matches(tr('enableHapticFeedback')) ||
        _matches(tr('enableUndoForAppRemoval'));
    final hasSwipe = _matches(tr('enableSwipeGestures')) ||
        _matches(tr('swipeRightAction')) ||
        _matches(tr('swipeLeftAction'));

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
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      opacity: settings.enableSwipeGestures ? 1.0 : 0.4,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        child: IgnorePointer(
                          ignoring: !settings.enableSwipeGestures,
                          child: Column(
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
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),

        // 3. Discovery & Safety Group
        _buildDiscoverySafetyGroup(context, isSearching),
      ],
    );
  }

  Widget _buildSwipeActionDropdown(
    BuildContext context, {
    required bool isRight,
  }) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        final currentAction =
            isRight ? settings.swipeRightAction : settings.swipeLeftAction;
        return ListTile(
          leading: Icon(
            isRight
                ? Icons.swipe_right_outlined
                : Icons.swipe_left_outlined,
          ),
          title: Text(
            isRight ? tr('swipeRightAction') : tr('swipeLeftAction'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(
            isRight
                ? tr('swipeRightActionDescription')
                : tr('swipeLeftActionDescription'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<AppSwipeAction>(
              value: currentAction,
              borderRadius: BorderRadius.circular(16),
              items: AppSwipeAction.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(tr('action_${e.name}')),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  AppHaptics.selectionClick();
                  if (isRight) {
                    settings.swipeRightAction = value;
                  } else {
                    settings.swipeLeftAction = value;
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverySafetyGroup(BuildContext context, bool isSearching) {
    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.enableAllPlusFeatures) return const SizedBox.shrink();

        final hasDiscover = _matches(tr('plusDiscover')) ||
            _matches(tr('plusDiscoverSuggestions'));
        final hasBanWarnings =
            _matches(tr('plusEnableBanWarnings'), isAdvanced: true);

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
                              TextButton(
                                onPressed: () {
                                  AppHaptics.selectionClick();
                                  Navigator.pop(context, false);
                                },
                                child: Text(tr('cancel')),
                              ),
                              FilledButton(
                                onPressed: () {
                                  AppHaptics.selectionClick();
                                  Navigator.pop(context, true);
                                },
                                child: Text(tr('enable')),
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
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    child: settings.plusEnableBanWarnings
                        ? Padding(
                            padding: const EdgeInsets.only(
                              left: 72.0,
                              right: 24.0,
                              bottom: 12.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(
                                    'plusBanWarningThresholdDescription',
                                    args: [
                                      settings.plusBanWarningThreshold
                                          .toString(),
                                    ],
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: settings
                                            .plusBanWarningThreshold
                                            .toDouble(),
                                        min: 1,
                                        max: 50,
                                        divisions: 49,
                                        label: settings
                                            .plusBanWarningThreshold
                                            .toString(),
                                        onChanged: (val) {
                                          final rounded = val.round();
                                          if (rounded !=
                                              settings
                                                  .plusBanWarningThreshold) {
                                            AppHaptics.selectionClick();
                                            settings
                                                    .plusBanWarningThreshold =
                                                rounded;
                                          }
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        settings.plusBanWarningThreshold
                                            .toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
