import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/url_validator.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/main.dart';

class DeepLinkService {
  DeepLinkService._();

  static Future<void> interpretLink({
    required Uri uri,
    required BuildContext context,
    required Function(String) goToAddApp,
    required AppsProvider appsProvider,
  }) async {
    if (!URLValidator.isValidDeepLink(uri)) {
      showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return GlassDialog(
            title: tr('error'),
            icon: Icons.link_off_outlined,
            content: const Text('Invalid or unauthorized deep link.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(tr('ok')),
              ),
            ],
          );
        },
      );
      return;
    }

    var action = uri.host;
    var data = uri.path.length > 1 ? uri.path.substring(1) : "";
    data = URLValidator.sanitizeInput(data);

    try {
      if (action == 'add') {
        await goToAddApp(data);
      } else if (action == 'app' || action == 'apps') {
        var dataStr = Uri.decodeComponent(data);

        if (!URLValidator.isValidJSONInput(dataStr)) {
          showDialog(
            context: context,
            builder: (BuildContext ctx) {
              return GlassDialog(
                title: tr('error'),
                icon: Icons.warning_amber_outlined,
                content: const Text('Invalid or potentially malicious JSON data.'),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(tr('ok')),
                  ),
                ],
              );
            },
          );
          return;
        }

        if (await showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return GeneratedFormModal(
                  title: tr(
                    'importX',
                    args: [
                      (action == 'app' ? tr('app') : tr('appsString'))
                          .toLowerCase(),
                    ],
                  ),
                  items: const [],
                  additionalWidgets: [
                    ExpansionTile(
                      title: const Text('Raw JSON'),
                      children: [
                        Text(
                          dataStr,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ) !=
            null) {
          var result = await appsProvider.import(
            action == 'app'
                ? '{ "apps": [$dataStr] }'
                : '{ "apps": $dataStr }',
          );
          if (context.mounted) {
            showMessage(
              tr(
                'importedX',
                args: [plural('apps', result.key.length).toLowerCase()],
              ),
              context,
            );
          }
        }
      } else {
        throw ObtainiumError(tr('unknown'));
      }
    } catch (e) {
      if (context.mounted) {
        showError(e, context);
      }
    }
  }
}
