import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/components/settings/settings_group.dart'; // To access SettingsGroup if needed or use Column
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

    List<Widget> themeWidgets = [
      if (_matches(tr('theme'))) _buildThemeDropdown(context),
      if (_matches(tr('followSystemThemeExplanation'))) _buildFollowSystemExplanation(context),
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
      if (_matches(tr('navigationLabels'))) _buildNavigationLabelDropdown(context),
      if (_matches(tr('colour')) || _matches(tr('selectColourShade'))) _buildColorPicker(context),
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
          SettingsGroup(
            title: isSearching ? null : (tr('appearance') ?? 'Appearance'),
            children: themeWidgets,
          ),
        if (typographyWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('typography'),
            children: typographyWidgets,
          ),
        if (animationWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('animations'),
            children: animationWidgets,
          ),
      ],
    );
  }

  Widget _buildThemeDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(tr('theme'), style: Theme.of(context).textTheme.bodyLarge),
          trailing: DropdownButton<ThemeSettings>(
            underline: const SizedBox(),
            value: settings.theme,
            items: [
              DropdownMenuItem(value: ThemeSettings.system, child: Text(tr('followSystem'))),
              DropdownMenuItem(value: ThemeSettings.light, child: Text(tr('light'))),
              DropdownMenuItem(value: ThemeSettings.dark, child: Text(tr('dark'))),
            ],
            onChanged: (value) {
              if (value != null) {
                HapticFeedback.selectionClick();
                settings.theme = value;
              }
            },
          ),
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

  Widget _buildBlackThemeToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (settings.theme == ThemeSettings.light) {
          return const SizedBox.shrink();
        }
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: Text(tr('useBlackTheme'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.useBlackTheme,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            settings.useBlackTheme = value;
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

  Widget _buildNavigationLabelDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ListTile(
          leading: const Icon(Icons.label_important_outlined),
          title: Text(tr('navigationLabels'), style: Theme.of(context).textTheme.bodyLarge),
          trailing: DropdownButton<NavigationDestinationLabelBehavior>(
            underline: const SizedBox(),
            value: settings.navigationLabelBehavior,
            items: [
              DropdownMenuItem(value: NavigationDestinationLabelBehavior.alwaysShow, child: Text(tr('alwaysShow'))),
              DropdownMenuItem(value: NavigationDestinationLabelBehavior.onlyShowSelected, child: Text(tr('onlyShowSelected'))),
              DropdownMenuItem(value: NavigationDestinationLabelBehavior.alwaysHide, child: Text(tr('neverShow'))),
            ],
            onChanged: (value) {
              if (value != null) {
                HapticFeedback.selectionClick();
                settings.navigationLabelBehavior = value;
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

  Widget _buildPageTransitionsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.animation_outlined),
          title: Text(tr('disablePageTransitions'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.disablePageTransitions,
          onChanged: (value) {
            settings.disablePageTransitions = value;
          },
        );
      },
    );
  }

  Widget _buildReverseTransitionsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.swap_horizontal_circle_outlined),
          title: Text(tr('reversePageTransitions'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.reversePageTransitions,
          onChanged: settings.disablePageTransitions
              ? null
              : (value) {
                  settings.reversePageTransitions = value;
                },
        );
      },
    );
  }

  Widget _buildHighlightTouchTargetsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile.adaptive(
          secondary: const Icon(Icons.touch_app_outlined),
          title: Text(tr('highlightTouchTargets'), style: Theme.of(context).textTheme.bodyLarge),
          value: settings.highlightTouchTargets,
          onChanged: (value) {
            settings.highlightTouchTargets = value;
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
