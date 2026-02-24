import 'dart:typed_data';
import 'package:android_package_manager/android_package_manager.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';

class AppInMemory {
  late App app;
  double? downloadProgress;
  PackageInfo? installedInfo;
  Uint8List? icon;

  AppInMemory(this.app, this.downloadProgress, this.installedInfo, this.icon);
  AppInMemory deepCopy() =>
      AppInMemory(app.deepCopy(), downloadProgress, installedInfo, icon);

  String get name => app.overrideName ?? app.finalName;
  String get author => app.overrideAuthor ?? app.finalAuthor;
}
