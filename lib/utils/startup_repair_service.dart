import 'dart:io';
import 'package:obtainium/services/app_file_service.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle app repair and recovery in case of persistent crashes
class StartupRepairService {
  StartupRepairService._();

  /// Clears the icon cache to resolve potential image loading or corruption crashes
  static Future<void> clearIconCache() async {
    try {
      final dirs = await AppFileService.initAppDirectories();
      final iconsDir = dirs['iconsCacheDir'];
      if (iconsDir != null && iconsDir.existsSync()) {
        iconsDir.deleteSync(recursive: true);
        iconsDir.createSync(recursive: true);
        talker.info('Repair: Icon cache cleared');
      }
    } catch (e) {
      talker.error('Repair: Failed to clear icon cache: $e');
    }
  }

  /// Performs a factory reset by clearing all SharedPreferences
  static Future<void> factoryReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      talker.info(
        'Repair: Factory reset performed (SharedPreferences cleared)',
      );
    } catch (e) {
      talker.error('Repair: Factory reset failed: $e');
    }
  }

  /// Clears specifically problematic settings that might cause launch crashes
  /// (e.g. invalid URLs in recent apps, corrupted provider states)
  static Future<void> clearProviderStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = [
        'apps', // App list data
        'recent_apps',
        'source_configs',
        'plugin_state',
      ];
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      talker.info('Repair: Corrupted provider states cleared');
    } catch (e) {
      talker.error('Repair: Failed to clear provider states: $e');
    }
  }

  /// Resets crash analytics to allow normal operation after repair
  static Future<void> resetAnalytics() async {
    await CrashAnalytics.resetStats();
    talker.info('Repair: Crash analytics reset');
  }
}
