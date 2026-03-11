import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Context menu sheet shown on long-press of an app in grid or list view.
void showAppShortcutsMenu(
  BuildContext context, {
  required String appId,
  required String appUrl,
  required VoidCallback onToggleSelected,
}) {
  HapticFeedback.heavyImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DragHandle(margin: EdgeInsets.only(top: 8, bottom: 8)),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(tr('editAppSettings')),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => AppPage(appId: appId, isModal: true),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh_outlined),
            title: Text(tr('forceUpdate')),
            onTap: () {
              Navigator.pop(ctx);
              context
                  .read<AppsProvider>()
                  .downloadAndInstallLatestApps([appId], context, useExisting: false);
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
        ],
      ),
    ),
  );
}
