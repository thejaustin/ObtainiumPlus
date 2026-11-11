import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:obtainium/services/shizuku_status_service.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:provider/provider.dart';

/// Shows the Obtainium+ Features Overview & Live Diagnostics Sheet.
///
/// Its rows are links: each setting has one home in the settings tabs, and
/// [onOpenSection] (when given) closes the sheet and opens that tab.
Future<void> showPlusFeaturesSheet({
  required BuildContext context,
  ValueChanged<int>? onOpenSection,
}) {
  return showDraggableModalBottomSheet<void>(
    context: context,
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (sheetContext, scrollController) {
      return PlusFeaturesSheetContent(
        scrollController: scrollController,
        onOpenSection: onOpenSection,
      );
    },
  );
}

class PlusFeaturesSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<int>? onOpenSection;

  const PlusFeaturesSheetContent({
    super.key,
    required this.scrollController,
    this.onOpenSection,
  });

  @override
  State<PlusFeaturesSheetContent> createState() =>
      _PlusFeaturesSheetContentState();
}

class _PlusFeaturesSheetContentState extends State<PlusFeaturesSheetContent> {
  String _shizukuProvider = 'Shizuku';
  bool _isShizukuInstalled = false;
  bool _isShizukuGranted = false;
  int? _binderLatencyMs;
  bool _isBenchmarking = false;

  @override
  void initState() {
    super.initState();
    _checkShizuku();
  }

  // Same status source as the status card and Service Doctor, so the
  // screens can't disagree.
  Future<void> _checkShizuku() async {
    try {
      final snap = await ShizukuStatusService.instance.refreshFrom(context);
      if (mounted) {
        setState(() {
          _shizukuProvider = snap.providerLabel;
          _isShizukuInstalled = snap.isInstalled;
          _isShizukuGranted = snap.isActive;
        });
      }
    } catch (_) {}
  }

  Future<void> _runBenchmark() async {
    if (_isBenchmarking) return;
    AppHaptics.selectionClick();
    setState(() => _isBenchmarking = true);
    final latency = (await ShizukuStatusService.instance.refreshFrom(
      context,
    )).latencyMs;
    if (mounted) {
      setState(() {
        _binderLatencyMs = latency;
        _isBenchmarking = false;
      });
      if (latency != null) {
        AppHaptics.mediumImpact();
      }
    }
  }

  /// A row naming a setting that lives in a settings tab; tapping closes
  /// the sheet and opens that tab.
  Widget _buildSettingLink(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int section,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(tr(kSettingsSections[section].labelKey)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        AppHaptics.selectionClick();
        Navigator.of(context).pop();
        widget.onOpenSection?.call(section);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final radius = CardMetrics.card(plusSettings.plusGlobalCornerRadius);
    final innerRadius = CardMetrics.inner(radius);

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: ListView(
        controller: widget.scrollController,
        physics: plusSettings.scrollPhysics,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.4),
                  colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                ],
              ),
              shape: CardMetrics.shape(
                radius,
                expressive: isM3E,
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: ShapeDecoration(
                    color: colorScheme.primary,
                    shape: CardMetrics.shape(innerRadius, expressive: isM3E),
                    shadows: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: colorScheme.onPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('plusFeaturesOverview'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('plusFeaturesOverviewDescription'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: ShizukuPlus & Direct IPC
          _buildSectionHeader(
            context,
            icon: Icons.flash_on_rounded,
            title: tr('shizukuDirectIpc'),
          ),
          const SizedBox(height: 10),
          _buildCard(
            context,
            radius: radius,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.security_rounded,
                    color: _isShizukuGranted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    tr('plusShizukuIntegration', args: [_shizukuProvider]),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    !_isShizukuInstalled
                        ? tr('notInstalled')
                        : _isShizukuGranted
                        ? tr('plusShizukuActive')
                        : tr('plusShizukuPermissionNeeded'),
                  ),
                  trailing: _isShizukuInstalled
                      ? TextButton(
                          onPressed: () {
                            AppHaptics.selectionClick();
                            ShizukuInstaller.openShizukuManager();
                          },
                          child: Text(tr('open')),
                        )
                      : null,
                ),
                const Divider(height: 1),

                // Binder latency benchmark tile
                ListTile(
                  leading: Icon(
                    Icons.speed_rounded,
                    color: colorScheme.tertiary,
                  ),
                  title: Text(
                    tr('binderLatencyBenchmark'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _isBenchmarking
                        ? tr('benchmarkRunning')
                        : _binderLatencyMs != null
                        ? tr(
                            'binderLatencyResult',
                            args: [_binderLatencyMs.toString()],
                          )
                        : tr('binderLatencyDescription'),
                  ),
                  trailing: _isBenchmarking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: ExpressiveCircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : ScaleTouchWrapper(
                          hapticOnPressDown: true,
                          child: FilledButton.tonal(
                            onPressed: _runBenchmark,
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              _binderLatencyMs != null
                                  ? tr('retest')
                                  : tr('benchmark'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                ),

                // Fallback to system installer switch
                _buildSettingLink(
                  context,
                  icon: Icons.swap_horiz_rounded,
                  title: tr('shizukuFallbackToSystem'),
                  section: SettingsSectionIndex.installAndSafety,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Expressive Motion & Dynamic UI
          _buildSectionHeader(
            context,
            icon: Icons.animation_rounded,
            title: tr('expressiveMotion'),
          ),
          const SizedBox(height: 10),
          _buildCard(
            context,
            radius: radius,
            child: Column(
              children: [
                _buildSettingLink(
                  context,
                  icon: Icons.auto_awesome_motion_rounded,
                  title: tr('plusEnhancedAnimations'),
                  section: SettingsSectionIndex.lookAndMotion,
                ),
                const Divider(height: 1),
                _buildSettingLink(
                  context,
                  icon: Icons.brush_rounded,
                  title: tr('plusMaterialExpressive'),
                  section: SettingsSectionIndex.lookAndMotion,
                ),
                const Divider(height: 1),
                _buildSettingLink(
                  context,
                  icon: Icons.blur_on_rounded,
                  title: tr('plusGlassmorphism'),
                  section: SettingsSectionIndex.lookAndMotion,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 3: Background Reliability & OEM Optimization
          _buildSectionHeader(
            context,
            icon: Icons.tune_rounded,
            title: tr('backgroundReliability'),
          ),
          const SizedBox(height: 10),
          _buildCard(
            context,
            radius: radius,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phonelink_setup_rounded),
                  title: Text(
                    tr('oemCompatibilityGuides'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(tr('oemCompatibilityGuidesDescription')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selectionClick();
                    showDeviceOptimizationSheet(context: context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.battery_charging_full_rounded),
                  title: Text(
                    tr('batteryOptimizationExemption'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(tr('batteryOptimizationExemptionDescription')),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {
                    AppHaptics.lightImpact();
                    AppInstallService.requestBatteryOptimizationExemption();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 4: Smart Retries & Android 14+ Update Ownership
          _buildSectionHeader(
            context,
            icon: Icons.verified_user_rounded,
            title: tr('smartRetriesAndOwnership'),
          ),
          const SizedBox(height: 10),
          _buildCard(
            context,
            radius: radius,
            child: Column(
              children: [
                _buildSettingLink(
                  context,
                  icon: Icons.bolt_outlined,
                  title: tr('plusSmartRetries'),
                  section: SettingsSectionIndex.installAndSafety,
                ),
                const Divider(height: 1),
                _buildSettingLink(
                  context,
                  icon: Icons.security_update_good_rounded,
                  title: tr('plusUpdateOwnership'),
                  section: SettingsSectionIndex.installAndSafety,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required double radius,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isM3E = context
        .watch<PlusSettingsProvider>()
        .plusEnableMaterialExpressive;
    return Material(
      color: colorScheme.surfaceContainer,
      shape: CardMetrics.shape(
        radius,
        expressive: isM3E,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
