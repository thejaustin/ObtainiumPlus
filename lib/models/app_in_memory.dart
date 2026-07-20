import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/source_provider.dart';

class AppInMemory {
  late App app;
  final ValueNotifier<double?> downloadProgressNotifier;
  PackageInfo? installedInfo;
  Uint8List? icon;

  double? get downloadProgress => downloadProgressNotifier.value;
  set downloadProgress(double? value) => downloadProgressNotifier.value = value;

  AppInMemory(this.app, double? progress, this.installedInfo, this.icon)
    : downloadProgressNotifier = ValueNotifier(progress);

  AppInMemory deepCopy() =>
      AppInMemory(app.deepCopy(), downloadProgress, installedInfo, icon);

  String get name => app.overrideName ?? app.finalName;
  String get author => app.overrideAuthor ?? app.finalAuthor;

  bool get hasMultipleSigners {
    return installedInfo?.signingInfo?.hasMultipleSigners ?? false;
  }

  List<String> get certificateHashes {
    final signatures = this.hasMultipleSigners
        ? installedInfo?.signingInfo?.apkContentSigners
        : installedInfo?.signingInfo?.signingCertificateHistory;

    return signatures?.map((signature) {
          final digest = sha256.convert(signature);
          return digest.bytes
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(':');
        }).toList() ??
        [];
  }
}
