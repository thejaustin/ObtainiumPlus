import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/system_app_selector_sheet.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/utils/locale_constants.dart';
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

    List<Widget> children = [
      // Page Transitions
      if (_matches(tr('disablePageTransitions'), isAdvanced: true))
        _buildFeatureToggle(
          context,
          icon: Icons.animation_outlined,
          title: tr('disablePageTransitions'),
          subtitle: tr('disablePageTransitionsDescription'),
          value: (s) => s.disablePageTransitions,
          onChanged: (s, v) => s.disablePageTransitions = v,
        ),
      // Haptic Feedback
      if (_matches(tr('enableHapticFeedback')))
        _buildFeatureToggle(
          context,
          icon: Icons.vibration_outlined,
          title: tr('enableHapticFeedback'),
          subtitle: tr('enableHapticFeedbackDescription'),
          value: (s) => s.enableHapticFeedback,
          onChanged: (s, v) => s.enableHapticFeedback = v,
        ),

      // Swipe Gestures
      if (_matches(tr('enableSwipeGestures')))
        _buildFeatureToggle(
          context,
          icon: Icons.gesture_outlined,
          title: tr('enableSwipeGestures'),
          subtitle: tr('enableSwipeGesturesDescription'),
          value: (s) => s.enableSwipeGestures,
          onChanged: (s, v) => s.enableSwipeGestures = v,
        ),

      // Undo App Removal
      if (_matches(tr('enableUndoForAppRemoval')))
        _buildFeatureToggle(
          context,
          icon: Icons.undo_outlined,
          title: tr('enableUndoForAppRemoval'),
          subtitle: tr('enableUndoForAppRemovalDescription'),
          value: (s) => s.enableUndoForAppRemoval,
          onChanged: (s, v) => s.enableUndoForAppRemoval = v,
        ),

      // Animation Speed
      if (_matches(tr('animationSpeed')))
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, child) {
            return ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: Text(
                tr('animationSpeed'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(
                '${(settings.animationSpeedMultiplier * 100).round()}%',
              ),
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
      if (_matches(tr('language')))
        Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            final currentLocale = context.locale;
            final matchedLocaleEntry = supportedLocales.firstWhere(
              (entry) => entry.key.languageCode == currentLocale.languageCode,
              orElse: () => supportedLocales.first,
            );
            return ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(
                tr('language'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(matchedLocaleEntry.value),
              onTap: () {
                AppHaptics.selectionClick();
                _showLanguagePicker(context, settings);
              },
            );
          },
        ),
    ];

    return Column(
      children: [
        if (children.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('appBehavior'),
            icon: Icons.settings_suggest_rounded,
            isExpandable: !isSearching,
            initiallyExpanded: false,
            children: children,
          ),
        _buildDiscoverySafetyGroup(context, isSearching),
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, _) {
            if (!settings.enableSwipeGestures &&
                !_matches(tr('swipeRightAction')) &&
                !_matches(tr('swipeLeftAction'))) {
              return const SizedBox.shrink();
            }
            final swipeChildren = [
              if (_matches(tr('swipeRightAction')))
                _buildSwipeActionDropdown(context, isRight: true),
              if (_matches(tr('swipeLeftAction')))
                _buildSwipeActionDropdown(context, isRight: false),
            ];
            if (swipeChildren.isEmpty) return const SizedBox.shrink();
            return Opacity(
              opacity: settings.enableSwipeGestures ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !settings.enableSwipeGestures,
                child: ExpressiveSettingsGroup(
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

  Widget _buildSwipeActionDropdown(
    BuildContext context, {
    required bool isRight,
  }) {
    return Consumer<BehaviorSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AppSwipeAction>(
                    segments: AppSwipeAction.values
                        .map(
                          (e) => ButtonSegment(
                            value: e,
                            label: Text(tr('action_${e.name}')),
                          ),
                        )
                        .toList(),
                    selected: {
                      isRight
                          ? settings.swipeRightAction
                          : settings.swipeLeftAction,
                    },
                    onSelectionChanged: (value) {
                      if (isRight) {
                        settings.swipeRightAction = value.first;
                      } else {
                        settings.swipeLeftAction = value.first;
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscoverySafetyGroup(BuildContext context, bool isSearching) {
    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.enableAllPlusFeatures) return const SizedBox.shrink();

        final items = [
          if (_matches(tr('plusDiscover')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.explore_outlined),
              title: Text(
                tr('plusDiscover'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('plusDiscoverDescription')),
              value: settings.plusEnableDiscover,
              onChanged: (val) {
                AppHaptics.selectionClick();
                settings.plusEnableDiscover = val;
              },
            ),
          if (_matches(tr('plusDiscoverSuggestions')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: Text(
                tr('plusDiscoverSuggestions'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('plusDiscoverSuggestionsDescription')),
              value: settings.plusDiscoverSuggestions,
              onChanged: (val) {
                AppHaptics.selectionClick();
                settings.plusDiscoverSuggestions = val;
              },
            ),
          if (_matches(tr('importInstalledApps')))
            ListTile(
              leading: const Icon(Icons.install_mobile_rounded),
              title: Text(
                tr('importInstalledApps'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('importInstalledAppsDescription')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppHaptics.selectionClick();
                showSystemAppSelectorSheet(context: context);
              },
            ),
          if (_matches(tr('plusEnableBanWarnings'), isAdvanced: true)) ...[
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.warning_amber_rounded),
              title: Text(
                tr('plusEnableBanWarnings'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('plusEnableBanWarningsDescription')),
              value: settings.plusEnableBanWarnings,
              onChanged: (val) async {
                if (val) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => GlassDialog(
                      title: tr('plusEnableBanWarnings'),
                      icon: Icons.warning_amber_rounded,
                      content: Text(tr('plusEnableBanWarningsDescription')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(tr('cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
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
            if (settings.plusEnableBanWarnings)
              Padding(
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
                        args: [settings.plusBanWarningThreshold.toString()],
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: settings.plusBanWarningThreshold.toDouble(),
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: settings.plusBanWarningThreshold.toString(),
                            onChanged: (val) {
                              settings.plusBanWarningThreshold = val.round();
                            },
                          ),
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.centerRight,
                          child: Text(
                            settings.plusBanWarningThreshold.toString(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ];

        if (items.isEmpty) return const SizedBox.shrink();

        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('appDiscoveryAndSafety'),
          icon: Icons.explore_outlined,
          isExpandable: !isSearching,
          initiallyExpanded: false,
          children: items,
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
          onChanged: (v) => onChanged(settings, v),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassDialog(
          title: tr('language'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supportedLocales.length,
              itemBuilder: (context, index) {
                final entry = supportedLocales[index];
                final isSelected =
                    context.locale.languageCode == entry.key.languageCode;
                return ListTile(
                  title: Text(entry.value),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    AppHaptics.selectionClick();
                    settings.forcedLocale = entry.key;
                    context.setLocale(entry.key);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('close')),
            ),
          ],
        );
      },
    );
  }
}
