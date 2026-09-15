import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

/// Shows the Obtainium+ Features Overview & Live Diagnostics Sheet.
Future<void> showPlusFeaturesSheet({required BuildContext context}) {
  return showDraggableModalBottomSheet<void>(
    context: context,
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (sheetContext, scrollController) {
      return PlusFeaturesSheetContent(scrollController: scrollController);
    },
  );
}

class PlusFeaturesSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const PlusFeaturesSheetContent({
    super.key,
    required this.scrollController,
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

  Future<void> _checkShizuku() async {
    try {
      final label = await ShizukuInstaller.getShizukuProviderLabel();
      final pkg = await ShizukuInstaller.getInstalledShizukuPackageId();
      final status = await ShizukuApkInstaller().checkPermission().timeout(
            const Duration(seconds: 2),
            onTimeout: () => 'timeout',
          );
      if (mounted) {
        setState(() {
          _shizukuProvider = label;
          _isShizukuInstalled = pkg != null;
          _isShizukuGranted = status == 'authorized';
        });
      }
    } catch (_) {}
  }

  Future<void> _runBenchmark() async {
    if (_isBenchmarking) return;
    AppHaptics.selectionClick();
    setState(() => _isBenchmarking = true);
    final latency = await ShizukuInstaller.measureBinderLatencyMs();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plusSettings = context.watch<PlusSettingsProvider>();
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final radius = plusSettings.plusGlobalCornerRadius.clamp(16.0, 28.0);
    final innerRadius = CardMetrics.inner(radius);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.4),
                  colorScheme.tertiaryContainer.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(innerRadius),
                    boxShadow: [
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
                    color: _isShizukuGranted ? Colors.green : colorScheme.primary,
                  ),
                  title: Text(
                    '$_shizukuProvider Integration',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    !_isShizukuInstalled
                        ? 'Not installed'
                        : _isShizukuGranted
                            ? 'Active & authorized for silent installs'
                            : 'Permission needed or service stopped',
                  ),
                  trailing: _isShizukuInstalled
                      ? TextButton(
                          onPressed: () {
                            AppHaptics.selectionClick();
                            ShizukuInstaller.openShizukuManager();
                          },
                          child: const Text('Open'),
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
                  title: const Text(
                    'Binder IPC Latency Benchmark',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _isBenchmarking
                        ? tr('benchmarkRunning')
                        : _binderLatencyMs != null
                            ? '$_binderLatencyMs ms round-trip latency'
                            : 'Benchmark Android binder transport speed',
                  ),
                  trailing: _isBenchmarking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : ScaleTouchWrapper(
                          onTap: _runBenchmark,
                          child: FilledButton.tonal(
                            onPressed: _runBenchmark,
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(
                              _binderLatencyMs != null ? 'Retest' : 'Benchmark',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                ),

                // Fallback to system installer switch
                SwitchListTile.adaptive(
                  dense: true,
                  secondary: const Icon(Icons.swap_horiz_rounded),
                  title: Text(
                    tr('shizukuFallbackToSystem'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tr('shizukuFallbackToSystemDescription'),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: behaviorSettings.shizukuFallbackToSystem,
                  onChanged: (v) {
                    AppHaptics.selectionClick();
                    behaviorSettings.shizukuFallbackToSystem = v;
                  },
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
                SwitchListTile.adaptive(
                  dense: true,
                  secondary: const Icon(Icons.auto_awesome_motion_rounded),
                  title: Text(
                    tr('plusEnhancedAnimations'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tr('plusEnhancedAnimationsDescription'),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: plusSettings.plusEnableEnhancedAnimations,
                  onChanged: (v) {
                    AppHaptics.selectionClick();
                    plusSettings.plusEnableEnhancedAnimations = v;
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  dense: true,
                  secondary: const Icon(Icons.palette_outlined),
                  title: Text(
                    tr('plusMaterialExpressive'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tr('plusMaterialExpressiveDescription'),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: plusSettings.plusEnableMaterialExpressive,
                  onChanged: (v) {
                    AppHaptics.selectionClick();
                    plusSettings.plusEnableMaterialExpressive = v;
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  dense: true,
                  secondary: const Icon(Icons.blur_on_rounded),
                  title: Text(
                    tr('plusGlassmorphism'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tr('plusGlassmorphismDescription'),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: plusSettings.plusEnableGlassmorphism,
                  onChanged: (v) {
                    AppHaptics.selectionClick();
                    plusSettings.plusEnableGlassmorphism = v;
                  },
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
                  title: const Text(
                    'OEM Compatibility Guides',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'OneUI 8 AutoBlocker, HyperOS, ColorOS & OxygenOS tuning',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selectionClick();
                    showDeviceOptimizationSheet(context: context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.battery_charging_full_rounded),
                  title: const Text(
                    'Battery Optimization Exemption',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Prevent Android from suspending background update checks',
                  ),
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
                SwitchListTile.adaptive(
                  dense: true,
                  secondary: const Icon(Icons.bolt_rounded),
                  title: Text(
                    tr('plusSmartRetries'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tr('plusSmartRetriesDescription'),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: plusSettings.plusEnableSmartRetries,
                  onChanged: (v) {
                    AppHaptics.selectionClick();
                    plusSettings.plusEnableSmartRetries = v;
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  dense: true,
                  secondary: const Icon(Icons.shield_outlined),
                  title: Text(
                    tr('plusUpdateOwnership'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    tr('plusUpdateOwnershipDescription'),
                    style: theme.textTheme.bodySmall,
                  ),
                  value: plusSettings.plusUpdateOwnership,
                  onChanged: (v) {
                    AppHaptics.selectionClick();
                    plusSettings.plusUpdateOwnership = v;
                  },
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
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}
