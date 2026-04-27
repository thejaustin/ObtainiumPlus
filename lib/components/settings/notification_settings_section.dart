import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/settings/settings_group.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: tr('notifications'),
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              children: [
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.mark_email_unread_outlined),
                  title: Text(tr('enableNotificationDigest'), style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text(tr('notificationDigestDescription')),
                  value: settings.plusEnableNotificationDigest,
                  onChanged: (val) => settings.plusEnableNotificationDigest = val,
                ),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.do_not_disturb_on_outlined),
                  title: Text(tr('enableQuietHours'), style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text(tr('quietHoursDescription')),
                  value: settings.plusEnableNotificationQuietHours,
                  onChanged: (val) => settings.plusEnableNotificationQuietHours = val,
                ),
                if (settings.plusEnableNotificationQuietHours)
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(tr('quietHoursSchedule'), style: Theme.of(context).textTheme.bodyLarge),
                    subtitle: Text('${settings.plusNotificationQuietHoursStart}:00 - ${settings.plusNotificationQuietHoursEnd}:00'),
                    onTap: () => _showQuietHoursDialog(context, settings),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showQuietHoursDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('quietHoursSchedule')),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(tr('start')),
                            DropdownButton<int>(
                              value: settings.plusNotificationQuietHoursStart,
                              onChanged: (val) {
                                if (val != null) {
                                  settings.plusNotificationQuietHoursStart = val;
                                  setDialogState(() {});
                                }
                              },
                              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(tr('end')),
                            DropdownButton<int>(
                              value: settings.plusNotificationQuietHoursEnd,
                              onChanged: (val) {
                                if (val != null) {
                                  settings.plusNotificationQuietHoursEnd = val;
                                  setDialogState(() {});
                                }
                              },
                              items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('done')),
            ),
          ],
        );
      },
    );
  }
}
