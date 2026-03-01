import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/app_sources/apkpure.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/version_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalAppUpdate {
  final String appId;
  final String name;
  final String currentVersion;
  final String latestVersion;
  final String? author;
  final DateTime? releaseDate;

  ExternalAppUpdate({
    required this.appId,
    required this.name,
    required this.currentVersion,
    required this.latestVersion,
    this.author,
    this.releaseDate,
  });
}

class PlayStoreMirrorService {
  PlayStoreMirrorService._();

  static final APKPure _backend = APKPure();

  static Future<List<ExternalAppUpdate>> scanForUpdates({
    required Map<String, AppInMemory> trackedApps,
    Function(int current, int total)? onProgress,
  }) async {
    final List<PackageInfo> installed = await AppInstallService.getAllInstalledInfo();
    final List<ExternalAppUpdate> updates = [];
    
    // Filter out system apps and tracked apps
    final List<PackageInfo> untracked = installed.where((pkg) {
      if (pkg.packageName == null) return false;
      
      // Ignore apps already tracked in Obtainium
      if (trackedApps.containsKey(pkg.packageName)) return false;
      
      // Ignore common system/google packages that we shouldn't manage
      if (pkg.packageName!.startsWith('com.android.') || 
          pkg.packageName!.startsWith('com.google.android.gms') ||
          pkg.packageName == 'android') return false;
          
      return true;
    }).toList();

    int count = 0;
    for (final pkg in untracked) {
      count++;
      onProgress?.call(count, untracked.length);
      
      try {
        // We use a timeout to prevent slow scans from hanging
        final APKDetails details = await _backend.getLatestAPKDetails(
          'https://apkpure.com/any/${pkg.packageName}',
          {'autoApkFilterByArch': true},
        ).timeout(const Duration(seconds: 5));

        final String currentVersion = pkg.versionName ?? pkg.versionCode.toString();
        final String latestVersion = details.version;

        // Simple version comparison
        if (latestVersion != currentVersion) {
          final res = reconcileVersionDifferences(currentVersion, latestVersion);
          // If reconcile returns key=true, it means latest is actually newer
          if (res != null && res.key == true) {
            updates.add(ExternalAppUpdate(
              appId: pkg.packageName!,
              name: details.names.name,
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              author: details.names.author,
              releaseDate: details.releaseDate,
            ));
          }
        }
      } catch (e) {
        // Skip apps not found on the mirror or other errors
      }
    }

    return updates;
  }

  static Future<void> openInAuroraStore(String appId) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: 'market://details?id=$appId',
      package: 'com.aurora.store', // Force Aurora Store if installed
    );
    try {
      await intent.launch();
    } catch (e) {
      // Fallback to any market handler
      final fallback = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'market://details?id=$appId',
      );
      await fallback.launch();
    }
  }

  static Future<void> openInPlayStore(String appId, {bool useAppLinks = true}) async {
    if (useAppLinks) {
      // Try using app links (https URL) first
      final playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=$appId');
      if (await canLaunchUrl(playStoreUri)) {
        try {
          await launchUrl(
            playStoreUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          return;
        } catch (e) {
          // Fall through to intent-based approach
        }
      }
    }
    
    // Fallback to Android Intent with market:// scheme
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: 'https://play.google.com/store/apps/details?id=$appId',
      package: 'com.android.vending',
    );
    try {
      await intent.launch();
    } catch (e) {
      // Try market:// scheme as final fallback
      final marketIntent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'market://details?id=$appId',
      );
      await marketIntent.launch();
    }
  }

  /// Open app in a specific store or source
  static Future<void> openInSource({
    required String appId,
    required String source,
    String? packageName,
  }) async {
    switch (source) {
      case 'play_store':
        await openInPlayStore(appId);
        break;
      case 'aurora':
        await openInAuroraStore(appId);
        break;
      case 'github':
        if (packageName != null) {
          final uri = Uri.parse('https://github.com/search?q=$packageName');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case 'apkpure':
        if (packageName != null) {
          final uri = Uri.parse('https://apkpure.com/any/$packageName');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      default:
        // Default to Play Store
        await openInPlayStore(appId);
    }
  }
}
