import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/components/tag_editor.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:share_plus/share_plus.dart';

class AppActionsContextMenu {
  static void show(
    BuildContext context,
    AppInMemory appInMemory, {
    VoidCallback? onEnterMultiSelect,
  }) {
    // Created once so sheet rebuilds don't re-query the platform; uses the
    // cached DeviceUtils lookup (#62).
    final sdkIntFuture = DeviceUtils.getAndroidInfo().then(
      (info) => info.version.sdkInt,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final plusSettings = context.watch<PlusSettingsProvider>();
        final sheetRadius = plusSettings.plusGlobalCornerRadius.clamp(
          16.0,
          32.0,
        );
        final iconRadius = CardMetrics.inner(sheetRadius);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(sheetRadius),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: SingleChildScrollView(
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
                if (appInMemory.app.installedVersion != null &&
                    appInMemory.app.additionalSettings['trackOnly'] != true)
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.97,
                    child: ListTile(
                      leading: const Icon(Icons.launch_rounded),
                      title: Text(tr('launch')),
                      onTap: () {
                        AppHaptics.selectionClick();
                        Navigator.pop(context);
                        AppInstallService.openApp(appInMemory.app.id);
                      },
                    ),
                  ),
                () {
                  final bool isInstalled =
                      appInMemory.app.installedVersion != null;
                  final bool hasUpdate = isInstalled &&
                      appInMemory.app.latestVersion.isNotEmpty &&
                      appInMemory.app.latestVersion !=
                          appInMemory.app.installedVersion;

                  if (hasUpdate) {
                    return ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.97,
                      child: ListTile(
                        leading: Icon(
                          Icons.system_update_alt_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          tr('update'),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${appInMemory.app.installedVersion} → ${appInMemory.app.latestVersion}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        onTap: () {
                          AppHaptics.selectionClick();
                          Navigator.pop(context);
                          context
                              .read<AppsProvider>()
                              .downloadAndInstallLatestApps(
                                [appInMemory.app.id],
                                context,
                              );
                        },
                      ),
                    );
                  } else if (!isInstalled) {
                    return ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.97,
                      child: ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: Text(tr('install')),
                        subtitle: appInMemory.app.latestVersion.isNotEmpty
                            ? Text(
                                appInMemory.app.latestVersion,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                        onTap: () {
                          AppHaptics.selectionClick();
                          Navigator.pop(context);
                          context
                              .read<AppsProvider>()
                              .downloadAndInstallLatestApps(
                                [appInMemory.app.id],
                                context,
                              );
                        },
                      ),
                    );
                  } else {
                    return ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.97,
                      child: ListTile(
                        leading: const Icon(Icons.refresh_rounded),
                        title: Text(tr('install')),
                        subtitle: Text(
                          tr('upToDate'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () {
                          AppHaptics.selectionClick();
                          Navigator.pop(context);
                          context
                              .read<AppsProvider>()
                              .downloadAndInstallLatestApps(
                                [appInMemory.app.id],
                                context,
                              );
                        },
                      ),
                    );
                  }
                }(),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.97,
                  child: ListTile(
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
                ),
                if (plusSettings.plusEnableTags)
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.97,
                    child: ListTile(
                      leading: const Icon(Icons.label_outline_rounded),
                      title: Text(tr('editTags')),
                      subtitle: appInMemory.app.tags.isNotEmpty
                          ? Text(
                              appInMemory.app.tags.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      onTap: () async {
                        AppHaptics.selectionClick();
                        Navigator.pop(context);
                        final appsProvider = context.read<AppsProvider>();
                        final allTags = getAllTagsFromApps(
                          appsProvider.apps.entries.toList(),
                        );
                        final result = await showTagEditor(
                          context: context,
                          currentTags: appInMemory.app.tags,
                          allTags: allTags,
                        );
                        if (result != null) {
                          appInMemory.app.tags = result;
                          appsProvider.saveApps([appInMemory.app]);
                        }
                      },
                    ),
                  ),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.97,
                  child: ListTile(
                    leading: Icon(
                      appInMemory.app.pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      appInMemory.app.pinned ? tr('unpin') : tr('pin'),
                    ),
                    onTap: () {
                      AppHaptics.selectionClick();
                      Navigator.pop(context);
                      final appsProvider = context.read<AppsProvider>();
                      appInMemory.app.pinned = !appInMemory.app.pinned;
                      appsProvider.saveApps([appInMemory.app]);
                    },
                  ),
                ),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.97,
                  child: ListTile(
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
                ),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.97,
                  child: ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: Text(tr('copyAppURL')),
                    onTap: () {
                      AppHaptics.selectionClick();
                      Navigator.pop(context);
                      Clipboard.setData(
                        ClipboardData(text: appInMemory.app.url),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('copiedToClipboard'))),
                      );
                    },
                  ),
                ),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.97,
                  child: ListTile(
                    leading: const Icon(Icons.share_rounded),
                    title: Text(tr('share')),
                    onTap: () {
                      AppHaptics.selectionClick();
                      Navigator.pop(context);
                      Share.share(appInMemory.app.url);
                    },
                  ),
                ),
                if (appInMemory.installedInfo != null)
                  FutureBuilder<int>(
                    future: sdkIntFuture,
                    builder: (context, snapshot) {
                      if ((snapshot.data ?? 0) < 34) {
                        return const SizedBox.shrink();
                      }
                      return ScaleTouchWrapper(
                        hapticOnPressDown: true,
                        scaleDownFactor: 0.97,
                        child: ListTile(
                          leading: const Icon(Icons.archive_outlined),
                          title: Text(tr('archiveApp')),
                          subtitle: Text(tr('archiveAppSubtitle')),
                          onTap: () async {
                            AppHaptics.selectionClick();
                            Navigator.pop(context);
                            final ok = await AppInstallService.requestArchive(
                              appInMemory.app.id,
                            );
                            if (context.mounted && !ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('archiveAppFailed'))),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                if (onEnterMultiSelect != null)
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    scaleDownFactor: 0.97,
                    child: ListTile(
                      leading: const Icon(Icons.checklist_rounded),
                      title: Text(tr('select')),
                      onTap: () {
                        AppHaptics.selectionClick();
                        Navigator.pop(context);
                        onEnterMultiSelect();
                      },
                    ),
                  ),
                const Divider(height: 1),
                ScaleTouchWrapper(
                  hapticOnPressDown: true,
                  scaleDownFactor: 0.97,
                  child: ListTile(
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
                      context.read<AppsProvider>().removeAppsWithModal(
                        context,
                        [appInMemory.app],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
