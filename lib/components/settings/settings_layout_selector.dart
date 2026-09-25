import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Segmented style switch and granular legacy UI toggles
class SettingsLayoutSelector extends StatelessWidget {
  final bool isSearching;
  const SettingsLayoutSelector({super.key, this.isSearching = false});

  @override
  Widget build(BuildContext context) {
    if (isSearching) return const SizedBox.shrink();

    final plusSettings = context.watch<PlusSettingsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentMode = plusSettings.plusSettingsLayoutMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.dashboard_customize_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('settingsLayoutMode'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              tr('settingsLayoutModeDesc'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _LayoutModeButton(
                          title: tr('settingsLayoutM3E'),
                          icon: Icons.grid_view_rounded,
                          isSelected:
                              currentMode == SettingsLayoutMode.m3eCompactGrid,
                          onTap: () {
                            AppHaptics.selectionClick();
                            plusSettings.plusSettingsLayoutMode =
                                SettingsLayoutMode.m3eCompactGrid;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LayoutModeButton(
                          title: tr('settingsLayoutClassic'),
                          icon: Icons.view_agenda_outlined,
                          isSelected:
                              currentMode == SettingsLayoutMode.classicGrouped,
                          onTap: () {
                            AppHaptics.selectionClick();
                            plusSettings.plusSettingsLayoutMode =
                                SettingsLayoutMode.classicGrouped;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Granular controls accordion to fine-tune old/new UI elements
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                leading: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                title: Text(
                  tr('settingsGranularOldUI'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  tr('settingsGranularOldUIDesc'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  _buildGranularSwitch(
                    context,
                    title: tr('settingsUseGridToggles'),
                    subtitle: tr('settingsUseGridTogglesDesc'),
                    value: plusSettings.plusSettingsUseGridToggles,
                    onChanged: (v) =>
                        plusSettings.plusSettingsUseGridToggles = v,
                  ),
                  _buildGranularSwitch(
                    context,
                    title: tr('settingsUseVisualThemePicker'),
                    subtitle: tr('settingsUseVisualThemePickerDesc'),
                    value: plusSettings.plusSettingsUseVisualThemePicker,
                    onChanged: (v) =>
                        plusSettings.plusSettingsUseVisualThemePicker = v,
                  ),
                  _buildGranularSwitch(
                    context,
                    title: tr('settingsUseSubmenuHub'),
                    subtitle: tr('settingsUseSubmenuHubDesc'),
                    value: plusSettings.plusSettingsUseSubmenuHub,
                    onChanged: (v) =>
                        plusSettings.plusSettingsUseSubmenuHub = v,
                  ),
                  _buildGranularSwitch(
                    context,
                    title: tr('shizukuStatusCard'),
                    subtitle: tr('plusMaterialExpressiveDescription'),
                    value: plusSettings.plusSettingsUseHeroCards,
                    onChanged: (v) =>
                        plusSettings.plusSettingsUseHeroCards = v,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGranularSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile.adaptive(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          value: value,
          onChanged: (v) {
            AppHaptics.selectionClick();
            onChanged(v);
          },
        ),
      ),
    );
  }
}

class _LayoutModeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutModeButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.25),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
