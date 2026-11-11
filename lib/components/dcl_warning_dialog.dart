import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// One-time explanation shown when Android blocks dynamic code loading and
/// Obtainium+ therefore uses the dart:io network client.
class DclWarningDialog extends StatelessWidget {
  const DclWarningDialog({
    super.key,
    required this.onOpenSettings,
    this.autofocus = false,
  });

  final VoidCallback onOpenSettings;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('androidCertStoreWarningTitle')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('androidCertStoreWarningP1')),
          const SizedBox(height: 12),
          Text(tr('androidCertStoreWarningP2')),
          const SizedBox(height: 12),
          Text(tr('androidCertStoreWarningP3')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('ok')),
        ),
        FilledButton.tonal(
          autofocus: autofocus,
          onPressed: () {
            Navigator.of(context).pop();
            onOpenSettings();
          },
          child: Text(tr('openAppSettings')),
        ),
      ],
    );
  }
}
