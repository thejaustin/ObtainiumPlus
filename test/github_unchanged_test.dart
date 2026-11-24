import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/models/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

App _app({
  int failed = 0,
  Map<String, dynamic>? settings,
  String version = '1.0',
}) => App(
  'o.r',
  'https://github.com/o/r',
  'o',
  'r',
  '1.0',
  version,
  [],
  0,
  settings ?? <String, dynamic>{},
  null,
  false,
  consecutiveFailedChecks: failed,
);

void main() {
  final source = GitHub();
  late List<Map<String, String>> sent;
  late int status;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GitHub.clearAtomStateForTest();
    sent = [];
    status = 200;
    GitHub.atomRequestOverride = (url, headers) async {
      sent.add(headers);
      return Response(
        '<feed/>',
        status,
        headers: status == 200 ? {'etag': 'W/"abc"'} : {},
      );
    };
  });
  tearDown(() => GitHub.atomRequestOverride = null);

  Future<void> firstFullCheck(App app) async {
    expect(await source.unchangedSinceLastCheck(app), isFalse);
    await source.recordCheckSucceeded(app);
  }

  test('no stored state means a full check', () async {
    expect(await source.unchangedSinceLastCheck(_app()), isFalse);
  });

  test('304 after a recorded check skips, and sends the stored ETag', () async {
    await firstFullCheck(_app());
    status = 304;
    expect(await source.unchangedSinceLastCheck(_app()), isTrue);
    expect(sent.last['if-none-match'], 'W/"abc"');
  });

  test('a changed feed (200) does a full check', () async {
    await firstFullCheck(_app());
    expect(await source.unchangedSinceLastCheck(_app()), isFalse);
  });

  test(
    'changed settings, failed last check, no version fall through',
    () async {
      await firstFullCheck(_app());
      status = 304;
      expect(
        await source.unchangedSinceLastCheck(_app(settings: {'x': 1})),
        isFalse,
      );
      expect(await source.unchangedSinceLastCheck(_app(failed: 1)), isFalse);
      expect(await source.unchangedSinceLastCheck(_app(version: '')), isFalse);
    },
  );

  test('state older than a day falls through', () async {
    await firstFullCheck(_app());
    final prefs = await SharedPreferences.getInstance();
    final old = DateTime.now()
        .subtract(const Duration(hours: 25))
        .millisecondsSinceEpoch;
    await prefs.setString(
      'ghAtomState',
      '{"https://github.com/o/r":{"etag":"W/\\"abc\\"","hash":"x","at":$old}}',
    );
    status = 304;
    expect(await source.unchangedSinceLastCheck(_app()), isFalse);
  });

  test('a failed request never skips', () async {
    await firstFullCheck(_app());
    GitHub.atomRequestOverride = (_, _) async => throw Exception('offline');
    expect(await source.unchangedSinceLastCheck(_app()), isFalse);
  });

  test(
    'settings that grow during the check (asset hashes) still skip',
    () async {
      expect(await source.unchangedSinceLastCheck(_app()), isFalse);
      // What the saved app looks like after getApp added assetSha256s.
      final saved = _app(
        settings: {
          'assetSha256s': {'a.apk': 'ff'},
        },
      );
      await source.recordCheckSucceeded(saved);
      status = 304;
      expect(await source.unchangedSinceLastCheck(saved), isTrue);
      expect(await source.unchangedSinceLastCheck(_app()), isFalse);
    },
  );
}
