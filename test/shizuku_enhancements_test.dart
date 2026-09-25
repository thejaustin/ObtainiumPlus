import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/installers/shizuku_installer.dart';
import 'package:obtainium/services/adb_port_prober.dart';
import 'package:obtainium/services/shizuku_telemetry_service.dart';

void main() {
  group('AdbPortProber Tests', () {
    test('candidatePorts includes standard ADB loopback port 5555', () {
      expect(AdbPortProber.candidatePorts, contains(5555));
      expect(AdbPortProber.candidatePorts.first, equals(5555));
    });

    test('isPortOpen returns false for invalid ports', () async {
      expect(await AdbPortProber.isPortOpen(0), isFalse);
      expect(await AdbPortProber.isPortOpen(-1), isFalse);
      expect(await AdbPortProber.isPortOpen(70000), isFalse);
    });
  });

  group('ShizukuTelemetryService Tests', () {
    final telemetry = ShizukuTelemetryService.instance;

    setUp(() {
      telemetry.clear();
    });

    test('logs entries and maintains max limit', () {
      expect(telemetry.entries, isEmpty);

      telemetry.log(
        action: 'testAction',
        targetPackage: 'com.example.app',
        durationMs: 120,
        latencyMs: 15,
        status: 'success',
        details: 'Installed cleanly',
      );

      expect(telemetry.entries.length, equals(1));
      final entry = telemetry.entries.first;
      expect(entry.action, equals('testAction'));
      expect(entry.targetPackage, equals('com.example.app'));
      expect(entry.durationMs, equals(120));
      expect(entry.latencyMs, equals(15));
      expect(entry.status, equals('success'));
      expect(entry.isSuccess, isTrue);
      expect(entry.isBlocked, isFalse);
      expect(entry.isError, isFalse);

      // Verify max buffer capacity
      for (int i = 0; i < 60; i++) {
        telemetry.log(
          action: 'bulkAction$i',
          durationMs: 10,
          status: 'success',
        );
      }
      expect(telemetry.entries.length, equals(ShizukuTelemetryService.maxEntries));
    });

    test('identifies blocked and error statuses correctly', () {
      telemetry.log(
        action: 'installApk',
        targetPackage: 'com.blocked.app',
        durationMs: 50,
        status: 'blocked',
        details: 'Blocked by Samsung Auto Blocker',
      );
      final entry = telemetry.entries.first;
      expect(entry.isBlocked, isTrue);
      expect(entry.isSuccess, isFalse);

      telemetry.log(
        action: 'installApk',
        targetPackage: 'com.error.app',
        durationMs: 50,
        status: 'error',
        details: 'Signature conflict',
      );
      expect(telemetry.entries.first.isError, isTrue);
    });

    test('exportPlainText generates report string', () {
      telemetry.log(
        action: 'installAPK',
        targetPackage: 'com.test.pkg',
        durationMs: 250,
        latencyMs: 12,
        status: 'success',
        details: 'Committed via binder',
      );

      final report = telemetry.exportPlainText();
      expect(report, contains('=== ObtainiumPlus Shizuku Activity Log ==='));
      expect(report, contains('installAPK [com.test.pkg]'));
      expect(report, contains('latency: 12ms'));
    });

    test('clear removes all entries', () {
      telemetry.log(action: 'foo', durationMs: 1, status: 'success');
      expect(telemetry.entries, isNotEmpty);
      telemetry.clear();
      expect(telemetry.entries, isEmpty);
    });
  });

  group('ShizukuInstaller Diagnostics & Error Mapping Tests', () {
    test('isBlockedByAutoBlocker recognizes code -21 and 21', () {
      expect(ShizukuInstaller.isBlockedByAutoBlocker(-21), isTrue);
      expect(ShizukuInstaller.isBlockedByAutoBlocker(21), isTrue);
      expect(ShizukuInstaller.isBlockedByAutoBlocker(0), isFalse);
      expect(ShizukuInstaller.isBlockedByAutoBlocker(1), isFalse);
    });

    test('getDiagnosticMessageForErrorCode provides helpful messages', () {
      final msgBlocked = ShizukuInstaller.getDiagnosticMessageForErrorCode(-21);
      expect(msgBlocked, contains('Auto Blocker'));

      final msgConflict = ShizukuInstaller.getDiagnosticMessageForErrorCode(-1);
      expect(msgConflict, contains('Signature conflict'));

      final msgStorage = ShizukuInstaller.getDiagnosticMessageForErrorCode(-3);
      expect(msgStorage, contains('Insufficient device storage'));

      final msgIncompatible = ShizukuInstaller.getDiagnosticMessageForErrorCode(-7);
      expect(msgIncompatible, contains('Incompatible device architecture'));

      final msgInvalid = ShizukuInstaller.getDiagnosticMessageForErrorCode(-2);
      expect(msgInvalid, contains('Package parsing error'));
    });
  });
}
