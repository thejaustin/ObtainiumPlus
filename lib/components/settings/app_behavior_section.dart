import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:provider/provider.dart';

/// App behavior and interaction settings section
class AppBehaviorSection extends StatelessWidget {
  final String? searchQuery;

  const AppBehaviorSection({
    super.key,
    this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    List<Widget> children = [
      // Page Transitions
      _buildFeatureToggle(
        context,
        icon: Icons.animation_outlined,
        title: tr('disablePageTransitions'),
        subtitle: tr('disablePageTransitionsDescription'),
        value: (s) => s.disablePageTransitions,
        onChanged: (s, v) => s.disablePageTransitions = v,
        visible: (s) => _matches(tr('disablePageTransitions')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.flip_outlined,
        title: tr('reversePageTransitions'),
        subtitle: tr('reversePageTransitionsDescription'),
        value: (s) => s.reversePageTransitions,
        onChanged: (s, v) => s.reversePageTransitions = v,
        visible: (s) => _matches(tr('reversePageTransitions')),
      ),
      
      // Haptic Feedback
      _buildFeatureToggle(
        context,
        icon: Icons.vibration_outlined,
        title: tr('enableHapticFeedback'),
        subtitle: tr('enableHapticFeedbackDescription'),
        value: (s) => s.enableHapticFeedback,
        onChanged: (s, v) => s.enableHapticFeedback = v,
        visible: (s) => _matches(tr('enableHapticFeedback')),
      ),
      
      // Swipe Gestures
      _buildFeatureToggle(
        context,
        icon: Icons.gesture_outlined,
        title: tr('enableSwipeGestures'),
        subtitle: tr('enableSwipeGesturesDescription'),
        value: (s) => s.enableSwipeGestures,
        onChanged: (s, v) => s.enableSwipeGestures = v,
        visible: (s) => _matches(tr('enableSwipeGestures')),
      ),
      
      // Undo App Removal
      _buildFeatureToggle(
        context,
        icon: Icons.undo_outlined,
        title: tr('enableUndoForAppRemoval'),
        subtitle: tr('enableUndoForAppRemovalDescription'),
        value: (s) => s.enableUndoForAppRemoval,
        onChanged: (s, v) => s.enableUndoForAppRemoval = v,
        visible: (s) => _matches(tr('enableUndoForAppRemoval')),
      ),
      
      // Animation Speed
      if (_matches(tr('animationSpeed')))
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, child) {
            return ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: Text(tr('animationSpeed'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text('${(settings.animationSpeedMultiplier * 100).round()}%'),
              trailing: DropdownButton<double>(
                value: settings.animationSpeedMultiplier,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 0.5, child: Text('50%')),
                  DropdownMenuItem(value: 0.75, child: Text('75%')),
                  DropdownMenuItem(value: 1.0, child: Text('100%')),
                  DropdownMenuItem(value: 1.5, child: Text('150%')),
                  DropdownMenuItem(value: 2.0, child: Text('200%')),
                ],
                onChanged: (value) {
                  if (value != null) settings.animationSpeedMultiplier = value;
                },
              ),
            );
          },
        ),
    ];

    return Column(
      children: [
        if (children.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('appBehavior'),
            children: children,
          ),
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, _) {
            if (!settings.enableSwipeGestures &&
                !_matches(tr('swipeRightAction')) &&
                !_matches(tr('swipeLeftAction'))) {
              return const SizedBox.shrink();
            }
            final swipeChildren = [
              if (_matches(tr('swipeRightAction'))) _buildSwipeActionDropdown(context, isRight: true),
              if (_matches(tr('swipeLeftAction'))) _buildSwipeActionDropdown(context, isRight: false),
            ];
            if (swipeChildren.isEmpty) return const SizedBox.shrink();
            return Opacity(
              opacity: settings.enableSwipeGestures ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !settings.enableSwipeGestures,
                child: SettingsGroup(
                  title: isSearching ? null : tr('swipeActions'),
                  children: swipeChildren,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSwipeActionDropdown(BuildContext context, {required bool isRight}) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: Icon(isRight ? Icons.swipe_right_outlined : Icons.swipe_left_outlined),
          title: Text(isRight ? tr('swipeRightAction') : tr('swipeLeftAction'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(isRight ? tr('swipeRightActionDescription') : tr('swipeLeftActionDescription')),
          trailing: DropdownButton<AppSwipeAction>(
            underline: const SizedBox(),
            value: isRight ? settings.swipeRightAction : settings.swipeLeftAction,
            items: AppSwipeAction.values.map((e) => DropdownMenuItem(value: e, child: Text(tr('action_${e.name}')))).toList(),
            onChanged: (value) {
              if (value != null) {
                if (isRight) {
                  settings.swipeRightAction = value;
                } else {
                  settings.swipeLeftAction = value;
                }
              }
            },
          ),
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
    required bool Function(BehaviorSettingsProvider) visible,
  }) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        if (!visible(settings)) return const SizedBox.shrink();
        return SwitchListTile.adaptive(
          secondary: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(subtitle),
          value: value(settings),
          onChanged: (v) => onChanged(settings, v),
        );
      },
    );
  }
}
