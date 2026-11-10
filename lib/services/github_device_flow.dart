import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GitHub OAuth device flow ("Sign in with GitHub" for the API token).
///
/// Needs a GitHub OAuth App with "Enable Device Flow" ticked. The client ID
/// is public (not a secret) and comes from the build:
/// `--dart-define=GITHUB_OAUTH_CLIENT_ID=<id>`. Without it the sign-in option
/// is hidden; the ID the app shipped before was not a registered app, so
/// GitHub answered every request with "Not Found".
class GitHubDeviceFlow {
  static const String clientId = String.fromEnvironment(
    'GITHUB_OAUTH_CLIENT_ID',
  );

  static bool get isConfigured => clientId.isNotEmpty;

  @visibleForTesting
  static http.Client Function() clientFactory = http.Client.new;

  /// Step 1: ask GitHub for a user code. Throws [DeviceFlowError] with a
  /// readable reason when GitHub refuses.
  static Future<DeviceCode> requestCode({String scope = ''}) async {
    final client = clientFactory();
    try {
      final res = await client
          .post(
            Uri.parse('https://github.com/login/device/code'),
            headers: const {'Accept': 'application/json'},
            body: {'client_id': clientId, if (scope.isNotEmpty) 'scope': scope},
          )
          .timeout(const Duration(seconds: 20));
      final data = _decode(res.body);
      if (res.statusCode != 200 || data['device_code'] == null) {
        throw DeviceFlowError(
          (data['error_description'] ?? data['error'] ?? 'HTTP ${res.statusCode}')
              .toString(),
        );
      }
      return DeviceCode(
        deviceCode: data['device_code'].toString(),
        userCode: data['user_code'].toString(),
        verificationUri: data['verification_uri'].toString(),
        interval: Duration(
          seconds: (data['interval'] as num?)?.toInt() ?? 5,
        ),
        expiresIn: Duration(
          seconds: (data['expires_in'] as num?)?.toInt() ?? 900,
        ),
      );
    } finally {
      client.close();
    }
  }

  /// Step 2: poll until the user approves. Requests run one at a time (no
  /// overlapping timers), `slow_down` adds 5 s to the interval as GitHub
  /// requires, and the wait ends when the code expires or [isCancelled]
  /// turns true (returns null then).
  static Future<String?> pollForToken(
    DeviceCode code, {
    required bool Function() isCancelled,
    @visibleForTesting Future<void> Function(Duration)? wait,
  }) async {
    final sleep = wait ?? (d) => Future<void>.delayed(d);
    final deadline = DateTime.now().add(code.expiresIn);
    var interval = code.interval;
    final client = clientFactory();
    try {
      while (!isCancelled()) {
        await sleep(interval);
        if (isCancelled()) return null;
        if (DateTime.now().isAfter(deadline)) {
          throw const DeviceFlowError.expired();
        }
        http.Response res;
        try {
          res = await client
              .post(
                Uri.parse('https://github.com/login/oauth/access_token'),
                headers: const {'Accept': 'application/json'},
                body: {
                  'client_id': clientId,
                  'device_code': code.deviceCode,
                  'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
                },
              )
              .timeout(const Duration(seconds: 20));
        } on Exception {
          continue; // network glitch: try again next interval
        }
        final outcome = classifyPollResponse(_decode(res.body));
        switch (outcome.kind) {
          case PollKind.token:
            return outcome.token;
          case PollKind.pending:
            break;
          case PollKind.slowDown:
            interval = outcome.interval ?? interval + const Duration(seconds: 5);
          case PollKind.expired:
            throw const DeviceFlowError.expired();
          case PollKind.denied:
            throw const DeviceFlowError.denied();
          case PollKind.error:
            throw DeviceFlowError(outcome.message ?? 'Unknown error');
        }
      }
      return null;
    } finally {
      client.close();
    }
  }

  /// Maps one access_token response (GitHub answers 200 with an `error`
  /// field while waiting) to what the poll loop should do.
  @visibleForTesting
  static PollOutcome classifyPollResponse(Map<String, dynamic> data) {
    final token = data['access_token'];
    if (token is String && token.isNotEmpty) {
      return PollOutcome(PollKind.token, token: token);
    }
    switch (data['error']) {
      case 'authorization_pending':
        return const PollOutcome(PollKind.pending);
      case 'slow_down':
        final s = (data['interval'] as num?)?.toInt();
        return PollOutcome(
          PollKind.slowDown,
          interval: s == null ? null : Duration(seconds: s),
        );
      case 'expired_token':
        return const PollOutcome(PollKind.expired);
      case 'access_denied':
        return const PollOutcome(PollKind.denied);
      default:
        return PollOutcome(
          PollKind.error,
          message: (data['error_description'] ?? data['error'])?.toString(),
        );
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : const {};
    } catch (_) {
      return const {};
    }
  }
}

class DeviceCode {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final Duration interval;
  final Duration expiresIn;

  const DeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.interval,
    required this.expiresIn,
  });
}

enum PollKind { token, pending, slowDown, expired, denied, error }

class PollOutcome {
  final PollKind kind;
  final String? token;
  final Duration? interval;
  final String? message;
  const PollOutcome(this.kind, {this.token, this.interval, this.message});
}

class DeviceFlowError implements Exception {
  final String message;
  final bool isExpired;
  final bool isDenied;
  const DeviceFlowError(this.message) : isExpired = false, isDenied = false;
  const DeviceFlowError.expired()
    : message = 'expired',
      isExpired = true,
      isDenied = false;
  const DeviceFlowError.denied()
    : message = 'denied',
      isExpired = false,
      isDenied = true;
  @override
  String toString() => message;
}
