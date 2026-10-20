import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/generic_boolean_control_grid.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
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
              hapticOnPressDown: true,
              onTap: () async {
                try {
                  await AppInstallService.openNotificationSettings(
                    AppConstants.obtainiumPlusId,
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(tr('error'))));
                  }
                }
              },
              child: ListTile(
                leading: buildSettingsIconBadge(
                  context,
                  Icons.notifications_active_outlined,
                  active: true,
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
                secondary: buildSettingsIconBadge(
                  context,
                  settings.plusEnableNotificationEnhancements
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_active_outlined,
                  active: settings.plusEnableNotificationEnhancements,
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
                  val ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                  settings.plusEnableNotificationEnhancements = val;
                },
              ),
            AnimatedSize(
              duration: Duration(
                milliseconds: settings.plusEnableEnhancedAnimations ? 250 : 0,
              ),
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
                            embedded: true,
                            settings: [
                              if (_matches(tr('enableNotificationDigest')))
                                (
                                  icon: Icons.mark_email_unread_outlined,
                                  label: tr('enableNotificationDigest'),
                                  description: tr(
                                    'notificationDigestDescription',
                                  ),
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
                          duration: Duration(
                            milliseconds: settings.plusEnableEnhancedAnimations
                                ? 200
                                : 0,
                          ),
                          curve: Curves.easeInOutCubic,
                          child:
                              settings.plusEnableNotificationQuietHours &&
                                  _matches(tr('quietHoursSchedule'))
                              ? ScaleTouchWrapper(
                                  hapticOnPressDown: true,
                                  onTap: () =>
                                      _showQuietHoursDialog(context, settings),
                                  child: ListTile(
                                    leading: buildSettingsIconBadge(
                                      context,
                                      Icons.schedule_outlined,
                                      active: true,
                                    ),
                                    title: Text(
                                      tr('quietHoursSchedule'),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
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
          description: isSearching ? null : tr('notificationsGroupDesc'),
          persistKey: 'notifications',
          icon: Icons.notifications_active_rounded,
          isExpandable: !isSearching,
          initiallyExpanded: true,
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
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('start'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _formatHour(
                                settings.plusNotificationQuietHoursStart,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Slider(
                              value: settings.plusNotificationQuietHoursStart
                                  .toDouble(),
                              min: 0,
                              max: 23,
                              divisions: 23,
                              onChanged: (val) {
                                AppHaptics.selectionClick();
                                settings.plusNotificationQuietHoursStart = val
                                    .round();
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('end'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _formatHour(
                                settings.plusNotificationQuietHoursEnd,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Slider(
                              value: settings.plusNotificationQuietHoursEnd
                                  .toDouble(),
                              min: 0,
                              max: 23,
                              divisions: 23,
                              onChanged: (val) {
                                AppHaptics.selectionClick();
                                settings.plusNotificationQuietHoursEnd = val
                                    .round();
                                setDialogState(() {});
                              },
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
