import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/services/app_install_service.dart';

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
      var cachedIcon = File('${iconsCacheDir.path}/$appId.png');
      var alreadyCached = cachedIcon.existsSync() && !ignoreCache;
      var icon = alreadyCached
          ? (await cachedIcon.readAsBytes())
          : (await (await AppInstallService.getInstalledInfo(appId))?.applicationInfo?.getAppIcon());
      
      if (icon != null && !alreadyCached) {
        unawaited(cachedIcon.writeAsBytes(icon.toList()));
      }
      
      if (icon != null) {
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
          ifAbsent: () => AppInMemory(
            apps[appId]!.app,
            null,
            apps[appId]?.installedInfo,
            icon,
          ),
        );
        notifyListeners();
      }
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
    final appsNeedingIcons = appIds.where((id) =>
      apps[id] != null &&
      apps[id]!.icon == null &&
      !_iconsLoading.contains(id)
    ).toList();

    if (appsNeedingIcons.isEmpty) return;

    // Batch load with concurrency limit
    final batch = appsNeedingIcons.take(15).toList();

    for (final appId in batch) {
      unawaited(updateAppIcon(
        appId: appId,
        apps: apps,
        iconsCacheDir: iconsCacheDir,
        notifyListeners: notifyListeners,
      ));
    }
  }
}
