import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';

class AppActionsContextMenu {
  static void show(
    BuildContext context,
    AppInMemory appInMemory, {
    VoidCallback? onEnterMultiSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final plusSettings = context.watch<PlusSettingsProvider>();
        final sheetRadius = plusSettings.plusGlobalCornerRadius.clamp(
          16.0,
          32.0,
        );
        final iconRadius = CardMetrics.inner(sheetRadius);

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(sheetRadius),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(iconRadius),
                        ),
                        child: Icon(
                          Icons.apps_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appInMemory.app.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              appInMemory.app.author,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Actions
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: Text(tr('update')),
                  onTap: () {
                    AppHaptics.selectionClick();
                    Navigator.pop(context);
                    context.read<AppsProvider>().downloadAndInstallLatestApps([
                      appInMemory.app.id,
                    ], context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(tr('editApp')),
                  onTap: () {
                    AppHaptics.selectionClick();
                    Navigator.pop(context);
                    showAddAppSheet(
                      context: context,
                      appId: appInMemory.app.id,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    appInMemory.app.pinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(appInMemory.app.pinned ? tr('unpin') : tr('pin')),
                  onTap: () {
                    AppHaptics.selectionClick();
                    Navigator.pop(context);
                    final appsProvider = context.read<AppsProvider>();
                    appInMemory.app.pinned = !appInMemory.app.pinned;
                    appsProvider.saveApps([appInMemory.app]);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(tr('systemSettings')),
                  onTap: () {
                    AppHaptics.selectionClick();
                    Navigator.pop(context);
                    context.read<AppsProvider>().openAppSettings(
                      appInMemory.app.id,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(tr('copyAppURL')),
                  onTap: () {
                    AppHaptics.selectionClick();
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: appInMemory.app.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('copiedToClipboard'))),
                    );
                  },
                ),
                if (onEnterMultiSelect != null)
                  ListTile(
                    leading: const Icon(Icons.checklist_rounded),
                    title: Text(tr('select')),
                    onTap: () {
                      AppHaptics.selectionClick();
                      Navigator.pop(context);
                      onEnterMultiSelect();
                    },
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    tr('remove'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    AppHaptics.heavyImpact();
                    Navigator.pop(context);
                    context.read<AppsProvider>().removeAppsWithModal(context, [
                      appInMemory.app,
                    ]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
