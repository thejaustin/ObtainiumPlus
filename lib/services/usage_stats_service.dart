import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shizuku_apk_installer/shizuku_apk_installer.dart';

/// Represents Android usage statistics for an installed package.
class AppUsageStats {
  final String packageName;
  final DateTime? lastTimeUsed;
  final Duration totalForegroundDuration;
  final DateTime? firstTimeStamp;
  final DateTime? lastTimeStamp;

  const AppUsageStats({
    required this.packageName,
    this.lastTimeUsed,
    this.totalForegroundDuration = Duration.zero,
    this.firstTimeStamp,
    this.lastTimeStamp,
  });

  factory AppUsageStats.fromMap(String packageName, Map<dynamic, dynamic> map) {
    final lastUsedMs = (map['lastTimeUsed'] as num?)?.toInt() ?? 0;
    final fgMs = (map['totalForegroundMs'] as num?)?.toInt() ?? 0;
    final firstMs = (map['firstTimeStamp'] as num?)?.toInt() ?? 0;
    final lastMs = (map['lastTimeStamp'] as num?)?.toInt() ?? 0;

    return AppUsageStats(
      packageName: packageName,
      lastTimeUsed: lastUsedMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastUsedMs)
          : null,
      totalForegroundDuration: Duration(milliseconds: fgMs),
      firstTimeStamp: firstMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(firstMs)
          : null,
      lastTimeStamp: lastMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : null,
    );
  }

  /// Returns a clean, human-readable relative time string (e.g. "Just now", "2h ago", "Never").
  String get relativeLastUsed {
    if (lastTimeUsed == null || lastTimeUsed!.millisecondsSinceEpoch == 0) {
      return 'Never';
    }
    final now = DateTime.now();
    final difference = now.difference(lastTimeUsed!);

    if (difference.isNegative) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Returns a clean formatted string for total foreground duration (e.g. "2h 15m", "< 1m").
  String get formattedForegroundDuration {
    if (totalForegroundDuration.inMinutes < 1) {
      if (totalForegroundDuration.inSeconds > 0) {
        return '${totalForegroundDuration.inSeconds}s';
      }
      return '< 1m';
    }
    final hours = totalForegroundDuration.inHours;
    final minutes = totalForegroundDuration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// Result of an automated or manual Usage Access grant attempt.
class UsageAccessGrantResult {
  final bool success;
  final String status;
  final String? method;
  final String? message;

  const UsageAccessGrantResult({
    required this.success,
    required this.status,
    this.method,
    this.message,
  });

  bool get isGranted => success || status == 'GRANTED';
}

/// Service providing query and management of Android Usage Access (`PACKAGE_USAGE_STATS`).
class UsageStatsService {
  static const MethodChannel _channel = MethodChannel(
    'dev.thejaustin.obtainiumplus/native',
  );

  static Map<String, AppUsageStats>? _cachedUsageStats;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(seconds: 45);

  /// Checks if Usage Access is granted to Obtainium+.
  static Future<bool> isUsageAccessGranted() async {
    try {
      final granted = await _channel.invokeMethod<bool>('isUsageAccessGranted');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Android system Usage Access Settings screen.
  /// First tries with `package:dev.thejaustin.obtainiumplus`, falling back to general list.
  static Future<bool> openUsageAccessSettings() async {
    try {
      final opened = await _channel.invokeMethod<bool>(
        'openUsageAccessSettings',
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to grant Usage Access silently via Shizuku shell IPC.
  /// Falls back to root shell (`su`) if Shizuku is not running on a rooted device.
  static Future<UsageAccessGrantResult> grantWithShizuku() async {
    try {
      // 1. Proactively ensure Shizuku permission has been requested if Shizuku is alive
      try {
        final perm = await ShizukuApkInstaller().checkPermission();
        if (perm == 'services_not_found') {
          // Shizuku is not running; native call will attempt root fallback if available
        }
      } catch (_) {}

      // 2. Invoke privileged native appops grant
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'grantUsageAccessShizuku',
      );

      if (res != null) {
        final success = res['success'] == true;
        final status =
            (res['status'] as String?) ?? (success ? 'GRANTED' : 'FAILED');
        final method = res['method'] as String?;
        final message = res['message'] as String?;

        if (success) {
          invalidateCache();
        }

        return UsageAccessGrantResult(
          success: success,
          status: status,
          method: method,
          message: message,
        );
      }

      final verified = await isUsageAccessGranted();
      return UsageAccessGrantResult(
        success: verified,
        status: verified ? 'GRANTED' : 'FAILED',
        method: 'shizuku',
      );
    } catch (e) {
      final verified = await isUsageAccessGranted();
      return UsageAccessGrantResult(
        success: verified,
        status: verified ? 'GRANTED' : 'ERROR',
        message: e.toString(),
      );
    }
  }

  /// Queries all aggregated usage stats across the given timeframe (default: past 365 days).
  static Future<Map<String, AppUsageStats>> getAllUsageStats({
    DateTime? startTime,
    DateTime? endTime,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedUsageStats != null &&
        _cacheTimestamp != null &&
        now.difference(_cacheTimestamp!) < _cacheTtl) {
      return _cachedUsageStats!;
    }

    final start = startTime ?? now.subtract(const Duration(days: 365));
    final end = endTime ?? now;

    try {
      final raw = await _channel
          .invokeMapMethod<String, dynamic>('queryAllUsageStats', {
            'startTime': start.millisecondsSinceEpoch,
            'endTime': end.millisecondsSinceEpoch,
          });

      if (raw == null) {
        return _cachedUsageStats ?? {};
      }

      final map = <String, AppUsageStats>{};
      raw.forEach((pkg, data) {
        if (data is Map) {
          map[pkg] = AppUsageStats.fromMap(pkg, data);
        }
      });

      _cachedUsageStats = map;
      _cacheTimestamp = DateTime.now();
      return map;
    } catch (_) {
      return _cachedUsageStats ?? {};
    }
  }

  /// Gets the usage statistics for a single app package.
  static Future<AppUsageStats?> getAppUsage(
    String packageName, {
    bool forceRefresh = false,
  }) async {
    final all = await getAllUsageStats(forceRefresh: forceRefresh);
    return all[packageName];
  }

  /// Invalidates the local memory cache of usage statistics.
  static void invalidateCache() {
    _cachedUsageStats = null;
    _cacheTimestamp = null;
  }
}
