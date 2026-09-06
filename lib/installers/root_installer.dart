import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/installers/installer.dart';
import 'package:obtainium/providers/source_provider.dart';

/// Installs via elevated `su` root shell commands directly using `pm install`.
/// Supports silent installs and multi-split installs via package installer sessions.
class RootInstaller extends Installer {
  RootInstaller(super.settingsProvider);

  @override
  String get modeKey => 'root';

  @override
  Future<bool> canInstallSilently(App app) async => true;

  @override
  Future<bool> checkPermission() async {
    try {
      final res = await Process.run('su', [
        '-c',
        'id',
      ]).timeout(const Duration(seconds: 5));
      return res.exitCode == 0 && res.stdout.toString().contains('uid=0');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> ensurePermission() async {
    final granted = await checkPermission();
    if (!granted) {
      throw ObtainiumError(tr('rootNotDetected'));
    }
  }

  @override
  Future<InstallResult> installApk(
    List<String> apkFilePaths, {
    required String appId,
    Map<String, dynamic> installOptions = const {},
  }) async {
    if (apkFilePaths.isEmpty) {
      return InstallResult.error(1);
    }
    try {
      ProcessResult res;
      if (apkFilePaths.length == 1) {
        final escaped = apkFilePaths.first.replaceAll("'", "'\\''");
        res = await Process.run('su', [
          '-c',
          "pm install -r -d '$escaped'",
        ]).timeout(const Duration(minutes: 3));
      } else {
        // Multi-APK / Split APK install via pm install-create session
        final sessionCreate = await Process.run('su', [
          '-c',
          'pm install-create -r -d',
        ]).timeout(const Duration(seconds: 30));
        if (sessionCreate.exitCode != 0) {
          return InstallResult.error(sessionCreate.exitCode);
        }
        // Output format: "Success: created install session [12345]"
        final match = RegExp(
          r'\[(\d+)\]',
        ).firstMatch(sessionCreate.stdout.toString());
        if (match == null) {
          return InstallResult.error(1);
        }
        final sessionId = match.group(1)!;
        bool writeSuccess = true;
        for (int i = 0; i < apkFilePaths.length; i++) {
          final p = apkFilePaths[i];
          final f = File(p);
          final size = await f.length();
          final escaped = p.replaceAll("'", "'\\''");
          final writeRes = await Process.run('su', [
            '-c',
            "pm install-write -S $size $sessionId split_$i '$escaped'",
          ]).timeout(const Duration(minutes: 2));
          if (writeRes.exitCode != 0) {
            writeSuccess = false;
            break;
          }
        }
        if (!writeSuccess) {
          await Process.run('su', ['-c', 'pm install-abandon $sessionId']);
          return InstallResult.error(1);
        }
        res = await Process.run('su', [
          '-c',
          'pm install-commit $sessionId',
        ]).timeout(const Duration(minutes: 3));
      }
      final out = '${res.stdout} ${res.stderr}';
      if (res.exitCode == 0 && out.toLowerCase().contains('success')) {
        return InstallResult.success();
      }
      return InstallResult.error(res.exitCode != 0 ? res.exitCode : 1);
    } catch (_) {
      return InstallResult.error(1);
    }
  }
}
