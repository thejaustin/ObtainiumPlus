import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/http_client_factory.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsProvider settings;
  final seen = <http.BaseRequest>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider()
      ..prefs = await SharedPreferences.getInstance();
    seen.clear();
  });

  tearDown(() {
    HttpClientFactory.resolver = HttpClientFactory.defaultResolver;
  });

  void serve(Future<http.Response> Function(http.Request) handler) {
    final client = MockClient((request) {
      seen.add(request);
      return handler(request);
    });
    HttpClientFactory.resolver = (uri, {bool allowInsecure = false}) async =>
        client;
  }

  test('the response keeps the headers that were sent', () async {
    serve((r) async => http.Response('ok', 200));
    final res = await SourceUtils.httpRequest(
      'https://api.github.com/repos/o/r',
      headers: {'authorization': 'Token abc'},
      settingsProvider: settings,
    );
    expect(res.body, 'ok');
    expect(res.request!.headers['authorization'], 'Token abc');
  });

  test('follows redirects and drops auth on a cross-host hop', () async {
    serve((r) async {
      if (r.url.host == 'api.github.com') {
        return http.Response(
          '',
          302,
          headers: {'location': 'https://objects.example.com/file'},
        );
      }
      return http.Response('final', 200);
    });
    final headers = {'authorization': 'Token abc', 'accept': 'x'};
    final res = await SourceUtils.httpRequest(
      'https://api.github.com/start',
      headers: headers,
      settingsProvider: settings,
    );
    expect(res.body, 'final');
    expect(seen.last.url.host, 'objects.example.com');
    expect(seen.last.headers.containsKey('authorization'), isFalse);
    expect(seen.last.headers['accept'], 'x');
    // The caller's map is untouched.
    expect(headers['authorization'], 'Token abc');
  });

  test('a relative redirect resolves against the current URL', () async {
    serve((r) async {
      if (r.url.path == '/a') {
        return http.Response('', 301, headers: {'location': '/b'});
      }
      return http.Response(r.url.toString(), 200);
    });
    final res = await SourceUtils.httpRequest(
      'https://example.com/a',
      settingsProvider: settings,
    );
    expect(res.body, 'https://example.com/b');
  });

  test('refuses an https to http downgrade', () async {
    serve(
      (r) async =>
          http.Response('', 302, headers: {'location': 'http://example.com/x'}),
    );
    expect(
      SourceUtils.httpRequest(
        'https://example.com/a',
        settingsProvider: settings,
      ),
      throwsA(isA<ObtainiumError>()),
    );
  });
}
