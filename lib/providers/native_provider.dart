import 'dart:async';
import 'dart:io';
import 'package:android_system_font/android_system_font.dart';
import 'package:flutter/services.dart';

class NativeFeatures {
  static bool _systemFontLoaded = false;
  static bool _systemFontLoading = false;

  static Future<ByteData> _readFileBytes(String path) async {
    var bytes = await File(path).readAsBytes();
    return ByteData.view(bytes.buffer);
  }

  static Future<void> loadSystemFont() async {
    if (_systemFontLoaded || _systemFontLoading) return;
    _systemFontLoading = true;
    try {
      final fontFilePath = await AndroidSystemFont().getFilePath();
      if (fontFilePath != null && fontFilePath.isNotEmpty) {
        final fontFile = File(fontFilePath);
        if (await fontFile.exists()) {
          final fontLoader = FontLoader('SystemFont');
          fontLoader.addFont(_readFileBytes(fontFilePath));
          await fontLoader.load();
          _systemFontLoaded = true;
        }
      }
    } catch (_) {
    } finally {
      _systemFontLoading = false;
    }
  }
}
