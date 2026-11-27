import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

const machineTranslationsPrefKey = 'useMachineTranslations';

/// Fills strings no human has translated with the AI-written ones in
/// `assets/translations/machine/`, when [enabled]. Human text always wins: a
/// machine string is used only while the locale's value is still the English
/// source, so approving a human translation replaces it automatically.
Map<String, dynamic> overlayMachineTranslations(
  Map<String, dynamic> human,
  Map<String, dynamic> english,
  Map<String, dynamic> machine,
) {
  final merged = Map<String, dynamic>.of(human);
  for (final e in machine.entries) {
    if (e.value is String && merged[e.key] == english[e.key]) {
      merged[e.key] = e.value;
    }
  }
  return merged;
}

/// The normal asset loader plus the optional machine-translation layer
/// (off by default; see the "Machine translations" setting).
class HumanFirstAssetLoader extends AssetLoader {
  const HumanFirstAssetLoader({this.enabled = _enabledInPrefs});

  final Future<bool> Function() enabled;

  static Future<bool> _enabledInPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.safeBool(machineTranslationsPrefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    const base = RootBundleAssetLoader();
    final human = await base.load(path, locale);
    if (human == null || locale.languageCode == 'en' || !await enabled()) {
      return human;
    }
    try {
      final name = base.getLocalePath('$path/machine', locale);
      final machine =
          jsonDecode(await rootBundle.loadString(name)) as Map<String, dynamic>;
      final english = await base.load(path, const Locale('en')) ?? {};
      return overlayMachineTranslations(human, english, machine);
    } catch (_) {
      return human; // no machine file for this language
    }
  }
}
