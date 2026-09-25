import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/settings/shizuku_status_card.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/services/device_compatibility_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

/// Live connectivity and permission status for Shizuku/ShizukuPlus.
enum ShizukuLiveStatus {
  active,
  permissionNeeded,
  notRunning,
  rootless,
}

/// Shows the Device Compatibility & Performance Sheet.
Future<void> showDeviceOptimizationSheet({required BuildContext context}) {
  return showDraggableModalBottomSheet<void>(
    context: context,
    initialChildSize: 0.85,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (sheetContext, scrollController) {
      return DeviceOptimizationSheetContent(scrollController: scrollController);
    },
  );
}

class DeviceOptimizationSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const DeviceOptimizationSheetContent({
    super.key,
    required this.scrollController,
  });

  @override
  State<DeviceOptimizationSheetContent> createState() =>
      _DeviceOptimizationSheetContentState();
}

class _DeviceOptimizationSheetContentState
    extends State<DeviceOptimizationSheetContent>
    with WidgetsBindingObserver {
  DeviceOEM? _selectedOEM;
  DeviceOEM _detectedOEM = DeviceOEM.generic;
  String _deviceSummary = '';
  String _deviceManufacturer = '';
  String _deviceModel = '';
  String _androidVersion = '';
  int _sdkInt = 0;
  bool _isLoading = true;
  bool? _isBatteryUnrestricted;
  ShizukuLiveStatus _shizukuStatus = ShizukuLiveStatus.rootless;
  bool _isShizukuPlus = false;
  int? _binderLatencyMs;
  bool _isTestingBinder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLiveStatus();
    }
  }

  Future<ShizukuLiveStatus> _evaluateShizukuStatus() async {
    try {
      final pkg = await ShizukuInstaller.getInstalledShizukuPackageId();
      if (pkg == null) {
        _isShizukuPlus = false;
        return ShizukuLiveStatus.rootless;
      }
      _isShizukuPlus = pkg == AppConstants.shizukuPlusId;
      final status = await ShizukuApkInstaller().checkPermission();
      if (status?.startsWith('authorized') == true ||
          status?.startsWith('granted') == true) {
        return ShizukuLiveStatus.active;
      }
      if (status == 'denied') {
        return ShizukuLiveStatus.permissionNeeded;
      }
      return ShizukuLiveStatus.notRunning;
    } catch (_) {
      _isShizukuPlus = false;
      return ShizukuLiveStatus.rootless;
    }
  }

  Future<void> _refreshLiveStatus() async {
    bool? isUnrestricted;
    try {
      isUnrestricted =
          await DeviceCompatibilityService.isIgnoringBatteryOptimizations();
    } catch (_) {}
    final shizuku = await _evaluateShizukuStatus();
    if (mounted) {
      setState(() {
        _isBatteryUnrestricted = isUnrestricted;
        _shizukuStatus = shizuku;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    final oem = await DeviceUtils.getDeviceOEM();
    final summary = await DeviceUtils.getDeviceSummary();
    bool? isUnrestricted;
    try {
      isUnrestricted =
          await DeviceCompatibilityService.isIgnoringBatteryOptimizations();
    } catch (_) {}
    final shizuku = await _evaluateShizukuStatus();
    try {
      final info = await DeviceUtils.getAndroidInfo();
      _deviceManufacturer = info.manufacturer;
      _deviceModel = info.model;
      _androidVersion = info.version.release;
      _sdkInt = info.version.sdkInt;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _detectedOEM = oem;
        _selectedOEM = oem;
        _deviceSummary = summary;
        _isBatteryUnrestricted = isUnrestricted;
        _shizukuStatus = shizuku;
        _isLoading = false;
      });
    }
  }

  static const List<DeviceOEM> _supportedOEMs = [
    DeviceOEM.samsung,
    DeviceOEM.xiaomi,
    DeviceOEM.oneplus,
    DeviceOEM.nothing,
    DeviceOEM.pixel,
    DeviceOEM.vivo,
    DeviceOEM.transsion,
    DeviceOEM.motorola,
    DeviceOEM.huawei,
    DeviceOEM.generic,
  ];

  String _getOEMLabel(DeviceOEM oem) {
    switch (oem) {
      case DeviceOEM.samsung:
        return 'Samsung One UI';
      case DeviceOEM.xiaomi:
        return 'Xiaomi HyperOS / MIUI';
      case DeviceOEM.oneplus:
      case DeviceOEM.oppo:
      case DeviceOEM.realme:
        return 'OnePlus / OPPO / Realme';
      case DeviceOEM.nothing:
        return 'Nothing OS';
      case DeviceOEM.pixel:
        return 'Google Pixel';
      case DeviceOEM.vivo:
        return 'Vivo / iQOO';
      case DeviceOEM.transsion:
        return 'Transsion (Tecno / Infinix)';
      case DeviceOEM.huawei:
        return 'Huawei / Honor';
      case DeviceOEM.motorola:
        return 'Motorola';
      case DeviceOEM.generic:
        return 'Stock Android';
    }
  }

  IconData _getOEMIcon(DeviceOEM oem) {
    switch (oem) {
      case DeviceOEM.samsung:
        return Icons.phone_android_rounded;
      case DeviceOEM.xiaomi:
        return Icons.bolt_rounded;
      case DeviceOEM.oneplus:
      case DeviceOEM.oppo:
      case DeviceOEM.realme:
        return Icons.speed_rounded;
      case DeviceOEM.nothing:
        return Icons.flare_rounded;
      case DeviceOEM.pixel:
        return Icons.auto_awesome_rounded;
      case DeviceOEM.vivo:
        return Icons.battery_charging_full_rounded;
      case DeviceOEM.transsion:
        return Icons.offline_bolt_rounded;
      case DeviceOEM.huawei:
        return Icons.shield_rounded;
      case DeviceOEM.motorola:
        return Icons.smartphone_rounded;
      case DeviceOEM.generic:
        return Icons.android_rounded;
    }
  }

  void _copySpecsToClipboard(BuildContext context) {
    AppHaptics.lightImpact();
    final specs = _deviceSummary.isNotEmpty
        ? _deviceSummary
        : 'Manufacturer: $_deviceManufacturer\nModel: $_deviceModel\nAndroid: $_androidVersion (API $_sdkInt)\nPlatform: ${_getOEMLabel(_detectedOEM)}';
    Clipboard.setData(ClipboardData(text: specs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device specifications copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getShizukuChipLabel() {
    final name = _isShizukuPlus ? 'ShizukuPlus' : 'Shizuku';
    switch (_shizukuStatus) {
      case ShizukuLiveStatus.active:
        return '$name: Active (Turbo)';
      case ShizukuLiveStatus.permissionNeeded:
        return '$name: Tap to Authorize';
      case ShizukuLiveStatus.notRunning:
        return '$name: Not Running (Tap)';
      case ShizukuLiveStatus.rootless:
        return 'Rootless Mode (Active)';
    }
  }

  IconData _getShizukuChipIcon() {
    switch (_shizukuStatus) {
      case ShizukuLiveStatus.active:
        return _isShizukuPlus
            ? Icons.electric_bolt_rounded
            : Icons.bolt_rounded;
      case ShizukuLiveStatus.permissionNeeded:
        return Icons.key_rounded;
      case ShizukuLiveStatus.notRunning:
        return Icons.play_arrow_rounded;
      case ShizukuLiveStatus.rootless:
        return Icons.verified_user_outlined;
    }
  }

  Color _getShizukuChipColor(ColorScheme colorScheme) {
    switch (_shizukuStatus) {
      case ShizukuLiveStatus.active:
        return Colors.green;
      case ShizukuLiveStatus.permissionNeeded:
        return Colors.orange;
      case ShizukuLiveStatus.notRunning:
        return colorScheme.primary;
      case ShizukuLiveStatus.rootless:
        return colorScheme.tertiary;
    }
  }

  Future<void> _handleShizukuChipTap(BuildContext context) async {
    AppHaptics.selectionClick();
    switch (_shizukuStatus) {
      case ShizukuLiveStatus.active:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isShizukuPlus
                  ? 'ShizukuPlus Turbo Mode is active. Elevated Unified Privilege binder IPC enables sub-second installs.'
                  : 'Shizuku Turbo Mode is active. Elevated binder IPC enables sub-second installs.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        break;
      case ShizukuLiveStatus.permissionNeeded:
        try {
          await ShizukuApkInstaller().checkPermission();
          _refreshLiveStatus();
        } catch (_) {}
        break;
      case ShizukuLiveStatus.notRunning:
        await ShizukuInstaller.openShizukuManager();
        break;
      case ShizukuLiveStatus.rootless:
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 22),
                SizedBox(width: 8),
                Text('Rootless Mode Active'),
              ],
            ),
            content: const Text(
              'ObtainiumPlus operates with 100% native Android package management without requiring root or ADB access.\n\n'
              '• Android 14+: Background updates install silently via "Update Ownership" & "User Pre-approval".\n\n'
              '• Earlier Android versions: Installing or launching Shizuku / ShizukuPlus enables silent elevated background installations.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        break;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeOEM = _selectedOEM ?? _detectedOEM;
    final guide = DeviceCompatibilityService.getGuideForOEM(activeOEM);
    final isViewingDetected = activeOEM == _detectedOEM;

    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Compatibility & Performance',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'OEM settings, unthrottled downloads & install fixes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: tr('close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Horizontally scrolling OEM selection tabs
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: _supportedOEMs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final oem = _supportedOEMs[index];
              final isSelected = oem == activeOEM;
              final isDetected = oem == _detectedOEM;
              return ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  _getOEMIcon(oem),
                  size: 16,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getOEMLabel(oem)),
                    if (isDetected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.onPrimary.withValues(alpha: 0.25)
                              : colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    AppHaptics.selectionClick();
                    setState(() => _selectedOEM = oem);
                  }
                },
              );
            },
          ),
        ),

        // Main scrollable guide content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // Hero Diagnostics Banner
                    Card(
                      elevation: 0,
                      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getOEMIcon(_detectedOEM),
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _deviceModel.isNotEmpty
                                                  ? '$_deviceManufacturer $_deviceModel'
                                                  : 'Detected Device',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.green.withValues(alpha: 0.4),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 11,
                                                  color: Colors.green,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Android $_androidVersion (API $_sdkInt) • ${_getOEMLabel(_detectedOEM)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (_isBatteryUnrestricted != null) ...[
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _isBatteryUnrestricted == true
                                        ? null
                                        : () async {
                                            AppHaptics.selectionClick();
                                            await DeviceCompatibilityService.requestIgnoreBatteryOptimizations();
                                            final unrestricted = await DeviceCompatibilityService.isIgnoringBatteryOptimizations();
                                            if (mounted) {
                                              setState(() => _isBatteryUnrestricted = unrestricted);
                                            }
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isBatteryUnrestricted == true
                                            ? Colors.green.withValues(alpha: 0.15)
                                            : colorScheme.errorContainer.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _isBatteryUnrestricted == true
                                              ? Colors.green.withValues(alpha: 0.4)
                                              : colorScheme.error.withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isBatteryUnrestricted == true
                                                ? Icons.battery_charging_full_rounded
                                                : Icons.battery_alert_rounded,
                                            size: 13,
                                            color: _isBatteryUnrestricted == true
                                                ? Colors.green
                                                : colorScheme.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isBatteryUnrestricted == true
                                                ? 'Battery: Unrestricted'
                                                : 'Battery: Optimized (Tap to Fix)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _isBatteryUnrestricted == true
                                                  ? Colors.green
                                                  : colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _handleShizukuChipTap(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getShizukuChipColor(colorScheme).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getShizukuChipColor(colorScheme).withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getShizukuChipIcon(),
                                          size: 13,
                                          color: _getShizukuChipColor(colorScheme),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getShizukuChipLabel(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _getShizukuChipColor(colorScheme),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_shizukuStatus == ShizukuLiveStatus.active ||
                                    _binderLatencyMs != null ||
                                    _isTestingBinder)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _testBinderLatency,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiaryContainer
                                            .withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorScheme.tertiary
                                              .withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.speed_rounded,
                                            size: 13,
                                            color: colorScheme.tertiary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isTestingBinder
                                                ? 'Testing...'
                                                : _binderLatencyMs != null
                                                    ? 'IPC: ${_binderLatencyMs}ms'
                                                    : 'Test IPC Ping',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onTertiaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: const Text('Copy Specs'),
                                  onPressed: () => _copySpecsToClipboard(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Guide Switcher Notice
                    if (!isViewingDetected) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Viewing instructions for ${_getOEMLabel(activeOEM)}.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () {
                                AppHaptics.selectionClick();
                                setState(() => _selectedOEM = _detectedOEM);
                              },
                              child: const Text('My Device'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.03),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<DeviceOEM>(activeOEM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Guide Header
                            Row(
                      children: [
                        Icon(
                          _getOEMIcon(guide.oem),
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            guide.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Action Shortcuts Section
                    if (guide.actions.isNotEmpty) ...[
                      Text(
                        'Direct Settings Shortcuts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...guide.actions.map(
                        (action) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.launch_rounded,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              action.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              action.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              onPressed: () async {
                                AppHaptics.lightImpact();
                                final ok = await action.action();
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Setting could not be opened automatically. Please check system settings.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Open'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Important Highlights Section
                    Text(
                      'Known OEM Behaviors & Sideload Pitfalls',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...guide.highlights.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3, right: 10),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 17,
                                color: colorScheme.error,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recommended Step-by-Step Setup
                    Text(
                      'Recommended Configuration Steps',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...guide.steps.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 10, top: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Shizuku & ShizukuPlus Hero Status Card
                    const ShizukuStatusCard(margin: EdgeInsets.zero),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

                    // Non-root / Non-ADB Pro-tip Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.tertiary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rootless Silent Updates (Android 14+)',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Enable "Update Ownership" and "User Pre-approval" in ObtainiumPlus Installation settings. Once pre-approved, your apps will update silently in the background without needing root or Shizuku!',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
