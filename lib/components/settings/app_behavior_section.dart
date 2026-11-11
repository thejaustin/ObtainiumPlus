import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/connected_setting_container.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:obtainium/components/settings/usage_access_card.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/swipe_preview_widget.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:provider/provider.dart';

/// Which slice of the former Behavior tab to render. Swipe, library and
/// Discover live in Home & library; safety lives in Install & safety
/// (haptics moved to Look & motion → Motion & haptics).
enum AppBehaviorPart { swipe, library, discover, safety }

/// Behaviour rows that moved into other tabs, one [part] at a time.
class AppBehaviorSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;
  final AppBehaviorPart part;

  const AppBehaviorSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
    required this.part,
  });

  bool _matches(String text, {bool isAdvanced = false, String? desc}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    final q = searchQuery!.toLowerCase();
    return text.toLowerCase().contains(q) ||
        (desc != null && desc.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    switch (part) {
      case AppBehaviorPart.swipe:
        return _buildSwipeGroup(context, isSearching) ??
            const SizedBox.shrink();
      case AppBehaviorPart.library:
        final usage = _buildUsageAccessGroup(context, isSearching);
        final library = _buildLibraryStorageGroup(context, isSearching);
        if (usage == null && library == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [?library, ?usage],
        );
      case AppBehaviorPart.discover:
        return _buildDiscoverGroup(context, isSearching);
      case AppBehaviorPart.safety:
        return _buildSafetyGroup(context, isSearching);
    }
  }

  /// Swipe actions: `enableSwipeGestures` is the master; the expressive
  /// style (`plusEnableSwipeActions`) is its child, since the app list
  /// needs both on to swipe.
  Widget? _buildSwipeGroup(BuildContext context, bool isSearching) {
    final behavior = context.watch<BehaviorSettingsProvider>();
    final children = <Widget>[
      if (_matches(
            tr('expressiveSwipeStyle'),
            desc: tr('plusEnableSwipeActionsDescription'),
          ) ||
          _matches(tr('plusEnableSwipeActions')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.swipe_rounded,
          title: tr('expressiveSwipeStyle'),
          subtitle: tr('plusEnableSwipeActionsDescription'),
          value: (s) => s.plusEnableSwipeActions,
          onChanged: (s, v) => s.plusEnableSwipeActions = v,
        ),
      if (!isSearching) const SwipePreviewWidget(),
      if (_matches(
        tr('swipeRightAction'),
        desc: tr('swipeRightActionDescription'),
      ))
        _buildSwipeActionDropdown(context, isRight: true),
      if (_matches(
        tr('swipeLeftAction'),
        desc: tr('swipeLeftActionDescription'),
      ))
        _buildSwipeActionDropdown(context, isRight: false),
    ];
    final rows = <Widget>[
      if (_matches(
        tr('enableSwipeGestures'),
        desc: tr('enableSwipeGesturesDescription'),
      ))
        _buildFeatureToggle(
          context,
          icon: Icons.swipe_outlined,
          title: tr('enableSwipeGestures'),
          subtitle: tr('enableSwipeGesturesDescription'),
          value: (s) => s.enableSwipeGestures,
          onChanged: (s, v) => s.enableSwipeGestures = v,
        ),
      if (children.isNotEmpty)
        SettingsChildRows(
          enabled: behavior.enableSwipeGestures,
          children: children,
        ),
      if (_matches(
        tr('enableUndoForAppRemoval'),
        desc: tr('enableUndoForAppRemovalDescription'),
      ))
        _buildFeatureToggle(
          context,
          icon: Icons.undo_outlined,
          title: tr('enableUndoForAppRemoval'),
          subtitle: tr('enableUndoForAppRemovalDescription'),
          value: (s) => s.enableUndoForAppRemoval,
          onChanged: (s, v) => s.enableUndoForAppRemoval = v,
        ),
    ];
    if (rows.isEmpty) return null;
    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('swipeGestures'),
      description: isSearching ? null : tr('swipeGesturesGroupDesc'),
      persistKey: 'swipeGestures',
      icon: Icons.gesture_rounded,
      children: rows,
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
        final isM3E = plusSettings.plusEnableMaterialExpressive;
        final chipRadius = plusSettings.plusGlobalCornerRadius.clamp(8.0, 20.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 16,
            isCompact ? 4 : 8,
            isCompact ? 14 : 16,
            6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  buildSettingsIconBadge(
                    context,
                    isRight
                        ? Icons.swipe_right_outlined
                        : Icons.swipe_left_outlined,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRight
                              ? tr('swipeRightAction')
                              : tr('swipeLeftAction'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (!isCompact)
                          Text(
                            isRight
                                ? tr('swipeRightActionDescription')
                                : tr('swipeLeftActionDescription'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
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
                                  if (idx >= AppSwipeAction.values.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final action = AppSwipeAction.values[idx];
                                  final isSelected = action == currentAction;
                                  final chipShape = CardMetrics.shape(
                                    chipRadius,
                                    expressive: isM3E,
                                    side: BorderSide(
                                      color: isSelected
                                          ? colorScheme.primary.withValues(
                                              alpha: 0.5,
                                            )
                                          : colorScheme.outlineVariant
                                                .withValues(alpha: 0.3),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  );
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
                                        height: isCompact ? 34 : 38,
                                        decoration: ShapeDecoration(
                                          color: isSelected
                                              ? colorScheme.primaryContainer
                                              : colorScheme.surfaceContainerHigh
                                                    .withValues(alpha: 0.5),
                                          shape: chipShape,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          shape: CardMetrics.shape(
                                            chipRadius,
                                            expressive: isM3E,
                                          ),
                                          child: InkWell(
                                            customBorder: CardMetrics.shape(
                                              chipRadius,
                                              expressive: isM3E,
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

  Widget? _buildUsageAccessGroup(BuildContext context, bool isSearching) {
    if (isSearching &&
        !_matches(tr('appLaunchAndUsage'), desc: tr('appLaunchAndUsageDesc')) &&
        !_matches(tr('usageAccessSettings')) &&
        !(_matches('usage') || _matches(tr('searchKeywordUsage'))) &&
        !(_matches('screen time') || _matches(tr('searchKeywordScreenTime')))) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isSearching) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              tr('appLaunchAndUsage'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
        const UsageAccessCard(margin: EdgeInsets.only(bottom: 12)),
      ],
    );
  }

  Widget? _buildLibraryStorageGroup(BuildContext context, bool isSearching) {
    final hasRemove = _matches(
      tr('removeOnExternalUninstall'),
      desc: tr('removeOnExternalUninstallDescription'),
    );
    if (!hasRemove) return null;

    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    return ExpressiveSettingsGroup(
      title: isSearching ? null : tr('libraryAndStorage'),
      description: isSearching ? null : tr('libraryAndStorageDesc'),
      persistKey: 'libraryAndStorage',
      icon: Icons.folder_delete_outlined,
      isExpandable: !isSearching,
      initiallyExpanded: true,
      children: [
        SwitchListTile.adaptive(
          secondary: buildSettingsIconBadge(
            context,
            Icons.delete_sweep_outlined,
            active: behaviorSettings.removeOnExternalUninstall,
          ),
          title: Text(tr('removeOnExternalUninstall')),
          subtitle: Text(tr('removeOnExternalUninstallDescription')),
          value: behaviorSettings.removeOnExternalUninstall,
          onChanged: (v) {
            v ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
            behaviorSettings.removeOnExternalUninstall = v;
          },
        ),
      ],
    );
  }

  /// Discover (+): `plusEnableDiscover` is the master of the suggestions.
  Widget _buildDiscoverGroup(BuildContext context, bool isSearching) {
    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.enableAllPlusFeatures) return const SizedBox.shrink();
        final showMaster = _matches(
          tr('plusDiscover'),
          desc: tr('plusDiscoverDescription'),
        );
        final showChild = _matches(
          tr('plusDiscoverSuggestions'),
          desc: tr('plusDiscoverSuggestionsDescription'),
        );
        if (!showMaster && !showChild) return const SizedBox.shrink();
        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('plusDiscover'),
          persistKey: 'home.discover',
          icon: Icons.explore_outlined,
          children: [
            if (showMaster)
              buildFeatureToggle<PlusSettingsProvider>(
                context,
                icon: Icons.explore_outlined,
                title: tr('plusDiscover'),
                subtitle: tr('plusDiscoverDescription'),
                value: (s) => s.plusEnableDiscover,
                onChanged: (s, v) => s.plusEnableDiscover = v,
              ),
            if (showChild)
              SettingsChildRows(
                enabled: settings.plusEnableDiscover,
                children: [
                  buildFeatureToggle<PlusSettingsProvider>(
                    context,
                    icon: Icons.auto_awesome_outlined,
                    title: tr('plusDiscoverSuggestions'),
                    subtitle: tr('plusDiscoverSuggestionsDescription'),
                    value: (s) => s.plusDiscoverSuggestions,
                    onChanged: (s, v) => s.plusDiscoverSuggestions = v,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// Safety: ban warnings and their threshold.
  Widget _buildSafetyGroup(BuildContext context, bool isSearching) {
    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.enableAllPlusFeatures) return const SizedBox.shrink();
        final hasBanWarnings =
            _matches(
              tr('plusEnableBanWarnings'),
              desc: tr('plusEnableBanWarningsDescription'),
              isAdvanced: true,
            ) ||
            _matches(tr('plusBanWarningThreshold'), isAdvanced: true);
        if (!hasBanWarnings) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasBanWarnings)
              ExpressiveSettingsGroup(
                title: isSearching ? null : tr('settingsGroupSafety'),
                description: isSearching
                    ? null
                    : tr('safetyAndRateLimitsGroupDesc'),
                persistKey: 'safetyAndRateLimits',
                icon: Icons.shield_outlined,
                isExpandable: !isSearching,
                initiallyExpanded: true,
                children: [
                  SwitchListTile.adaptive(
                    secondary: buildSettingsIconBadge(
                      context,
                      Icons.warning_amber_rounded,
                      active: settings.plusEnableBanWarnings,
                      accentColor: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(tr('plusEnableBanWarnings')),
                    subtitle: Text(tr('plusEnableBanWarningsDescription')),
                    value: settings.plusEnableBanWarnings,
                    onChanged: (val) async {
                      val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
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
                        ? ConnectedSettingContainer(
                            accentColor: Theme.of(context).colorScheme.tertiary,
                            child: SettingsSliderTile(
                              icon: Icons.warning_amber_outlined,
                              title: tr('plusBanWarningThreshold'),
                              value: settings.plusBanWarningThreshold
                                  .toDouble(),
                              defaultValue: 10.0,
                              min: 1,
                              max: 50,
                              divisions: 49,
                              labelBuilder: (v) => v.toInt().toString(),
                              onChanged: (val) {
                                settings.plusBanWarningThreshold = val.round();
                              },
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
    return buildFeatureToggle<BehaviorSettingsProvider>(
      context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
    );
  }
}
