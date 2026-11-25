import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/services/contributors_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _body(Map<String, int> m, {Map<String, String> types = const {}}) =>
    jsonEncode([
      for (final e in m.entries)
        {
          'login': e.key,
          'contributions': e.value,
          'type': types[e.key] ?? 'User',
        },
    ]);

void main() {
  test('parse drops bots, sorts by contributions', () {
    final out = ContributorsService.parse(
      _body(
        {'a': 3, 'CertainBot': 99, 'dependabot[bot]': 40, 'b': 7},
        types: {'dependabot[bot]': 'Bot'},
      ),
    );
    expect(out.map((c) => c.login), ['b', 'a']);
    expect(out.first.profileUrl, 'https://github.com/b');
  });

  test('forkOnly credits work done in the fork, not inherited history', () {
    final fork = ContributorsService.parse(
      _body({'ImranR98': 1774, 'thejaustin': 873, 'gidano': 35, 'new': 2}),
    );
    final up = ContributorsService.parse(
      _body({'ImranR98': 1774, 'gidano': 35}),
    );
    final out = ContributorsService.forkOnly(fork, up);
    expect(out.map((c) => '${c.login}:${c.contributions}'), [
      'thejaustin:873',
      'new:2',
    ]);
  });

  test(
    'loadBoth caches for a day and falls back to the cache offline',
    () async {
      SharedPreferences.setMockInitialValues({});
      var calls = 0;
      var offline = false;
      ContributorsService.debugFetch = (repo, page) async {
        calls++;
        if (offline) throw Exception('no network');
        return _body({repo.startsWith('thejaustin') ? 'me' : 'them': 5});
      };
      addTearDown(() => ContributorsService.debugFetch = null);
      final (fork, up) = await ContributorsService.loadBoth();
      expect([fork.single.login, up.single.login], ['me', 'them']);
      expect(calls, 2);
      await ContributorsService.loadBoth();
      expect(calls, 2, reason: 'served from the fresh cache');

      // Expire the cache, go offline: the stale copy still answers.
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.endsWith('_ts'))) {
        await prefs.setInt(k, 0);
      }
      offline = true;
      final (f2, _) = await ContributorsService.loadBoth();
      expect(f2.single.login, 'me');
    },
  );

  test('pages through long lists', () async {
    SharedPreferences.setMockInitialValues({});
    final pages = <int>[];
    ContributorsService.debugFetch = (repo, page) async {
      pages.add(page);
      return page == 1
          ? _body({for (var i = 0; i < 100; i++) 'u$i': 200 - i})
          : _body({'last': 1});
    };
    addTearDown(() => ContributorsService.debugFetch = null);
    final (_, up) = await ContributorsService.loadBoth();
    expect(up.length, 101);
    expect(up.last.login, 'last');
    expect(pages.toSet(), {1, 2});
  });
}
