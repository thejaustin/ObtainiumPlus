import 'dart:async';
import 'dart:collection';

/// Hands out work items to a pool of workers so that at most [perKeyLimit]
/// items sharing a key (e.g. a host) are in flight at once, rotating between
/// keys. A long run of apps from one host can't occupy every worker or hammer
/// that host while apps from other hosts wait.
///
/// Items keep their original order within a key. Every item returned by
/// [take] must be passed to [done] once finished, or waiting workers stall.
class KeyedWorkQueue<T> {
  KeyedWorkQueue(Iterable<T> items, this.keyOf, {required int perKeyLimit})
    : perKeyLimit = perKeyLimit < 1 ? 1 : perKeyLimit {
    for (final item in items) {
      _pending.putIfAbsent(keyOf(item), Queue<T>.new).add(item);
    }
  }

  final String Function(T) keyOf;
  final int perKeyLimit;

  // Insertion order is the rotation order: a key that hands out an item moves
  // to the back.
  final LinkedHashMap<String, Queue<T>> _pending = LinkedHashMap();
  final Map<String, int> _active = {};
  Completer<void>? _slotFreed;

  bool get isEmpty => _pending.isEmpty;

  /// Returns the next item, or null once nothing is left. Waits while every
  /// key that still has items is at its limit.
  Future<T?> take() async {
    while (true) {
      if (_pending.isEmpty) return null;
      for (final key in _pending.keys) {
        if ((_active[key] ?? 0) >= perKeyLimit) continue;
        final queue = _pending.remove(key)!;
        final item = queue.removeFirst();
        if (queue.isNotEmpty) _pending[key] = queue;
        _active[key] = (_active[key] ?? 0) + 1;
        return item;
      }
      await (_slotFreed ??= Completer<void>()).future;
    }
  }

  /// Marks an item from [take] as finished, freeing its key's slot.
  void done(T item) {
    final key = keyOf(item);
    final active = (_active[key] ?? 1) - 1;
    if (active <= 0) {
      _active.remove(key);
    } else {
      _active[key] = active;
    }
    final waiters = _slotFreed;
    _slotFreed = null;
    waiters?.complete();
  }

  /// Drops every item not yet handed out, so idle workers finish.
  void clear() {
    _pending.clear();
    final waiters = _slotFreed;
    _slotFreed = null;
    waiters?.complete();
  }
}
