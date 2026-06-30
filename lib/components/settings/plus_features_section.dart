import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/pages/system_app_selector.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:provider/provider.dart';

class PlusFeaturesSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const PlusFeaturesSection({super.key, this.searchQuery, this.showAdvancedSettings});

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(showAdvancedSettings ?? false)) return false;
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            // Master toggle in its own expressive card
            ExpressiveSettingsGroup(
              title: isSearching ? null : tr('plusFeatures'),
              icon: Icons.auto_awesome_rounded,
              isExpandable: !isSearching,
              initiallyExpanded: true,
              helpText: tr('plusFeaturesHelp'),
              onReset: () {
                AppHaptics.heavyImpact();
                settings.enableAllPlusFeatures = true;
                // Add more specific resets if needed
              },
              children: [
                if (_matches(tr('enableAllPlusFeatures')))
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.auto_awesome),
                    title: Text(
                      tr('enableAllPlusFeatures'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(tr('enableAllPlusFeaturesDescription')),
                    value: settings.enableAllPlusFeatures,
                    onChanged: (value) =>
                        settings.enableAllPlusFeatures = value,
                  ),
              ],
            ),

            if (settings.enableAllPlusFeatures) ...[
              // --- APP MANAGEMENT ---
              ExpressiveSettingsGroup(
                title: isSearching ? null : tr('appManagement'),
                icon: Icons.manage_accounts_rounded,
                isExpandable: true,
                initiallyExpanded: false,
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
                      title: Text(
                        tr('importInstalledApps'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(tr('importInstalledAppsDescription')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppHaptics.selectionClick();
                        pushRoute(context, SystemAppSelector());
                      },
                    ),
                  if (_matches(tr('plusSystemUpdateScanner'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.system_update_alt_rounded,
                      title: tr('plusSystemUpdateScanner'),
                      subtitle: tr('plusSystemUpdateScannerDescription'),
                      value: settings.plusEnableSystemUpdateScanner,
                      onChanged: (val) =>
                          settings.plusEnableSystemUpdateScanner = val,
                      experimental: true,
                    ),
                  if (_matches(tr('plusEnableMicroGHub'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.hub_outlined,
                      title: tr('plusEnableMicroGHub'),
                      subtitle: tr('plusEnableMicroGHubDescription'),
                      value: settings.plusEnableMicroGHub,
                      onChanged: (val) => settings.plusEnableMicroGHub = val,
                    ),
                  if (_matches(tr('plusEnableStandaloneInstaller')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.install_mobile_outlined,
                      title: tr('plusEnableStandaloneInstaller'),
                      subtitle: tr('plusEnableStandaloneInstallerDescription'),
                      value: settings.plusEnableStandaloneInstaller,
                      onChanged: (val) =>
                          settings.plusEnableStandaloneInstaller = val,
                    ),
                  if (_matches(tr('plusUpdateSchedule')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.schedule_outlined,
                      title: tr('plusUpdateSchedule'),
                      subtitle: tr('plusUpdateScheduleDescription'),
                      value: settings.plusEnableUpdateSchedule,
                      onChanged: (val) =>
                          settings.plusEnableUpdateSchedule = val,
                    ),
                  if (_matches(tr('plusEnableAutoUpdateRules')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.rule_outlined,
                      title: tr('plusEnableAutoUpdateRules'),
                      subtitle: tr('plusEnableAutoUpdateRulesDescription'),
                      value: settings.plusEnableAutoUpdateRules,
                      onChanged: (val) =>
                          settings.plusEnableAutoUpdateRules = val,
                    ),
                  if (_matches(tr('backupEncryption'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.enhanced_encryption_outlined,
                      title: tr('backupEncryption'),
                      subtitle: tr('backupEncryptionDescription'),
                      value: settings.backupEncryptionEnabled,
                      onChanged: (val) =>
                          settings.backupEncryptionEnabled = val,
                    ),
                  if (_matches(tr('plusSmartRetries'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.bolt_outlined,
                      title: tr('plusSmartRetries'),
                      subtitle: tr('plusSmartRetriesDescription'),
                      value: settings.plusEnableSmartRetries,
                      onChanged: (val) => settings.plusEnableSmartRetries = val,
                    ),
                  if (_matches(tr('plusUpdateOwnership'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.security_update_good_rounded,
                      title: tr('plusUpdateOwnership'),
                      subtitle: tr('plusUpdateOwnershipDescription'),
                      value: settings.plusEnableUpdateOwnership,
                      onChanged: (val) =>
                          settings.plusEnableUpdateOwnership = val,
                    ),
                  if (_matches(tr('plusUserPreapproval'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.touch_app_outlined,
                      title: tr('plusUserPreapproval'),
                      subtitle: tr('plusUserPreapprovalDescription'),
                      value: settings.plusEnableUserPreapproval,
                      onChanged: (val) =>
                          settings.plusEnableUserPreapproval = val,
                    ),
                ],
              ),

              // --- NOTIFICATIONS ---
              ExpressiveSettingsGroup(
                title: isSearching ? null : tr('notifications'),
                icon: Icons.notifications_active_rounded,
                isExpandable: true,
                initiallyExpanded: false,
                children: [
                  if (_matches(tr('plusEnableNotificationEnhancements')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.notifications_active_outlined,
                      title: tr('plusEnableNotificationEnhancements'),
                      subtitle: tr(
                        'plusEnableNotificationEnhancementsDescription',
                      ),
                      value: settings.plusEnableNotificationEnhancements,
                      onChanged: (val) =>
                          settings.plusEnableNotificationEnhancements = val,
                    ),
                ],
              ),

              // --- UI & VISUALS ---
              ExpressiveSettingsGroup(
                title: isSearching ? null : tr('plusSectionInterfaceVisuals'),
                icon: Icons.face_retouching_natural_rounded,
                isExpandable: true,
                initiallyExpanded: false,
                children: [
                  if (_matches(tr('plusEnhancedAnimations')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.auto_awesome_motion_rounded,
                      title: tr('plusEnhancedAnimations'),
                      subtitle: tr('plusEnhancedAnimationsDescription'),
                      value: settings.plusEnableEnhancedAnimations,
                      onChanged: (val) =>
                          settings.plusEnableEnhancedAnimations = val,
                    ),
                  if (_matches(tr('plusShowStatusHub')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.info_outline_rounded,
                      title: tr('plusShowStatusHub'),
                      subtitle: tr('plusShowStatusHubDescription'),
                      value: settings.plusShowStatusHub,
                      onChanged: (val) => settings.plusShowStatusHub = val,
                    ),
                  if (_matches(tr('plusHomeDashboard')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.dashboard_customize_outlined,
                      title: tr('plusHomeDashboard'),
                      subtitle: tr('plusHomeDashboardDescription'),
                      value: settings.plusEnableHomeDashboard,
                      onChanged: (val) =>
                          settings.plusEnableHomeDashboard = val,
                    ),
                ],
              ),

              // --- QUICK-ADD FAB MENU ---
              GenericBooleanControlGrid<PlusSettingsProvider>(
                title: tr('fabMenuItems'),
                settings: [
                  if (_matches(tr('fabShowSearch')))
                    (
                      icon: Icons.search_rounded,
                      label: tr('fabShowSearch'),
                      description: tr('fabShowSearchDescription'),
                      getValue: (s) => s.plusFabShowSearch,
                      setValue: (s, v) => s.plusFabShowSearch = v,
                    ),
                  if (_matches(tr('fabShowAddByUrl')))
                    (
                      icon: Icons.link_outlined,
                      label: tr('fabShowAddByUrl'),
                      description: tr('fabShowAddByUrlDescription'),
                      getValue: (s) => s.plusFabShowAddByUrl,
                      setValue: (s, v) => s.plusFabShowAddByUrl = v,
                    ),
                  if (_matches(tr('fabShowGithubStarred')))
                    (
                      icon: Icons.star_border_rounded,
                      label: tr('fabShowGithubStarred'),
                      description: tr('fabShowGithubStarredDescription'),
                      getValue: (s) => s.plusFabShowGithubStarred,
                      setValue: (s, v) => s.plusFabShowGithubStarred = v,
                    ),
                  if (_matches(tr('fabShowGithubPersonalRepos')))
                    (
                      icon: Icons.person_outline_rounded,
                      label: tr('fabShowGithubPersonalRepos'),
                      description: tr('fabShowGithubPersonalReposDescription'),
                      getValue: (s) => s.plusFabShowGithubPersonalRepos,
                      setValue: (s, v) => s.plusFabShowGithubPersonalRepos = v,
                    ),
                  if (_matches(tr('fabShowImportInstalled')))
                    (
                      icon: Icons.install_mobile_outlined,
                      label: tr('fabShowImportInstalled'),
                      description: tr('fabShowImportInstalledDescription'),
                      getValue: (s) => s.plusFabShowImportInstalled,
                      setValue: (s, v) => s.plusFabShowImportInstalled = v,
                    ),
                ],
              ),

              // --- ADVANCED CUSTOMIZATION (Expandable) ---
              ExpressiveSettingsGroup(
                title: isSearching
                    ? null
                    : tr('plusSectionOrganizationSorting'),
                icon: Icons.sort_rounded,
                isExpandable: true,
                initiallyExpanded: false,
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
                  if (_matches(tr('plusShowTagsInList')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.label_outline,
                      title: tr('plusShowTagsInList'),
                      subtitle: tr('plusShowTagsInListDescription'),
                      value: settings.plusShowTagsInList,
                      onChanged: (val) => settings.plusShowTagsInList = val,
                    ),
                  if (_matches(tr('plusEnableTags')))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.label_important_outline,
                      title: tr('plusEnableTags'),
                      subtitle: tr('plusEnableTagsDescription'),
                      value: settings.plusEnableTags,
                      onChanged: (val) => settings.plusEnableTags = val,
                    ),
                  if (_matches(tr('plusAdvancedSorting'), isAdvanced: true))
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.sort_rounded,
                      title: tr('plusAdvancedSorting'),
                      subtitle: tr('plusAdvancedSortingDescription'),
                      value: settings.plusEnableAdvancedSorting,
                      onChanged: (val) =>
                          settings.plusEnableAdvancedSorting = val,
                    ),
                  if (_matches(tr('plusEnableBanWarnings'), isAdvanced: true)) ...[
                    _buildFeatureToggle(
                      context,
                      settings,
                      icon: Icons.warning_amber_rounded,
                      title: tr('plusEnableBanWarnings'),
                      subtitle: tr('plusEnableBanWarningsDescription'),
                      value: settings.plusEnableBanWarnings,
                      onChanged: (val) async {
                        if (val) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => GlassDialog(
                              title: tr('plusEnableBanWarnings'),
                              icon: Icons.warning_amber_rounded,
                              content: Text(tr('plusEnableBanWarningsDescription')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(tr('cancel')),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(tr('enable')),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            settings.plusEnableBanWarnings = true;
                          }
                        } else {
                          settings.plusEnableBanWarnings = false;
                        }
                      },
                    ),
                    if (settings.plusEnableBanWarnings)
                      Padding(
                        padding: const EdgeInsets.only(left: 72.0, right: 24.0, bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('plusBanWarningThresholdDescription', args: [settings.plusBanWarningThreshold.toString()]),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: settings.plusBanWarningThreshold.toDouble(),
                                    min: 1,
                                    max: 50,
                                    divisions: 49,
                                    label: settings.plusBanWarningThreshold.toString(),
                                    onChanged: (val) {
                                      settings.plusBanWarningThreshold = val.round();
                                    },
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    settings.plusBanWarningThreshold.toString(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
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
    PlusSettingsProvider settings, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool experimental = false, bool isAdvanced = false,
  }) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon),
      title: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          ),
          if (experimental)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(
                  settings.plusGlobalCornerRadius.clamp(0.0, 12.0),
                ),
              ),
              child: Text(
                tr('beta'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
