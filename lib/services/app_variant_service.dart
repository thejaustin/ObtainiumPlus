import 'package:android_package_manager/android_package_manager.dart';
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

  const InstalledVariant({
    required this.packageName,
    required this.label,
    this.versionName,
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
  static Set<String> candidateVariants(String packageName) {
    if (_notVariants.contains(packageName)) return const {};
    final out = <String>{
      for (final group in AppConstants.packageAliasGroups)
        if (group.contains(packageName)) ...group,
    };
    for (final s in _suffixes) {
      out.add('$packageName$s');
      if (packageName.endsWith(s)) {
        out.add(packageName.substring(0, packageName.length - s.length));
      }
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

  /// Installing a new Shizuku manager doesn't start its service; the user
  /// has to open it once (and the old one's service stops when it's removed).
  static bool isShizukuManager(String packageName) =>
      packageName == AppConstants.shizukuPlusId ||
      packageName == AppConstants.shizukuStockId;
}
