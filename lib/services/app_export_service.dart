import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:shared_storage/shared_storage.dart' as saf;
import 'package:obtainium/custom_errors.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

Uint8List _encodeJson(Map<String, dynamic> data) {
  var encoder = const JsonEncoder.withIndent("    ");
  return Uint8List.fromList(utf8.encode(encoder.convert(data)));
}

class AppExportService {
  AppExportService._();

  static Future<String> decryptBackup(String data, String password) async {
    return await compute(_decryptData, {'data': data, 'password': password});
  }

  static String _decryptData(Map<String, String> args) {
    try {
      final decodedData = jsonDecode(args['data']!);
      if (decodedData is Map && decodedData['encrypted'] == true) {
        final salt = decodedData['salt'];
        final ivBase64 = decodedData['iv'];
        final encryptedData = decodedData['data'];

        final keyHash = sha256
            .convert(utf8.encode(args['password']! + salt))
            .bytes;
        final key = encrypt.Key(Uint8List.fromList(keyHash));
        final iv = encrypt.IV.fromBase64(ivBase64);

        final encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
        );
        return encrypter.decrypt64(encryptedData, iv: iv);
      }
      return args['data']!;
    } catch (e) {
      throw ObtainiumError(tr('invalidBackupPassword'));
    }
  }

  static Future<Uint8List> _encryptData(Map<String, dynamic> args) async {
    final Map<String, dynamic> finalExport = args['exportData'];
    final String password = args['password'];

    var encoder = const JsonEncoder.withIndent("    ");
    final jsonStr = encoder.convert(finalExport);

    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final keyHash = sha256.convert(utf8.encode(password + salt)).bytes;
    final key = encrypt.Key(Uint8List.fromList(keyHash));
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    final encrypted = encrypter.encrypt(jsonStr, iv: iv);

    final wrappedData = {
      'encrypted': true,
      'salt': salt,
      'iv': iv.base64,
      'data': encrypted.base64,
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(wrappedData)));
  }

  static Map<String, dynamic> generateExportJSON({
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    List<String>? appIds,
    int? overrideExportSettings,
  }) {
    Map<String, dynamic> finalExport = {};
    finalExport['apps'] = apps.values
        .where((e) {
          if (appIds == null) {
            return true;
          } else {
            return appIds.contains(e.app.id);
          }
        })
        .map((e) => e.app.toJson())
        .toList();
    int shouldExportSettings = settingsProvider.exportSettings;
    if (overrideExportSettings != null) {
      shouldExportSettings = overrideExportSettings;
    }
    if (shouldExportSettings > 0) {
      var settingsValueKeys = settingsProvider.prefs?.getKeys();
      if (shouldExportSettings < 2) {
        settingsValueKeys?.removeWhere((k) => k.endsWith('-creds'));
      }
      finalExport['settings'] = Map<String, Object?>.fromEntries(
        (settingsValueKeys
                ?.map((key) => MapEntry(key, settingsProvider.prefs?.get(key)))
                .toList()) ??
            [],
      );
    }
    return finalExport;
  }

  static Future<Uint8List> getExportBytes({
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    String? password,
  }) async {
    Map<String, dynamic> finalExport = generateExportJSON(
      apps: apps,
      settingsProvider: settingsProvider,
    );

    if (password != null && password.isNotEmpty) {
      return await compute(_encryptData, {
        'exportData': finalExport,
        'password': password,
      });
    } else {
      return await compute(_encodeJson, finalExport);
    }
  }

  static Future<String?> export({
    required Map<String, AppInMemory> apps,
    required SettingsProvider settingsProvider,
    bool pickOnly = false,
    bool isAuto = false,
    String? password,
  }) async {
    var exportDir = await settingsProvider.getExportDir();
    if (isAuto) {
      if (settingsProvider.autoExportOnChanges != true) {
        return null;
      }
      if (exportDir == null) {
        return null;
      }
      var files = await saf
          .listFiles(exportDir, columns: [saf.DocumentFileColumn.id])
          .where((f) => f.uri.pathSegments.last.endsWith('-auto.json'))
          .toList();
      if (files.isNotEmpty) {
        for (var f in files) {
          saf.delete(f.uri);
        }
      }
    }
    if (exportDir == null || pickOnly) {
      await settingsProvider.pickExportDir();
      exportDir = await settingsProvider.getExportDir();
    }
    if (exportDir == null) {
      return null;
    }
    String? returnPath;
    if (!pickOnly) {
      Uint8List bytes = await getExportBytes(
        apps: apps,
        settingsProvider: settingsProvider,
        password: password,
      );

      var result = await saf.createFile(
        exportDir,
        displayName:
            '${tr('obtainiumExportHyphenatedLowercase')}-${DateTime.now().toIso8601String().replaceAll(':', '-')}${isAuto ? '-auto' : ''}.json',
        mimeType: 'application/json',
        bytes: bytes,
      );
      if (result == null) {
        throw ObtainiumError(tr('unexpectedError'));
      }
      returnPath = exportDir.pathSegments
          .join('/')
          .replaceFirst('tree/primary:', '/');
    }
    return returnPath;
  }

  static Future<MapEntry<List<App>, bool>> import({
    required String appsJSON,
    required bool Function() getLoadingApps,
    required SettingsProvider settingsProvider,
    required Future<void> Function(List<App>, {bool onlyIfExists}) saveApps,
    required void Function() notifyListeners,
  }) async {
    // Decode JSON in a background isolate to prevent UI freeze
    final decodedJSON = await compute(jsonDecode, appsJSON);
    var newFormat = decodedJSON is! List;
    List<App> importedApps =
        ((newFormat ? decodedJSON['apps'] : decodedJSON) as List<dynamic>)
            .map((e) => App.fromJson(e))
            .toList();
    while (getLoadingApps()) {
      await Future.delayed(const Duration(microseconds: 1));
    }
    for (App a in importedApps) {
      var installedInfo = await AppInstallService.getInstalledInfo(
        a.id,
        printErr: false,
      );
      a.installedVersion =
          a.additionalSettings['useVersionCodeAsOSVersion'] == true
          ? installedInfo?.versionCode.toString()
          : installedInfo?.versionName;
    }
    await saveApps(importedApps, onlyIfExists: false);
    notifyListeners();
    if (newFormat && decodedJSON['settings'] != null) {
      var settingsMap = decodedJSON['settings'] as Map<String, Object?>;
      settingsMap.forEach((key, value) {
        if (value is int) {
          settingsProvider.prefs?.setInt(key, value);
        } else if (value is double) {
          settingsProvider.prefs?.setDouble(key, value);
        } else if (value is bool) {
          settingsProvider.prefs?.setBool(key, value);
        } else if (value is List) {
          settingsProvider.prefs?.setStringList(
            key,
            value.map((e) => e as String).toList(),
          );
        } else {
          settingsProvider.prefs?.setString(key, value as String);
        }
      });
    }
    return MapEntry<List<App>, bool>(
      importedApps,
      newFormat && decodedJSON['settings'] != null,
    );
  }
}
