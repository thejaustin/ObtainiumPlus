import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:obtainium/utils/app_utils.dart';

/// Aggregated `apps_cache.json` index next to the per-app `<id>.json` files.
///
/// The per-app files are the source of truth; the index only exists so a cold
/// start can decode one file instead of hundreds. It is trusted only when:
///  * it lists exactly the per-app files currently on disk (by name), and
///  * no per-app file was modified after the index snapshot was taken.
/// Otherwise the loader falls back to a full per-app scan, so an app written
/// without a matching index write (crash before the debounced write, another
/// isolate saving, a quarantine restore) can never disappear from view.
///
/// The background-update isolate keeps its own (possibly older) copy of the
/// apps and never writes the index. Before it rewrites a per-app file it
/// drops a [dirtyFileName] marker: while that exists the index is neither
/// trusted nor replaced, until the foreground's next full scan clears it.
/// (The mtime check alone misses a background edit followed by a foreground
/// index write from a stale in-memory copy.)
class AppsCacheIndex {
  AppsCacheIndex._();

  static const String fileName = 'apps_cache.json';
  static const String tmpFileName = 'apps_cache.json.tmp';
  static const String dirtyFileName = 'apps_cache.dirty';
  static const int snapshotMarginMs = 150;
  static const int formatVersion = 2;

  /// Index tmp leftovers younger than this may belong to a write in flight.
  static const Duration staleTmpAge = Duration(minutes: 1);

  /// Whether [name] (a bare file name) is a per-app data file.
  static bool isAppFileName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.json') && lower != fileName;
  }

  static String _baseName(String path) => path.split('/').last;

  /// Builds the index document for [apps] (each an `App.toJson()` map).
  /// [snapshotAt] must be taken when the snapshot is built, before encoding.
  static Map<String, dynamic> buildIndex(
    List<Map<String, dynamic>> apps,
    int snapshotAt,
  ) {
    final files = <String>[
      for (final a in apps)
        if (a['id'] is String) '${a['id']}.json',
    ]..sort();
    return {
      'version': formatVersion,
      'timestamp': snapshotAt,
      'files': files,
      'apps': apps,
    };
  }

  /// Encodes [index] and atomically replaces the index file in [dirPath]
  /// through a single tmp file. Synchronous so it can run in [Isolate.run].
  /// Does nothing while the [dirtyFileName] marker exists.
  static void writeIndexSync(String dirPath, Map<String, dynamic> index) {
    if (File('$dirPath/$dirtyFileName').existsSync()) return;
    final tmp = File('$dirPath/$tmpFileName');
    tmp.writeAsStringSync(safeJsonEncode(index), flush: true);
    if (File('$dirPath/$dirtyFileName').existsSync()) {
      try {
        tmp.deleteSync();
      } catch (_) {}
      return;
    }
    tmp.renameSync('$dirPath/$fileName');
  }

  /// Marks the index untrustworthy (see class docs). Called by the
  /// background provider before it writes per-app files.
  static void markDirtySync(String dirPath) {
    final marker = File('$dirPath/$dirtyFileName');
    if (!marker.existsSync()) marker.writeAsStringSync('');
  }

  /// Deletes `apps_cache.json.tmp*` leftovers. Legacy `apps_cache.json.tmp_<ts>`
  /// names are no longer produced, so they go regardless of age.
  static void cleanupTmpSync(String dirPath, {DateTime? now}) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;
    final at = now ?? DateTime.now();
    for (final e in dir.listSync(followLinks: false)) {
      if (e is! File) continue;
      final name = _baseName(e.path);
      if (!name.startsWith(tmpFileName)) continue;
      try {
        if (name.startsWith('${tmpFileName}_') ||
            at.difference(e.lastModifiedSync()) > staleTmpAge) {
          e.deleteSync();
        }
      } catch (_) {}
    }
  }

  /// Cheap signature of the per-app files (names + newest mtime). Used to
  /// tell whether anything changed on disk since the last load.
  static String dirSignatureSync(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return '';
    final names = <String>[];
    var maxMtime = 0;
    for (final e in dir.listSync(followLinks: false)) {
      if (e is! File) continue;
      final name = _baseName(e.path);
      if (!isAppFileName(name)) continue;
      names.add(name);
      try {
        final m = e.statSync().modified.millisecondsSinceEpoch;
        if (m > maxMtime) maxMtime = m;
      } catch (_) {}
    }
    names.sort();
    return '${names.length}:$maxMtime:${_fnv1a(names.join('\n'))}';
  }

  static int _fnv1a(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  /// Reads the app data in [dirPath]: the index when it is consistent with
  /// the per-app files, otherwise every per-app file (corrupt ones are
  /// renamed to `.corrupt`). Pure file I/O + JSON decoding, so it is safe to
  /// run in [Isolate.run] — see [scan].
  ///
  /// [clearDirty] (foreground only) removes the [dirtyFileName] marker before
  /// the full scan, so the index written from that scan is trusted again.
  static AppsDirScan scanSync(
    String dirPath, {
    String? singleId,
    bool clearDirty = false,
  }) {
    final logs = <String>[];
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return AppsDirScan(const [], fromCache: false, logs: logs);
    }
    if (singleId != null) {
      final file = File('$dirPath/$singleId.json');
      final apps = <Map<String, dynamic>>[];
      if (file.existsSync()) {
        final m = _readAppFile(file, logs);
        if (m != null) apps.add(m);
      }
      return AppsDirScan(apps, fromCache: false, logs: logs);
    }

    cleanupTmpSync(dirPath);

    final dirtyMarker = File('$dirPath/$dirtyFileName');
    final dirty = dirtyMarker.existsSync();
    if (dirty && clearDirty) {
      // Before listing/reading, so a background write racing this scan
      // re-creates the marker rather than being lost.
      try {
        dirtyMarker.deleteSync();
      } catch (_) {}
    }

    final appFiles = <File>[];
    final names = <String>[];
    var maxMtime = 0;
    for (final e in dir.listSync(followLinks: false)) {
      if (e is! File) continue;
      final name = _baseName(e.path);
      if (!isAppFileName(name)) continue;
      appFiles.add(e);
      names.add(name);
      try {
        final m = e.statSync().modified.millisecondsSinceEpoch;
        if (m > maxMtime) maxMtime = m;
      } catch (_) {}
    }
    names.sort();
    final signature = '${names.length}:$maxMtime:${_fnv1a(names.join('\n'))}';

    final cacheFile = File('$dirPath/$fileName');
    if (dirty) {
      logs.add('Apps were changed in the background; rescanning app files');
    } else if (cacheFile.existsSync()) {
      try {
        final decoded = jsonDecode(cacheFile.readAsStringSync());
        if (decoded is Map &&
            decoded['version'] == formatVersion &&
            decoded['apps'] is List &&
            decoded['files'] is List &&
            decoded['timestamp'] is int) {
          final cachedNames = (decoded['files'] as List)
              .whereType<String>()
              .toList();
          final snapshotAt = decoded['timestamp'] as int;
          // Margin below the writer's debounce: a per-app write landing just
          // before the snapshot may not be in it yet, so don't trust that.
          if (listEquals(cachedNames, names) &&
              maxMtime <= snapshotAt - snapshotMarginMs) {
            return AppsDirScan(
              (decoded['apps'] as List)
                  .whereType<Map<String, dynamic>>()
                  .toList(),
              fromCache: true,
              logs: logs,
              signature: signature,
            );
          }
          logs.add('apps_cache.json is out of date; rescanning app files');
        }
      } catch (e) {
        logs.add('Could not load apps_cache.json index: $e');
      }
    }

    final apps = <Map<String, dynamic>>[];
    for (final f in appFiles) {
      final m = _readAppFile(f, logs);
      if (m != null) apps.add(m);
    }
    return AppsDirScan(
      apps,
      fromCache: false,
      logs: logs,
      signature: signature,
    );
  }

  static Map<String, dynamic>? _readAppFile(File file, List<String> logs) {
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException('App JSON is not an object');
    } on FormatException catch (err) {
      logs.add('Corrupt JSON when loading App (will be ignored): $err');
      try {
        file.renameSync('${file.path}.corrupt');
      } catch (_) {}
    } on FileSystemException catch (err) {
      logs.add('Skipped missing/unreadable app file ${file.path}: $err');
    } catch (err) {
      logs.add('Skipped unreadable app file ${file.path}: $err');
    }
    return null;
  }

  /// [scanSync] on a background isolate (falls back to the current isolate
  /// if spawning fails).
  static Future<AppsDirScan> scan(
    String dirPath, {
    String? singleId,
    bool clearDirty = false,
  }) async {
    try {
      return await Isolate.run(
        () => scanSync(dirPath, singleId: singleId, clearDirty: clearDirty),
      );
    } catch (_) {
      return scanSync(dirPath, singleId: singleId, clearDirty: clearDirty);
    }
  }

  /// [dirSignatureSync] on a background isolate.
  static Future<String> dirSignature(String dirPath) async {
    try {
      return await Isolate.run(() => dirSignatureSync(dirPath));
    } catch (_) {
      return dirSignatureSync(dirPath);
    }
  }
}

class AppsDirScan {
  AppsDirScan(
    this.apps, {
    required this.fromCache,
    required this.logs,
    this.signature,
  });

  /// Raw `App.toJson()` maps.
  final List<Map<String, dynamic>> apps;
  final bool fromCache;
  final List<String> logs;

  /// [AppsCacheIndex.dirSignatureSync]-compatible signature of the files
  /// seen during the scan (null for single-app scans).
  final String? signature;
}

/// Serialises index writes: one pending write at a time, debounced so a burst
/// of saves writes only the latest snapshot. The snapshot is taken when the
/// write actually runs, never when it is scheduled.
class AppsCacheWriter {
  AppsCacheWriter({
    this.debounce = const Duration(milliseconds: 300),
    this.useIsolate = true,
  });

  final Duration debounce;
  final bool useIsolate;

  Timer? _timer;
  bool _running = false;
  bool _rerun = false;
  String? _dirPath;
  List<Map<String, dynamic>> Function()? _snapshot;
  Completer<void>? _pending;

  bool get hasPendingWrite => _pending != null;

  /// Schedules a write of [snapshot] into [dirPath]. The returned future
  /// completes once a write that includes this request has finished (errors
  /// are swallowed — the index is only an optimisation).
  Future<void> schedule(
    String dirPath,
    List<Map<String, dynamic>> Function() snapshot,
  ) {
    _dirPath = dirPath;
    _snapshot = snapshot;
    final pending = _pending ??= Completer<void>();
    _timer?.cancel();
    _timer = Timer(debounce, _fire);
    return pending.future;
  }

  /// Runs any pending write now.
  Future<void> flush() {
    final pending = _pending;
    if (pending == null) return Future.value();
    _timer?.cancel();
    _fire();
    return pending.future;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fire() async {
    if (_running) {
      _rerun = true;
      return;
    }
    final completer = _pending;
    final dirPath = _dirPath;
    final snapshot = _snapshot;
    _pending = null;
    if (completer == null || dirPath == null || snapshot == null) return;
    _running = true;
    try {
      final snapshotAt = DateTime.now().millisecondsSinceEpoch;
      final index = AppsCacheIndex.buildIndex(snapshot(), snapshotAt);
      if (useIsolate) {
        await _writeOnIsolate(dirPath, index);
      } else {
        AppsCacheIndex.writeIndexSync(dirPath, index);
      }
    } catch (_) {
    } finally {
      _running = false;
      if (!completer.isCompleted) completer.complete();
      if (_rerun) {
        _rerun = false;
        if (_pending != null) {
          _timer?.cancel();
          unawaited(_fire());
        }
      }
    }
  }

  static Future<void> _writeOnIsolate(
    String dirPath,
    Map<String, dynamic> index,
  ) async {
    try {
      await Isolate.run(() => AppsCacheIndex.writeIndexSync(dirPath, index));
    } catch (_) {
      AppsCacheIndex.writeIndexSync(dirPath, index);
    }
  }
}
