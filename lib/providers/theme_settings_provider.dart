import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:obtainium/utils/theme_style.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSettings { system, light, dark }

class ThemeSettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;

  Future<void> initializeSettings(SharedPreferences p) async {
    prefs = p;
    _migrateThemeStyle(p);
    notifyListeners();
  }

  /// First launch after the named styles were introduced. New installs get
  /// [AppThemeStyle.obtainiumPlus]; existing installs keep their current look
  /// (the app already used Expressive shapes plus the Plus effects) unless
  /// they had switched Expressive off.
  void _migrateThemeStyle(SharedPreferences p) {
    if (p.containsKey('appThemeStyle')) return;
    const existingInstallKeys = [
      'theme',
      'themeColor',
      'themeVariant',
      'plusEnableMaterialExpressive',
      'plusEnableGlassmorphism',
    ];
    final existing = existingInstallKeys.any(p.containsKey);
    if (!existing) return;
    final expressive = p.safeBool('plusEnableMaterialExpressive') ?? true;
    final glass = p.safeBool('plusEnableGlassmorphism') ?? true;
    final style = switch ((expressive, glass)) {
      (true, true) => AppThemeStyle.expressivePlus,
      (true, false) => AppThemeStyle.expressive,
      (false, true) => AppThemeStyle.obtainiumPlus,
      (false, false) => AppThemeStyle.obtainium,
    };
    p.setInt('appThemeStyle', style.index);
  }

  AppThemeStyle get themeStyle =>
      prefs?.safeEnum('appThemeStyle', AppThemeStyle.values) ??
      AppThemeStyle.obtainiumPlus;

  set themeStyle(AppThemeStyle s) {
    prefs?.setInt('appThemeStyle', s.index);
    notifyListeners();
  }

  ThemeSettings get theme {
    return prefs?.safeEnum('theme', ThemeSettings.values) ??
        ThemeSettings.system;
  }

  set theme(ThemeSettings t) {
    prefs?.setInt('theme', t.index);
    notifyListeners();
  }

  DynamicSchemeVariant get themeVariant {
    return prefs?.safeEnum('themeVariant', DynamicSchemeVariant.values) ??
        defaultVariantFor(themeStyle);
  }

  set themeVariant(DynamicSchemeVariant t) {
    prefs?.setInt('themeVariant', t.index);
    notifyListeners();
  }

  Color get themeColor {
    int? colorCode = prefs?.safeInt('themeColor');
    return (colorCode != null) ? Color(colorCode) : obtainiumSeedColor;
  }

  set themeColor(Color themeColor) {
    prefs?.setInt('themeColor', themeColor.value);
    notifyListeners();
  }

  bool get useMaterialYou {
    return prefs?.safeBool('useMaterialYou') ?? false;
  }

  set useMaterialYou(bool useMaterialYou) {
    prefs?.setBool('useMaterialYou', useMaterialYou);
    notifyListeners();
  }

  bool get matchSystemMaterialStyle {
    return prefs?.safeBool('matchSystemMaterialStyle') ?? false;
  }

  set matchSystemMaterialStyle(bool matchSystemMaterialStyle) {
    prefs?.setBool('matchSystemMaterialStyle', matchSystemMaterialStyle);
    notifyListeners();
  }

  bool get useBlackTheme {
    return prefs?.safeBool('useBlackTheme') ?? false;
  }

  set useBlackTheme(bool useBlackTheme) {
    prefs?.setBool('useBlackTheme', useBlackTheme);
    notifyListeners();
  }

  bool get useSystemFont {
    return prefs?.safeBool('useSystemFont') ?? false;
  }

  set useSystemFont(bool useSystemFont) {
    prefs?.setBool('useSystemFont', useSystemFont);
    notifyListeners();
  }
}
