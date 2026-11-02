import 'package:android_package_manager/android_package_manager.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/utils/app_constants.dart';

/// What to do when the APK about to be installed is a different build of an
/// app that's already installed under another package name (Shizuku+ vs its
/// drop-in "Shizuku" build, an app's .fdroid or .debug variant, ...).
/// Installing it wouldn't update the installed app; it would add a second one.
enum VariantAction {
  /// Nothing else is installed, or the exact package is: install as usual.
  install,

  /// Show the choice dialog.
  ask,

  /// No one to ask (background run) and no remembered choice: hold the
  /// install rather than silently adding a second app.
  hold,
}

/// The user's answer in the dialog.
enum VariantChoice {
  /// Install, then uninstall the other build once the batch is done.
  replace,

  /// Install next to the other build.
  keepBoth,

  /// Skip this file and pick the build that's already installed.
  useInstalled,

  cancel,
}

/// An installed build that the APK would sit beside instead of updating.
class InstalledVariant {
  final String packageName;
  final String label;
  final String? versionName;
  final int userId;
  final String profileLabel;
  final String? installerPackage;

  const InstalledVariant({
    required this.packageName,
    required this.label,
    this.versionName,
    this.userId = 0,
    this.profileLabel = 'Main Profile',
    this.installerPackage,
  });
}

class AppVariantService {
  AppVariantService._();

  /// Per-app memory of "Keep both" with "Don't ask again" ticked.
  static const rememberedChoiceKey = 'variantChoice';
  static const keepBothValue = 'keepBoth';

  /// Packages that share an alias group but are separate apps, not builds of
  /// one app. Dhizuku is a device-owner service, not a Shizuku build.
  static const _notVariants = {AppConstants.dhizukuId};

  /// Suffixes that mark another build of the same app.
  static const _suffixes = [
    '.debug',
    '.beta',
    '.nightly',
    '.preview',
    '.foss',
    '.fdroid',
    '.plus',
    '.standalone',
  ];

  /// Package names that could be another build of [packageName].
  static Set<String> candidateVariants(
    String packageName, {
    String? url,
    String? name,
    List<String>? apkUrls,
  }) {
    if (_notVariants.contains(packageName)) return const {};
    final out = <String>{};

    // If packageName is a real package ID (contains a dot)
    if (packageName.contains('.')) {
      for (final group in AppConstants.packageAliasGroups) {
        if (group.contains(packageName)) out.addAll(group);
      }
      for (final s in _suffixes) {
        out.add('$packageName$s');
        if (packageName.endsWith(s)) {
          out.add(packageName.substring(0, packageName.length - s.length));
        }
      }
    }

    // Also check URL, name, or apkUrls keywords (crucial when app was added via GitHub before APK download,
    // where app.id is a hash or repo name like "1ccb9d856a86" or "ShizukuPlus")
    final lowerCombined =
        '${packageName.toLowerCase()} ${url?.toLowerCase() ?? ''} ${name?.toLowerCase() ?? ''} ${apkUrls?.join(' ').toLowerCase() ?? ''}';
    if (lowerCombined.contains('shizuku')) {
      out.addAll([AppConstants.shizukuPlusId, AppConstants.shizukuStockId]);
    }
    if (lowerCombined.contains('obtainium')) {
      out.addAll([
        AppConstants.obtainiumPlusId,
        'dev.imranr.obtainium',
        'dev.imranr.obtainium.fdroid',
        'dev.imranr.obtainium.debug',
      ]);
    }
    if (lowerCombined.contains('appmanager') ||
        lowerCombined.contains('app_manager')) {
      out.addAll([
        AppConstants.appManagerId,
        'io.github.muntashirakon.AppManager.debug',
      ]);
    }
    if (lowerCombined.contains('termux')) {
      out.addAll([AppConstants.termuxPlusId, 'com.termux']);
    }

    out
      ..remove(packageName)
      ..removeAll(_notVariants);
    return out;
  }

  static VariantAction decide({
    required bool apkPackageInstalled,
    required List<InstalledVariant> installedVariants,
    required String? rememberedChoice,
    required bool askEnabled,
    required bool hasContext,
  }) {
    if (apkPackageInstalled || installedVariants.isEmpty) {
      return VariantAction.install;
    }
    if (!askEnabled || rememberedChoice == keepBothValue) {
      return VariantAction.install;
    }
    return hasContext ? VariantAction.ask : VariantAction.hold;
  }

  /// Exact lookups only: the general installed-info helpers fall back to
  /// aliases, which would report the other build as this one.
  static Future<bool> isInstalledExactly(
    AndroidPackageManager pm,
    String packageName,
  ) async {
    try {
      return (await pm
              .getPackageInfo(
                packageName: packageName,
                flags: PackageInfoFlags(const {}),
              )
              .timeout(const Duration(seconds: 5))) !=
          null;
    } catch (_) {
      return false;
    }
  }

  static Future<List<InstalledVariant>> findInstalledVariants(
    AndroidPackageManager pm,
    String packageName,
  ) async {
    final found = <InstalledVariant>[];
    for (final candidate in candidateVariants(packageName)) {
      PackageInfo? info;
      try {
        info = await pm
            .getPackageInfo(
              packageName: candidate,
              flags: PackageInfoFlags(const {}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (info == null) continue;
      String? label;
      try {
        label = await pm.getApplicationLabel(packageName: candidate);
      } catch (_) {}
      found.add(
        InstalledVariant(
          packageName: candidate,
          label: (label == null || label.isEmpty) ? candidate : label,
          versionName: info.versionName,
        ),
      );
    }
    return found;
  }

  /// Finds all installed builds of [packageName] on device, including [packageName] itself,
  /// any aliases, drop-in builds, variant suffixes (.debug, .beta, .fdroid, etc.), and
  /// parallel space / multi-user profiles (Insular / Shelter work profiles, Dual Messenger, Dual Apps).
  static Future<List<InstalledVariant>> findAllInstalledVariants(
    AndroidPackageManager pm,
    String packageName, {
    String? url,
    String? name,
    List<String>? apkUrls,
  }) async {
    final targets = <String>{
      if (packageName.contains('.')) packageName,
      ...candidateVariants(packageName, url: url, name: name, apkUrls: apkUrls),
    };
    final found = <InstalledVariant>[];
    const channel = MethodChannel('dev.thejaustin.obtainiumplus/native');

    // 1. Query parallel profiles & dual messenger apps (native LauncherApps & UserManager)
    try {
      final List? profileApps = await channel.invokeListMethod(
        'getInstalledProfilesAndApps',
        {'packageName': packageName.contains('.') ? packageName : null},
      );
      if (profileApps != null) {
        for (final item in profileApps) {
          if (item is Map) {
            final pkg = item['packageName'] as String?;
            if (pkg != null && targets.contains(pkg)) {
              String? installer;
              try {
                installer = await channel.invokeMethod<String>(
                  'getInstallerPackageName',
                  {'packageName': pkg},
                );
              } catch (_) {}
              found.add(
                InstalledVariant(
                  packageName: pkg,
                  label: item['label'] as String? ?? pkg,
                  versionName: item['versionName'] as String?,
                  userId: item['userId'] as int? ?? 0,
                  profileLabel:
                      item['profileLabel'] as String? ?? 'Main Profile',
                  installerPackage: installer,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    // 2. Direct package manager lookups for any remaining targets not covered
    for (final candidate in targets) {
      if (found.any((v) => v.packageName == candidate && v.userId == 0)) {
        continue;
      }
      PackageInfo? info;
      try {
        info = await pm
            .getPackageInfo(
              packageName: candidate,
              flags: PackageInfoFlags(const {}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (info == null) continue;
      String? label;
      try {
        label = await pm.getApplicationLabel(packageName: candidate);
      } catch (_) {}
      String? installer;
      try {
        installer = await channel.invokeMethod<String>(
          'getInstallerPackageName',
          {'packageName': candidate},
        );
      } catch (_) {}
      found.add(
        InstalledVariant(
          packageName: candidate,
          label: (label == null || label.isEmpty) ? candidate : label,
          versionName: info.versionName,
          userId: 0,
          profileLabel: 'Main Profile',
          installerPackage: installer,
        ),
      );
    }
    return found;
  }

  /// Friendly store or installation origin label
  static String getInstallerLabel(String? installerPackage) {
    if (installerPackage == null || installerPackage.isEmpty) {
      return 'Sideloaded / Direct';
    }
    if (installerPackage == 'com.android.vending') return 'Google Play Store';
    if (installerPackage == 'com.sec.android.app.samsungapps')
      return 'Galaxy Store';
    if (installerPackage == 'com.aurora.store') return 'Aurora Store';
    if (installerPackage == 'org.fdroid.fdroid' ||
        installerPackage == 'com.looker.droidify') {
      return 'F-Droid';
    }
    if (installerPackage == AppConstants.obtainiumPlusId ||
        installerPackage == 'dev.imranr.obtainium') {
      return 'Obtainium+';
    }
    return installerPackage;
  }

  /// Human-friendly description for known variants (drop-in, standalone, debug, etc.)
  static String getVariantTypeLabel(String packageName) {
    if (packageName == AppConstants.shizukuStockId) {
      return 'Drop-in';
    }
    if (packageName == AppConstants.shizukuPlusId) {
      return 'Standalone Plus';
    }
    if (packageName.endsWith('.debug')) return 'Debug';
    if (packageName.endsWith('.beta')) return 'Beta';
    if (packageName.endsWith('.fdroid')) return 'F-Droid';
    if (packageName.endsWith('.foss')) return 'FOSS';
    if (packageName.endsWith('.plus')) return 'Plus';
    if (packageName.endsWith('.standalone')) return 'Standalone';
    return 'Standard';
  }

  /// Installing a new Shizuku manager doesn't start its service; the user
  /// has to open it once (and the old one's service stops when it's removed).
  static bool isShizukuManager(String packageName) =>
      packageName == AppConstants.shizukuPlusId ||
      packageName == AppConstants.shizukuStockId;
}
