import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obtainium/services/github_device_flow.dart';

void main() {
  const code = DeviceCode(
    deviceCode: 'dc',
    userCode: 'ABCD-1234',
    verificationUri: 'https://github.com/login/device',
    interval: Duration(seconds: 5),
    expiresIn: Duration(minutes: 15),
  );

  tearDown(() => GitHubDeviceFlow.clientFactory = http.Client.new);

  test('classifies GitHub poll responses', () {
    PollKind k(Map<String, dynamic> d) =>
        GitHubDeviceFlow.classifyPollResponse(d).kind;
    expect(k({'access_token': 'gho_x'}), PollKind.token);
    expect(k({'error': 'authorization_pending'}), PollKind.pending);
    expect(k({'error': 'slow_down', 'interval': 10}), PollKind.slowDown);
    expect(k({'error': 'expired_token'}), PollKind.expired);
    expect(k({'error': 'access_denied'}), PollKind.denied);
    expect(k({'error': 'incorrect_client_credentials'}), PollKind.error);
  });

  test('keeps polling through pending and slow_down, honouring the new '
      'interval, and returns the token', () async {
    final replies = [
      {'error': 'authorization_pending'},
      {'error': 'slow_down', 'interval': 10},
      {'access_token': 'gho_token'},
    ];
    GitHubDeviceFlow.clientFactory = () => MockClient(
      (_) async => http.Response(jsonEncode(replies.removeAt(0)), 200),
    );
    final waits = <Duration>[];
    final token = await GitHubDeviceFlow.pollForToken(
      code,
      isCancelled: () => false,
      wait: (d) async => waits.add(d),
    );
    expect(token, 'gho_token');
    expect(waits, [
      const Duration(seconds: 5),
      const Duration(seconds: 5),
      const Duration(seconds: 10),
    ]);
  });

  test('denied and expired end the flow with a typed error', () async {
    GitHubDeviceFlow.clientFactory = () => MockClient(
      (_) async => http.Response(jsonEncode({'error': 'access_denied'}), 200),
    );
    expect(
      GitHubDeviceFlow.pollForToken(
        code,
        isCancelled: () => false,
        wait: (_) async {},
      ),
      throwsA(isA<DeviceFlowError>().having((e) => e.isDenied, 'denied', true)),
    );
  });

  test('cancelling stops without a token', () async {
    var calls = 0;
    GitHubDeviceFlow.clientFactory = () => MockClient((_) async {
      calls++;
      return http.Response(jsonEncode({'error': 'authorization_pending'}), 200);
    });
    var cancelled = false;
    final token = await GitHubDeviceFlow.pollForToken(
      code,
      isCancelled: () => cancelled,
      wait: (_) async {
        if (calls >= 2) cancelled = true;
      },
    );
    expect(token, isNull);
    expect(calls, 2);
  });

  test('an unregistered client ID reports GitHub\'s reason', () async {
    GitHubDeviceFlow.clientFactory = () => MockClient(
      (_) async => http.Response(jsonEncode({'error': 'Not Found'}), 404),
    );
    expect(
      GitHubDeviceFlow.requestCode(),
      throwsA(isA<DeviceFlowError>().having((e) => e.message, 'message', 'Not Found')),
    );
  });
}
