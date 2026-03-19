import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';

/// Shows a dialog when user enters an unsupported URL,
/// suggesting alternative sources they can use.
Future<void> showUnsupportedSourceDialog({
  required BuildContext context,
  List<String>? suggestedSources,
  String? failedUrl,
}) {
  final settings = context.read<SettingsProvider>();
  final enableGlass = settings.plusEnableGlassmorphism;
  
  // Default supported sources if none provided
  final sources = suggestedSources ?? [
    'GitHub',
    'GitLab',
    'APKPure',
    'APKMirror',
    'F-Droid',
    'Huawei AppGallery',
  ];

  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(enableGlass ? 0.85 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
            ),
            boxShadow: AppShadows.smooth(
            color: Colors.black,
            opacity: enableGlass ? 0.2 : 0.1,
            blurFactor: enableGlass ? 1.5 : 1.0,
            ),
            ),
            child: ClipRRect(          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: enableGlass ? 15 : 0,
              sigmaY: enableGlass ? 15 : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, enableGlass),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildContent(context, sources, failedUrl),
                  ),
                ),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildHeader(BuildContext context, bool enableGlass) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.tertiaryContainer.withOpacity(enableGlass ? 0.3 : 0.5),
          Theme.of(context).colorScheme.tertiaryContainer.withOpacity(enableGlass ? 0.15 : 0.25),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.link_off_outlined,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            tr('unsupportedUrl'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildContent(BuildContext context, List<String> sources, String? failedUrl) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        tr('unsupportedUrlDescription'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      // Show failed URL for debugging (if developer mode or long-press)
      if (failedUrl != null && failedUrl.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bug_report_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Failed URL (for debugging):',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                failedUrl,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      Text(
        tr('supportedSources').toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sources.map((source) => _buildSourceChip(context, source)).toList(),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr('supportedSourcesTip'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildSourceChip(BuildContext context, String source) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getSourceIcon(source),
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 6),
        Text(
          source,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    ),
  );
}

IconData _getSourceIcon(String source) {
  switch (source.toLowerCase()) {
    case 'github':
      return Icons.code_outlined;
    case 'gitlab':
      return Icons.account_tree_outlined;
    case 'apkpure':
    case 'apkmirror':
    case 'apkcombo':
      return Icons.android_outlined;
    case 'f-droid':
    case 'fdroid':
      return Icons.shopping_bag_outlined;
    case 'huawei appgallery':
    case 'huawei':
      return Icons.store_outlined;
    case 'google play':
    case 'play store':
      return Icons.shop_outlined;
    default:
      return Icons.link_outlined;
  }
}

Widget _buildActions(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('ok')),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            // Could navigate to discover page or show source info
          },
          child: Text(tr('browseSupportedSources')),
        ),
      ],
    ),
  );
}
