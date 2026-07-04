import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// LRU Cache for app icons to manage memory usage
class IconLRUCache {
  final int maxSize;
  final Map<String, Uint8List> _cache = {};
  final List<String> _accessOrder = [];
  final void Function(String)? onEvict;

  IconLRUCache({this.maxSize = 50, this.onEvict});

  Uint8List? get(String appId) {
    if (_cache.containsKey(appId)) {
      // Move to end (most recently used)
      _accessOrder.remove(appId);
      _accessOrder.add(appId);
      return _cache[appId];
    }
    return null;
  }

  void put(String appId, Uint8List icon) {
    if (_cache.containsKey(appId)) {
      _accessOrder.remove(appId);
    } else if (_cache.length >= maxSize) {
      // Evict least recently used
      final lru = _accessOrder.removeAt(0);
      _cache.remove(lru);
      onEvict?.call(lru);
    }
    _cache[appId] = icon;
    _accessOrder.add(appId);
  }

  void remove(String appId) {
    if (_cache.containsKey(appId)) {
      _cache.remove(appId);
      _accessOrder.remove(appId);
      onEvict?.call(appId);
    }
  }

  void clear() {
    // Notify about all evictions before clearing
    if (onEvict != null) {
      for (var appId in _cache.keys) {
        onEvict!(appId);
      }
    }
    _cache.clear();
    _accessOrder.clear();
  }

  int get length => _cache.length;
}

class AppIconService {
  AppIconService._();

  static void Function(String)? _evictionHandler;

  static void setEvictionHandler(void Function(String) handler) {
    _evictionHandler = handler;
  }

  static final IconLRUCache _iconCache = IconLRUCache(
    maxSize: 50,
    onEvict: (appId) => _evictionHandler?.call(appId),
  );
  static final Set<String> _iconsLoading = {};
  static final Set<String> _iconsFailed = {};

  static Future<void> updateAppIcon({
    required String? appId,
    required Map<String, AppInMemory> apps,
    required Directory iconsCacheDir,
    required Function() notifyListeners,
    bool ignoreCache = false,
  }) async {
    if (appId == null || apps[appId] == null) return;

    // Check if already loading this icon
    if (_iconsLoading.contains(appId)) return;

    // Check if previous load failed
    if (_iconsFailed.contains(appId) && !ignoreCache) return;

    // Check LRU cache first
    final cachedInMemory = _iconCache.get(appId);
    if (cachedInMemory != null && !ignoreCache) {
      if (apps[appId]?.icon == null) {
        apps.update(
          appId,
          (value) => AppInMemory(
            value.app,
            value.downloadProgress,
            value.installedInfo,
            cachedInMemory,
          ),
        );
        notifyListeners();
      }
      return;
    }

    // Skip if already has icon and not forcing refresh
    if (apps[appId]?.icon != null && !ignoreCache) return;

    _iconsLoading.add(appId);
    try {
      // Check if cache directory exists
      if (!iconsCacheDir.existsSync()) {
        try {
          iconsCacheDir.createSync(recursive: true);
        } catch (e) {
          _iconsFailed.add(appId);
          return;
        }
      }

      var cachedIcon = File('${iconsCacheDir.path}/$appId.png');

      // Safely check and read cached icon
      Uint8List? icon;
      try {
        var alreadyCached = cachedIcon.existsSync() && !ignoreCache;
        if (alreadyCached) {
          icon = await cachedIcon.readAsBytes();
        }
      } catch (e) {
        // Cache file exists but is corrupted or unreadable
        try {
          if (cachedIcon.existsSync()) {
            cachedIcon.deleteSync();
          }
        } catch (_) {}

        talker.warning('Failed to read cached icon for $appId: $e');
        await CrashAnalytics.recordCrash(
          errorType: 'IconCacheReadError',
          errorMessage:
              'Failed to read cached icon for $appId: ${e.toString()}',
        );
        await Sentry.captureException(e);

        icon = null;
      }

      // Fetch from installed app if not cached
      if (icon == null) {
        try {
          final installedInfo = await AppInstallService.getInstalledInfo(appId);
          icon = await installedInfo?.applicationInfo?.getAppIcon();

          // Save to cache if successfully fetched
          if (icon != null) {
            try {
              await cachedIcon.writeAsBytes(icon.toList());
            } catch (e) {
              // Cache write failed, but we can still use the icon
            }
          }
        } catch (e) {
          // App not installed or icon not available
          _iconsFailed.add(appId);
          return;
        }
      }

      if (icon != null && apps.containsKey(appId)) {
        _iconsFailed.remove(appId);
        // Add to LRU cache
        _iconCache.put(appId, icon);
        apps.update(
          appId,
          (value) => AppInMemory(
            value.app,
            value.downloadProgress,
            value.installedInfo,
            icon,
          ),
        );
        notifyListeners();
      } else {
        _iconsFailed.add(appId);
      }
    } catch (e) {
      // Unexpected error during icon loading
      _iconsFailed.add(appId);
    } finally {
      _iconsLoading.remove(appId);
    }
  }

  static Future<void> precacheIcons({
    required List<String> appIds,
    required Map<String, AppInMemory> apps,
    required Directory iconsCacheDir,
    required Function() notifyListeners,
  }) async {
    // Filter to apps that need icons and aren't currently loading
    final appsNeedingIcons = appIds
        .where(
          (id) =>
              apps[id] != null &&
              apps[id]!.icon == null &&
              !_iconsLoading.contains(id),
        )
        .toList();

    if (appsNeedingIcons.isEmpty) return;

    // Batch load with concurrency limit
    final batch = appsNeedingIcons.take(15).toList();

    for (final appId in batch) {
      unawaited(
        updateAppIcon(
          appId: appId,
          apps: apps,
          iconsCacheDir: iconsCacheDir,
          notifyListeners: notifyListeners,
        ),
      );
    }
  }
}
