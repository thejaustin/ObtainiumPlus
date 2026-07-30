import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/source_provider.dart';

/// Live download state for an app: the progress percent (listenable, with -1
/// meaning "installing" and null meaning "idle") plus the bytes downloaded and
/// total size when known. Held by reference and shared across [AppInMemory]
/// copies so UI listeners bound to an earlier instance keep updating even
/// after saveApps replaces the map entry with a copy.
class DownloadState {
  final ValueNotifier<double?> progress = ValueNotifier(null);
  int? receivedBytes;
  int? totalBytes;
}

class AppInMemory {
  late App app;
  final DownloadState download;
  PackageInfo? installedInfo;
  Uint8List? icon;
  String? sourceType;

  ValueNotifier<double?> get downloadProgressNotifier => download.progress;

  double? get downloadProgress => download.progress.value;
  set downloadProgress(double? value) => download.progress.value = value;

  int? get downloadReceivedBytes => download.receivedBytes;
  set downloadReceivedBytes(int? value) => download.receivedBytes = value;

  int? get downloadTotalBytes => download.totalBytes;
  set downloadTotalBytes(int? value) => download.totalBytes = value;

  AppInMemory(
    this.app,
    double? progress,
    this.installedInfo,
    this.icon, {
    this.sourceType,
    DownloadState? download,
  }) : download = download ?? (DownloadState()..progress.value = progress);

  AppInMemory deepCopy() => AppInMemory(
    app.deepCopy(),
    downloadProgress,
    installedInfo,
    icon,
    sourceType: sourceType,
    download: download,
  );

  AppInMemory copyWith({
    App? app,
    PackageInfo? installedInfo,
    Uint8List? icon,
    String? sourceType,
  }) => AppInMemory(
    app ?? this.app,
    downloadProgress,
    installedInfo ?? this.installedInfo,
    icon ?? this.icon,
    sourceType: sourceType ?? this.sourceType,
    download: download,
  );

  String get name => app.overrideName ?? app.finalName;
  String get author => app.overrideAuthor ?? app.finalAuthor;

  bool get needsRefreshBeforeDownload =>
      app.settings.getBool('refreshBeforeDownload') ||
      (app.apkUrls.isNotEmpty && app.apkUrls.first.value == 'placeholder');

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
