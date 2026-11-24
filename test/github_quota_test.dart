import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:shared_preferences/shared_preferences.dart';

Response _apiResponse({
  required int remaining,
  required int reset,
  bool authenticated = false,
}) => Response(
  '[]',
  200,
  headers: {
    'x-ratelimit-remaining': '$remaining',
    'x-ratelimit-reset': '$reset',
  },
  request: Request(
    'GET',
    Uri.parse('https://api.github.com/repos/o/r/releases'),
  )..headers.addAll({if (authenticated) 'Authorization': 'Token x'}),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GitHub.clearApiBlockForTest();
  });

  final future = DateTime.now().add(const Duration(minutes: 30));
  final reset = future.millisecondsSinceEpoch ~/ 1000;

  test('a nearly exhausted quota blocks the API before any 403', () {
    GitHub.noteQuotaForTest(_apiResponse(remaining: 40, reset: reset));
    expect(GitHub.apiBlockedMinutesForTest(false), isNull);

    GitHub.noteQuotaForTest(_apiResponse(remaining: 2, reset: reset));
    expect(GitHub.apiBlockedMinutesForTest(false), inInclusiveRange(29, 31));
    // Token and anonymous quotas are separate.
    expect(GitHub.apiBlockedMinutesForTest(true), isNull);
  });

  test('the token quota is tracked separately', () {
    GitHub.noteQuotaForTest(
      _apiResponse(remaining: 0, reset: reset, authenticated: true),
    );
    expect(GitHub.apiBlockedMinutesForTest(true), isNotNull);
    expect(GitHub.apiBlockedMinutesForTest(false), isNull);
  });

  test('non-API hosts and responses without headers are ignored', () {
    GitHub.noteQuotaForTest(Response('', 200));
    GitHub.noteQuotaForTest(
      Response(
        '',
        200,
        headers: {'x-ratelimit-remaining': '0', 'x-ratelimit-reset': '$reset'},
        request: Request('GET', Uri.parse('https://github.com/o/r/x')),
      ),
    );
    expect(GitHub.apiBlockedMinutesForTest(false), isNull);
  });

  test('the repo-info probe runs once per day per repo', () async {
    const a = 'https://github.com/o/a';
    const b = 'https://github.com/o/b';
    expect(await GitHub.repoProbeDueForTest(a), isTrue);
    expect(await GitHub.repoProbeDueForTest(a), isFalse);
    expect(await GitHub.repoProbeDueForTest(b), isTrue);

    final old = DateTime.now()
        .subtract(const Duration(hours: 25))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({'ghRepoProbeAt': '{"$a":$old}'});
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(await GitHub.repoProbeDueForTest(a), isTrue);
  });

  test('the probe is skipped while the API is blocked', () async {
    GitHub.noteQuotaForTest(_apiResponse(remaining: 0, reset: reset));
    expect(await GitHub.repoProbeDueForTest('https://github.com/o/c'), isFalse);
  });
}
