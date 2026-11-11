import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/advanced_settings_section.dart';
import 'package:obtainium/components/settings/appearance_hub.dart';
import 'package:obtainium/components/settings/apps_view_settings_section.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/installation_section.dart';
import 'package:obtainium/components/settings/motion_haptics_section.dart';
import 'package:obtainium/components/settings/settings_page_section.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/components/settings/settings_tab_masthead.dart';
import 'package:obtainium/components/settings/theme_settings_section.dart';
import 'package:obtainium/components/settings/update_settings_section.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

/// The rows of one settings section, or of every section while searching.
///
/// Browsing shows each section's own layout (the Look & motion hub cards,
/// "More…" links). Searching lists the matching rows of every section
/// inline, including those that otherwise sit on a subpage, so every row
/// can be found.
class SettingsTabContent extends StatelessWidget {
  /// Section to show while not searching (see [SettingsSectionIndex]).
  final int section;
  final String searchQuery;
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final bool showIntervalLabel;
  final ValueChanged<bool> onIntervalLabelChange;
  final void Function(void Function()) onSetState;

  const SettingsTabContent({
    super.key,
    required this.section,
    required this.searchQuery,
    required this.androidInfoFuture,
    required this.showIntervalLabel,
    required this.onIntervalLabelChange,
    required this.onSetState,
  });

  bool get _searching => searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final showAdvanced = context.select<PlusSettingsProvider, bool>(
      (p) => p.plusShowAdvancedSettings,
    );
    final indices = _searching
        ? List.generate(kSettingsSections.length, (i) => i)
        : [section.clamp(0, kSettingsSections.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in indices) ...[
          if (!_searching)
            SettingsTabMasthead(
              icon: kSettingsSections[i].selectedIcon,
              title: tr(kSettingsSections[i].labelKey),
              description: tr(kSettingsSections[i].descKey),
              accentColor: Theme.of(context).colorScheme.primary,
            ),
          _body(context, i, showAdvanced),
        ],
      ],
    );
  }

  Widget _body(BuildContext context, int index, bool showAdvanced) {
    final query = searchQuery;
    switch (index) {
      case SettingsSectionIndex.lookAndMotion:
        Widget theme(String? sub) => ThemeSettingsSection(
          searchQuery: query,
          androidInfoFuture: androidInfoFuture,
          colorsNameMap: const <ColorSwatch<Object>, String>{},
          showAdvancedSettings: showAdvanced,
          subCategory: sub,
        );
        final motion = MotionHapticsSection(
          searchQuery: query,
          showAdvancedSettings: showAdvanced,
        );
        final settingsPage = SettingsPageSection(
          searchQuery: query,
          showAdvancedSettings: showAdvanced,
        );
        if (_searching) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [theme(null), motion, settingsPage],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppearanceHub(
              androidInfoFuture: androidInfoFuture,
              themeContent: theme('theme'),
              shapesContent: theme('shapes'),
              motionContent: motion,
              settingsPageContent: settingsPage,
            ),
            ExpressiveSettingsGroup(
              persistKey: 'look.moreLink',
              children: [
                SettingsSubpageLink.more(
                  subtitle: tr('settingsMoreLookDesc'),
                  searching: false,
                  child: theme('more'),
                ),
              ],
            ),
          ],
        );
      case SettingsSectionIndex.homeAndLibrary:
        return AppsViewSettingsSection(
          searchQuery: query,
          onSetState: onSetState,
          showAdvancedSettings: showAdvanced,
        );
      case SettingsSectionIndex.updatesAndNotifications:
        return UpdateSettingsSection(
          searchQuery: query,
          showIntervalLabel: showIntervalLabel,
          onIntervalLabelChange: onIntervalLabelChange,
          androidInfoFuture: androidInfoFuture,
          showAdvancedSettings: showAdvanced,
        );
      case SettingsSectionIndex.installAndSafety:
        return InstallationSection(
          searchQuery: query,
          showAdvancedSettings: showAdvanced,
        );
      default:
        return AdvancedSettingsSection(
          searchQuery: query,
          showAdvancedSettings: showAdvanced,
        );
    }
  }
}
