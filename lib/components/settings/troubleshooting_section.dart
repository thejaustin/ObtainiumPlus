import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:provider/provider.dart';

/// Section for system settings shortcuts and troubleshooting
class TroubleshootingSection extends StatelessWidget {
  const TroubleshootingSection({super.key});

  @override
  Widget build(BuildContext context) {
    const height8 = SizedBox(height: 8);
    const height16 = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('troubleshootingAndSystem'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        height8,
        _buildSystemShortcutTile(
          context,
          icon: Icons.info_outlined,
          title: tr('openAppInfo'),
          onTap: () => AppInstallService.openAppSettings(obtainiumId),
        ),
        _buildSystemShortcutTile(
          context,
          icon: Icons.notifications_active_outlined,
          title: tr('notificationSettings'),
          onTap: () => AppInstallService.openNotificationSettings(obtainiumId),
        ),
        _buildSystemShortcutTile(
          context,
          icon: Icons.battery_saver_outlined,
          title: tr('batteryOptimizationSettings'),
          onTap: () => AppInstallService.openBatteryOptimizationSettings(),
        ),
        _buildSystemShortcutTile(
          context,
          icon: Icons.install_mobile_outlined,
          title: tr('installUnknownApps'),
          onTap: () => AppInstallService.openInstallUnknownAppsSettings(obtainiumId),
        ),
        _buildSystemShortcutTile(
          context,
          icon: Icons.layers_outlined,
          title: tr('overlaySettings'),
          onTap: () => AppInstallService.openOverlaySettings(obtainiumId),
        ),
        _buildSystemShortcutTile(
          context,
          icon: Icons.insights_outlined,
          title: tr('usageAccessSettings'),
          onTap: () => AppInstallService.openUsageAccessSettings(),
        ),
      ],
    );
  }

  Widget _buildSystemShortcutTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
