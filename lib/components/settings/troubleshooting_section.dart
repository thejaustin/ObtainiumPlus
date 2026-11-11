import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/nav_helper.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/startup_repair_service.dart';
import 'package:obtainium/pages/statistics.dart';
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/pages/developer_settings.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';

/// Section for system settings shortcuts and troubleshooting
class TroubleshootingSection extends StatefulWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  /// Rows from other sections that belong under Troubleshooting (deep
  /// logging, touch-target highlight); listed before the cache tiles.
  final List<Widget> extraRows;

  const TroubleshootingSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
    this.extraRows = const [],
  });

  @override
  State<TroubleshootingSection> createState() => _TroubleshootingSectionState();
}

class _TroubleshootingSectionState extends State<TroubleshootingSection> {
  int _devModeTapCount = 0;

  bool _matches(String text, {bool isAdvanced = false, String? desc}) {
    if (isAdvanced && !(widget.showAdvancedSettings ?? false)) return false;
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) return true;
    final q = widget.searchQuery!.toLowerCase();
    return text.toLowerCase().contains(q) ||
        (desc != null && desc.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching =
        widget.searchQuery != null && widget.searchQuery!.isNotEmpty;
    final plusSettings = context.watch<PlusSettingsProvider>();

    final items = [
      if (_matches(tr('openAppInfo')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.info_outlined,
          title: tr('openAppInfo'),
          onTap: () =>
              AppInstallService.openAppSettings(AppConstants.obtainiumPlusId),
        ),
      if (_matches(tr('overlaySettings')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.layers_outlined,
          title: tr('overlaySettings'),
          onTap: () => AppInstallService.openOverlaySettings(
            AppConstants.obtainiumPlusId,
          ),
        ),
      if (_matches(tr('usageAccessSettings')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.insights_outlined,
          title: tr('usageAccessSettings'),
          onTap: () => AppInstallService.openUsageAccessSettings(),
        ),
      if (_matches(tr('appLogs'), desc: tr('appLogsDescription')))
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          child: ListTile(
            leading: buildSettingsIconBadge(context, Icons.bug_report_outlined),
            title: Text(tr('appLogs')),
            subtitle: Text(tr('appLogsDescription')),
            onTap: () {
              AppHaptics.selectionClick();
              NavHelper.pushLogsPage(context);
            },
          ),
        ),
      if (_matches(tr('statistics'), desc: tr('statisticsDescription')))
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          child: ListTile(
            leading: buildSettingsIconBadge(context, Icons.bar_chart_rounded),
            title: Text(tr('statistics')),
            subtitle: Text(tr('statisticsDescription')),
            onTap: () {
              AppHaptics.selectionClick();
              pushRoute(context, const StatisticsPage());
            },
          ),
        ),
      if (_matches(tr('viewChangelog'), desc: tr('viewChangelogDescription')))
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          child: ListTile(
            leading: buildSettingsIconBadge(context, Icons.history_edu_rounded),
            title: Text(tr('viewChangelog')),
            subtitle: Text(tr('viewChangelogDescription')),
            onTap: () {
              AppHaptics.selectionClick();
              pushRoute(context, const ChangelogPage());
            },
          ),
        ),
      if (_matches(
        tr('plusShowChangelogAfterUpdate'),
        desc: tr('plusShowChangelogAfterUpdateDescription'),
      ))
        SwitchListTile.adaptive(
          secondary: buildSettingsIconBadge(
            context,
            Icons.new_releases_outlined,
            active: plusSettings.plusShowChangelogAfterUpdate,
          ),
          title: Text(tr('plusShowChangelogAfterUpdate')),
          subtitle: Text(tr('plusShowChangelogAfterUpdateDescription')),
          value: plusSettings.plusShowChangelogAfterUpdate,
          onChanged: (v) {
            v ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
            plusSettings.plusShowChangelogAfterUpdate = v;
          },
        ),
      ...widget.extraRows,
      if (_matches(tr('clearAPKCache'), desc: tr('clearAPKCacheDescription')))
        _buildCleanupTile(
          context,
          icon: Icons.cleaning_services_rounded,
          title: tr('clearAPKCache'),
          subtitle: tr('clearAPKCacheDescription'),
          onTap: () => _clearAPKCache(context),
        ),
      if (_matches(tr('clearIconCache'), desc: tr('clearIconCacheDescription')))
        _buildCleanupTile(
          context,
          icon: Icons.image_not_supported_rounded,
          title: tr('clearIconCache'),
          subtitle: tr('clearIconCacheDescription'),
          onTap: () => _clearIconCache(context),
        ),
    ];

    final developer = [
      if (!plusSettings.plusDeveloperMode &&
          _matches(tr('lookingForDevOptions'), desc: tr('devOptionsHint')))
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          child: ListTile(
            leading: buildSettingsIconBadge(
              context,
              Icons.help_outline,
              active: true,
            ),
            title: Text(tr('lookingForDevOptions')),
            subtitle: Text(tr('devOptionsHint')),
            onTap: () {
              setState(() {
                _devModeTapCount++;
              });
              AppHaptics.lightImpact();
              if (_devModeTapCount >= 7) {
                plusSettings.plusDeveloperMode = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('devOptionsEnabled'))),
                );
              } else if (_devModeTapCount > 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr(
                        'devOptionsStepsAway',
                        args: ['${7 - _devModeTapCount}'],
                      ),
                    ),
                    duration: const Duration(milliseconds: 500),
                  ),
                );
              }
            },
          ),
        ),
      if (plusSettings.plusDeveloperMode &&
          _matches(tr('developerAndDiagnostics')))
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          child: ListTile(
            leading: buildSettingsIconBadge(
              context,
              Icons.developer_mode_rounded,
              active: true,
            ),
            title: Text(tr('developerAndDiagnostics')),
            subtitle: Text(tr('relatedDeveloperDesc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppHaptics.selectionClick();
              pushRoute(context, const DeveloperSettingsPage());
            },
          ),
        ),
    ];

    if (items.isEmpty && developer.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('troubleshootingAndSystem'),
            description: isSearching ? null : tr('troubleshootingGroupDesc'),
            persistKey: 'troubleshootingAndSystem',
            icon: Icons.bug_report_rounded,
            children: items,
          ),
        if (developer.isNotEmpty)
          ExpressiveSettingsGroup(
            title: isSearching ? null : tr('settingsGroupDeveloper'),
            persistKey: 'advanced.developer',
            icon: Icons.developer_mode_rounded,
            children: developer,
          ),
      ],
    );
  }

  Widget _buildCleanupTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      onTap: onTap,
      child: ListTile(
        leading: buildSettingsIconBadge(context, icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  void _clearAPKCache(BuildContext context) async {
    final count = await StartupRepairService.clearAPKCache();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('clearedXAPKs', args: [count.toString()]))),
      );
    }
  }

  void _clearIconCache(BuildContext context) async {
    await StartupRepairService.clearIconCache();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('iconCacheCleared'))));
    }
  }

  Widget _buildSystemShortcutTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Future<void> Function() onTap,
  }) {
    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      onTap: () async {
        try {
          await onTap();
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(tr('error'))));
          }
        }
      },
      child: ListTile(
        leading: buildSettingsIconBadge(context, icon),
        title: Text(title),
        trailing: const Icon(Icons.open_in_new, size: 18),
      ),
    );
  }
}
