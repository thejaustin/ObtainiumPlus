import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/apps/niagara_alphabet_scrubber.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';

AppInMemory _app(String name, {bool pinned = false}) => AppInMemory(
  App(
    name,
    'https://example.invalid/$name',
    'a',
    name,
    '1',
    '1',
    [],
    0,
    {},
    null,
    pinned,
  ),
  null,
  null,
  null,
);

List<String> _symbols(List<ScrubberBucket>? b) =>
    b!.map((e) => e.symbol).toList();

void main() {
  // Order AppsPage produces with "pin updates" on: pinned, then pending
  // updates (name-sorted among themselves), then everything else by name.
  final pinned = _app('Signal', pinned: true);
  final updates = [
    'Aurora',
    'Droidify',
    'Element',
    'Obtainium',
  ].map(_app).toList();
  final rest = [
    'Bitwarden',
    'F-Droid',
    'Mihon',
    'NewPipe',
    'Seal',
    'Termux',
  ].map(_app).toList();
  final list = [pinned, ...updates, ...rest];

  test('pinned updates get one leading entry and indices only move down', () {
    final b = NiagaraAlphabetScrubber.buildBuckets(
      list,
      updates.map((a) => a.app.id).toSet(),
    );
    expect(_symbols(b), ['★', '↑', 'B', 'F', 'M', 'N', 'S', 'T']);
    final idx = b!.map((e) => e.firstAppIndex).toList();
    for (var i = 1; i < idx.length; i++) {
      expect(idx[i], greaterThan(idx[i - 1]));
    }
    expect(b[1].firstAppIndex, 1);
    expect(b[2].firstAppIndex, 5);
  });

  test('an out-of-order list hides the rail instead of jumping around', () {
    // Same list without telling the scrubber which apps were lifted.
    expect(NiagaraAlphabetScrubber.buildBuckets(list, const {}), isNull);
    expect(NiagaraAlphabetScrubber.willShow(list), isFalse);
  });

  test('# may appear at both ends without hiding the rail', () {
    final l = [
      '1Password',
      'Aegis',
      'Bitwarden',
      'Chrome',
      'Éclair',
    ].map(_app).toList();
    expect(_symbols(NiagaraAlphabetScrubber.buildBuckets(l, const {})), [
      '#',
      'A',
      'B',
      'C',
    ]);
  });
}
