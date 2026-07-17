import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

class NotificationSettingsSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;
  const NotificationSettingsSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

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
        final List<Widget> children = [
          if (!settings.plusEnableNotificationEnhancements)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                tr('noAdvancedNotifications'),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          if (settings.plusEnableNotificationEnhancements) ...[
            if (_matches(tr('enableNotificationDigest')))
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.mark_email_unread_outlined),
                title: Text(
                  tr('enableNotificationDigest'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(tr('notificationDigestDescription')),
                value: settings.plusEnableNotificationDigest,
                onChanged: (val) => settings.plusEnableNotificationDigest = val,
              ),
            if (_matches(tr('enableQuietHours')))
              SwitchListTile.adaptive(
                secondary: const Icon(Icons.do_not_disturb_on_outlined),
                title: Text(
                  tr('enableQuietHours'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(tr('quietHoursDescription')),
                value: settings.plusEnableNotificationQuietHours,
                onChanged: (val) =>
                    settings.plusEnableNotificationQuietHours = val,
              ),
            if (settings.plusEnableNotificationQuietHours &&
                _matches(tr('quietHoursSchedule')))
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(
                  tr('quietHoursSchedule'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(
                  '${settings.plusNotificationQuietHoursStart}:00 - ${settings.plusNotificationQuietHoursEnd}:00',
                ),
                onTap: () => _showQuietHoursDialog(context, settings),
              ),
          ],
        ];

        if (children.isEmpty) return const SizedBox.shrink();

        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('notifications'),
          icon: Icons.notifications_active_rounded,
          isExpandable: !isSearching,
          initiallyExpanded: false,
          children: children,
        );
      },
    );
  }

  void _showQuietHoursDialog(
    BuildContext context,
    PlusSettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return GlassDialog(
          title: tr('quietHoursSchedule'),
          icon: Icons.schedule_outlined,
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
                                  settings.plusNotificationQuietHoursStart =
                                      val;
                                  setDialogState(() {});
                                }
                              },
                              items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('$i:00'),
                                ),
                              ),
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
                              items: List.generate(
                                24,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('$i:00'),
                                ),
                              ),
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
