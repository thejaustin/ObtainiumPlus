import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.pickAnyAsset
            ? tr('selectX', args: [tr('releaseAsset').toLowerCase()]) // Simplified for refactor
            : tr('pickAnAPK'),
      ),
      content: Column(
        children: [
          urlsToSelectFrom.length > 1
              ? Text(
                  tr('appHasMoreThanOnePackage', args: [widget.app.finalName]),
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 16),
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
                  : tr('deviceSupportsFollowingArchs'), // Simplified
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop(fileUrl);
          },
          child: Text(tr('continue')),
        ),
      ],
    );
  }
}

class APKOriginWarningDialog extends StatefulWidget {
  const APKOriginWarningDialog({
    super.key,
    required this.sourceUrl,
    required this.apkUrl,
  });

  final String sourceUrl;
  final String apkUrl;

  @override
  State<APKOriginWarningDialog> createState() => _APKOriginWarningDialogState();
}

class _APKOriginWarningDialogState extends State<APKOriginWarningDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(tr('warning')),
      content: Text(
        tr(
          'sourceIsXButPackageFromYPrompt',
          args: [
            Uri.parse(widget.sourceUrl).host,
            Uri.parse(widget.apkUrl).host,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop(true);
          },
          child: Text(tr('continue')),
        ),
      ],
    );
  }
}
