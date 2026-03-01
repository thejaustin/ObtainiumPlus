import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/pages/system_app_selector.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Plus Features settings section widget
/// Organized into clear categories to reduce overwhelm
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
            if (!isSearching)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('plusFeaturesInfo'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // --- APP MANAGEMENT ---
            if (!isSearching) _buildCategoryHeader(context, tr('appManagement')),
            
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

            if (_matches(tr('importInstalledApps')))
              ListTile(
                leading: const Icon(Icons.install_mobile_rounded),
                title: Text(tr('importInstalledApps'), style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(tr('importInstalledAppsDescription')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SystemAppSelector()),
                  );
                },
              ),

            if (_matches(tr('plusSystemUpdateScanner')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.system_update_alt_rounded,
                title: tr('plusSystemUpdateScanner'),
                subtitle: tr('plusSystemUpdateScannerDescription'),
                value: settings.plusEnableSystemUpdateScanner,
                onChanged: (val) => settings.plusEnableSystemUpdateScanner = val,
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

            const Divider(height: 24),

            // --- UI & LAYOUT ---
            if (!isSearching) _buildCategoryHeader(context, tr('uiAndLayout')),

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
                icon: Icons.pages_outlined,
                title: tr('plusModernAppPage'),
                subtitle: tr('plusModernAppPageDescription'),
                value: settings.plusEnableModernAppPage,
                onChanged: (val) => settings.plusEnableModernAppPage = val,
              ),

            if (_matches(tr('plusModernAddAppPage')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.add_to_home_screen_rounded,
                title: tr('plusModernAddAppPage'),
                subtitle: tr('plusModernAddAppPageDescription'),
                value: settings.plusEnableModernAddAppPage,
                onChanged: (val) => settings.plusEnableModernAddAppPage = val,
              ),

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

            if (_matches(tr('plusResponsiveAppLayout')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.view_quilt_rounded,
                title: tr('plusResponsiveAppLayout'),
                subtitle: tr('plusResponsiveAppLayoutDescription'),
                value: settings.plusEnableResponsiveAppLayout,
                onChanged: (val) => settings.plusEnableResponsiveAppLayout = val,
              ),

            const Divider(height: 24),

            // --- VISUAL ENHANCEMENTS ---
            if (!isSearching) _buildCategoryHeader(context, tr('visualEnhancements')),

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

            if (_matches(tr('plusHapticFeedback')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.vibration_rounded,
                title: tr('plusHapticFeedback'),
                subtitle: tr('plusHapticFeedbackDescription'),
                value: settings.plusEnableHapticFeedback,
                onChanged: (val) => settings.plusEnableHapticFeedback = val,
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

            if (_matches(tr('plusUICustomization')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.dashboard_customize_outlined,
                title: tr('plusUICustomization'),
                subtitle: tr('plusUICustomizationDescription'),
                value: settings.plusEnableUICustomization,
                onChanged: (val) => settings.plusEnableUICustomization = val,
              ),

            if (_matches(tr('plusEnableExperimentalCustomization')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.science_outlined,
                title: tr('plusEnableExperimentalCustomization'),
                subtitle: tr('plusEnableExperimentalCustomizationDescription'),
                value: settings.plusEnableExperimentalCustomization,
                onChanged: (val) => settings.plusEnableExperimentalCustomization = val,
              ),

            const Divider(height: 24),

            // --- ORGANIZATION ---
            if (!isSearching) _buildCategoryHeader(context, tr('organization')),

            if (_matches(tr('plusIconCaching')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.cached_rounded,
                title: tr('plusIconCaching'),
                subtitle: tr('plusIconCachingDescription'),
                value: settings.plusEnableIconCaching,
                onChanged: (val) => settings.plusEnableIconCaching = val,
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

            const Divider(height: 24),

            // --- CUSTOMIZATION ---
            if (_matches(tr('customizeTabs')))
              ListTile(
                leading: const Icon(Icons.tab_outlined),
                title: Text(tr('customizeTabs'), style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(tr('dragToReorderTabs')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  HapticFeedback.selectionClick();
                  showTabCustomization(context);
                },
              ),

            // --- DEVELOPER OPTIONS ---
            if (!isSearching) _buildCategoryHeader(context, tr('developerOptions')),

            if (_matches(tr('developerOptions')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.developer_mode_rounded,
                title: tr('developerOptions'),
                subtitle: tr('developerOptionsDescription'),
                value: settings.plusDeveloperMode,
                onChanged: (val) => settings.plusDeveloperMode = val,
              ),

            if (settings.plusDeveloperMode && _matches(tr('plusShowLegacyUIComparison')))
              _buildFeatureToggle(
                context,
                settings,
                icon: Icons.compare_outlined,
                title: tr('plusShowLegacyUIComparison'),
                subtitle: tr('plusShowLegacyUIComparisonDescription'),
                value: settings.plusShowLegacyUIComparison,
                onChanged: (val) => settings.plusShowLegacyUIComparison = val,
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

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
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
