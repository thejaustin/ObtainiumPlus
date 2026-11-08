import 'package:android_package_manager/android_package_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_variant_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Opens a diagnostic sheet to inspect multi-user profiles, cloned workspaces (Insular, Shelter),
/// Samsung Dual Messenger, and package installer origins across the entire Android system.
Future<void> showMultiUserDiagnosticSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
    builder: (ctx) => const MultiUserDiagnosticSheet(),
  );
}

class MultiUserDiagnosticSheet extends StatefulWidget {
  const MultiUserDiagnosticSheet({super.key});

  @override
  State<MultiUserDiagnosticSheet> createState() =>
      _MultiUserDiagnosticSheetState();
}

class _MultiUserDiagnosticSheetState extends State<MultiUserDiagnosticSheet> {
  bool _isLoading = true;
  List<InstalledVariant> _variants = [];
  Map<int, List<InstalledVariant>> _byUser = {};

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final pm = AndroidPackageManager();
      final results = await AppVariantService.findAllInstalledVariants(pm, '');
      final Map<int, List<InstalledVariant>> grouped = {};
      for (final v in results) {
        grouped.putIfAbsent(v.userId, () => []).add(v);
      }
      if (mounted) {
        setState(() {
          _variants = results;
          _byUser = grouped;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyDiagnosticReport() {
    final buffer = StringBuffer();
    buffer.writeln('### Android Multi-User & Parallel Environment Report');
    buffer.writeln(
      '**Total Detected Packages across Profiles:** ${_variants.length}',
    );
    buffer.writeln('**Distinct User Profiles:** ${_byUser.keys.length}\n');

    for (final entry in _byUser.entries) {
      final userId = entry.key;
      final list = entry.value;
      final label = list.first.profileLabel;
      buffer.writeln('#### User $userId ($label) - ${list.length} packages');
      for (final app in list.take(15)) {
        buffer.writeln(
          '- `${app.packageName}` (${app.label}, v${app.versionName ?? 'unknown'}) '
          '[installer: ${app.installerPackage ?? 'unknown'}]',
        );
      }
      if (list.length > 15) {
        buffer.writeln('- *...and ${list.length - 15} more packages*');
      }
      buffer.writeln('');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppHaptics.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Multi-user diagnostic report copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusSettingsCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(baseRadius);

    final Widget sheetContent = Container(
      decoration: BoxDecoration(
        color: enableGlass
            ? cs.surface.withValues(alpha: 0.88)
            : cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.supervised_user_circle_rounded,
                      color: cs.onTertiaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multi-User & Parallel Environment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Insular, Shelter & Dual Messenger profiles',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _variants.isNotEmpty)
                    ScaleTouchWrapper(
                      hapticOnPressDown: true,
                      scaleDownFactor: 0.88,
                      child: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Copy Environment Report',
                        onPressed: _copyDiagnosticReport,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: ExpressiveCircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : _byUser.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No multi-user profiles detected on this device.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      shrinkWrap: true,
                      itemCount: _byUser.keys.length,
                      itemBuilder: (context, index) {
                        final userId = _byUser.keys.elementAt(index);
                        final apps = _byUser[userId]!;
                        final label = apps.first.profileLabel;
                        final isWork = userId == 10 || userId == 11;
                        final isDual = userId == 95 || userId == 999;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: cs.surfaceContainerLow,
                          shape: CardMetrics.shape(
                            cardRadius,
                            expressive:
                                plusSettings.plusEnableMaterialExpressive,
                            side: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isWork
                                          ? Icons.work_outline_rounded
                                          : (isDual
                                                ? Icons.content_copy_rounded
                                                : Icons.person_outline_rounded),
                                      color: isWork
                                          ? cs.primary
                                          : (isDual
                                                ? cs.tertiary
                                                : cs.secondary),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'User $userId ($label)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.secondaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${apps.length} apps',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: cs.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Detected installer sources in this space: '
                                  '${apps.map((a) => a.installerPackage ?? 'sideload').toSet().join(', ')}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: const Key('multi_user_diagnostic_dismissible'),
      direction: DismissDirection.down,
      onDismissed: (_) => Navigator.of(context).pop(),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: 20,
        child: sheetContent,
      ),
    );
  }
}
