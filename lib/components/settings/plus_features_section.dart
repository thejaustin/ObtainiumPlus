import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Plus Features settings section widget
/// Allows granular control over Obtainium+ enhancements
class PlusFeaturesSection extends StatelessWidget {
  final String? searchQuery;

  const PlusFeaturesSection({
    super.key,
    this.searchQuery,
  });

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        List<Widget> children = [
          // Master toggle
          if (_matches(tr('enableAllPlusFeatures')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.auto_awesome),
              title: Text(tr('enableAllPlusFeatures'), style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(tr('enableAllPlusFeaturesDescription')),
              value: settings.enableAllPlusFeatures,
              onChanged: (value) => settings.enableAllPlusFeatures = value,
            ),

          if (settings.enableAllPlusFeatures) ...[
            const SizedBox(height: 8),

            // UI Features
            if (_matches(tr('plusGridView')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.grid_view_rounded,
                title: tr('plusGridView'),
                subtitle: tr('plusGridViewDescription'),
                value: settings.plusEnableGridView,
                onChanged: (val) => settings.plusEnableGridView = val,
              ),

            if (_matches(tr('plusQuickFilters')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.filter_alt_outlined,
                title: tr('plusQuickFilters'),
                subtitle: tr('plusQuickFiltersDescription'),
                value: settings.plusEnableQuickFilters,
                onChanged: (val) => settings.plusEnableQuickFilters = val,
              ),

            if (_matches(tr('plusDiscover')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.explore_outlined,
                title: tr('plusDiscover'),
                subtitle: tr('plusDiscoverDescription'),
                value: settings.plusEnableDiscover,
                onChanged: (val) => settings.plusEnableDiscover = val,
              ),

            if (_matches(tr('plusEnhancedAnimations')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.animation_outlined,
                title: tr('plusEnhancedAnimations'),
                subtitle: tr('plusEnhancedAnimationsDescription'),
                value: settings.plusEnableEnhancedAnimations,
                onChanged: (val) => settings.plusEnableEnhancedAnimations = val,
              ),

            if (_matches(tr('plusAdvancedSorting')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.sort_rounded,
                title: tr('plusAdvancedSorting'),
                subtitle: tr('plusAdvancedSortingDescription'),
                value: settings.plusEnableAdvancedSorting,
                onChanged: (val) => settings.plusEnableAdvancedSorting = val,
              ),

            if (_matches(tr('plusSwipeActions')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.swipe_outlined,
                title: tr('plusSwipeActions'),
                subtitle: tr('plusSwipeActionsDescription'),
                value: settings.plusEnableSwipeActions,
                onChanged: (val) => settings.plusEnableSwipeActions = val,
              ),

            if (_matches(tr('plusCategoryReorder')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.drag_indicator_outlined,
                title: tr('plusCategoryReorder'),
                subtitle: tr('plusCategoryReorderDescription'),
                value: settings.plusEnableCategoryReorder,
                onChanged: (val) => settings.plusEnableCategoryReorder = val,
              ),

            if (_matches(tr('plusUpdateSchedule')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.schedule_outlined,
                title: tr('plusUpdateSchedule'),
                subtitle: tr('plusUpdateScheduleDescription'),
                value: settings.plusEnableUpdateSchedule,
                onChanged: (val) => settings.plusEnableUpdateSchedule = val,
              ),

            if (_matches(tr('plusUICustomization')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.palette_outlined,
                title: tr('plusUICustomization'),
                subtitle: tr('plusUICustomizationDescription'),
                value: settings.plusEnableUICustomization,
                onChanged: (val) => settings.plusEnableUICustomization = val,
              ),

            if (_matches(tr('plusHapticFeedback')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.vibration,
                title: tr('plusHapticFeedback'),
                subtitle: tr('plusHapticFeedbackDescription'),
                value: settings.plusEnableHapticFeedback,
                onChanged: (val) => settings.plusEnableHapticFeedback = val,
              ),

            if (_matches(tr('plusIconCaching')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.image_outlined,
                title: tr('plusIconCaching'),
                subtitle: tr('plusIconCachingDescription'),
                value: settings.plusEnableIconCaching,
                onChanged: (val) => settings.plusEnableIconCaching = val,
              ),

            if (_matches(tr('plusModernSettings')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.settings_suggest_outlined,
                title: tr('plusModernSettings'),
                subtitle: tr('plusModernSettingsDescription'),
                value: settings.plusEnableModernSettings,
                onChanged: (val) => settings.plusEnableModernSettings = val,
              ),

            if (_matches(tr('plusModernAppPage')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.smartphone,
                title: tr('plusModernAppPage'),
                subtitle: tr('plusModernAppPageDescription'),
                value: settings.plusEnableModernAppPage,
                onChanged: (val) => settings.plusEnableModernAppPage = val,
              ),

            if (_matches(tr('plusResponsiveAppLayout')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.devices,
                title: tr('plusResponsiveAppLayout'),
                subtitle: tr('plusResponsiveAppLayoutDescription'),
                value: settings.plusEnableResponsiveAppLayout,
                onChanged: (val) => settings.plusEnableResponsiveAppLayout = val,
              ),
          ],
        ];

        if (children.every((w) => w is SizedBox && w.child == null)) {
          return const SizedBox.shrink();
        }

        return SettingsGroup(
          title: isSearching ? null : tr('obtainiumPlusFeatures'),
          children: children,
        );
      },
    );
  }

  Widget _buildFeatureToggle(
    BuildContext context,
    SettingsProvider settings, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
