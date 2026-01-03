import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/native_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Theme & Colors settings section widget
/// PERFORMANCE: Extracted to reduce unnecessary rebuilds
class ThemeSettingsSection extends StatelessWidget {
  final Future<AndroidDeviceInfo>? androidInfoFuture;
  final Map<ColorSwatch<Object>, String> colorsNameMap;

  const ThemeSettingsSection({
    super.key,
    required this.androidInfoFuture,
    required this.colorsNameMap,
  });

  @override
  Widget build(BuildContext context) {
    const height8 = SizedBox(height: 8);
    const height16 = SizedBox(height: 16);
    const height32 = SizedBox(height: 32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme & Colors subsection
        Text(
          tr('themeAndColors'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        height8,
        _buildThemeDropdown(context),
        height8,
        _buildFollowSystemExplanation(context),
        height16,
        _buildBlackThemeToggle(context),
        _buildMaterialYouToggle(context),
        _buildMatchSystemMaterialStyleToggle(context),
        _buildThemeStyleDropdown(context),
        _buildColorPicker(context),

        // Typography subsection
        height32,
        Text(
          tr('typography'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        _buildSystemFontToggle(context),

        // Animations subsection
        height32,
        Text(
          tr('animations'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        height8,
        _buildPageTransitionsToggle(context),
        height16,
        _buildReverseTransitionsToggle(context),
        height16,
        _buildHighlightTouchTargetsToggle(context),
      ],
    );
  }

  Widget _buildThemeDropdown(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return DropdownButtonFormField(
          decoration: InputDecoration(labelText: tr('theme')),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
          value: settings.theme,
          items: [
            DropdownMenuItem(
              value: ThemeSettings.system,
              child: Text(tr('followSystem')),
            ),
            DropdownMenuItem(
              value: ThemeSettings.light,
              child: Text(tr('light')),
            ),
            DropdownMenuItem(
              value: ThemeSettings.dark,
              child: Text(tr('dark')),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              settings.theme = value;
            }
          },
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
            return Text(
              tr('followSystemThemeExplanation'),
              style: Theme.of(context).textTheme.labelSmall,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(tr('useBlackTheme'))),
                Switch(
                  value: settings.useBlackTheme,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    settings.useBlackTheme = value;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
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
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(tr('useMaterialYou'))),
                Switch(
                  value: settings.useMaterialYou,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    settings.useMaterialYou = value;
                  },
                ),
              ],
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
        return Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('matchSystemMaterialStyle')),
                      Text(
                        tr('matchSystemMaterialStyleDescription'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.matchSystemMaterialStyle,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    settings.matchSystemMaterialStyle = value;
                  },
                ),
              ],
            ),
          ],
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
        return Column(
          children: [
            const SizedBox(height: 16),
            DropdownButtonFormField<DynamicSchemeVariant>(
              decoration: InputDecoration(labelText: tr('themeStyle')),
              dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              iconEnabledColor: Theme.of(context).colorScheme.onSurfaceVariant,
              value: settings.themeVariant,
              items: DynamicSchemeVariant.values.map((v) {
                String name = v.name.substring(0, 1).toUpperCase() +
                    v.name.substring(1).replaceAllMapped(
                      RegExp(r'(?=[A-Z])'),
                      (Match m) => ' ',
                    );
                return DropdownMenuItem(
                  value: v,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  settings.themeVariant = value;
                }
              },
            ),
          ],
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
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(tr('selectX', args: [tr('colour').toLowerCase()])),
          subtitle: Text(
            "${ColorTools.nameThatColor(settings.themeColor)} "
            "(${ColorTools.materialNameAndCode(settings.themeColor, colorSwatchNameMap: colorsNameMap)})",
          ),
          trailing: ColorIndicator(
            width: 40,
            height: 40,
            borderRadius: 20,
            color: settings.themeColor,
            onSelectFocus: false,
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
      heading: Text(
        tr('selectX', args: [tr('colour').toLowerCase()]),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subheading: Text(
        tr('selectColourShade'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      wheelSubheading: Text(
        tr('selectColourShade'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      colorCodeHasColor: true,
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodyMedium,
      colorCodePrefixStyle: Theme.of(context).textTheme.bodySmall,
      selectedPickerTypeColor: Theme.of(context).colorScheme.primary,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: false,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      actionsPadding: const EdgeInsets.all(16),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(tr('useSystemFont'))),
                    Switch(
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
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPageTransitionsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('disablePageTransitions'))),
            Switch(
              value: settings.disablePageTransitions,
              onChanged: (value) {
                settings.disablePageTransitions = value;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildReverseTransitionsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('reversePageTransitions'))),
            Switch(
              value: settings.reversePageTransitions,
              onChanged: settings.disablePageTransitions
                  ? null
                  : (value) {
                      settings.reversePageTransitions = value;
                    },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHighlightTouchTargetsToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(tr('highlightTouchTargets'))),
            Switch(
              value: settings.highlightTouchTargets,
              onChanged: (value) {
                settings.highlightTouchTargets = value;
              },
            ),
          ],
        );
      },
    );
  }
}
