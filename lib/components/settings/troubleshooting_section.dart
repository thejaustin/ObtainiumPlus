import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:provider/provider.dart';

/// Section for system settings shortcuts and troubleshooting
class TroubleshootingSection extends StatelessWidget {
  final String? searchQuery;
  const TroubleshootingSection({super.key, this.searchQuery});

  bool _matches(String text) {
    if (searchQuery == null || searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery!.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    final items = [
      if (_matches(tr('openAppInfo')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.info_outlined,
          title: tr('openAppInfo'),
          onTap: () => AppInstallService.openAppSettings(obtainiumId),
        ),
      if (_matches(tr('notificationSettings')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.notifications_active_outlined,
          title: tr('notificationSettings'),
          onTap: () => AppInstallService.openNotificationSettings(obtainiumId),
        ),
      if (_matches(tr('batteryOptimizationSettings')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.battery_saver_outlined,
          title: tr('batteryOptimizationSettings'),
          onTap: () => AppInstallService.openBatteryOptimizationSettings(),
        ),
      if (_matches(tr('installUnknownApps')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.install_mobile_outlined,
          title: tr('installUnknownApps'),
          onTap: () =>
              AppInstallService.openInstallUnknownAppsSettings(obtainiumId),
        ),
      if (_matches(tr('overlaySettings')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.layers_outlined,
          title: tr('overlaySettings'),
          onTap: () => AppInstallService.openOverlaySettings(obtainiumId),
        ),
      if (_matches(tr('usageAccessSettings')))
        _buildSystemShortcutTile(
          context,
          icon: Icons.insights_outlined,
          title: tr('usageAccessSettings'),
          onTap: () => AppInstallService.openUsageAccessSettings(),
        ),
      if (!context.watch<SettingsProvider>().plusDeveloperMode)
        ListTile(
          leading: Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            tr('lookingForDevOptions'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(tr('devOptionsHint')),
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return SettingsGroup(
      title: isSearching ? null : tr('troubleshootingAndSystem'),
      children: items,
    );
  }

  Widget _buildSystemShortcutTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () {
        AppHaptics.lightImpact();
        onTap();
      },
    );
  }
}
