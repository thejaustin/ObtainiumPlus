import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/utils/locale_constants.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/components/settings/settings_layout_selector.dart';
import 'package:obtainium/components/settings/visual_theme_selector.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';

/// Theme & Colors settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class ThemeSettingsSection extends StatelessWidget {
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final Map<ColorSwatch<Object>, String> colorsNameMap;
  final String? searchQuery;
  final bool? showAdvancedSettings;
  final String? subCategory;

  const ThemeSettingsSection({
    super.key,
    required this.androidInfoFuture,
    required this.colorsNameMap,
    this.searchQuery,
    this.showAdvancedSettings,
    this.subCategory,
  });

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    final themeSettings = context.watch<ThemeSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();

    List<Widget> advancedWidgets = [
      if (_matches(tr('glassmorphismUI')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.blur_on_rounded,
          title: tr('glassmorphismUI'),
          subtitle: tr('glassmorphismUIDescription'),
          value: (s) => s.plusEnableGlassmorphism,
          onChanged: (s, v) => s.plusEnableGlassmorphism = v,
        ),
      if (_matches(tr('plusPopupSlider'), isAdvanced: true))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.unfold_more_rounded,
          title: tr('plusPopupSlider'),
          subtitle: tr('plusPopupSliderDescription'),
          value: (s) => s.plusEnablePopupSlider,
          onChanged: (s, v) => s.plusEnablePopupSlider = v,
        ),
      if (_matches(tr('plusExpressiveProgress')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.auto_mode_rounded,
          title: tr('plusExpressiveProgress'),
          subtitle: tr('plusExpressiveProgressDescription'),
          value: (s) => s.plusEnableExpressiveProgress,
          onChanged: (s, v) => s.plusEnableExpressiveProgress = v,
        ),
      if (_matches(tr('plusBouncyPhysics')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.unfold_more_rounded,
          title: tr('plusBouncyPhysics'),
          subtitle: tr('plusBouncyPhysicsDescription'),
          value: (s) => s.plusEnableBouncyPhysics,
          onChanged: (s, v) => s.plusEnableBouncyPhysics = v,
        ),
      if (_matches(tr('plusOneHandedMode')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.swipe_down_rounded,
          title: tr('plusOneHandedMode'),
          subtitle: tr('plusOneHandedModeDescription'),
          value: (s) => s.plusEnableOneHandedMode,
          onChanged: (s, v) => s.plusEnableOneHandedMode = v,
        ),
      if (_matches(tr('plusTopUILayout'), isAdvanced: true))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.vertical_align_top_rounded,
          title: tr('plusTopUILayout'),
          subtitle: tr('plusTopUILayoutDescription'),
          value: (s) => s.plusTopUILayout,
          onChanged: (s, v) => s.plusTopUILayout = v,
        ),
    ];

    List<Widget> themeWidgets = [
      if ((subCategory != 'theme' || isSearching) &&
          (_matches(tr('designSystemThemeStyle')) ||
              _matches(tr('obtainiumPlusTheme')) ||
              _matches(tr('materialExpressiveTheme')) ||
              _matches(tr('plusMaterialExpressive'))))
        _buildDesignSystemSelector(context),
      if (_matches(tr('theme')))
        plusSettings.plusSettingsUseVisualThemePicker
            ? const VisualThemeSelector(embedded: true)
            : _buildThemeSegmented(context),
      if (_matches(tr('followSystemThemeExplanation')))
        _buildFollowSystemExplanation(context),
      if (_matches(tr('themePresets'))) _buildThemePresets(context),
      if (_matches(tr('useBlackTheme')) &&
          !plusSettings.plusSettingsUseVisualThemePicker &&
          themeSettings.theme != ThemeSettings.light)
        buildFeatureToggle<ThemeSettingsProvider>(
          context,
          icon: Icons.dark_mode_outlined,
          title: tr('useBlackTheme'),
          subtitle: tr('useBlackThemeDescription'),
          value: (s) => s.useBlackTheme,
          onChanged: (s, v) => s.useBlackTheme = v,
        ),
      _buildMaterialYouToggle(context),
      _buildMatchSystemMaterialStyleToggle(context),
      if (_matches(tr('themeStyle'))) _buildThemeStyleDropdown(context),
      if (_matches(tr('navigationLabels')) ||
          _matches(tr('plusNavBarAlwaysShowLabels')))
        _buildNavigationLabelSegmented(context),
      if (_matches(tr('colour')) || _matches(tr('selectColourShade')))
        _buildColorPicker(context),
      if (_matches(tr('plusUseCompactSettings')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.density_small_rounded,
          title: tr('plusUseCompactSettings'),
          subtitle: tr('plusUseCompactSettingsDescription'),
          value: (s) => s.plusUseCompactSettings,
          onChanged: (s, v) => s.plusUseCompactSettings = v,
        ),
      if (_matches(tr('useSystemFont'))) _buildSystemFontToggle(context),
      if (_matches(tr('language'))) _buildLanguagePicker(context),

      // Advanced/Experimental Section
      if (plusSettings.enableAllPlusFeatures && advancedWidgets.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            key: const PageStorageKey<String>('settings_advanced_theming'),
            onExpansionChanged: (_) => AppHaptics.selectionClick(),
            expansionAnimationStyle: AnimationStyle(
              curve: Easing.emphasizedDecelerate,
              reverseCurve: Easing.emphasizedAccelerate,
              duration: const Duration(milliseconds: 280),
            ),
            leading: buildSettingsIconBadge(context, Icons.science_outlined),
            title: Text(
              tr('advancedTheming'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(tr('advancedThemingDescription')),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer
                        .withValues(alpha: AppOpacity.medium),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: AppOpacity.low),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('experimentalModeInfo'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...advancedWidgets,
            ],
          ),
        ),
    ];

    List<Widget> animationWidgets = [
      if (_matches(tr('plusEnhancedAnimations')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.auto_awesome_motion_rounded,
          title: tr('plusEnhancedAnimations'),
          subtitle: tr('plusEnhancedAnimationsDescription'),
          value: (s) => s.plusEnableEnhancedAnimations,
          onChanged: (s, v) => s.plusEnableEnhancedAnimations = v,
        ),
      if (_matches(tr('disablePageTransitions'), isAdvanced: true))
        buildFeatureToggle<BehaviorSettingsProvider>(
          context,
          icon: Icons.animation_outlined,
          title: tr('disablePageTransitions'),
          subtitle: tr('disablePageTransitionsDescription'),
          value: (s) => s.disablePageTransitions,
          onChanged: (s, v) => s.disablePageTransitions = v,
        ),
      if (_matches(tr('reversePageTransitions')) &&
          !behaviorSettings.disablePageTransitions)
        buildFeatureToggle<BehaviorSettingsProvider>(
          context,
          icon: Icons.swap_horizontal_circle_outlined,
          title: tr('reversePageTransitions'),
          subtitle: tr('reversePageTransitionsDescription'),
          value: (s) => s.reversePageTransitions,
          onChanged: (s, v) => s.reversePageTransitions = v,
        ),
      if (_matches(tr('highlightTouchTargets')))
        buildFeatureToggle<BehaviorSettingsProvider>(
          context,
          icon: Icons.touch_app_outlined,
          title: tr('highlightTouchTargets'),
          subtitle: tr('highlightTouchTargetsDescription'),
          value: (s) => s.highlightTouchTargets,
          onChanged: (s, v) => s.highlightTouchTargets = v,
        ),
      if (_matches(tr('animationSpeed')))
        Consumer<BehaviorSettingsProvider>(
          builder: (context, settings, child) => SettingsSliderTile(
            icon: Icons.speed_outlined,
            title: tr('animationSpeed'),
            value: settings.animationSpeedMultiplier.clamp(0.25, 2.0),
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
              settings.animationSpeedMultiplier = nearest;
            },
          ),
        ),
      if (plusSettings.enableAllPlusFeatures &&
          plusSettings.plusDeveloperMode &&
          _matches('third party loading indicator'))
        SwitchListTile.adaptive(
          secondary: buildSettingsIconBadge(
            context,
            Icons.refresh_rounded,
            active: plusSettings.plusDevUseThirdPartyLoadingIndicator,
          ),
          title: Text(
            'Use Wavy Loading Spinner',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: const Text(
            'Replaces the M3E morphing loading indicator with the wavy ring for comparison.',
          ),
          value: plusSettings.plusDevUseThirdPartyLoadingIndicator,
          onChanged: (val) {
            val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
            plusSettings.plusDevUseThirdPartyLoadingIndicator = val;
          },
        ),
    ];

    List<Widget> shapeWidgets = [
      _buildCornerRadiusPreview(context, plusSettings),
      if (_matches(tr('plusGlobalCornerRadius')))
        SettingsSliderTile(
          icon: Icons.rounded_corner_rounded,
          title: tr('plusGlobalCornerRadius'),
          value: plusSettings.plusGlobalCornerRadius,
          defaultValue: 28.0,
          min: 0,
          max: 40,
          divisions: 40,
          labelBuilder: (v) => '${v.toInt()}px',
          onChanged: (val) => plusSettings.plusGlobalCornerRadius = val,
        ),
      if (_matches(tr('plusOverrideIndividualCornerRadius')))
        buildFeatureToggle<PlusSettingsProvider>(
          context,
          icon: Icons.tune_rounded,
          title: tr('plusOverrideIndividualCornerRadius'),
          subtitle: tr('plusOverrideIndividualCornerRadiusDescription'),
          value: (s) => s.plusOverrideIndividualCornerRadius,
          onChanged: (s, v) => s.plusOverrideIndividualCornerRadius = v,
        ),
      if (plusSettings.plusOverrideIndividualCornerRadius) ...[
        if (_matches(tr('plusHomeCornerRadius')))
          SettingsSliderTile(
            icon: Icons.home_max_rounded,
            title: tr('plusHomeCornerRadius'),
            value: plusSettings.plusHomeCornerRadius,
            defaultValue: 20.0,
            min: 0,
            max: 40,
            divisions: 40,
            labelBuilder: (v) => '${v.toInt()}px',
            onChanged: (val) => plusSettings.plusHomeCornerRadius = val,
          ),
        if (_matches(tr('plusSettingsCornerRadius')))
          SettingsSliderTile(
            icon: Icons.settings_suggest_rounded,
            title: tr('plusSettingsCornerRadius'),
            value: plusSettings.plusSettingsCornerRadius,
            defaultValue: 20.0,
            min: 0,
            max: 40,
            divisions: 40,
            labelBuilder: (v) => '${v.toInt()}px',
            onChanged: (val) => plusSettings.plusSettingsCornerRadius = val,
          ),
      ],
    ];

    final showTheme = subCategory == null || subCategory == 'theme';
    final showMotion = subCategory == null || subCategory == 'motion';

    return Column(
      children: [
        if (subCategory == null)
          SettingsLayoutSelector(isSearching: isSearching),
        if (showTheme && themeWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching || subCategory != null ? null : tr('appearance'),
            persistKey: 'appearance',
            icon: Icons.palette_rounded,
            helpText: tr('appearanceHelp'),
            isExpandable: !isSearching && subCategory == null,
            initiallyExpanded: true,
            children: themeWidgets,
          ),
        if (showMotion && shapeWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching || subCategory != null
                ? null
                : tr('plusShapesAndCorners'),
            persistKey: 'plusShapesAndCorners',
            icon: Icons.rounded_corner_rounded,
            helpText: tr('shapesHelp'),
            isExpandable: !isSearching && subCategory == null,
            initiallyExpanded: true,
            onReset: () {
              AppHaptics.heavyImpact();
              plusSettings.plusGlobalCornerRadius = 20.0;
              plusSettings.plusHomeCornerRadius = 20.0;
              plusSettings.plusSettingsCornerRadius = 16.0;
              plusSettings.plusOverrideIndividualCornerRadius = false;
            },
            children: shapeWidgets,
          ),
        if (showMotion && animationWidgets.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching || subCategory != null ? null : tr('animations'),
            persistKey: 'animations',
            icon: Icons.animation_rounded,
            isExpandable: !isSearching && subCategory == null,
            initiallyExpanded: true,
            children: animationWidgets,
          ),
      ],
    );
  }

  Widget _buildCornerRadiusPreview(
    BuildContext context,
    PlusSettingsProvider settings,
  ) {
    if (searchQuery != null && searchQuery!.isNotEmpty)
      return const SizedBox.shrink();

    final radius = settings.plusGlobalCornerRadius;
    final isM3E = settings.plusEnableMaterialExpressive;
    final colorScheme = Theme.of(context).colorScheme;

    final animsEnabled = settings.plusEnableEnhancedAnimations;
    final dur = Duration(milliseconds: animsEnabled ? 250 : 0);
    const curve = Curves.easeOutCubic;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon tile — large square morphing shape
              AnimatedContainer(
                duration: dur,
                curve: curve,
                width: 76,
                height: 76,
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primary.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: CardMetrics.shape(
                    radius,
                    expressive: isM3E,
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.apps_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card tile — wide morphing shape
                  AnimatedContainer(
                    duration: dur,
                    curve: curve,
                    width: 160,
                    height: 52,
                    decoration: ShapeDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      shape: CardMetrics.shape(
                        radius,
                        expressive: isM3E,
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: AnimatedContainer(
                            duration: dur,
                            curve: curve,
                            width: 28,
                            height: 28,
                            decoration: ShapeDecoration(
                              color: colorScheme.secondaryContainer,
                              shape: CardMetrics.shape(
                                (radius * 0.6).clamp(4, 20),
                                expressive: isM3E,
                              ),
                            ),
                            child: Icon(
                              Icons.download_rounded,
                              size: 16,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Name',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'v1.0.0',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Chip — pill morphing shape
                  AnimatedContainer(
                    duration: dur,
                    curve: curve,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: ShapeDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      shape: CardMetrics.shape(
                        radius.clamp(0, 20),
                        expressive: isM3E,
                        side: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Update',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr('cornerRadiusPreview'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignSystemSelector(BuildContext context) {
    return Consumer<PlusSettingsProvider>(
      builder: (context, plusSettings, child) {
        final isM3E = plusSettings.plusEnableMaterialExpressive;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: buildSettingsIconBadge(
                context,
                isM3E ? Icons.brush_rounded : Icons.auto_awesome_rounded,
                active: true,
              ),
              title: Text(
                tr('designSystemThemeStyle'),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isM3E
                    ? tr('materialExpressiveThemeDescription')
                    : tr('obtainiumPlusThemeDescription'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(tr('obtainiumPlusTheme')),
                      icon: const Icon(Icons.auto_awesome_rounded),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(tr('materialExpressiveTheme')),
                      icon: const Icon(Icons.brush_rounded),
                    ),
                  ],
                  selected: {isM3E},
                  onSelectionChanged: (Set<bool> newSelection) {
                    final next = newSelection.first;
                    if (next) {
                      AppHaptics.toggleOn();
                    } else {
                      AppHaptics.toggleOff();
                    }
                    plusSettings.plusEnableMaterialExpressive = next;
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeSegmented(BuildContext context) {
    return Consumer<ThemeSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: buildSettingsIconBadge(context, Icons.palette_outlined),
              title: Text(
                tr('theme'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('themeDescription')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SegmentedButton<ThemeSettings>(
                segments: [
                  ButtonSegment(
                    value: ThemeSettings.system,
                    label: Text(tr('followSystem')),
                    icon: const Icon(Icons.settings_suggest_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeSettings.light,
                    label: Text(tr('light')),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeSettings.dark,
                    label: Text(tr('dark')),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {settings.theme},
                onSelectionChanged: (Set<ThemeSettings> newSelection) {
                  AppHaptics.selectionClick();
                  settings.theme = newSelection.first;
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemePresets(BuildContext context) {
    final presets = [
      ('Obtainium', const Color(0xFF6438B5)),
      ('Material', const Color(0xFF0B57D0)),
      ('Oceanic', const Color(0xFF006874)),
      ('Forest', const Color(0xFF2E6B27)),
      ('Ruby', const Color(0xFFB3261E)),
      ('Sunset', const Color(0xFF984061)),
      ('Amber', const Color(0xFFE8710A)),
      ('Midnight', const Color(0xFF3F51B5)),
      ('Slate', const Color(0xFF4E5D6C)),
      ('Coral', const Color(0xFFFF4040)),
      ('Cosmic', const Color(0xFF7C4DFF)),
      ('Sakura', const Color(0xFFE91E63)),
      ('Aurora', const Color(0xFF00BFA5)),
      ('Solar', const Color(0xFFFF6D00)),
    ];

    return Consumer<ThemeSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.useMaterialYou) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: buildSettingsIconBadge(
                context,
                Icons.color_lens_outlined,
              ),
              title: Text(
                tr('themePresets'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('themePresetsDescription')),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: presets.map((preset) {
                  final name = preset.$1;
                  final color = preset.$2;
                  final isSelected = settings.themeColor.value == color.value;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(name),
                      avatar: CircleAvatar(backgroundColor: color, radius: 10),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selectionClick();
                          settings.themeColor = color;
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context
                              .watch<PlusSettingsProvider>()
                              .plusGlobalCornerRadius,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationLabelSegmented(BuildContext context) {
    return Consumer<ViewSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: buildSettingsIconBadge(
                context,
                Icons.label_important_outlined,
              ),
              title: Text(
                tr('navigationLabels'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('navigationLabelsDescription')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SegmentedButton<NavigationDestinationLabelBehavior>(
                segments: [
                  ButtonSegment(
                    value: NavigationDestinationLabelBehavior.alwaysShow,
                    label: Text(tr('alwaysShow')),
                  ),
                  ButtonSegment(
                    value: NavigationDestinationLabelBehavior.onlyShowSelected,
                    label: Text(tr('onlyShowSelected')),
                  ),
                  ButtonSegment(
                    value: NavigationDestinationLabelBehavior.alwaysHide,
                    label: Text(tr('neverShow')),
                  ),
                ],
                selected: {settings.navigationLabelBehavior},
                onSelectionChanged:
                    (Set<NavigationDestinationLabelBehavior> newSelection) {
                      AppHaptics.selectionClick();
                      settings.navigationLabelBehavior = newSelection.first;
                    },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowSystemExplanation(BuildContext context) {
    return Consumer<ThemeSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.theme != ThemeSettings.system) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<AndroidDeviceInfo>(
          future: androidInfoFuture,
          builder: (ctx, snapshot) {
            if ((snapshot.data?.version.sdkInt ?? 30) >= 29) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                tr('followSystemThemeExplanation'),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialYouToggle(BuildContext context) {
    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        if ((snapshot.data?.version.sdkInt ?? 0) < 31) {
          return const SizedBox.shrink();
        }
        return Consumer<ThemeSettingsProvider>(
          builder: (context, settings, child) {
            return SwitchListTile.adaptive(
              secondary: buildSettingsIconBadge(
                context,
                Icons.auto_awesome_outlined,
                active: settings.useMaterialYou,
              ),
              title: Text(
                tr('useMaterialYou'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              value: settings.useMaterialYou,
              onChanged: (value) {
                value ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                settings.useMaterialYou = value;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMatchSystemMaterialStyleToggle(BuildContext context) {
    return Consumer<ThemeSettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.useMaterialYou) {
          return const SizedBox.shrink();
        }
        return SwitchListTile.adaptive(
          secondary: buildSettingsIconBadge(
            context,
            Icons.settings_suggest_outlined,
            active: settings.matchSystemMaterialStyle,
          ),
          title: Text(
            tr('matchSystemMaterialStyle'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(tr('matchSystemMaterialStyleSubtitle')),
          value: settings.matchSystemMaterialStyle,
          onChanged: (value) {
            value ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
            settings.matchSystemMaterialStyle = value;
          },
        );
      },
    );
  }

  Widget _buildThemeStyleDropdown(BuildContext context) {
    return Consumer<ThemeSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.useMaterialYou && settings.matchSystemMaterialStyle) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: buildSettingsIconBadge(context, Icons.style_outlined),
              title: Text(
                tr('themeStyle'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: settings.useMaterialYou
                  ? Text(
                      'Shapes the color palette generated from your system wallpaper',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<DynamicSchemeVariant>(
                    segments: DynamicSchemeVariant.values.map((v) {
                      String name =
                          v.name.substring(0, 1).toUpperCase() +
                          v.name
                              .substring(1)
                              .replaceAllMapped(
                                RegExp(r'(?=[A-Z])'),
                                (Match m) => ' ',
                              );
                      return ButtonSegment(value: v, label: Text(name));
                    }).toList(),
                    selected: {settings.themeVariant},
                    onSelectionChanged: (value) {
                      AppHaptics.selectionClick();
                      settings.themeVariant = value.first;
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

  Widget _buildColorPicker(BuildContext context) {
    final List<({String name, Color color})> presetColors = const [
      (name: 'Purple', color: Color(0xFF6438B5)),
      (name: 'Ocean', color: Color(0xFF0288D1)),
      (name: 'Teal', color: Color(0xFF00897B)),
      (name: 'Sunset', color: Color(0xFFF4511E)),
      (name: 'Rose', color: Color(0xFFD81B60)),
      (name: 'Amber', color: Color(0xFFFFB300)),
    ];

    return Consumer<ThemeSettingsProvider>(
      builder: (context, settings, child) {
        if (settings.useMaterialYou) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: buildSettingsIconBadge(
                context,
                Icons.color_lens_outlined,
              ),
              title: Text(
                tr('selectX', args: [tr('colour').toLowerCase()]),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(ColorTools.nameThatColor(settings.themeColor)),
              trailing: ColorIndicator(
                width: 32,
                height: 32,
                borderRadius: 16,
                color: settings.themeColor,
                onSelect: () async {
                  AppHaptics.lightImpact();
                  final Color colorBeforeDialog = settings.themeColor;
                  if (!(await _showColorPickerDialog(context, settings))) {
                    settings.themeColor = colorBeforeDialog;
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: presetColors.map((preset) {
                    final bool isSelected =
                        settings.themeColor.value == preset.color.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: preset.color,
                          radius: 8,
                        ),
                        label: Text(preset.name),
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onPressed: () {
                          AppHaptics.selectionClick();
                          settings.themeColor = preset.color;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showColorPickerDialog(
    BuildContext context,
    ThemeSettingsProvider settings,
  ) async {
    return ColorPicker(
      color: settings.themeColor,
      onColorChanged: (Color color) => settings.themeColor = color,
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        tr('selectX', args: [tr('colour').toLowerCase()]),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subheading: Text(
        tr('selectColourShade'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      colorCodeHasColor: true,
      selectedPickerTypeColor: Theme.of(context).colorScheme.primary,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      constraints: const BoxConstraints(
        minHeight: 480,
        minWidth: 300,
        maxWidth: 320,
      ),
    );
  }

  Widget _buildSystemFontToggle(BuildContext context) {
    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        if ((snapshot.data?.version.sdkInt ?? 0) < 34) {
          return const SizedBox.shrink();
        }
        return Consumer<ThemeSettingsProvider>(
          builder: (context, settings, child) {
            return SwitchListTile.adaptive(
              secondary: buildSettingsIconBadge(
                context,
                Icons.font_download_outlined,
                active: settings.useSystemFont,
              ),
              title: Text(
                tr('useSystemFont'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              value: settings.useSystemFont,
              onChanged: (useSystemFont) {
                useSystemFont ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                if (useSystemFont) {
                  NativeFeatures.loadSystemFont().then(
                    (val) {
                      settings.useSystemFont = true;
                    },
                    onError: (e) {
                      talker.warning('loadSystemFont failed: $e');
                    },
                  );
                } else {
                  settings.useSystemFont = false;
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLanguagePicker(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final currentLocale = context.locale;
        final matchedLocaleEntry = supportedLocales.firstWhere(
          (entry) => entry.key.languageCode == currentLocale.languageCode,
          orElse: () => supportedLocales.first,
        );
        return ListTile(
          leading: buildSettingsIconBadge(context, Icons.language_outlined),
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
            ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.94,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('close')),
              ),
            ),
          ],
        );
      },
    );
  }
}
