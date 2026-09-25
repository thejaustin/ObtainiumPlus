import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';
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

  String _formatHour(int hour) {
    final h = hour % 24;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final padded24 = h.toString().padLeft(2, '0');
    return '$displayHour:00 $period ($padded24:00)';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;

    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        final List<Widget> children = [
          if (_matches(tr('notificationSettings')))
            ScaleTouchWrapper(
              onTap: () {
                AppHaptics.selectionClick();
                AppInstallService.openNotificationSettings(
                  AppConstants.obtainiumPlusId,
                );
              },
              child: ListTile(
                leading: Icon(
                  Icons.notifications_active_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  tr('notificationSettings'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              ),
            ),
          if (settings.enableAllPlusFeatures) ...[
            if (_matches(tr('plusEnableNotificationEnhancements')))
              SwitchListTile.adaptive(
                secondary: Icon(
                  settings.plusEnableNotificationEnhancements
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_active_outlined,
                  color: settings.plusEnableNotificationEnhancements
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(
                  tr('plusEnableNotificationEnhancements'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(
                  tr('plusEnableNotificationEnhancementsDescription'),
                ),
                value: settings.plusEnableNotificationEnhancements,
                onChanged: (val) {
                  AppHaptics.selectionClick();
                  settings.plusEnableNotificationEnhancements = val;
                },
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              child: !settings.plusEnableNotificationEnhancements
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        tr('noAdvancedNotifications'),
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_matches(tr('enableNotificationDigest')) ||
                            _matches(tr('enableQuietHours')))
                          GenericBooleanControlGrid<PlusSettingsProvider>(
                            title: tr('settingsTabNotifications'),
                            settings: [
                              if (_matches(tr('enableNotificationDigest')))
                                (
                                  icon: Icons.mark_email_unread_outlined,
                                  label: tr('enableNotificationDigest'),
                                  description:
                                      tr('notificationDigestDescription'),
                                  getValue: (s) =>
                                      s.plusEnableNotificationDigest,
                                  setValue: (s, v) =>
                                      s.plusEnableNotificationDigest = v,
                                ),
                              if (_matches(tr('enableQuietHours')))
                                (
                                  icon: Icons.do_not_disturb_on_outlined,
                                  label: tr('enableQuietHours'),
                                  description: tr('quietHoursDescription'),
                                  getValue: (s) =>
                                      s.plusEnableNotificationQuietHours,
                                  setValue: (s, v) =>
                                      s.plusEnableNotificationQuietHours = v,
                                ),
                            ],
                          ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutCubic,
                          child: settings.plusEnableNotificationQuietHours &&
                                  _matches(tr('quietHoursSchedule'))
                              ? ScaleTouchWrapper(
                                  onTap: () {
                                    AppHaptics.selectionClick();
                                    _showQuietHoursDialog(context, settings);
                                  },
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.schedule_outlined,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Text(
                                      tr('quietHoursSchedule'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                    subtitle: Text(
                                      '${_formatHour(settings.plusNotificationQuietHoursStart)} — ${_formatHour(settings.plusNotificationQuietHoursEnd)}',
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
            ),
          ],
        ];

        if (children.isEmpty) return const SizedBox.shrink();

        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('notifications'),
          persistKey: 'notifications',
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
    final colorScheme = Theme.of(context).colorScheme;
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr('quietHoursDescription'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('start'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value:
                                      settings.plusNotificationQuietHoursStart,
                                  onChanged: (val) {
                                    if (val != null) {
                                      AppHaptics.selectionClick();
                                      settings
                                          .plusNotificationQuietHoursStart = val;
                                      setDialogState(() {});
                                    }
                                  },
                                  items: List.generate(
                                    24,
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        _formatHour(i),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('end'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  isExpanded: true,
                                  value: settings.plusNotificationQuietHoursEnd,
                                  onChanged: (val) {
                                    if (val != null) {
                                      AppHaptics.selectionClick();
                                      settings.plusNotificationQuietHoursEnd =
                                          val;
                                      setDialogState(() {});
                                    }
                                  },
                                  items: List.generate(
                                    24,
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        _formatHour(i),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
              onPressed: () {
                AppHaptics.selectionClick();
                Navigator.pop(context);
              },
              child: Text(tr('done')),
            ),
          ],
        );
      },
    );
  }
}
