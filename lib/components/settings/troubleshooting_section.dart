import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:provider/provider.dart';

/// Section for system settings shortcuts and troubleshooting
class TroubleshootingSection extends StatelessWidget {
  const TroubleshootingSection({super.key});

  Future<void> _openWithGuidance(
    BuildContext context, {
    required VoidCallback action,
    bool Function(String manufacturer)? condition,
    String? titleKey,
    String? messageKey,
  }) async {
    if (condition != null && titleKey != null && messageKey != null) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      
      // Check for manufacturer overrides (e.g. Xiaomi uses "redmi" or "poco" sometimes)
      final isXiaomi = manufacturer.contains('xiaomi') || 
                       manufacturer.contains('redmi') || 
                       manufacturer.contains('poco');
                       
      // Pass the refined manufacturer check to the condition
      if (context.mounted && condition(isXiaomi ? 'xiaomi' : manufacturer)) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr(titleKey) ?? 'Notice'),
            content: Text(tr(messageKey) ?? 'Please follow the instructions.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  action();
                },
                child: Text(tr('openSettings')),
              ),
            ],
          ),
        );
        return;
      }
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    const height8 = SizedBox(height: 8);
    const height16 = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          onTap: () => _openWithGuidance(
            context,
            action: () => AppInstallService.openBatteryOptimizationSettings(),
            condition: (m) => m == 'xiaomi',
            titleKey: 'xiaomiTroubleshootingTitle',
            messageKey: 'xiaomiTroubleshootingDescription',
          ),
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
          onTap: () => _openWithGuidance(
            context,
            action: () => AppInstallService.openUsageAccessSettings(),
            condition: (m) => m.contains('samsung'),
            titleKey: 'samsungUsageAccessTitle',
            messageKey: 'samsungUsageAccessMessage',
          ),
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
