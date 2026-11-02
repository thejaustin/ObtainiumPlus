import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/services/app_variant_service.dart';
import 'package:obtainium/utils/haptic_utils.dart';

/// Result of [showVariantConflictDialog]. [dontAskAgain] only matters for
/// [VariantChoice.keepBoth]; the other choices resolve the conflict.
typedef VariantDecision = ({VariantChoice choice, bool dontAskAgain});

/// Asks what to do when the APK about to be installed is another build of an
/// app that's already installed under a different package name.
Future<VariantDecision> showVariantConflictDialog(
  BuildContext context, {
  required String appName,
  required String apkPackage,
  required InstalledVariant installed,
  required bool canPickOtherFile,
}) async {
  final result = await showDialog<VariantDecision>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _VariantConflictDialog(
      appName: appName,
      apkPackage: apkPackage,
      installed: installed,
      canPickOtherFile: canPickOtherFile,
    ),
  );
  return result ?? (choice: VariantChoice.cancel, dontAskAgain: false);
}

class _VariantConflictDialog extends StatefulWidget {
  final String appName;
  final String apkPackage;
  final InstalledVariant installed;
  final bool canPickOtherFile;

  const _VariantConflictDialog({
    required this.appName,
    required this.apkPackage,
    required this.installed,
    required this.canPickOtherFile,
  });

  @override
  State<_VariantConflictDialog> createState() => _VariantConflictDialogState();
}

class _VariantConflictDialogState extends State<_VariantConflictDialog> {
  bool _dontAskAgain = false;

  void _pick(VariantChoice choice) {
    AppHaptics.selectionClick();
    Navigator.of(context).pop((
      choice: choice,
      dontAskAgain: _dontAskAgain && choice == VariantChoice.keepBoth,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final installed = widget.installed;
    final installedName = installed.versionName == null
        ? installed.label
        : '${installed.label} ${installed.versionName}';
    final involvesShizuku =
        AppVariantService.isShizukuManager(widget.apkPackage) ||
        AppVariantService.isShizukuManager(installed.packageName);

    Widget option({
      required IconData icon,
      required String title,
      required String subtitle,
      required VariantChoice choice,
      bool emphasized = false,
    }) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ScaleTouchWrapper(
          scaleDownFactor: 0.98,
          child: Material(
            color: emphasized
                ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => _pick(choice),
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              minLeadingWidth: 24,
              leading: Icon(
                icon,
                color: emphasized
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(title),
              subtitle: Text(subtitle),
            ),
          ),
        ),
      );
    }

    return Dismissible(
      key: const Key('variant_conflict_dialog_dismiss'),
      direction: DismissDirection.down,
      onDismissed: (_) => _pick(VariantChoice.cancel),
      child: GlassDialog(
        title: tr('variantConflictTitle'),
        icon: Icons.layers_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(
                'variantConflictBody',
                args: [installedName, installed.packageName, widget.apkPackage],
              ),
            ),
            if (involvesShizuku) ...[
              const SizedBox(height: 8),
              Text(
                tr('variantConflictShizukuNote'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            option(
              icon: Icons.swap_horiz_rounded,
              title: tr('variantReplaceTitle'),
              subtitle: tr('variantReplaceDesc', args: [installed.label]),
              choice: VariantChoice.replace,
              emphasized: true,
            ),
            if (widget.canPickOtherFile)
              option(
                icon: Icons.undo_rounded,
                title: tr('variantUseInstalledTitle'),
                subtitle: tr('variantUseInstalledDesc'),
                choice: VariantChoice.useInstalled,
              ),
            option(
              icon: Icons.library_add_outlined,
              title: tr('variantKeepBothTitle'),
              subtitle: tr('variantKeepBothDesc', args: [installed.label]),
              choice: VariantChoice.keepBoth,
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              controlAffinity: ListTileControlAffinity.leading,
              value: _dontAskAgain,
              onChanged: (v) => setState(() => _dontAskAgain = v ?? false),
              title: Text(tr('variantDontAskAgain')),
              subtitle: Text(tr('variantDontAskAgainDesc')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _pick(VariantChoice.cancel),
            child: Text(tr('cancel')),
          ),
        ],
      ),
    );
  }
}
