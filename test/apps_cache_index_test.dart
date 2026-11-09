import 'dart:convert';
import 'dart:io';

import 'package:android_package_manager/android_package_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/apps_cache_index.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePackageInfo implements PackageInfo {
  _FakePackageInfo(this.packageName, this.versionName);
  @override
  final String? packageName;
  @override
  final String? versionName;
  @override
  int? get versionCode => 1;
  @override
  int? get firstInstallTime => null;
  @override
  int? get lastUpdateTime => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _app(String id, {String version = '1.0'}) => {
  'id': id,
  'url': 'https://github.com/example/$id',
  'latestVersion': version,
};

void _writeApp(Directory dir, Map<String, dynamic> app, {DateTime? mtime}) {
  final f = File('${dir.path}/${app['id']}.json')
    ..writeAsStringSync(jsonEncode(app));
  if (mtime != null) f.setLastModifiedSync(mtime);
}

Map<String, dynamic> _readIndex(Directory dir) =>
    jsonDecode(
          File('${dir.path}/${AppsCacheIndex.fileName}').readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('apps_cache_index_test');
  });

  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('AppsCacheIndex.scanSync', () {
    test('uses the index when it matches the per-app files', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      _writeApp(dir, _app('a.one'), mtime: past);
      _writeApp(dir, _app('b.two'), mtime: past);
      AppsCacheIndex.writeIndexSync(
        dir.path,
        AppsCacheIndex.buildIndex([
          _app('a.one'),
          _app('b.two'),
        ], DateTime.now().millisecondsSinceEpoch),
      );
      final scan = AppsCacheIndex.scanSync(dir.path);
      expect(scan.fromCache, isTrue);
      expect(
        scan.apps.map((a) => a['id']),
        unorderedEquals(['a.one', 'b.two']),
      );
    });

    test('an app file missing from the index appears after load', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      _writeApp(dir, _app('a.one'), mtime: past);
      AppsCacheIndex.writeIndexSync(
        dir.path,
        AppsCacheIndex.buildIndex([
          _app('a.one'),
        ], DateTime.now().millisecondsSinceEpoch),
      );
      // e.g. a quarantine restore or a crash before the index write.
      _writeApp(dir, _app('c.three'), mtime: past);

      final scan = AppsCacheIndex.scanSync(dir.path);
      expect(scan.fromCache, isFalse);
      expect(
        scan.apps.map((a) => a['id']),
        unorderedEquals(['a.one', 'c.three']),
      );
    });

    test('a per-app file newer than the index wins over the index', () {
      final snapshotAt = DateTime.now().subtract(const Duration(minutes: 5));
      AppsCacheIndex.writeIndexSync(
        dir.path,
        AppsCacheIndex.buildIndex([
          _app('a.one', version: '1.0'),
        ], snapshotAt.millisecondsSinceEpoch),
      );
      _writeApp(dir, _app('a.one', version: '2.0'), mtime: DateTime.now());

      final scan = AppsCacheIndex.scanSync(dir.path);
      expect(scan.fromCache, isFalse);
      expect(scan.apps.single['latestVersion'], '2.0');
    });

    test('a legacy v1 index is ignored', () {
      _writeApp(dir, _app('a.one'));
      File('${dir.path}/${AppsCacheIndex.fileName}').writeAsStringSync(
        jsonEncode({
          'version': 1,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'apps': <Object>[],
        }),
      );
      final scan = AppsCacheIndex.scanSync(dir.path);
      expect(scan.fromCache, isFalse);
      expect(scan.apps.single['id'], 'a.one');
    });

    test('corrupt app files are renamed and skipped', () {
      _writeApp(dir, _app('a.one'));
      File('${dir.path}/bad.app.json').writeAsStringSync('{not json');
      final scan = AppsCacheIndex.scanSync(dir.path);
      expect(scan.apps.single['id'], 'a.one');
      expect(File('${dir.path}/bad.app.json.corrupt').existsSync(), isTrue);
    });

    test('stale index tmp files are removed', () {
      final old = DateTime.now().subtract(const Duration(hours: 1));
      final legacy = File('${dir.path}/apps_cache.json.tmp_123456')
        ..writeAsStringSync('x');
      final staleTmp = File('${dir.path}/${AppsCacheIndex.tmpFileName}')
        ..writeAsStringSync('x')
        ..setLastModifiedSync(old);
      _writeApp(dir, _app('a.one'));

      final scan = AppsCacheIndex.scanSync(dir.path);
      expect(legacy.existsSync(), isFalse);
      expect(staleTmp.existsSync(), isFalse);
      expect(scan.apps.single['id'], 'a.one');
    });

    test('a fresh index tmp file (write in flight) is kept', () {
      final fresh = File('${dir.path}/${AppsCacheIndex.tmpFileName}')
        ..writeAsStringSync('x');
      AppsCacheIndex.cleanupTmpSync(dir.path);
      expect(fresh.existsSync(), isTrue);
    });

    test('dirSignature changes when a file is added', () {
      _writeApp(dir, _app('a.one'));
      final before = AppsCacheIndex.dirSignatureSync(dir.path);
      expect(AppsCacheIndex.dirSignatureSync(dir.path), before);
      _writeApp(dir, _app('b.two'));
      expect(AppsCacheIndex.dirSignatureSync(dir.path), isNot(before));
    });
  });

  group('AppsCacheWriter', () {
    test('two rapid saves leave the index matching the latest state', () async {
      final writer = AppsCacheWriter(
        debounce: const Duration(milliseconds: 20),
      );
      var state = [_app('a.one')];
      final f1 = writer.schedule(dir.path, () => state);
      state = [_app('a.one'), _app('b.two', version: '3.0')];
      final f2 = writer.schedule(dir.path, () => state);
      await Future.wait([f1, f2]);

      final index = _readIndex(dir);
      expect((index['apps'] as List).map((a) => (a as Map)['id']), [
        'a.one',
        'b.two',
      ]);
      expect(index['files'], ['a.one.json', 'b.two.json']);
      expect(
        dir.listSync().map((e) => e.path.split('/').last),
        isNot(contains(startsWith(AppsCacheIndex.tmpFileName))),
      );
    });

    test('a save scheduled during a write is written afterwards', () async {
      final writer = AppsCacheWriter(debounce: Duration.zero);
      var state = [_app('a.one')];
      final f1 = writer.schedule(dir.path, () => state);
      // Let the first write start, then schedule again while it runs.
      await Future<void>.delayed(Duration.zero);
      state = [_app('z.last')];
      final f2 = writer.schedule(dir.path, () => state);
      await Future.wait([f1, f2]);
      await writer.flush();

      final index = _readIndex(dir);
      expect((index['apps'] as List).single['id'], 'z.last');
    });
  });

  group('background dirty marker', () {
    test('a valid index is ignored while the marker exists', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      _writeApp(dir, _app('a.one', version: '2.0'), mtime: past);
      AppsCacheIndex.writeIndexSync(
        dir.path,
        AppsCacheIndex.buildIndex([
          _app('a.one', version: '1.0'),
        ], DateTime.now().millisecondsSinceEpoch),
      );
      AppsCacheIndex.markDirtySync(dir.path);

      final bgScan = AppsCacheIndex.scanSync(dir.path);
      expect(bgScan.fromCache, isFalse);
      expect(bgScan.apps.single['latestVersion'], '2.0');
      // Only the foreground scan clears it.
      expect(
        File('${dir.path}/${AppsCacheIndex.dirtyFileName}').existsSync(),
        isTrue,
      );
      final fgScan = AppsCacheIndex.scanSync(dir.path, clearDirty: true);
      expect(fgScan.fromCache, isFalse);
      expect(
        File('${dir.path}/${AppsCacheIndex.dirtyFileName}').existsSync(),
        isFalse,
      );
    });

    test('the index is not replaced while the marker exists', () {
      AppsCacheIndex.markDirtySync(dir.path);
      AppsCacheIndex.writeIndexSync(
        dir.path,
        AppsCacheIndex.buildIndex([_app('a.one')], 0),
      );
      expect(
        File('${dir.path}/${AppsCacheIndex.fileName}').existsSync(),
        isFalse,
      );
      expect(
        File('${dir.path}/${AppsCacheIndex.tmpFileName}').existsSync(),
        isFalse,
      );
    });
  });

  test(
    'real App maps round-trip through the writer and isolate scan',
    () async {
      final apps = [
        App(
          'com.example.one',
          'https://github.com/example/one',
          'Author',
          'One',
          '1.0',
          '1.1',
          const [],
          0,
          const {'versionDetection': true},
          DateTime(2026, 11, 1),
          false,
        ),
        App(
          'com.example.two',
          'https://github.com/example/two',
          'Author',
          'Two',
          null,
          '2.0',
          const [],
          0,
          const {},
          null,
          false,
        ),
      ];
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      for (final a in apps) {
        _writeApp(dir, a.toJson(), mtime: past);
      }
      final writer = AppsCacheWriter(debounce: Duration.zero);
      await writer.schedule(dir.path, () => [for (final a in apps) a.toJson()]);

      final scan = await AppsCacheIndex.scan(dir.path);
      expect(scan.fromCache, isTrue);
      final loaded = scan.apps.map(App.fromJson).toList();
      expect(
        loaded.map((a) => a.id),
        unorderedEquals(['com.example.one', 'com.example.two']),
      );
      expect(
        loaded.firstWhere((a) => a.id == 'com.example.one').latestVersion,
        '1.1',
      );
    },
  );

  group('AppsProvider self-entry install correction', () {
    late AppsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.initializeSettings();
      provider = AppsProvider(isBg: true, settingsProvider: settings);
    });

    tearDown(() => provider.dispose());

    test('provider reconcile treats 1.7.3-p15 and v1.7.3-p15 as equal', () {
      expect(
        provider.reconcileVersionDifferences('1.7.3-p15', 'v1.7.3-p15')!.key,
        isTrue,
      );
      expect(
        provider.reconcileVersionDifferences('1.7.3-p10', 'v1.7.3-p15')!.key,
        isFalse,
      );
    });

    test(
      'pseudo-version self entry picks up the OS-installed latest build',
      () {
        final app = App(
          'dev.thejaustin.obtainiumplus',
          'https://github.com/thejaustin/ObtainiumPlus',
          'thejaustin',
          'Obtainium+',
          'v1.7.3-p10',
          'v1.7.3-p15',
          const [],
          0,
          {'versionDetection': false},
          null,
          false,
          // The constructor default is an unmodifiable const [].
          installHistory: [],
        );
        final corrected = provider.getCorrectedInstallStatusAppIfPossible(
          app,
          _FakePackageInfo('dev.thejaustin.obtainiumplus', '1.7.3-p15'),
        );
        expect(corrected, isNotNull);
        expect(corrected!.installedVersion, 'v1.7.3-p15');
      },
    );

    test('an older OS build still leaves the update offered', () {
      final app = App(
        'dev.thejaustin.obtainiumplus',
        'https://github.com/thejaustin/ObtainiumPlus',
        'thejaustin',
        'Obtainium+',
        'v1.7.3-p10',
        'v1.7.3-p15',
        const [],
        0,
        {'versionDetection': false},
        null,
        false,
        // The constructor default is an unmodifiable const [].
        installHistory: [],
      );
      final corrected =
          provider.getCorrectedInstallStatusAppIfPossible(
            app,
            _FakePackageInfo('dev.thejaustin.obtainiumplus', '1.7.3-p12'),
          ) ??
          app;
      expect(corrected.installedVersion, 'v1.7.3-p10');
    });
  });
}
