import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/services/http_client_factory.dart';
import 'package:obtainium/services/pin_store.dart';

class _ThrowingClient extends http.BaseClient {
  _ThrowingClient(this.error);
  final Object error;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(error);
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pin_failure_test');
    PinStore.instance.clearFailure();
  });

  tearDown(() async {
    PinStore.instance.clearFailure();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('recordFailure and clearFailure notify once and track the host', () {
    final store = PinStore.forTesting(() async => tempDir);
    var notified = 0;
    store.addListener(() => notified++);

    expect(store.lastFailureHost, isNull);
    store.recordFailure('api.github.com');
    store.recordFailure('api.github.com'); // duplicate: no extra notify
    expect(store.lastFailureHost, 'api.github.com');
    expect(notified, 1);

    store.clearFailure();
    store.clearFailure();
    expect(store.lastFailureHost, isNull);
    expect(notified, 2);
  });

  test(
    'restoreAllBuiltIn clears the failure and re-enables built-ins',
    () async {
      final store = PinStore.forTesting(() async => tempDir);
      await store.ensureLoaded();
      store.recordFailure('api.github.com');
      await store.restoreAllBuiltIn();
      expect(store.lastFailureHost, isNull);
      expect(store.hasBuiltInOverrides, isFalse);
    },
  );

  test(
    'a TLS failure becomes CertificatePinningError and is recorded',
    () async {
      final client = PinGuardClient(
        _ThrowingClient(const HandshakeException('pin mismatch')),
      );
      await expectLater(
        client.get(Uri.parse('https://api.github.com/x')),
        throwsA(isA<CertificatePinningError>()),
      );
      expect(PinStore.instance.lastFailureHost, 'api.github.com');
    },
  );

  test('non-TLS errors pass through untouched', () async {
    final client = PinGuardClient(
      _ThrowingClient(const SocketException('offline')),
    );
    await expectLater(
      client.get(Uri.parse('https://api.github.com/x')),
      throwsA(isA<SocketException>()),
    );
    expect(PinStore.instance.lastFailureHost, isNull);
  });

  test('CertificatePinningError carries the CERT_PINNING code and host', () {
    final e = CertificatePinningError('codeberg.org');
    expect(e.code, 'CERT_PINNING');
    expect(e.data?['host'], 'codeberg.org');
  });
}
