import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/services/download_install_pipeline.dart';

void main() {
  /// Records events; download times are in ms per id.
  Future<List<String>> run(
    List<String> ids,
    Map<String, int> downloadMs, {
    int concurrency = 2,
    Set<String> last = const {},
    Set<String> failInstall = const {},
    List<String>? errors,
    int installMs = 5,
  }) async {
    final events = <String>[];
    var installing = 0;
    await runDownloadInstallPipeline<String>(
      ids: ids,
      downloadConcurrency: concurrency,
      download: (id) async {
        events.add('dl-start:$id');
        await Future<void>.delayed(Duration(milliseconds: downloadMs[id]!));
        events.add('dl-done:$id');
        return 'file-$id';
      },
      install: (id, file) async {
        expect(file, 'file-$id');
        installing++;
        expect(installing, 1, reason: 'installs must not overlap');
        events.add('install-start:$id');
        await Future<void>.delayed(Duration(milliseconds: installMs));
        installing--;
        if (failInstall.contains(id)) throw StateError('boom $id');
        events.add('installed:$id');
      },
      installLast: last.contains,
      onInstallError: (id, e) => errors?.add(id),
    );
    return events;
  }

  test('each install starts after its own download', () async {
    final events = await run(['a', 'b', 'c'], {'a': 30, 'b': 5, 'c': 15});
    for (final id in ['a', 'b', 'c']) {
      expect(
        events.indexOf('install-start:$id'),
        greaterThan(events.indexOf('dl-done:$id')),
      );
    }
  });

  test('installs overlap later downloads', () async {
    final events = await run(['fast', 'slow'], {'fast': 5, 'slow': 80});
    expect(
      events.indexOf('installed:fast'),
      lessThan(events.indexOf('dl-done:slow')),
      reason: 'the fast app should install while the slow one downloads',
    );
  });

  test('install-last items wait for everything else, in order', () async {
    final events = await run(
      ['self', 'provider', 'x', 'y'],
      {'self': 1, 'provider': 1, 'x': 20, 'y': 40},
      last: {'self', 'provider'},
      concurrency: 4,
    );
    final installs = events
        .where((e) => e.startsWith('install-start:'))
        .map((e) => e.split(':').last)
        .toList();
    expect(installs.sublist(0, 2).toSet(), {'x', 'y'});
    expect(installs.sublist(2), ['self', 'provider']);
  });

  test('a failed install does not block the rest', () async {
    final errors = <String>[];
    final events = await run(
      ['a', 'b', 'c'],
      {'a': 5, 'b': 10, 'c': 15},
      failInstall: {'a'},
      errors: errors,
    );
    expect(errors, ['a']);
    expect(events, containsAll(['installed:b', 'installed:c']));
  });

  test('sequential downloads still pipeline installs', () async {
    final events = await run(
      ['a', 'b'],
      {'a': 5, 'b': 60},
      concurrency: 1,
      installMs: 5,
    );
    expect(
      events.indexOf('installed:a'),
      lessThan(events.indexOf('dl-done:b')),
    );
  });
}
