import 'dart:async';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:obtainium/services/adb_port_prober.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/device_utils.dart';

/// Device model info and instructions for specific Android OEMs.
class DeviceOptimizationGuide {
  final DeviceOEM oem;
  final String title;
  final String subtitle;
  final List<String> highlights;
  final List<String> steps;
  final List<DeviceActionItem> actions;

  const DeviceOptimizationGuide({
    required this.oem,
    required this.title,
    required this.subtitle,
    required this.highlights,
    required this.steps,
    required this.actions,
  });
}

/// Action item representing a settings shortcut button.
class DeviceActionItem {
  final String label;
  final String description;
  final Future<bool> Function() action;

  const DeviceActionItem({
    required this.label,
    required this.description,
    required this.action,
  });
}

/// Service providing device-specific shortcuts and installation optimizations
/// for various Android OEMs (Samsung One UI, Xiaomi HyperOS/MIUI, OnePlus/OPPO
/// OxygenOS/ColorOS, Nothing OS, Vivo, Huawei, etc.).
class DeviceCompatibilityService {
  DeviceCompatibilityService._();

  static const String _appId = AppConstants.obtainiumPlusId;

  // --------------------------------------------------------------------------
  // Samsung One UI Specific Methods
  // --------------------------------------------------------------------------

  /// Opens Samsung Auto Blocker settings (One UI 6.0+ / Android 14+ / One UI 8+).
  /// Auto Blocker blocks sideloading and non-store package installations by default.
  /// Targets the dedicated rampart package introduced in One UI 6.1+, falling back
  /// to legacy settings components.
  static Future<bool> openSamsungAutoBlockerSettings() async {
    final intents = [
      // One UI 6.1+ / One UI 7 / One UI 8 dedicated rampart setting activity
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.samsung.android.rampart/com.samsung.android.rampart.ui.MainSettingActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'com.samsung.android.settings.AUTO_BLOCKER',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.android.settings/com.samsung.android.settings.autoblocker.AutoBlockerSettingsActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.settings.SECURITY_ADVANCED_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'com.samsung.android.intent.action.AUTO_BLOCKER_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.samsung.android.sm.policy/com.samsung.android.sm.policy.ui.AutoBlockerActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.samsung.android.sm/com.samsung.android.sm.ui.security.AutoBlockerActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.settings.SECURITY_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Samsung "Never sleeping apps" / Battery background limits settings.
  /// Directs user to the "Never sleeping apps" whitelist (activity_type=2).
  static Future<bool> openSamsungNeverSleepingAppsSettings() async {
    final intents = [
      AndroidIntent(
        action: 'com.samsung.android.sm.ACTION_OPEN_CHECKABLE_LISTACTIVITY',
        componentName:
            'com.samsung.android.lool/com.samsung.android.sm.battery.ui.usage.CheckableAppListActivity',
        arguments: {'activity_type': 2},
        flags: const [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'com.samsung.android.sm.ACTION_BACKGROUND_USAGE_LIMITS',
        componentName:
            'com.samsung.android.lool/com.samsung.android.sm.ui.battery.BackgroundUsageLimitsActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'com.samsung.android.sm.ACTION_BATTERY',
        componentName:
            'com.samsung.android.lool/com.samsung.android.sm.battery.ui.BatteryActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.samsung.android.lool/com.samsung.android.sm.battery.ui.BatteryActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.samsung.android.sm/com.samsung.android.sm.ui.battery.BatteryActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Samsung Device Care / App Protection (McAfee) settings.
  static Future<bool> openSamsungAppProtectionSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.samsung.android.sm/com.samsung.android.sm.ui.security.SecurityActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.samsung.android.lool/com.samsung.android.sm.ui.security.SecurityActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // Xiaomi / HyperOS / MIUI Specific Methods
  // --------------------------------------------------------------------------

  /// Opens Xiaomi Autostart management settings.
  static Future<bool> openXiaomiAutostartSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'miui.intent.action.OP_AUTO_START',
        componentName:
            'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.miui.securitycenter',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Xiaomi Battery Saver settings to set "No restrictions".
  static Future<bool> openXiaomiBatterySaverSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'miui.intent.action.POWER_HIDE_MODE_LIST',
        componentName:
            'com.miui.securitycenter/com.miui.powercenter.PowerSettings',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.miui.powerkeeper/com.miui.powerkeeper.ui.HiddenAppsConfigActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Xiaomi Special App Access / Install Unknown Apps.
  static Future<bool> openXiaomiInstallUnknownApps() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.miui.securitycenter/com.miui.permcenter.install.SpecialAppAccessActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
        data: 'package:$_appId',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Xiaomi Developer Options (useful for disabling MIUI / System Optimization).
  static Future<bool> openXiaomiDeveloperSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // OnePlus / OPPO / Realme (OxygenOS / ColorOS / Realme UI) Specific Methods
  // --------------------------------------------------------------------------

  /// Opens OxygenOS/ColorOS Auto-launch / Startup permissions.
  static Future<bool> openOppoOnePlusAutoLaunchSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.coloros.safecenter/com.coloros.safecenter.startupapp.StartupAppListActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.oplus.safecenter/com.oplus.safecenter.permission.startup.StartupAppListActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.coloros.safecenter/com.coloros.safecenter.permission.floatwindow.FloatWindowListActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens OxygenOS/ColorOS Battery Optimization / App Battery Usage.
  static Future<bool> openOppoOnePlusBatterySettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.coloros.oppoguardelf/com.coloros.powermanager.fuelgaue.PowerUsageModelActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.oplus.battery/com.oplus.powermanager.fuelgaue.PowerUsageModelActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // Nothing OS Specific Methods
  // --------------------------------------------------------------------------

  /// Opens Nothing OS App Battery settings.
  static Future<bool> openNothingBatterySettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'action_application_details_settings',
        data: 'package:$_appId',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // Vivo / iQOO (Funtouch OS / OriginOS) Specific Methods
  // --------------------------------------------------------------------------

  /// Opens Vivo Autostart settings.
  static Future<bool> openVivoAutostartSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.vivo.permissionmanager/com.vivo.permissionmanager.activity.PurviewTabActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Vivo High Background Power consumption settings.
  static Future<bool> openVivoHighBackgroundPowerSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.vivo.abe/com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // Transsion (Tecno HiOS / Infinix XOS / Itel itelOS) Specific Methods
  // --------------------------------------------------------------------------

  /// Opens Transsion Phone Master Autostart settings.
  static Future<bool> openTranssionAutoStartSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.transsion.phonemaster/com.transsion.phonemaster.autostart.AutoStartActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.transsion.phonemaster/com.transsion.phonemaster.permission.AutoStartListActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.transsion.phonemaster/com.transsion.phonemaster.MainActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Transsion Power Marathon / Power Center settings.
  static Future<bool> openTranssionPowerCenterSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'com.transsion.phonemaster.action.POWER_MANAGEMENT',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.transsion.powercenter/com.transsion.powercenter.PowerCenterActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // Huawei / Honor (EMUI / MagicOS) Specific Methods
  // --------------------------------------------------------------------------

  /// Opens Huawei Startup Management settings.
  static Future<bool> openHuaweiAutostartSettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.huawei.systemmanager/com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        componentName:
            'com.huawei.systemmanager/com.huawei.systemmanager.optimize.process.ProtectActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  // --------------------------------------------------------------------------
  // General Device Settings Shortcuts
  // --------------------------------------------------------------------------

  /// Opens system Battery Optimization settings list.
  static Future<bool> openBatteryOptimizationSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens Install Unknown Apps setting for the app.
  static Future<bool> openInstallUnknownAppsSettings() async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
        data: 'package:$_appId',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens App Info details in OS settings.
  static Future<bool> openAppDetailsSettings() async {
    try {
      final intent = AndroidIntent(
        action: 'action_application_details_settings',
        data: 'package:$_appId',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether ObtainiumPlus is exempt from Android OS battery optimizations.
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      const channel = MethodChannel('dev.thejaustin.obtainiumplus/native');
      final bool? result = await channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests exemption from Android OS battery optimizations (displays system dialog).
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      const channel = MethodChannel('dev.thejaustin.obtainiumplus/native');
      final bool? result = await channel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Motorola battery usage and background restriction settings.
  static Future<bool> openMotorolaBatterySettings() async {
    final intents = [
      const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'action_application_details_settings',
        data: 'package:$_appId',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens Shizuku or ShizukuPlus manager app.
  static Future<bool> openShizukuManager() async {
    final intents = [
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: AppConstants.shizukuPlusId,
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'moe.shizuku.privileged.api',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
      const AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'bin.xposed.Dhizuku',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      ),
    ];
    for (final intent in intents) {
      try {
        await intent.launch();
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Probes whether ADB daemon is actively listening on local loopback (port 5555).
  static Future<int?> probeActiveAdbPort() async {
    return AdbPortProber.findActiveLoopbackPort();
  }


  // --------------------------------------------------------------------------
  // Device Guides for Non-Root / Non-ADB Users
  // --------------------------------------------------------------------------

  /// Returns tailored optimization guide and shortcuts for the specified OEM.
  static DeviceOptimizationGuide getGuideForOEM(DeviceOEM oem) {
    switch (oem) {
      case DeviceOEM.samsung:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Samsung One UI Optimization',
          subtitle: 'Resolve Auto Blocker, App Protection scans & background sleep',
          highlights: [
            'One UI 6.0+ Auto Blocker can silently block APK sideloading and package sessions.',
            'Shizuku / ShizukuPlus elevated binder completely bypasses One UI Auto Blocker restrictions.',
            'Samsung App Protection (McAfee) pauses installation for 5–10s to verify APKs.',
            'Battery Background Limits puts download workers to sleep when the screen turns off.',
          ],
          steps: [
            'Disable Auto Blocker: Settings → Security and privacy → Auto Blocker → Turn OFF (or disable "Block apps from unauthorized sources").',
            'Add to Never Sleeping Apps: Settings → Battery → Background usage limits → Never sleeping apps → Add ObtainiumPlus.',
            'Install Unknown Apps: Enable "Allow from this source" for ObtainiumPlus.',
            'Fast Package Verification: Keep Turbo Verification ON for instant completion.',
          ],
          actions: [
            DeviceActionItem(
              label: 'Auto Blocker Settings',
              description: 'Disable sideloading block on One UI 6+',
              action: openSamsungAutoBlockerSettings,
            ),
            DeviceActionItem(
              label: 'Never Sleeping Apps',
              description: 'Prevent Samsung from killing downloads',
              action: openSamsungNeverSleepingAppsSettings,
            ),
            DeviceActionItem(
              label: 'Install Unknown Apps',
              description: 'Grant native install permission',
              action: openInstallUnknownAppsSettings,
            ),
            DeviceActionItem(
              label: 'Shizuku / ShizukuPlus Manager',
              description: 'Manage elevated installer bypass',
              action: openShizukuManager,
            ),
          ],
        );

      case DeviceOEM.xiaomi:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Xiaomi HyperOS & MIUI Optimization',
          subtitle: 'Bypass MIUI installer delays, configure Autostart & Battery',
          highlights: [
            'MIUI Security installer intercepts session installs with 5–10s countdowns.',
            'Shizuku / ShizukuPlus elevated mode eliminates the MIUI Security countdown completely.',
            'Without Autostart permission, background update checks and downloads are terminated immediately.',
            'MIUI Battery Saver restricts background networking when app is closed.',
          ],
          steps: [
            'Enable Autostart: Security app → Permissions → Autostart → Enable for ObtainiumPlus.',
            'Set Battery to No Restrictions: App Info → Battery saver → No restrictions.',
            'Disable MIUI/System Optimization (Optional): Developer Options → Disable "Turn on system optimization" to restore 100% native Android package installer without countdowns.',
          ],
          actions: [
            DeviceActionItem(
              label: 'Autostart Settings',
              description: 'Allow background updates & downloads',
              action: openXiaomiAutostartSettings,
            ),
            DeviceActionItem(
              label: 'Battery Saver (No Restrictions)',
              description: 'Prevent MIUI background freezing',
              action: openXiaomiBatterySaverSettings,
            ),
            DeviceActionItem(
              label: 'Developer Options',
              description: 'Access System Optimization toggle',
              action: openXiaomiDeveloperSettings,
            ),
            DeviceActionItem(
              label: 'Shizuku / ShizukuPlus Manager',
              description: 'Eliminate MIUI installation countdowns',
              action: openShizukuManager,
            ),
          ],
        );

      case DeviceOEM.oneplus:
      case DeviceOEM.oppo:
      case DeviceOEM.realme:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'OnePlus & OPPO (OxygenOS / ColorOS)',
          subtitle: 'Enable Auto-launch, background activity & unrestricted power',
          highlights: [
            'OxygenOS / ColorOS aggressively freezes network sockets when downloading in background.',
            'PackageInstaller sessions may stall if Auto-launch is disabled.',
          ],
          steps: [
            'Enable Auto-launch: Phone Manager → Privacy permissions → Startup manager → Enable ObtainiumPlus.',
            'Allow Background Activity: App Info → Battery usage → Allow background activity.',
            'Turn off Battery Optimization: Settings → Battery → Advanced settings → Optimize battery use → Don\'t optimize.',
          ],
          actions: [
            DeviceActionItem(
              label: 'Auto-launch Settings',
              description: 'Allow startup & background activity',
              action: openOppoOnePlusAutoLaunchSettings,
            ),
            DeviceActionItem(
              label: 'Battery Usage Settings',
              description: 'Allow unrestricted background power',
              action: openOppoOnePlusBatterySettings,
            ),
            DeviceActionItem(
              label: 'Install Unknown Apps',
              description: 'Grant native install permission',
              action: openInstallUnknownAppsSettings,
            ),
          ],
        );

      case DeviceOEM.nothing:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Nothing OS Optimization',
          subtitle: 'Leverage pure Android session installs with Unrestricted Battery',
          highlights: [
            'Nothing OS supports ultra-clean native PackageInstaller sessions and Android 14 User Pre-approval.',
            'Nothing OS RAM management aggressively reclaims background memory during large file downloads unless battery is Unrestricted.',
          ],
          steps: [
            'Set Battery to Unrestricted: App Info → App battery usage → Select "Unrestricted".',
            'Grant Unknown Apps: Enable "Allow from this source".',
            'Enable User Pre-approval: Under Installation settings, ensure Android 14 User Pre-approval is ON for seamless 1-tap unattended updates without root or ADB.',
          ],
          actions: [
            DeviceActionItem(
              label: 'App Battery Usage',
              description: 'Set to Unrestricted for uninterrupted downloads',
              action: openNothingBatterySettings,
            ),
            DeviceActionItem(
              label: 'Install Unknown Apps',
              description: 'Grant native install permission',
              action: openInstallUnknownAppsSettings,
            ),
          ],
        );

      case DeviceOEM.vivo:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Vivo & iQOO (Funtouch OS / OriginOS)',
          subtitle: 'Enable High Background Power and Autostart Whitelist',
          highlights: [
            'Vivo Funtouch OS strictly cuts background download threads after 3 minutes.',
            'Autostart whitelist is required for timely update notifications.',
          ],
          steps: [
            'Enable Autostart: iManager → App management → Autostart manager → Enable ObtainiumPlus.',
            'High Background Power: Settings → Battery → High background power consumption → Enable for ObtainiumPlus.',
          ],
          actions: [
            DeviceActionItem(
              label: 'Autostart Manager',
              description: 'Whitelist ObtainiumPlus for startup',
              action: openVivoAutostartSettings,
            ),
            DeviceActionItem(
              label: 'High Background Power',
              description: 'Allow unlimited background consumption',
              action: openVivoHighBackgroundPowerSettings,
            ),
          ],
        );

      case DeviceOEM.transsion:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Transsion (Tecno HiOS / Infinix XOS / itelOS)',
          subtitle: 'Prevent Phone Master & Power Marathon from killing downloads',
          highlights: [
            'Phone Master aggressively terminates background tasks within 30 seconds of screen off.',
            'Power Marathon freezes active HTTP sockets, causing download timeouts.',
            'HiOS/XOS package installer shows a 5-second security countdown on sideloaded APKs.',
          ],
          steps: [
            'Enable Autostart: Phone Master → App management → Auto-start management → Enable ObtainiumPlus.',
            'Bypass Power Marathon: Settings → Battery Lab / Power Marathon → Battery optimization → ObtainiumPlus → Don\'t optimize.',
            'Allow Unknown Apps: Settings → Special app access → Install unknown apps → ObtainiumPlus → Allow.',
          ],
          actions: [
            DeviceActionItem(
              label: 'Phone Master Auto-start',
              description: 'Whitelist ObtainiumPlus for startup',
              action: openTranssionAutoStartSettings,
            ),
            DeviceActionItem(
              label: 'Power Marathon / Center',
              description: 'Prevent background sleep and freeze',
              action: openTranssionPowerCenterSettings,
            ),
            DeviceActionItem(
              label: 'Battery Optimization',
              description: 'Disable aggressive battery saver',
              action: openBatteryOptimizationSettings,
            ),
          ],
        );

      case DeviceOEM.huawei:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Huawei & Honor (EMUI / MagicOS)',
          subtitle: 'Configure Protected Apps and App Launch Management',
          highlights: [
            'EMUI PowerGenie terminates background services when screen locks.',
          ],
          steps: [
            'Set App Launch to Manual: Settings → Battery → App launch → ObtainiumPlus → Manage manually (Enable Auto-launch, Secondary launch, and Run in background).',
            'Allow Unknown Apps: Settings → Security → More settings → Install apps from external sources.',
          ],
          actions: [
            DeviceActionItem(
              label: 'App Launch Management',
              description: 'Manage startup manually',
              action: openHuaweiAutostartSettings,
            ),
            DeviceActionItem(
              label: 'Battery Optimization',
              description: 'Ignore battery optimization',
              action: openBatteryOptimizationSettings,
            ),
          ],
        );

      case DeviceOEM.motorola:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Motorola MyUX Optimization',
          subtitle: 'Disable Adaptive Battery & background execution limits',
          highlights: [
            'Motorola MyUX aggressively sleeps background sockets when screen turns off.',
            'Adaptive Battery can delay periodic update checks by several hours.',
          ],
          steps: [
            'Set Battery to Unrestricted: Settings → Apps → ObtainiumPlus → App battery usage → Select "Unrestricted".',
            'Disable Background Data Restrictions: Settings → Apps → ObtainiumPlus → Mobile data & Wi-Fi → Enable "Unrestricted data usage".',
            'Allow Unknown Apps: Settings → Apps → Special app access → Install unknown apps → ObtainiumPlus → Allow.',
          ],
          actions: [
            DeviceActionItem(
              label: 'Battery Usage Settings',
              description: 'Set battery to Unrestricted',
              action: openMotorolaBatterySettings,
            ),
            DeviceActionItem(
              label: 'Install Unknown Apps',
              description: 'Grant native install permission',
              action: openInstallUnknownAppsSettings,
            ),
          ],
        );

      default:
        return DeviceOptimizationGuide(
          oem: oem,
          title: 'Stock Android / Pixel Optimization',
          subtitle: 'Unrestricted background performance and native silent updates',
          highlights: [
            'Android 12+ supports unattended updates when Obtainium is the installing package.',
            'Android 14+ supports User Pre-approval for seamless background installs without root or ADB.',
          ],
          steps: [
            'Set Battery to Unrestricted: Settings → Apps → ObtainiumPlus → Battery → Unrestricted.',
            'Grant Unknown Sources: Settings → Apps → Special app access → Install unknown apps → ObtainiumPlus → Allowed.',
            'Enable Update Ownership: In Installation settings, enable Android 14 Update Ownership for seamless future updates.',
          ],
          actions: [
            DeviceActionItem(
              label: 'Battery Optimization',
              description: 'Set to Unrestricted',
              action: openBatteryOptimizationSettings,
            ),
            DeviceActionItem(
              label: 'Install Unknown Apps',
              description: 'Grant native install permission',
              action: openInstallUnknownAppsSettings,
            ),
          ],
        );
    }
  }
}
