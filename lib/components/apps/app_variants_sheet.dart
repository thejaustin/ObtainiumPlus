import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/system_app_selector_sheet.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/services/app_variant_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Shows the Local Installation & Variants bottom sheet, allowing the user
/// to see all installed builds of an app (drop-in vs regular, debug, fdroid)
/// and choose which one to link or match.
Future<void> showAppVariantsSheet({
  required BuildContext context,
  required String appId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
    builder: (ctx) => _AppVariantsSheet(appId: appId),
  );
}

class _AppVariantsSheet extends StatefulWidget {
  final String appId;

  const _AppVariantsSheet({required this.appId});

  @override
  State<_AppVariantsSheet> createState() => _AppVariantsSheetState();
}

class _AppVariantsSheetState extends State<_AppVariantsSheet> {
  bool _loading = true;
  List<InstalledVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _scanVariants();
  }

  Future<void> _scanVariants() async {
    setState(() => _loading = true);
    final appsProvider = context.read<AppsProvider>();
    final app = appsProvider.apps[widget.appId];
    final packageToScan = app?.app.id ?? widget.appId;

    try {
      final variants = await AppVariantService.findAllInstalledVariants(
        pm,
        packageToScan,
        url: app?.app.url,
        name: app?.name,
        apkUrls: app?.app.apkUrls.map((e) => e.value).toList(),
      );
      if (mounted) {
        setState(() {
          _variants = variants;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _linkVariant(InstalledVariant variant) async {
    AppHaptics.success();
    final appsProvider = context.read<AppsProvider>();
    final app = appsProvider.apps[widget.appId];
    if (app != null) {
      app.app.installedVersion = variant.versionName ?? app.app.latestVersion;
      app.app.additionalSettings['linkedPackage'] = variant.packageName;
      appsProvider.saveApps([app.app]);
      await appsProvider.checkUpdate(app.app.id);
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Linked to ${variant.label} (${variant.packageName})'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _unlink() async {
    AppHaptics.selectionClick();
    final appsProvider = context.read<AppsProvider>();
    final app = appsProvider.apps[widget.appId];
    if (app != null) {
      app.app.installedVersion = null;
      app.app.additionalSettings.remove('linkedPackage');
      appsProvider.saveApps([app.app]);
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unlinked local installation'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final enableGlass = plusSettings.plusEnableGlassmorphism;
    final appsProvider = context.watch<AppsProvider>();
    final app = appsProvider.apps[widget.appId];
    final appName = app?.name ?? widget.appId;
    final linkedPackage =
        app?.app.additionalSettings['linkedPackage'] as String? ?? app?.app.id;

    final sheetRadius = Radius.circular(
      plusSettings.plusGlobalCornerRadius.clamp(20.0, 32.0),
    );

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: sheetRadius),
      child: ConditionalBlur(
        enabled: enableGlass,
        sigma: AppConstants.glassBlurSigmaSoft,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          decoration: BoxDecoration(
            color: enableGlass
                ? colorScheme.surface.withValues(
                    alpha: AppConstants.glassSurfaceAlphaStrong,
                  )
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: sheetRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Center(child: DragHandle()),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.hub_outlined,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Installation & Variants',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose which local build to pair with $appName',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Re-scan',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _scanVariants,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Flexible(
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: ExpressiveCircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: [
                            if (_variants.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.layers_clear_outlined,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No matching variants found on device',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Install this app or manually pick an installed package below.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              ..._variants.map((v) {
                                final isLinked =
                                    linkedPackage == v.packageName &&
                                    app?.app.installedVersion != null;
                                final typeLabel =
                                    AppVariantService.getVariantTypeLabel(
                                      v.packageName,
                                    );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ScaleTouchWrapper(
                                    scaleDownFactor: 0.98,
                                    onTap: () => _linkVariant(v),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isLinked
                                            ? colorScheme.primaryContainer
                                                  .withValues(alpha: 0.45)
                                            : colorScheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isLinked
                                              ? colorScheme.primary
                                              : colorScheme.outlineVariant
                                                    .withValues(alpha: 0.3),
                                          width: isLinked ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 2,
                                            ),
                                        leading: CircleAvatar(
                                          backgroundColor: isLinked
                                              ? colorScheme.primary
                                              : colorScheme
                                                    .surfaceContainerHighest,
                                          foregroundColor: isLinked
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurfaceVariant,
                                          child: Icon(
                                            isLinked
                                                ? Icons.check_rounded
                                                : Icons.android_rounded,
                                            size: 20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                v.label,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .secondaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                typeLabel,
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSecondaryContainer,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${v.packageName}${v.versionName != null ? ' • v${v.versionName}' : ''}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                if (v.userId != 0) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 1,
                                                        ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme
                                                          .tertiaryContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      v.profileLabel,
                                                      style: theme
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onTertiaryContainer,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                                Text(
                                                  'via ${AppVariantService.getInstallerLabel(v.installerPackage)}',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: isLinked
                                            ? Icon(
                                                Icons.link_rounded,
                                                color: colorScheme.primary,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 8),
                            ScaleTouchWrapper(
                              scaleDownFactor: 0.98,
                              onTap: () {
                                AppHaptics.selectionClick();
                                showSystemAppSelectorSheet(context: context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.apps_rounded,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Browse All Installed Apps...',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            'Link this entry to any installed app',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (app?.app.installedVersion != null)
                        TextButton.icon(
                          onPressed: _unlink,
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: const Text('Unlink'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                          ),
                        ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(tr('close')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
