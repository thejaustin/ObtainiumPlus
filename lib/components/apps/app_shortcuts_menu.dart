import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/category_editor_selector.dart';
import 'package:obtainium/components/tag_editor.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:obtainium/utils/app_constants.dart';

/// Context menu sheet shown on long-press of an app in grid or list view.
void showAppShortcutsMenu(
  BuildContext context, {
  required String appId,
  required String appUrl,
  required VoidCallback onToggleSelected,
}) {
  final appsProvider = context.read<AppsProvider>();
  final appInMemory = appsProvider.apps[appId];
  if (appInMemory == null) return;
  final settings = context.watch<SettingsProvider>();
  final enableGlass = settings.plusEnableGlassmorphism;
  final colorScheme = Theme.of(context).colorScheme;

  AppHaptics.heavyImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final sheet = Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(enableGlass ? 0.78 : 1.0),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: enableGlass
              ? Border(
                  top: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.18),
                  ),
                  left: BorderSide(
                    color: colorScheme.onSurface.withOpacity(AppOpacity.hint),
                  ),
                  right: BorderSide(
                    color: colorScheme.onSurface.withOpacity(AppOpacity.hint),
                  ),
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragHandle(margin: EdgeInsets.only(top: 8, bottom: 8)),

              // Header with App Name
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  appInMemory.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.launch_outlined),
                title: Text(tr('launch')),
                onTap: () {
                  Navigator.pop(ctx);
                  AppInstallService.openApp(appId);
                },
              ),

              ListTile(
                leading: const Icon(Icons.system_update_outlined),
                title: Text(tr('update')),
                enabled:
                    appInMemory.app.installedVersion !=
                    appInMemory.app.latestVersion,
                onTap: () {
                  Navigator.pop(ctx);
                  appsProvider.downloadAndInstallLatestApps([appId], context);
                },
              ),

              ListTile(
                leading: Icon(
                  appInMemory.app.pinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin,
                ),
                title: Text(appInMemory.app.pinned ? tr('unpin') : tr('pin')),
                onTap: () {
                  Navigator.pop(ctx);
                  appInMemory.app.pinned = !appInMemory.app.pinned;
                  appsProvider.saveApps([appInMemory.app]);
                },
              ),

              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(tr('categorize')),
                onTap: () async {
                  Navigator.pop(ctx);
                  final newCategories = await showDialog<Set<String>>(
                    context: context,
                    builder: (dCtx) => GlassDialog(
                      title: tr('categorize'),
                      icon: Icons.category_outlined,
                      content: SizedBox(
                        width: double.maxFinite,
                        child: SingleChildScrollView(
                          child: CategoryEditorSelector(
                            alignment: WrapAlignment.start,
                            preselected: appInMemory.app.categories.toSet(),
                            onSelected: (categories) =>
                                Navigator.pop(dCtx, categories),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: Text(tr('cancel')),
                        ),
                      ],
                    ),
                  );
                  if (newCategories != null) {
                    appInMemory.app.categories = newCategories.toList();
                    appsProvider.saveApps([appInMemory.app]);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(tr('tags')),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTagEditorStandalone(context, appInMemory);
                },
              ),

              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(tr('editAppSettings')),
                onTap: () {
                  Navigator.pop(ctx);
                  showDraggableModalBottomSheet(
                    context: context,
                    builder: (context, controller) => AppPage(
                      appId: appId,
                      isModal: true,
                      scrollController: controller,
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(tr('share')),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(appUrl);
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.select_all_outlined),
                title: Text(tr('select')),
                onTap: () {
                  Navigator.pop(ctx);
                  onToggleSelected();
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  tr('remove'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  appsProvider.removeAppsWithModal(context, [appInMemory.app]);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (!enableGlass) return sheet;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: sheet,
        ),
      );
    },
  );
}

void _showTagEditorStandalone(
  BuildContext context,
  AppInMemory appInMemory,
) async {
  final appsProvider = context.read<AppsProvider>();
  final allTags = appsProvider
      .getAppValues()
      .expand((a) => a.app.tags)
      .toSet()
      .toList();
  allTags.sort();

  final newTags = await showTagEditor(
    context: context,
    currentTags: appInMemory.app.tags,
    allTags: allTags,
  );

  if (newTags != null) {
    final app = appInMemory.app;
    app.tags = newTags;
    await appsProvider.saveApps([app]);
  }
}
