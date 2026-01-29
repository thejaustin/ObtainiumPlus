import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/info_tooltip.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/pages/settings.dart'; // To access SettingsGroup if needed or use Column
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
    final settings = context.watch<SettingsProvider>();
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    List<Widget> themeWidgets = [
      if (_matches(tr('theme'))) _buildThemeDropdown(context),
      if (_matches(tr('followSystemThemeExplanation'))) _buildFollowSystemExplanation(context),
      if (_matches(tr('useBlackTheme'))) _buildBlackThemeToggle(context),
      if (_matches(tr('useMaterialYou'))) _buildMaterialYouToggle(context),
      if (_matches(tr('matchSystemMaterialStyle'))) _buildMatchSystemMaterialStyleToggle(context),
      if (_matches(tr('themeStyle'))) _buildThemeStyleDropdown(context),
      // Only show Navigation Labels if UI Customization is enabled
      if (settings.plusEnableUICustomization && _matches(tr('navigationLabels'))) _buildNavigationLabelDropdown(context),
      if (_matches(tr('colour')) || _matches(tr('selectColourShade'))) _buildColorPicker(context),
    ];

    List<Widget> typographyWidgets = [
       if (_matches(tr('useSystemFont'))) _buildSystemFontToggle(context),
    ];

    List<Widget> animationWidgets = [
       if (_matches(tr('disablePageTransitions'))) _buildPageTransitionsToggle(context),
       if (_matches(tr('reversePageTransitions'))) _buildReverseTransitionsToggle(context),
       if (_matches(tr('highlightTouchTargets'))) _buildHighlightTouchTargetsToggle(context),
    ];

    List<Widget> appBarWidgets = [
       // Only show App Bar Style if UI Customization is enabled
       if (settings.plusEnableUICustomization && (_matches(tr('appBarStyle') ?? 'App Bar Style'))) _buildAppBarStylePicker(context),
    ];

    return Column(
      children: [
        if (themeWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : (tr('appearance') ?? 'Appearance'),
            children: themeWidgets,
          ),
        if (appBarWidgets.any((w) => w is! SizedBox))
          SettingsGroup(
            title: isSearching ? null : tr('appBarStyle') ?? 'App Bar Style',
            children: appBarWidgets,
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

  Widget _buildAppBarStylePicker(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                tr('appBarStyleDescription') ?? 'Choose how page headers appear throughout the app',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _AppBarStyleOption(
                      style: AppBarStyle.compact,
                      isSelected: settings.appBarStyle == AppBarStyle.compact,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        settings.appBarStyle = AppBarStyle.compact;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AppBarStyleOption(
                      style: AppBarStyle.large,
                      isSelected: settings.appBarStyle == AppBarStyle.large,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        settings.appBarStyle = AppBarStyle.large;
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Per-page customization link
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: Text(tr('perPageCustomization') ?? 'Per-page customization', style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(
                settings.appBarStyleOverrides.isEmpty
                    ? tr('noCustomPages') ?? 'No custom pages'
                    : tr('customPagesCount', args: [settings.appBarStyleOverrides.length.toString()]) ?? '${settings.appBarStyleOverrides.length} custom page(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              onTap: () => _showPerPageCustomizationDialog(context, settings),
            ),
          ],
        );
      },
    );
  }

  void _showPerPageCustomizationDialog(BuildContext context, SettingsProvider settings) {
    // Define available pages that can be customized
    final pages = [
      {'id': 'settings', 'name': tr('settings')},
      {'id': 'apps', 'name': tr('appsString')},
      {'id': 'add', 'name': tr('addApp')},
      {'id': 'appearance', 'name': tr('appearance') ?? 'Appearance'},
      {'id': 'updates', 'name': tr('updates')},
      {'id': 'general', 'name': tr('general')},
      {'id': 'advanced', 'name': tr('advanced')},
      {'id': 'viewOptions', 'name': tr('viewOptions')},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('perPageCustomization') ?? 'Per-page Customization'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              final pageId = page['id']!;
              final pageName = page['name']!;
              final hasOverride = settings.hasAppBarStyleOverride(pageId);
              final currentStyle = settings.getAppBarStyleForPage(pageId);

              return ListTile(
                title: Text(pageName),
                subtitle: Text(
                  hasOverride
                      ? (currentStyle == AppBarStyle.large ? tr('large') ?? 'Large' : tr('compact') ?? 'Compact')
                      : tr('followGlobal') ?? 'Follow global',
                  style: TextStyle(
                    color: hasOverride
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'global') {
                      settings.setAppBarStyleForPage(pageId, null);
                    } else if (value == 'compact') {
                      settings.setAppBarStyleForPage(pageId, AppBarStyle.compact);
                    } else if (value == 'large') {
                      settings.setAppBarStyleForPage(pageId, AppBarStyle.large);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'global',
                      child: Row(
                        children: [
                          Icon(
                            Icons.public_outlined,
                            size: 20,
                            color: !hasOverride ? Theme.of(context).colorScheme.primary : null,
                          ),
                          const SizedBox(width: 12),
                          Text(tr('followGlobal') ?? 'Follow global'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'compact',
                      child: Row(
                        children: [
                          Icon(
                            Icons.density_small_outlined,
                            size: 20,
                            color: hasOverride && currentStyle == AppBarStyle.compact
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(tr('compact') ?? 'Compact'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'large',
                      child: Row(
                        children: [
                          Icon(
                            Icons.density_large_outlined,
                            size: 20,
                            color: hasOverride && currentStyle == AppBarStyle.large
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(tr('large') ?? 'Large'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          if (settings.appBarStyleOverrides.isNotEmpty)
            TextButton(
              onPressed: () {
                settings.clearAppBarStyleOverrides();
              },
              child: Text(tr('resetAll') ?? 'Reset all'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('close') ?? 'Close'),
          ),
        ],
      ),
    );
  }
}

/// Visual preview widget for app bar style selection (Samsung-style)
class _AppBarStyleOption extends StatelessWidget {
  final AppBarStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppBarStyleOption({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLarge = style == AppBarStyle.large;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Phone mockup
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // App bar preview
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isLarge ? 56 : 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: isLarge ? 20 : 16,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isLarge
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 6,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 12,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  height: 10,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurface,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  // Content preview (list items)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: List.generate(
                          isLarge ? 3 : 4,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colorScheme.onSurface.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Label
            Text(
              isLarge ? (tr('large') ?? 'Large') : (tr('compact') ?? 'Compact'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // Checkmark indicator
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Icon(
                Icons.check_circle,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
