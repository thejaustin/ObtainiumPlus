import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/device_optimization_sheet.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:obtainium/components/settings/shizuku_status_card.dart';
import 'package:obtainium/components/system_app_selector_sheet.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/providers/settings_provider.dart';

/// App installation and update settings
class InstallationSection extends StatefulWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const InstallationSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  @override
  State<InstallationSection> createState() => _InstallationSectionState();
}

class _InstallationSectionState extends State<InstallationSection>
    with WidgetsBindingObserver {
  String? _installedShizukuPkg;
  bool _isShizukuGranted = false;
  bool _isCheckingShizuku = false;
  int? _binderLatencyMs;
  bool _isTestingBinder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkShizukuStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkShizukuStatus();
    }
  }

  Future<void> _checkShizukuStatus() async {
    if (_isCheckingShizuku) return;
    _isCheckingShizuku = true;
    try {
      final pkg = await ShizukuInstaller.getInstalledShizukuPackageId();
      bool granted = false;
      if (pkg != null) {
        final status = await ShizukuApkInstaller().checkPermission();
        granted = status?.startsWith('authorized') == true ||
            status?.startsWith('granted') == true;
      }
      if (mounted) {
        setState(() {
          _installedShizukuPkg = pkg;
          _isShizukuGranted = granted;
        });
      }
    } catch (_) {
    } finally {
      _isCheckingShizuku = false;
    }
  }

  Future<void> _testBinderLatency() async {
    if (_isTestingBinder) return;
    AppHaptics.selectionClick();
    setState(() => _isTestingBinder = true);
    final latency = await ShizukuInstaller.measureBinderLatencyMs();
    if (mounted) {
      setState(() {
        _binderLatencyMs = latency;
        _isTestingBinder = false;
      });
    }
  }

  bool _matches(String text, {bool isAdvanced = false}) {
    if (isAdvanced && !(widget.showAdvancedSettings ?? false)) return false;
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) return true;
    return text.toLowerCase().contains(widget.searchQuery!.toLowerCase());
  }


  @override
  Widget build(BuildContext context) {
    final bool isSearching =
        widget.searchQuery != null && widget.searchQuery!.isNotEmpty;
    final plusSettings = context.watch<PlusSettingsProvider>();

    return Consumer<BehaviorSettingsProvider>(
      builder: (context, behaviorSettings, child) {
        List<Widget> children = [
          // Device Compatibility & Performance
          if (_matches(tr('devicePerformanceAndCompatibility')) ||
              _matches('compatibility') ||
              _matches('performance') ||
              _matches('device tuning') ||
              _matches('device optimization') ||
              _matches('tuning') ||
              _matches('speed') ||
              _matches('oem') ||
              _matches('samsung') ||
              _matches('xiaomi') ||
              _matches('hyperos') ||
              _matches('miui') ||
              _matches('oneplus') ||
              _matches('oppo') ||
              _matches('nothing') ||
              _matches('vivo') ||
              _matches('transsion') ||
              _matches('motorola') ||
              _matches('autoblocker') ||
              _matches('freeze') ||
              !isSearching)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(
                tr('devicePerformanceAndCompatibility'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: FutureBuilder<String>(
                future: DeviceUtils.getDeviceSummary(),
                builder: (context, snapshot) {
                  final detected = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('devicePerformanceAndCompatibilitySubtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (detected != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Detected: $detected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                },
              ),
              trailing: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(tr('tune')),
                onPressed: () {
                  AppHaptics.selectionClick();
                  showDeviceOptimizationSheet(context: context);
                },
              ),
              onTap: () {
                AppHaptics.selectionClick();
                showDeviceOptimizationSheet(context: context);
              },
            ),
          // Parallel Downloads
          if (_matches(tr('parallelDownloads'), isAdvanced: true))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.file_download_outlined),
              title: Text(
                tr('parallelDownloads'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('parallelDownloadsDescription')),
              value: behaviorSettings.parallelDownloads,
              onChanged: (v) => behaviorSettings.parallelDownloads = v,
            ),

          // App Verifier
          if (_matches(tr('beforeNewInstallsShareToAppVerifier')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.verified_user_outlined),
              title: Text(
                tr('beforeNewInstallsShareToAppVerifier'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(
                tr('beforeNewInstallsShareToAppVerifierDescription'),
              ),
              value: behaviorSettings.beforeNewInstallsShareToAppVerifier,
              onChanged: (v) =>
                  behaviorSettings.beforeNewInstallsShareToAppVerifier = v,
            ),

          // Use Play Store App Links
          if (_matches(tr('usePlayStoreAppLinks')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.storefront_outlined),
              title: Text(
                tr('usePlayStoreAppLinks'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('usePlayStoreAppLinksDescription')),
              value: behaviorSettings.usePlayStoreAppLinks,
              onChanged: (v) => behaviorSettings.usePlayStoreAppLinks = v,
            ),

          // Allow Third-Party Sources
          if (_matches(tr('allowThirdPartySources')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.source_outlined),
              title: Text(
                tr('allowThirdPartySources'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('allowThirdPartySourcesDescription')),
              value: behaviorSettings.allowThirdPartySources,
              onChanged: (v) => behaviorSettings.allowThirdPartySources = v,
            ),

          // Install Unknown Apps (system settings shortcut)
          if (_matches(tr('installUnknownApps')))
            ListTile(
              leading: Icon(
                Icons.install_mobile_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(
                tr('installUnknownApps'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () async {
                try {
                  await AppInstallService.openInstallUnknownAppsSettings(
                    AppConstants.obtainiumPlusId,
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(tr('error'))));
                  }
                }
              },
            ),

          // Import Installed Apps
          if (_matches(tr('importInstalledApps')))
            ListTile(
              leading: const Icon(Icons.install_mobile_rounded),
              title: Text(
                tr('importInstalledApps'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('importInstalledAppsDescription')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                AppHaptics.selectionClick();
                showSystemAppSelectorSheet(context: context);
              },
            ),

          // Smart Retries & Caching
          if (_matches(tr('plusSmartRetries'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.bolt_outlined,
              title: tr('plusSmartRetries'),
              subtitle: tr('plusSmartRetriesDescription'),
              value: (s) => s.plusEnableSmartRetries,
              onChanged: (s, v) => s.plusEnableSmartRetries = v,
            ),

          // MicroG Compat Hub
          if (_matches(tr('plusEnableMicroGHub'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.hub_outlined,
              title: tr('plusEnableMicroGHub'),
              subtitle: tr('plusEnableMicroGHubDescription'),
              value: (s) => s.plusEnableMicroGHub,
              onChanged: (s, v) => s.plusEnableMicroGHub = v,
            ),

          // Standalone Installer
          if (_matches(tr('plusEnableStandaloneInstaller')))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.install_mobile_outlined,
              title: tr('plusEnableStandaloneInstaller'),
              subtitle: tr('plusEnableStandaloneInstallerDescription'),
              value: (s) => s.plusEnableStandaloneInstaller,
              onChanged: (s, v) => s.plusEnableStandaloneInstaller = v,
            ),

          // Update Ownership (Android 14+)
          if (_matches(tr('plusUpdateOwnership'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.security_update_good_rounded,
              title: tr('plusUpdateOwnership'),
              subtitle: tr('plusUpdateOwnershipDescription'),
              value: (s) => s.plusEnableUpdateOwnership,
              onChanged: (s, v) => s.plusEnableUpdateOwnership = v,
            ),

          // User Pre-approval (Android 14+)
          if (_matches(tr('plusUserPreapproval'), isAdvanced: true))
            buildFeatureToggle<PlusSettingsProvider>(
              context,
              icon: Icons.touch_app_outlined,
              title: tr('plusUserPreapproval'),
              subtitle: tr('plusUserPreapprovalDescription'),
              value: (s) => s.plusEnableUserPreapproval,
              onChanged: (s, v) => s.plusEnableUserPreapproval = v,
            ),

          // Remove on External Uninstall
          if (_matches(tr('removeOnExternalUninstall')))
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.delete_sweep_outlined),
              title: Text(
                tr('removeOnExternalUninstall'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(tr('removeOnExternalUninstallDescription')),
              value: behaviorSettings.removeOnExternalUninstall,
              onChanged: (v) => behaviorSettings.removeOnExternalUninstall = v,
            ),

          // Installer method selector — unified radio picker replacing the old
          // separate Shizuku and Root switches.
          if (_matches(tr('useShizuku')) ||
              _matches(tr('rootInstaller')) ||
              _matches(tr('installMethod')) ||
              _matches(tr('installerMethodLabel')) ||
              _matches(tr('shizukuPretendToBeGooglePlay')) ||
              _matches(tr('shizukuFallbackToSystem')) ||
              _matches('binder') ||
              !isSearching)
            _buildInstallerMethodSelector(
              context,
              behaviorSettings,
              plusSettings,
            ),
        ];

        return ExpressiveSettingsGroup(
          title: isSearching ? null : tr('installation'),
          description: isSearching ? null : tr('installationGroupDesc'),
          persistKey: 'installation',
          icon: Icons.install_mobile_rounded,
          isExpandable: !isSearching,
          initiallyExpanded: true,
          children: children,
        );
      },
    );
  }

  /// Unified installer method picker — replaces the old separate Shizuku and
  /// Root switches with a single radio group that also shows availability.
  Widget _buildInstallerMethodSelector(
    BuildContext context,
    BehaviorSettingsProvider behaviorSettings,
    PlusSettingsProvider plusSettings,
  ) {
    final currentMode = behaviorSettings.installerMode;
    final shizukuAvailable =
        _installedShizukuPkg != null && _isShizukuGranted;
    final shizukuInstalled = _installedShizukuPkg != null;
    final isShizukuPlus = _installedShizukuPkg == AppConstants.shizukuPlusId;
    final hasExternal = behaviorSettings.externalInstallerPackage != null &&
        behaviorSettings.externalInstallerPackage!.isNotEmpty;

    Future<void> onSelectShizuku() async {
      AppHaptics.selectionClick();
      final shizukuInstaller = ShizukuInstaller(
        SettingsProvider(behaviorSettings.prefs),
      );
      final resCode = await shizukuInstaller.checkPermissionWithRetry();
      final isGranted =
          resCode?.startsWith('authorized') == true ||
          resCode?.startsWith('granted') == true;
      if (isGranted) {
        behaviorSettings.useShizuku = true;
        behaviorSettings.installerMode = 'shizuku';
        _checkShizukuStatus();
        return;
      }
      behaviorSettings.useShizuku = false;
      if (!context.mounted) return;
      final pkg = await ShizukuInstaller.getInstalledShizukuPackageId();
      if (pkg == null) {
        _showError(context, ObtainiumError(tr('shizukuNotInstalled')));
        return;
      }
      final isPlus = pkg == AppConstants.shizukuPlusId;
      switch (resCode) {
        case 'binder_not_found':
        case 'services_not_found':
        case null:
          _showError(
            context,
            ObtainiumError(
              isPlus
                  ? tr('shizukuPlusServiceStopped')
                  : tr('shizukuBinderNotFound'),
            ),
          );
        case 'old_shizuku':
          _showError(context, ObtainiumError(tr('shizukuOld')));
        case 'old_android_with_adb':
          _showError(
            context,
            ObtainiumError(tr('shizukuOldAndroidWithADB')),
          );
        case 'denied':
          _showError(context, ObtainiumError(tr('shizukuPermissionDenied')));
        default:
          _showError(context, ObtainiumError(tr('shizukuBinderNotFound')));
      }
      _checkShizukuStatus();
    }

    Widget buildChip(String label, {bool available = true, Color? color}) {
      final chipColor = color ??
          (available
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest);
      final textColor = available
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(context).colorScheme.onSurfaceVariant;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      );
    }

    Widget buildOption({
      required String mode,
      required IconData icon,
      required String title,
      required String description,
      Widget? chip,
      bool enabled = true,
    }) {
      final selected = currentMode == mode;
      Future<void> onActivate() async {
        if (mode == 'shizuku') {
          await onSelectShizuku();
        } else {
          AppHaptics.selectionClick();
          behaviorSettings.useShizuku = false;
          behaviorSettings.installerMode = mode;
        }
      }

      return ScaleTouchWrapper(
        scaleDownFactor: 0.98,
        hapticOnPressDown: enabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Radio<String>(
                value: mode,
                groupValue: currentMode,
                onChanged: enabled ? (_) => onActivate() : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: selected && enabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: enabled
                                      ? (selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : null)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                          ),
                        ),
                        if (chip != null) ...[
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: KeyedSubtree(key: ValueKey(chip.hashCode), child: chip),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 2),
          child: Row(
            children: [
              Icon(
                Icons.install_mobile_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                tr('installerMethodLabel'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),

        buildOption(
          mode: 'system',
          icon: Icons.android_rounded,
          title: tr('installMethodSystem'),
          description: tr('installMethodSystemDescription'),
        ),

        buildOption(
          mode: 'shizuku',
          icon: isShizukuPlus
              ? Icons.electric_bolt_rounded
              : Icons.terminal_outlined,
          title: shizukuInstalled
              ? (isShizukuPlus ? 'ShizukuPlus' : tr('installMethodShizuku'))
              : tr('installMethodShizuku'),
          description: shizukuAvailable
              ? tr('installMethodShizukuDescription')
              : shizukuInstalled
                  ? tr('shizukuBinderNotFound')
                  : tr('shizukuNotInstalled'),
          chip: shizukuAvailable
              ? buildChip(tr('installerAvailable'))
              : buildChip(tr('installerUnavailable'), available: false),
        ),

        buildOption(
          mode: 'root',
          icon: Icons.admin_panel_settings_outlined,
          title: tr('installMethodRoot'),
          description: tr('installMethodRootDescription'),
        ),

        if (hasExternal)
          buildOption(
            mode: 'external',
            icon: Icons.open_in_new_rounded,
            title: tr('installMethodExternal'),
            description: tr('installMethodExternalDescription'),
          ),

        // Shizuku sub-options — only shown when mode is shizuku
        AnimatedSize(
          duration: Duration(
            milliseconds: plusSettings.plusEnableEnhancedAnimations ? 280 : 0,
          ),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: currentMode == 'shizuku'
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 16,
                    top: 4,
                    bottom: 8,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      (plusSettings.plusSettingsCornerRadius * 0.5).clamp(8.0, 20.0),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(
                          (plusSettings.plusSettingsCornerRadius * 0.5).clamp(8.0, 20.0),
                        ),
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: AppOpacity.moderate),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (plusSettings.plusSettingsUseHeroCards)
                            const ShizukuStatusCard(
                              margin: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                            ),

                          SwitchListTile.adaptive(
                            dense: true,
                            secondary: const Icon(Icons.shop_outlined, size: 20),
                            title: Text(
                              tr('shizukuPretendToBeGooglePlay'),
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                            ),
                            subtitle: Text(
                              tr('shizukuPretendToBeGooglePlayDescription'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            value: behaviorSettings.shizukuPretendToBeGooglePlay,
                            onChanged: (v) {
                              AppHaptics.selectionClick();
                              behaviorSettings.shizukuPretendToBeGooglePlay = v;
                            },
                          ),

                          SwitchListTile.adaptive(
                            dense: true,
                            secondary:
                                const Icon(Icons.swap_horiz_rounded, size: 20),
                            title: Text(
                              tr('shizukuFallbackToSystem'),
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                            ),
                            subtitle: Text(
                              tr('shizukuFallbackToSystemDescription'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            value: behaviorSettings.shizukuFallbackToSystem,
                            onChanged: (v) {
                              AppHaptics.selectionClick();
                              behaviorSettings.shizukuFallbackToSystem = v;
                            },
                          ),

                          if (_isShizukuGranted)
                            ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.speed_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              title: AnimatedSwitcher(
                                duration: Duration(
                                  milliseconds:
                                      plusSettings.plusEnableEnhancedAnimations
                                          ? 200
                                          : 0,
                                ),
                                child: Text(
                                  _isTestingBinder
                                      ? tr('testingBinder')
                                      : _binderLatencyMs != null
                                          ? tr(
                                              'binderLatency',
                                              args: ['$_binderLatencyMs'],
                                            )
                                          : tr('testBinderConnection'),
                                  key: ValueKey<String>(
                                    _isTestingBinder
                                        ? 'testing'
                                        : _binderLatencyMs != null
                                            ? 'result_$_binderLatencyMs'
                                            : 'idle',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: _binderLatencyMs != null &&
                                                !_isTestingBinder
                                            ? (_binderLatencyMs! < 50
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : _binderLatencyMs! < 120
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .tertiary
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .error)
                                            : null,
                                      ),
                                ),
                              ),
                              trailing: _isTestingBinder
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: ExpressiveCircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : FilledButton.tonal(
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      onPressed: () {
                                        AppHaptics.selectionClick();
                                        _testBinderLatency();
                                      },
                                      child: Text(
                                        _binderLatencyMs != null ? 'Retest' : 'Test',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        AnimatedOpacity(
          opacity: (currentMode == 'shizuku' && behaviorSettings.shizukuFallbackToSystem) ? 1.0 : 0.0,
          duration: Duration(
            milliseconds: plusSettings.plusEnableEnhancedAnimations
                ? AppConstants.mediumAnimationMs
                : 0,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  tr('installerFallbackLabel'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showError(BuildContext context, ObtainiumError error) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(error.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
