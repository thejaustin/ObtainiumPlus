import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/components/settings/diagnostic_page_scaffold.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/shizuku_status_card.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/services/device_compatibility_service.dart';
import 'package:obtainium/services/shizuku_status_service.dart';
import 'package:obtainium/services/usage_stats_service.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

/// Opens Service Doctor (device compatibility & performance).
///
/// It used to be a bottom sheet that embedded the Shizuku status card,
/// whose "Service Doctor" chip opened the sheet again, stacking copies. It is
/// long-form reference content, so it's a page now.
Future<void> showDeviceOptimizationSheet({required BuildContext context}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const DeviceOptimizationPage()),
  );
}

class DeviceOptimizationPage extends StatefulWidget {
  const DeviceOptimizationPage({super.key});

  @override
  State<DeviceOptimizationPage> createState() => _DeviceOptimizationPageState();
}

class _DeviceOptimizationPageState extends State<DeviceOptimizationPage>
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
  bool? _isUsageAccessGranted;

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
    if (state == AppLifecycleState.resumed) _refreshLiveStatus();
  }

  Future<void> _refreshLiveStatus() async {
    bool? unrestricted;
    bool? usage;
    try {
      unrestricted =
          await DeviceCompatibilityService.isIgnoringBatteryOptimizations();
    } catch (_) {}
    try {
      usage = await UsageStatsService.isUsageAccessGranted();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isBatteryUnrestricted = unrestricted;
      _isUsageAccessGranted = usage;
    });
    // The status card on this page re-probes Shizuku itself; both read the
    // shared ShizukuStatusService result.
    try {
      await ShizukuStatusService.instance.refreshFrom(context);
    } catch (_) {}
  }

  Future<void> _loadDeviceInfo() async {
    DeviceOEM oem = DeviceOEM.generic;
    String summary = '';
    try {
      oem = await DeviceUtils.getDeviceOEM();
      summary = await DeviceUtils.getDeviceSummary();
      final info = await DeviceUtils.getAndroidInfo();
      _deviceManufacturer = info.manufacturer;
      _deviceModel = info.model;
      _androidVersion = info.version.release;
      _sdkInt = info.version.sdkInt;
    } catch (_) {}
    await _refreshLiveStatus();
    if (!mounted) return;
    setState(() {
      _detectedOEM = oem;
      _selectedOEM ??= oem;
      _deviceSummary = summary;
      _isLoading = false;
    });
  }

  String _oemLabel(DeviceOEM oem) {
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
        return tr('serviceDoctorStockAndroid');
    }
  }

  IconData _oemIcon(DeviceOEM oem) {
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

  void _copySpecs() {
    AppHaptics.lightImpact();
    final specs = _deviceSummary.isNotEmpty
        ? _deviceSummary
        : '$_deviceManufacturer $_deviceModel\n'
              'Android $_androidVersion (API $_sdkInt)\n'
              '${_oemLabel(_detectedOEM)}';
    Clipboard.setData(ClipboardData(text: specs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('specsCopiedToClipboard')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _fixBattery() async {
    AppHaptics.selectionClick();
    await DeviceCompatibilityService.requestIgnoreBatteryOptimizations();
    final unrestricted =
        await DeviceCompatibilityService.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _isBatteryUnrestricted = unrestricted);
  }

  Future<void> _onShizukuTap(ShizukuStatusSnapshot? snap) async {
    if (snap == null) return;
    AppHaptics.selectionClick();
    switch (snap.state) {
      case ShizukuServiceState.permissionNeeded:
        try {
          await ShizukuApkInstaller().checkPermission();
        } catch (_) {}
        if (mounted) unawaited(_refreshLiveStatus());
      case ShizukuServiceState.notRunning:
        await ShizukuInstaller.openShizukuManager();
      case ShizukuServiceState.active:
      case ShizukuServiceState.notInstalled:
        break;
    }
  }

  Widget _shizukuTile(ShizukuStatusSnapshot? snap) {
    final cs = Theme.of(context).colorScheme;
    final name = snap?.providerLabel ?? 'Shizuku+';
    final String title;
    final String subtitle;
    final IconData icon;
    final Color color;
    if (snap == null) {
      title = tr('checkingShizukuStatus');
      subtitle = tr('probingDaemon');
      icon = Icons.hourglass_top_rounded;
      color = cs.onSurfaceVariant;
    } else {
      switch (snap.state) {
        case ShizukuServiceState.active:
          title = tr('serviceDoctorShizukuActive', args: [name]);
          subtitle = tr('serviceDoctorShizukuActiveDesc', args: [name]);
          icon = Icons.electric_bolt_rounded;
          color = cs.primary;
        case ShizukuServiceState.permissionNeeded:
          title = tr('serviceDoctorShizukuPermission', args: [name]);
          subtitle = tr('serviceDoctorShizukuPermissionDesc', args: [name]);
          icon = Icons.key_rounded;
          color = cs.tertiary;
        case ShizukuServiceState.notRunning:
          title = tr('serviceDoctorShizukuStopped', args: [name]);
          subtitle = tr('serviceDoctorShizukuStoppedDesc', args: [name]);
          icon = Icons.power_off_rounded;
          color = cs.error;
        case ShizukuServiceState.notInstalled:
          title = tr('serviceDoctorShizukuMissing');
          subtitle = tr('serviceDoctorShizukuMissingDesc');
          icon = Icons.verified_user_outlined;
          color = cs.onSurfaceVariant;
      }
    }
    final actionable =
        snap?.state == ShizukuServiceState.permissionNeeded ||
        snap?.state == ShizukuServiceState.notRunning;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: actionable ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: actionable ? () => _onShizukuTap(snap) : null,
    );
  }

  Widget _buildDeviceGroup() {
    final cs = Theme.of(context).colorScheme;
    final deviceName = _deviceModel.isNotEmpty
        ? '$_deviceManufacturer $_deviceModel'
        : tr('serviceDoctorDeviceUnknown');
    return ExpressiveSettingsGroup(
      title: tr('serviceDoctorThisDevice'),
      icon: Icons.smartphone_rounded,
      children: [
        ListTile(
          leading: Icon(_oemIcon(_detectedOEM)),
          title: Text(deviceName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            tr(
              'serviceDoctorAndroidVersion',
              args: [_androidVersion, '$_sdkInt', _oemLabel(_detectedOEM)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: tr('copySpecs'),
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copySpecs,
          ),
        ),
        if (_isBatteryUnrestricted != null)
          ListTile(
            leading: Icon(
              _isBatteryUnrestricted!
                  ? Icons.battery_charging_full_rounded
                  : Icons.battery_alert_rounded,
              color: _isBatteryUnrestricted! ? cs.primary : cs.error,
            ),
            title: Text(
              _isBatteryUnrestricted!
                  ? tr('batteryUnrestricted')
                  : tr('batteryOptimized'),
            ),
            subtitle: Text(
              _isBatteryUnrestricted!
                  ? tr('serviceDoctorBatteryOk')
                  : tr('serviceDoctorBatteryFix'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _isBatteryUnrestricted!
                ? null
                : const Icon(Icons.chevron_right_rounded),
            onTap: _isBatteryUnrestricted! ? null : _fixBattery,
          ),
        ValueListenableBuilder<ShizukuStatusSnapshot?>(
          valueListenable: ShizukuStatusService.instance.status,
          builder: (_, snap, _) => _shizukuTile(snap),
        ),
        if (_isUsageAccessGranted != null)
          // The full Usage access card lives in Settings > Behavior, next to
          // the feature that uses it; this row only reports and links out.
          ListTile(
            leading: Icon(
              Icons.query_stats_rounded,
              color: _isUsageAccessGranted! ? cs.primary : cs.tertiary,
            ),
            title: Text(tr('serviceDoctorUsageAccess')),
            subtitle: Text(
              _isUsageAccessGranted!
                  ? tr('serviceDoctorUsageAccessGranted')
                  : tr('serviceDoctorUsageAccessMissing'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () async {
              AppHaptics.selectionClick();
              await UsageStatsService.openUsageAccessSettings();
            },
          ),
      ],
    );
  }

  Widget _buildOemPicker(DeviceOEM active) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('service_doctor_oem_chips'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        spacing: 8,
        children: [
          for (final oem in _supportedOEMs)
            ChoiceChip(
              showCheckmark: false,
              avatar: Icon(_oemIcon(oem)),
              label: Text(
                oem == _detectedOEM
                    ? '${_oemLabel(oem)} · ${tr('you')}'
                    : _oemLabel(oem),
              ),
              selected: oem == active,
              onSelected: (selected) {
                if (!selected) return;
                AppHaptics.selectionClick();
                setState(() => _selectedOEM = oem);
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGuide(DeviceOEM active) {
    final cs = Theme.of(context).colorScheme;
    final guide = DeviceCompatibilityService.getGuideForOEM(active);
    return [
      ExpressiveSettingsGroup(
        title: guide.title,
        description: guide.subtitle,
        icon: _oemIcon(guide.oem),
        children: [
          if (active != _detectedOEM)
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(
                tr('serviceDoctorViewingOther', args: [_oemLabel(active)]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  setState(() => _selectedOEM = _detectedOEM);
                },
                child: Text(tr('myDevice')),
              ),
            ),
          for (final action in guide.actions)
            ListTile(
              leading: const Icon(Icons.launch_rounded),
              title: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                action.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                AppHaptics.lightImpact();
                final ok = await action.action();
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('serviceDoctorSettingNotOpened')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
        ],
      ),
      if (guide.highlights.isNotEmpty)
        ExpressiveSettingsGroup(
          title: tr('knownOEMBehaviors'),
          icon: Icons.warning_amber_rounded,
          children: [
            for (final item in guide.highlights)
              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: cs.tertiary),
                title: Text(item),
              ),
          ],
        ),
      if (guide.steps.isNotEmpty)
        ExpressiveSettingsGroup(
          title: tr('recommendedConfigurationSteps'),
          icon: Icons.checklist_rounded,
          children: [
            for (final entry in guide.steps.asMap().entries)
              ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  child: Text(
                    '${entry.key + 1}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(entry.value),
              ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final active = _selectedOEM ?? _detectedOEM;
    return DiagnosticPageScaffold(
      title: tr('serviceDoctor'),
      subtitle: tr('devicePerformanceAndCompatibility'),
      storageKey: 'service_doctor_scroll',
      children: _isLoading
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: ExpressiveCircularProgressIndicator()),
              ),
            ]
          : [
              _buildDeviceGroup(),
              // Live provider status, with the one binder latency retest.
              const ShizukuStatusCard(
                margin: EdgeInsets.zero,
                showDoctorChip: false,
              ),
              ExpressiveSettingsGroup(
                title: tr('serviceDoctorOemGuide'),
                description: tr('devicePerformanceAndCompatibilitySubtitle'),
                icon: Icons.tune_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _buildOemPicker(active),
                  ),
                ],
              ),
              ..._buildGuide(active),
              ExpressiveSettingsGroup(
                title: tr('rootlessSilentUpdates'),
                icon: Icons.verified_user_outlined,
                children: [
                  ListTile(
                    leading: const Icon(Icons.system_update_rounded),
                    title: Text(tr('rootlessSilentUpdatesDesc')),
                  ),
                ],
              ),
            ],
    );
  }
}
