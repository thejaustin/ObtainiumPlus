import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/pages/system_app_selector.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

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
        return Column(
          children: [
            // Master toggle in its own expressive card
            ExpressiveSettingsGroup(
              children: [
                if (_matches(tr('enableAllPlusFeatures')))
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.auto_awesome),
                    title: Text(tr('enableAllPlusFeatures'), style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text(tr('enableAllPlusFeaturesDescription')),
                    value: settings.enableAllPlusFeatures,
                    onChanged: (value) => settings.enableAllPlusFeatures = value,
                  ),
              ],
            ),

            if (settings.enableAllPlusFeatures) ...[
              // --- APP MANAGEMENT ---
              ExpressiveSettingsGroup(
                title: isSearching ? null : tr('appManagement'),
                children: [
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
                        pushRoute(context, SystemAppSelector());
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
                ],
              ),

              // --- UI & VISUALS ---
              ExpressiveSettingsGroup(
                title: isSearching ? null : 'Interface & Visuals',
                children: [
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
                  if (_matches(tr('plusHomeDashboard')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.dashboard_customize_outlined,
                      title: tr('plusHomeDashboard'),
                      subtitle: tr('plusHomeDashboardDescription'),
                      value: settings.plusEnableHomeDashboard,
                      onChanged: (val) => settings.plusEnableHomeDashboard = val,
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
                ],
              ),

              // --- QUICK-ADD FAB MENU ---
              ExpressiveSettingsGroup(
                title: isSearching ? null : tr('fabMenuItems'),
                children: [
                  if (_matches(tr('fabShowSearch')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.search_rounded,
                      title: tr('fabShowSearch'),
                      subtitle: tr('fabShowSearchDescription'),
                      value: settings.plusFabShowSearch,
                      onChanged: (val) => settings.plusFabShowSearch = val,
                    ),
                  if (_matches(tr('fabShowAddByUrl')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.link_outlined,
                      title: tr('fabShowAddByUrl'),
                      subtitle: tr('fabShowAddByUrlDescription'),
                      value: settings.plusFabShowAddByUrl,
                      onChanged: (val) => settings.plusFabShowAddByUrl = val,
                    ),
                  if (_matches(tr('fabShowGithubStarred')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.star_border_rounded,
                      title: tr('fabShowGithubStarred'),
                      subtitle: tr('fabShowGithubStarredDescription'),
                      value: settings.plusFabShowGithubStarred,
                      onChanged: (val) => settings.plusFabShowGithubStarred = val,
                    ),
                  if (_matches(tr('fabShowGithubPersonalRepos')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.person_outline_rounded,
                      title: tr('fabShowGithubPersonalRepos'),
                      subtitle: tr('fabShowGithubPersonalReposDescription'),
                      value: settings.plusFabShowGithubPersonalRepos,
                      onChanged: (val) => settings.plusFabShowGithubPersonalRepos = val,
                    ),
                  if (_matches(tr('fabShowImportInstalled')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.install_mobile_outlined,
                      title: tr('fabShowImportInstalled'),
                      subtitle: tr('fabShowImportInstalledDescription'),
                      value: settings.plusFabShowImportInstalled,
                      onChanged: (val) => settings.plusFabShowImportInstalled = val,
                    ),
                ],
              ),

              // --- ADVANCED CUSTOMIZATION (Expandable) ---
              ExpressiveSettingsGroup(
                title: isSearching ? null : 'Organization & Sorting',
                children: [
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
                      icon: Icons.back_hand_outlined,
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
                ],
              ),
            ],
          ],
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
