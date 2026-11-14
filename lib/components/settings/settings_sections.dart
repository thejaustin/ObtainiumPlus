import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_text_styles.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/connected_choice_group.dart';
import 'package:obtainium/components/settings/connected_setting_container.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/pages/settings_subpage.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:provider/provider.dart';

/// One settings section (tab). [labelKey] names it in the chips and the
/// search empty state; [shortKey] is the one-word label for the dock and
/// the bottom NavigationBar, where the full label overflows at 360dp.
class SettingsSectionInfo {
  final String labelKey;
  final String shortKey;
  final String descKey;
  final IconData icon;
  final IconData selectedIcon;

  const SettingsSectionInfo({
    required this.labelKey,
    required this.shortKey,
    required this.descKey,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Index of each section. The count stays 5: the chip keys, the clamp in
/// SettingsPage, the dock, the NavigationBar and the hosted category bar
/// all read [kSettingsSections].
abstract final class SettingsSectionIndex {
  static const lookAndMotion = 0;
  static const homeAndLibrary = 1;
  static const updatesAndNotifications = 2;
  static const installAndSafety = 3;
  static const advanced = 4;
}

const kSettingsSections = <SettingsSectionInfo>[
  SettingsSectionInfo(
    labelKey: 'settingsTabLookMotion',
    shortKey: 'settingsTabLookMotionShort',
    descKey: 'settingsTabLookMotionDesc',
    icon: Icons.palette_outlined,
    selectedIcon: Icons.palette_rounded,
  ),
  SettingsSectionInfo(
    labelKey: 'settingsTabHomeLibrary',
    shortKey: 'settingsTabHomeLibraryShort',
    descKey: 'settingsTabHomeLibraryDesc',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  ),
  SettingsSectionInfo(
    labelKey: 'settingsTabUpdatesNotifications',
    shortKey: 'updates',
    descKey: 'settingsTabUpdatesNotificationsDesc',
    icon: Icons.system_update_outlined,
    selectedIcon: Icons.system_update_rounded,
  ),
  SettingsSectionInfo(
    labelKey: 'settingsTabInstallSafety',
    shortKey: 'settingsTabInstallSafetyShort',
    descKey: 'settingsTabInstallSafetyDesc',
    icon: Icons.install_mobile_outlined,
    selectedIcon: Icons.install_mobile_rounded,
  ),
  SettingsSectionInfo(
    labelKey: 'settingsTabAdvancedDebug',
    shortKey: 'advanced',
    descKey: 'settingsTabAdvancedDebugDesc',
    icon: Icons.code_rounded,
    selectedIcon: Icons.code_rounded,
  ),
];

/// A row that opens [child] as a [SettingsSubpage] ("More…" pages, the
/// tokens page). While searching it renders [child] inline instead, since
/// rows on a page that isn't pushed can't be found.
class SettingsSubpageLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool searching;
  final Widget child;

  const SettingsSubpageLink({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.searching,
    required this.child,
  });

  /// The "More…" link of a section: the rarely used rows of that section.
  const SettingsSubpageLink.more({
    super.key,
    this.subtitle,
    required this.searching,
    required this.child,
  }) : icon = Icons.more_horiz_rounded,
       title = '';

  String get _title => title.isEmpty ? tr('settingsMore') : title;

  @override
  Widget build(BuildContext context) {
    if (searching) return child;
    final isCompact = context.select<PlusSettingsProvider, bool>(
      (p) => p.plusUseCompactSettings,
    );
    return ScaleTouchWrapper(
      scaleDownFactor: 0.985,
      hapticOnPressDown: false,
      child: ListTile(
        leading: buildSettingsIconBadge(context, icon),
        title: Text(
          _title,
          style: settingsRowTitleStyle(context, compact: isCompact),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: settingsRowSubtitleStyle(context, compact: isCompact),
              ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          AppHaptics.selectionClick();
          pushRoute(
            context,
            SettingsSubpage(
              title: _title,
              subtitle: subtitle,
              icon: icon,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Child rows of a master switch, drawn in a [ConnectedSettingContainer].
/// When the master is off they stay in the layout but dim to 0.38 and stop
/// taking input, so the page doesn't jump when the master flips.
class SettingsChildRows extends StatelessWidget {
  final bool enabled;
  final List<Widget> children;

  const SettingsChildRows({
    super.key,
    required this.enabled,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return ConnectedSettingContainer(
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.38,
        duration: AppMotion.duration(
          context,
          const Duration(milliseconds: 200),
        ),
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A titled choice between a few values. Today's controls use a
/// [SegmentedButton]; preview options pass [connected] to use the
/// expressive [ConnectedChoiceGroup] (a radio sheet for 5+ options).
class SettingsChoiceRow<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final bool connected;

  const SettingsChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.value,
    required this.options,
    required this.onChanged,
    this.connected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = context.select<PlusSettingsProvider, bool>(
      (p) => p.plusUseCompactSettings,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: buildSettingsIconBadge(context, icon),
          title: Text(
            title,
            style: settingsRowTitleStyle(context, compact: isCompact),
          ),
          subtitle: description == null
              ? null
              : Text(
                  description!,
                  style: settingsRowSubtitleStyle(context, compact: isCompact),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: connected
              ? ConnectedChoiceGroup<T>(
                  options: options,
                  value: value,
                  sheetTitle: title,
                  onChanged: onChanged,
                )
              : SegmentedButton<T>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  segments: [
                    for (final e in options.entries)
                      ButtonSegment<T>(
                        value: e.key,
                        label: Text(
                          e.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  selected: {value},
                  onSelectionChanged: (s) {
                    if (s.first == value) return;
                    AppHaptics.selectionClick();
                    onChanged(s.first);
                  },
                ),
        ),
      ],
    );
  }
}
