import 'package:obtainium/utils/safe_prefs.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSettings { system, light, dark }

class ThemeSettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;

  Future<void> initializeSettings(SharedPreferences p) async {
    prefs = p;
    notifyListeners();
  }

  ThemeSettings get theme {
    return ThemeSettings.values[prefs?.safeInt('theme') ??
        ThemeSettings.system.index];
  }

  set theme(ThemeSettings t) {
    prefs?.setInt('theme', t.index);
    notifyListeners();
  }

  DynamicSchemeVariant get themeVariant {
    return DynamicSchemeVariant.values[prefs?.safeInt('themeVariant') ??
        DynamicSchemeVariant.expressive.index];
  }

  set themeVariant(DynamicSchemeVariant t) {
    prefs?.setInt('themeVariant', t.index);
    notifyListeners();
  }

  Color get themeColor {
    int? colorCode = prefs?.safeInt('themeColor');
    return (colorCode != null) ? Color(colorCode) : const Color(0xFF6438B5);
  }

  set themeColor(Color themeColor) {
    prefs?.setInt('themeColor', themeColor.value);
    notifyListeners();
  }

  bool get useMaterialYou {
    return prefs?.getBool('useMaterialYou') ?? false;
  }

  set useMaterialYou(bool useMaterialYou) {
    prefs?.setBool('useMaterialYou', useMaterialYou);
    notifyListeners();
  }

  bool get matchSystemMaterialStyle {
    return prefs?.getBool('matchSystemMaterialStyle') ?? false;
  }

  set matchSystemMaterialStyle(bool matchSystemMaterialStyle) {
    prefs?.setBool('matchSystemMaterialStyle', matchSystemMaterialStyle);
    notifyListeners();
  }

  bool get useBlackTheme {
    return prefs?.getBool('useBlackTheme') ?? false;
  }

  set useBlackTheme(bool useBlackTheme) {
    prefs?.setBool('useBlackTheme', useBlackTheme);
    notifyListeners();
  }

  bool get useSystemFont {
    return prefs?.getBool('useSystemFont') ?? false;
  }

  set useSystemFont(bool useSystemFont) {
    prefs?.setBool('useSystemFont', useSystemFont);
    notifyListeners();
  }
}
