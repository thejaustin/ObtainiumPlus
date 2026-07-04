import 'package:flutter/material.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SourceConfigProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  Future<void> initializeSettings(SharedPreferences prefs) async {
    _prefs = prefs;
    notifyListeners();
  }

  String? getSettingString(String settingId) {
    String? str = _prefs?.safeString(settingId);
    return str?.isNotEmpty == true ? str : null;
  }

  void setSettingString(String settingId, String value) {
    if (value.isEmpty) {
      _prefs?.remove(settingId);
    } else {
      _prefs?.setString(settingId, value);
    }
    notifyListeners();
  }

  bool getSettingBool(String settingId) {
    return _prefs?.safeBool(settingId) ?? false;
  }

  void setSettingBool(String settingId, bool value) {
    _prefs?.setBool(settingId, value);
    notifyListeners();
  }
}
