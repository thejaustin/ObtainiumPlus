import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/pages/visual_lab_page.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Look & motion → Settings page: the one home for how this settings page
/// is laid out (density, toggles, category bar, group style).
class SettingsPageSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const SettingsPageSection({
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

  static String _preview(String key) => tr('previewSuffix', args: [tr(key)]);

  @override
  Widget build(BuildContext context) {
    final isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    // Rows sit in groups whose header already says preview; the suffix
    // only shows in search results, where the header isn't drawn.
    String inGroup(String key) => isSearching ? _preview(key) : tr(key);
    final plus = context.watch<PlusSettingsProvider>();
    final outer = plus.plusSettingsGroupOuterRadius;
    final segmented =
        plus.plusSettingsGroupStyle == SettingsGroupStyle.segmented;

    final layoutWidgets = <Widget>[
      if (_matches(
        tr('visualLabNavPlacement'),
        desc: tr('visualLabNavPlacementDesc'),
      ))
        SettingsChoiceRow<SettingsNavPlacement>(
          icon: Icons.view_day_outlined,
          title: tr('visualLabNavPlacement'),
          description: tr('visualLabNavPlacementDesc'),
          value: plus.plusSettingsNavPlacement,
          options: {
            SettingsNavPlacement.bottom: tr('visualLabBottom'),
            SettingsNavPlacement.top: tr('visualLabTop'),
            SettingsNavPlacement.merged: tr('visualLabMerged'),
          },
          onChanged: (v) => plus.plusSettingsNavPlacement = v,
        ),
      if (_matches(
        tr('plusUseCompactSettings'),
        desc: tr('plusUseCompactSettingsDescription'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.density_small_rounded,
          title: tr('plusUseCompactSettings'),
          subtitle: tr('plusUseCompactSettingsDescription'),
          value: (s) => s.plusUseCompactSettings,
          onChanged: (s, v) => s.plusUseCompactSettings = v,
          hideWhenPlusOff: false,
        ),
      if (_matches(
        tr('visualLabDescriptionLines'),
        desc: tr('visualLabDescriptionLinesDesc'),
      ))
        SettingsChildRows(
          enabled: plus.plusUseCompactSettings,
          children: [
            SettingsChoiceRow<int>(
              icon: Icons.short_text_rounded,
              title: tr('visualLabDescriptionLines'),
              description: tr('visualLabDescriptionLinesDesc'),
              value: plus.plusLabCompactDescriptionLines,
              options: const {1: '1', 2: '2', 3: '3'},
              onChanged: (v) => plus.plusLabCompactDescriptionLines = v,
            ),
          ],
        ),
      if (_matches(
        tr('settingsUseGridToggles'),
        desc: tr('settingsUseGridTogglesDesc'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.grid_view_rounded,
          title: tr('settingsUseGridToggles'),
          subtitle: tr('settingsUseGridTogglesDesc'),
          value: (s) => s.plusSettingsUseGridToggles,
          onChanged: (s, v) => s.plusSettingsUseGridToggles = v,
          hideWhenPlusOff: false,
        ),
      if (_matches(
        tr('settingsUseVisualThemePicker'),
        desc: tr('settingsUseVisualThemePickerDesc'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.style_outlined,
          title: tr('settingsUseVisualThemePicker'),
          subtitle: tr('settingsUseVisualThemePickerDesc'),
          value: (s) => s.plusSettingsUseVisualThemePicker,
          onChanged: (s, v) => s.plusSettingsUseVisualThemePicker = v,
          hideWhenPlusOff: false,
        ),
      if (_matches(
        tr('settingsUseHeroCards'),
        desc: tr('settingsUseHeroCardsDesc'),
      ))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.view_agenda_outlined,
          title: tr('settingsUseHeroCards'),
          subtitle: tr('settingsUseHeroCardsDesc'),
          value: (s) => s.plusSettingsUseHeroCards,
          onChanged: (s, v) => s.plusSettingsUseHeroCards = v,
          hideWhenPlusOff: false,
        ),
      if (!isSearching || _matches(tr('visualLab')))
        ListTile(
          leading: buildSettingsIconBadge(context, Icons.science_outlined),
          title: Text(tr('visualLab')),
          subtitle: Text(tr('visualLabDescription')),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            AppHaptics.selectionClick();
            pushRoute(context, const VisualLabPage());
          },
        ),
    ];

    // Group style is an Obtainium+ preview; the corner sliders only apply
    // to the segmented style, so they only show with it.
    final groupWidgets = <Widget>[
      if (_matches(
        _preview('settingsGroupStyle'),
        desc: tr('settingsGroupStyleDesc'),
      ))
        SettingsChoiceRow<SettingsGroupStyle>(
          icon: Icons.view_list_rounded,
          title: inGroup('settingsGroupStyle'),
          description: tr('settingsGroupStyleDesc'),
          value: plus.plusSettingsGroupStyle,
          connected: true,
          options: {
            SettingsGroupStyle.card: tr('settingsGroupStyleCard'),
            SettingsGroupStyle.segmented: tr('settingsGroupStyleSegmented'),
          },
          onChanged: (v) => plus.plusSettingsGroupStyle = v,
        ),
      if (segmented &&
          (_matches(_preview('settingsGroupOuterRadius')) ||
              _matches(_preview('settingsGroupInnerRadius'))))
        SettingsChildRows(
          enabled: true,
          children: [
            if (_matches(_preview('settingsGroupOuterRadius')))
              SettingsSliderTile(
                icon: Icons.rounded_corner_rounded,
                title: inGroup('settingsGroupOuterRadius'),
                subtitle: tr('settingsGroupRadiusDesc'),
                value: outer,
                min: 0,
                max: PlusSettingsProvider.groupOuterRadiusMax,
                divisions: PlusSettingsProvider.groupOuterRadiusMax.round(),
                defaultValue: PlusSettingsProvider.groupOuterRadiusDefault,
                labelBuilder: (v) => '${v.round()} dp',
                onChanged: (v) =>
                    plus.plusSettingsGroupOuterRadius = v.roundToDouble(),
              ),
            if (_matches(_preview('settingsGroupInnerRadius')))
              SettingsSliderTile(
                icon: Icons.border_inner_rounded,
                title: inGroup('settingsGroupInnerRadius'),
                subtitle: tr('settingsGroupRadiusDesc'),
                value: plus.plusSettingsGroupInnerRadius.clamp(
                  0.0,
                  math.max(outer, 1.0),
                ),
                min: 0,
                max: math.max(outer, 1.0),
                divisions: math.max(outer.round(), 1),
                defaultValue: math.min(
                  PlusSettingsProvider.groupInnerRadiusDefault,
                  math.max(outer, 1.0),
                ),
                labelBuilder: (v) => '${v.round()} dp',
                onChanged: (v) =>
                    plus.plusSettingsGroupInnerRadius = v.roundToDouble(),
              ),
          ],
        ),
    ];

    Widget extra(
      IconData icon,
      String key,
      bool Function(PlusSettingsProvider) value,
      void Function(PlusSettingsProvider, bool) onChanged,
    ) => buildFeatureToggle<PlusSettingsProvider>(
      context,
      icon: icon,
      title: inGroup(key),
      subtitle: tr('${key}Desc'),
      value: value,
      onChanged: onChanged,
      hideWhenPlusOff: false,
    );
    final extraWidgets = <Widget>[
      if (_matches(
        _preview('settingsPredictiveBack'),
        desc: tr('settingsPredictiveBackDesc'),
      ))
        extra(
          Icons.swipe_left_alt_rounded,
          'settingsPredictiveBack',
          (s) => s.plusSettingsPredictiveBack,
          (s, v) => s.plusSettingsPredictiveBack = v,
        ),
      if (_matches(
        _preview('settingsSearchJump'),
        desc: tr('settingsSearchJumpDesc'),
      ))
        extra(
          Icons.manage_search_rounded,
          'settingsSearchJump',
          (s) => s.plusSettingsSearchJump,
          (s, v) => s.plusSettingsSearchJump = v,
        ),
      if (_matches(
        _preview('settingsLiveSummaries'),
        desc: tr('settingsLiveSummariesDesc'),
      ))
        extra(
          Icons.notes_rounded,
          'settingsLiveSummaries',
          (s) => s.plusSettingsLiveSummaries,
          (s, v) => s.plusSettingsLiveSummaries = v,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (layoutWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('settingsAppearanceSettingsPage'),
            persistKey: 'look.settingsPage',
            icon: Icons.dashboard_customize_outlined,
            children: layoutWidgets,
          ),
        if (plus.enableAllPlusFeatures && groupWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : _preview('settingsGroupsGroup'),
            description: isSearching ? null : tr('expressiveKitGroupDesc'),
            persistKey: 'look.settingsGroups',
            icon: Icons.view_list_rounded,
            children: groupWidgets,
          ),
        if (plus.enableAllPlusFeatures && extraWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : _preview('settingsExtrasGroup'),
            description: isSearching ? null : tr('expressiveKitGroupDesc'),
            persistKey: 'look.settingsExtras',
            icon: Icons.science_outlined,
            children: extraWidgets,
          ),
      ],
    );
  }
}
