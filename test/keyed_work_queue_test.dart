import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/services/keyed_work_queue.dart';

String _host(String item) => item.split('/').first;

void main() {
  test('rotates between keys and keeps order within a key', () async {
    final queue = KeyedWorkQueue<String>(
      ['gh/a', 'gh/b', 'gh/c', 'gl/x', 'fd/y', 'gl/z'],
      _host,
      perKeyLimit: 10,
    );
    final order = <String>[];
    String? item;
    while ((item = await queue.take()) != null) {
      order.add(item!);
      queue.done(item);
    }
    expect(order, ['gh/a', 'gl/x', 'fd/y', 'gh/b', 'gl/z', 'gh/c']);
  });

  test('never exceeds the per-key limit across concurrent workers', () async {
    final items = [for (var i = 0; i < 20; i++) 'gh/$i', 'gl/0', 'gl/1'];
    final queue = KeyedWorkQueue<String>(items, _host, perKeyLimit: 2);
    final active = <String, int>{};
    var peakGh = 0;
    final seen = <String>[];

    Future<void> worker() async {
      while (true) {
        final item = await queue.take();
        if (item == null) return;
        final key = _host(item);
        active[key] = (active[key] ?? 0) + 1;
        if (key == 'gh' && active[key]! > peakGh) peakGh = active[key]!;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        active[key] = active[key]! - 1;
        seen.add(item);
        queue.done(item);
      }
    }

    await Future.wait(List.generate(6, (_) => worker()));
    expect(peakGh, 2);
    expect(seen.toSet(), items.toSet());
    expect(seen.length, items.length);
  });

  test('clear releases waiting workers', () async {
    final queue = KeyedWorkQueue<String>(
      ['gh/a', 'gh/b'],
      _host,
      perKeyLimit: 1,
    );
    final first = await queue.take();
    expect(first, 'gh/a');
    final waiting = queue.take();
    queue.clear();
    expect(await waiting.timeout(const Duration(seconds: 1)), isNull);
    queue.done(first!);
  });
}
