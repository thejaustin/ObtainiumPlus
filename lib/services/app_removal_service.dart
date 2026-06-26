import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/generated_form.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/models/app.dart';

import 'package:obtainium/services/app_install_service.dart';

class AppRemovalService {
  AppRemovalService._();

  static Future<bool> removeAppsWithModal(
    BuildContext context,
    List<App> apps,
    Future<void> Function(List<String>) removeApps,
    Future<void> Function(List<App>, {bool attemptToCorrectInstallStatus})
    saveApps,
    Future<bool> Function() undoLastRemoval,
    bool enableUndo,
  ) async {
    var showUninstallOption = apps
        .where(
          (a) =>
              a.installedVersion != null &&
              a.additionalSettings['trackOnly'] != true,
        )
        .isNotEmpty;
    var values = await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return GeneratedFormModal(
          primaryActionColour: Theme.of(context).colorScheme.error,
          title: plural('removeAppQuestion', apps.length),
          items: !showUninstallOption
              ? []
              : [
                  [
                    GeneratedFormSwitch(
                      'rmAppEntry',
                      label: tr('removeFromObtainium'),
                      defaultValue: true,
                    ),
                  ],
                  [
                    GeneratedFormSwitch(
                      'uninstallApp',
                      label: tr('uninstallFromDevice'),
                    ),
                  ],
                ],
          initValid: true,
        );
      },
    );
    if (values != null) {
      bool uninstall = values['uninstallApp'] == true && showUninstallOption;
      bool remove = values['rmAppEntry'] == true || !showUninstallOption;
      if (uninstall) {
        for (var i = 0; i < apps.length; i++) {
          if (apps[i].installedVersion != null) {
            AppInstallService.uninstallApp(apps[i].id);
            apps[i].installedVersion = null;
          }
        }
        await saveApps(apps, attemptToCorrectInstallStatus: false);
      }
      if (remove) {
        List<String> appIdsToRemove = apps.map((e) => e.id).toList();
        await removeApps(appIdsToRemove);

        // Show snackbar with undo option if enabled in settings
        if (context.mounted && enableUndo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(plural('appsRemoved', apps.length)),
              action: SnackBarAction(
                label: tr('undo'),
                onPressed: () async {
                  bool success = await undoLastRemoval();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(tr('appsRestored'))));
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      return uninstall || remove;
    }
    return false;
  }
}
