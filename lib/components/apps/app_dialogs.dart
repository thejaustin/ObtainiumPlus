import 'package:obtainium/utils/haptic_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';

class AppFilePicker extends StatefulWidget {
  const AppFilePicker({
    super.key,
    required this.app,
    this.initVal,
    this.archs,
    this.pickAnyAsset = false,
  });

  final App app;
  final MapEntry<String, String>? initVal;
  final List<String>? archs;
  final bool pickAnyAsset;

  @override
  State<AppFilePicker> createState() => _AppFilePickerState();
}

class _AppFilePickerState extends State<AppFilePicker> {
  MapEntry<String, String>? fileUrl;

  @override
  Widget build(BuildContext context) {
    fileUrl ??= widget.initVal;
    var urlsToSelectFrom = widget.app.apkUrls;
    if (widget.pickAnyAsset) {
      urlsToSelectFrom = [...urlsToSelectFrom, ...widget.app.otherAssetUrls];
    }
    return GlassDialog(
      title: widget.pickAnyAsset
          ? tr('selectX', args: [tr('releaseAsset').toLowerCase()])
          : tr('pickAnAPK'),
      icon: Icons.install_mobile_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (urlsToSelectFrom.length > 1)
            Text(tr('appHasMoreThanOnePackage', args: [widget.app.finalName])),
          if (urlsToSelectFrom.length > 1) const SizedBox(height: 16),
          ...urlsToSelectFrom.map(
            (u) => RadioListTile<String>(
              title: Text(u.key),
              value: u.value,
              groupValue: fileUrl!.value,
              onChanged: (String? val) {
                setState(() {
                  final match = urlsToSelectFrom.where((e) => e.value == val);
                  if (match.isNotEmpty) {
                    fileUrl = match.first;
                  }
                });
              },
            ),
          ),
          if (widget.archs != null) const SizedBox(height: 16),
          if (widget.archs != null)
            Text(
              widget.archs!.length == 1
                  ? tr('deviceSupportsXArch', args: [widget.archs![0]])
                  : tr('deviceSupportsFollowingArchs'),
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.maybeOf(context)?.pop(null),
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            AppHaptics.selectionClick();
            Navigator.maybeOf(context)?.pop(fileUrl);
          },
          child: Text(tr('continue')),
        ),
      ],
    );
  }
}

class APKOriginWarningDialog extends StatelessWidget {
  const APKOriginWarningDialog({
    super.key,
    required this.sourceUrl,
    required this.apkUrl,
  });

  final String sourceUrl;
  final String apkUrl;

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: tr('warning'),
      icon: Icons.warning_amber_rounded,
      content: Text(
        tr(
          'sourceIsXButPackageFromYPrompt',
          args: [
            Uri.parse(sourceUrl).host,
            Uri.parse(apkUrl).host,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.maybeOf(context)?.pop(null),
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            AppHaptics.selectionClick();
            Navigator.maybeOf(context)?.pop(true);
          },
          child: Text(tr('continue')),
        ),
      ],
    );
  }
}
