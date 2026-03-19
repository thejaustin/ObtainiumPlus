import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Theme & Colors settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class ThemeSettingsSection extends StatelessWidget {
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final Map<ColorSwatch<Object>, String> colorsNameMap;
  final String? searchQuery;

  const ThemeSettingsSection({
    super.key,
    required this.androidInfoFuture,
    required this.colorsNameMap,
    this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    final settings = context.watch<SettingsProvider>();

    List<Widget> advancedWidgets = [
      _buildFeatureToggle(
        context,
        icon: Icons.blur_on_rounded,
        title: tr('glassmorphismUI'),
        subtitle: tr('glassmorphismUIDescription'),
        value: (SettingsProvider s) => s.plusEnableGlassmorphism,
        onChanged: (SettingsProvider s, bool v) => s.plusEnableGlassmorphism = v,
        visible: (SettingsProvider s) => _matches(tr('glassmorphismUI')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.unfold_more_rounded,
        title: tr('plusPopupSlider'),
        subtitle: tr('plusPopupSliderDescription'),
        value: (SettingsProvider s) => s.plusEnablePopupSlider,
        onChanged: (SettingsProvider s, bool v) => s.plusEnablePopupSlider = v,
        visible: (SettingsProvider s) => _matches(tr('plusPopupSlider')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.animation_outlined,
        title: tr('plusMaterialExpressive'),
        subtitle: tr('plusMaterialExpressiveDescription'),
        value: (SettingsProvider s) => s.plusEnableMaterialExpressive,
        onChanged: (SettingsProvider s, bool v) => s.plusEnableMaterialExpressive = v,
        visible: (SettingsProvider s) => _matches(tr('plusMaterialExpressive')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.vertical_align_top_rounded,
        title: tr('plusTopUILayout'),
        subtitle: tr('plusTopUILayoutDescription'),
        value: (SettingsProvider s) => s.plusTopUILayout,
        onChanged: (SettingsProvider s, bool v) => s.plusTopUILayout = v,
        visible: (SettingsProvider s) => _matches(tr('plusTopUILayout')),
      ),
    ];

    List<Widget> themeWidgets = [
      if (_matches(tr('theme'))) _buildThemeSegmented(context),
      if (_matches(tr('followSystemThemeExplanation'))) _buildFollowSystemExplanation(context),
      if (_matches(tr('themePresets'))) _buildThemePresets(context),
      _buildFeatureToggle(
        context,
        icon: Icons.dark_mode_outlined,
        title: tr('useBlackTheme'),
        subtitle: tr('useBlackThemeDescription'),
        value: (SettingsProvider s) => s.useBlackTheme,
        onChanged: (SettingsProvider s, bool v) => s.useBlackTheme = v,
        visible: (SettingsProvider s) => _matches(tr('useBlackTheme')) && s.theme != ThemeSettings.light,
      ),
      _buildMaterialYouToggle(context),
      _buildMatchSystemMaterialStyleToggle(context),
      if (_matches(tr('themeStyle'))) _buildThemeStyleDropdown(context),
      if (_matches(tr('navigationLabels'))) _buildNavigationLabelSegmented(context),
      if (_matches(tr('colour')) || _matches(tr('selectColourShade'))) _buildColorPicker(context),
      
      // Advanced/Experimental Section
      if (settings.plusEnableExperimentalCustomization && advancedWidgets.any((w) => w is! SizedBox))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            leading: const Icon(Icons.science_outlined),
            title: Text(tr('advancedTheming'), style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text(tr('advancedThemingDescription')),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('experimentalModeInfo'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
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

    List<Widget> typographyWidgets = [
       if (_matches(tr('useSystemFont'))) _buildSystemFontToggle(context),
    ];

    List<Widget> animationWidgets = [
       _buildFeatureToggle(
        context,
        icon: Icons.auto_awesome_motion_rounded,
        title: tr('plusEnhancedAnimations'),
        subtitle: tr('plusEnhancedAnimationsDescription'),
        value: (SettingsProvider s) => s.plusEnableEnhancedAnimations,
        onChanged: (SettingsProvider s, bool v) => s.plusEnableEnhancedAnimations = v,
        visible: (SettingsProvider s) => _matches(tr('plusEnhancedAnimations')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.animation_outlined,
        title: tr('disablePageTransitions'),
        subtitle: tr('disablePageTransitionsDescription'),
        value: (SettingsProvider s) => s.disablePageTransitions,
        onChanged: (SettingsProvider s, bool v) => s.disablePageTransitions = v,
        visible: (SettingsProvider s) => _matches(tr('disablePageTransitions')),
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.swap_horizontal_circle_outlined,
        title: tr('reversePageTransitions'),
        subtitle: tr('reversePageTransitionsDescription'),
        value: (SettingsProvider s) => s.reversePageTransitions,
        onChanged: (SettingsProvider s, bool v) => s.reversePageTransitions = v,
        visible: (SettingsProvider s) => _matches(tr('reversePageTransitions')) && !s.disablePageTransitions,
      ),
      _buildFeatureToggle(
        context,
        icon: Icons.touch_app_outlined,
        title: tr('highlightTouchTargets'),
        subtitle: tr('highlightTouchTargetsDescription'),
        value: (SettingsProvider s) => s.highlightTouchTargets,
        onChanged: (SettingsProvider s, bool v) => s.highlightTouchTargets = v,
        visible: (SettingsProvider s) => _matches(tr('highlightTouchTargets')),
      ),
    ];

    return Column(
      children: [
        if (themeWidgets.any((w) => w is! SizedBox))
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('appearance'),
            children: themeWidgets,
          ),
        if (typographyWidgets.any((w) => w is! SizedBox))
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('typography'),
            children: typographyWidgets,
          ),
        if (animationWidgets.any((w) => w is! SizedBox))
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('animations'),
            children: animationWidgets,
          ),
      ],
    );
  }

  Widget _buildThemeSegmented(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(tr('theme'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(tr('themeDescription')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SegmentedButton<ThemeSettings>(
                segments: [
                  ButtonSegment(value: ThemeSettings.system, label: Text(tr('followSystem')), icon: const Icon(Icons.settings_suggest_outlined)),
                  ButtonSegment(value: ThemeSettings.light, label: Text(tr('light')), icon: const Icon(Icons.light_mode_outlined)),
                  ButtonSegment(value: ThemeSettings.dark, label: Text(tr('dark')), icon: const Icon(Icons.dark_mode_outlined)),
                ],
                selected: {settings.theme},
                onSelectionChanged: (Set<ThemeSettings> newSelection) {
                  HapticFeedback.selectionClick();
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
      ('Material', Colors.blue),
      ('Emerald', Colors.teal),
      ('Ruby', Colors.red),
      ('Amber', Colors.orange),
      ('Midnight', Colors.indigo),
    ];

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.useMaterialYou) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: Text(tr('themePresets'), style: Theme.of(context).textTheme.bodyLarge),
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
                          HapticFeedback.selectionClick();
                          settings.themeColor = color;
                        }
                      },
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
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.label_important_outlined),
              title: Text(tr('navigationLabels'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(tr('navigationLabelsDescription')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SegmentedButton<NavigationDestinationLabelBehavior>(
                segments: [
                  ButtonSegment(value: NavigationDestinationLabelBehavior.alwaysShow, label: Text(tr('alwaysShow'))),
                  ButtonSegment(value: NavigationDestinationLabelBehavior.onlyShowSelected, label: Text(tr('onlyShowSelected'))),
                  ButtonSegment(value: NavigationDestinationLabelBehavior.alwaysHide, label: Text(tr('neverShow'))),
                ],
                selected: {settings.navigationLabelBehavior},
                onSelectionChanged: (Set<NavigationDestinationLabelBehavior> newSelection) {
                  HapticFeedback.selectionClick();
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
    return Consumer<SettingsProvider>(
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return SwitchListTile.adaptive(
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: Text(tr('useMaterialYou'), style: Theme.of(context).textTheme.bodyLarge),
              value: settings.useMaterialYou,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                settings.useMaterialYou = value;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMatchSystemMaterialStyleToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.useMaterialYou) {
          return const SizedBox.shrink();
        }
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.settings_suggest_outlined),
          title: Text(tr('matchSystemMaterialStyle'), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(tr('matchSystemMaterialStyleDescription')),
          value: settings.matchSystemMaterialStyle,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            settings.matchSystemMaterialStyle = value;
          },
        );
      },
    );
  }

  Widget _buildThemeStyleDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.useMaterialYou && settings.matchSystemMaterialStyle) {
          return const SizedBox.shrink();
        }
        return ListTile(
          leading: const Icon(Icons.style_outlined),
          title: Text(tr('themeStyle'), style: Theme.of(context).textTheme.bodyLarge),
          trailing: DropdownButton<DynamicSchemeVariant>(
            underline: const SizedBox(),
            value: settings.themeVariant,
            items: DynamicSchemeVariant.values.map((v) {
              String name = v.name.substring(0, 1).toUpperCase() +
                  v.name.substring(1).replaceAllMapped(RegExp(r'(?=[A-Z])'), (Match m) => ' ');
              return DropdownMenuItem(value: v, child: Text(name));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                HapticFeedback.selectionClick();
                settings.themeVariant = value;
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.useMaterialYou) {
          return const SizedBox.shrink();
        }
        return ListTile(
          leading: const Icon(Icons.color_lens_outlined),
          title: Text(tr('selectX', args: [tr('colour').toLowerCase()]), style: Theme.of(context).textTheme.bodyLarge),
          subtitle: Text("${ColorTools.nameThatColor(settings.themeColor)}"),
          trailing: ColorIndicator(
            width: 32,
            height: 32,
            borderRadius: 16,
            color: settings.themeColor,
            onSelect: () async {
              HapticFeedback.lightImpact();
              final Color colorBeforeDialog = settings.themeColor;
              if (!(await _showColorPickerDialog(context, settings))) {
                settings.themeColor = colorBeforeDialog;
              }
            },
          ),
        );
      },
    );
  }

  Future<bool> _showColorPickerDialog(BuildContext context, SettingsProvider settings) async {
    return ColorPicker(
      color: settings.themeColor,
      onColorChanged: (Color color) => settings.themeColor = color,
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(tr('selectX', args: [tr('colour').toLowerCase()]), style: Theme.of(context).textTheme.titleMedium),
      subheading: Text(tr('selectColourShade'), style: Theme.of(context).textTheme.titleMedium),
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
      constraints: const BoxConstraints(minHeight: 480, minWidth: 300, maxWidth: 320),
    );
  }

  Widget _buildSystemFontToggle(BuildContext context) {
    return FutureBuilder<AndroidDeviceInfo>(
      future: androidInfoFuture,
      builder: (ctx, snapshot) {
        if ((snapshot.data?.version.sdkInt ?? 0) < 34) {
          return const SizedBox.shrink();
        }
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return SwitchListTile.adaptive(
              secondary: const Icon(Icons.font_download_outlined),
              title: Text(tr('useSystemFont'), style: Theme.of(context).textTheme.bodyLarge),
              value: settings.useSystemFont,
              onChanged: (useSystemFont) {
                HapticFeedback.selectionClick();
                if (useSystemFont) {
                  NativeFeatures.loadSystemFont().then((val) {
                    settings.useSystemFont = true;
                  });
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

  Widget _buildFeatureToggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool Function(SettingsProvider) value,
    required void Function(SettingsProvider, bool) onChanged,
    required bool Function(SettingsProvider) visible,
  }) {
    return Consumer<SettingsProvider>(
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
