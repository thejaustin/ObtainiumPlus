import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/auth_bundle.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/utils/logger.dart';

class AuthProvider with ChangeNotifier {
  AuthBundle? _activeBundle;
  List<String> _dispensers = ['https://auroraoss.com/api/auth'];
  SharedPreferences? _prefs;

  AuthBundle? get activeBundle => _activeBundle;
  List<String> get dispensers => _dispensers;
  bool get hasActiveToken => _activeBundle != null;

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    
    // Load dispensers
    _dispensers = _prefs?.getStringList('play_store_dispensers') ?? ['https://auroraoss.com/api/auth'];
    
    // Load active bundle if exists
    final bundleJson = _prefs?.getString('active_auth_bundle');
    if (bundleJson != null) {
      try {
        _activeBundle = AuthBundle.fromJson(jsonDecode(bundleJson));
      } catch (e) {
        talker.warning('Failed to parse stored AuthBundle');
      }
    }
    notifyListeners();
  }

  Future<void> addDispenser(String url) async {
    if (!_dispensers.contains(url)) {
      _dispensers.add(url);
      await _prefs?.setStringList('play_store_dispensers', _dispensers);
      notifyListeners();
    }
  }

  Future<void> removeDispenser(String url) async {
    _dispensers.remove(url);
    await _prefs?.setStringList('play_store_dispensers', _dispensers);
    notifyListeners();
  }

  Future<void> refreshBundle(String dispenserUrl) async {
    try {
      final bundle = await AuthService.fetchAnonymousBundle(dispenserUrl);
      _activeBundle = bundle;
      await _prefs?.setString('active_auth_bundle', jsonEncode({
        'email': bundle.email,
        'aasToken': bundle.aasToken,
        'authToken': bundle.authToken,
        'deviceConfig': bundle.deviceConfig,
      }));
      notifyListeners();
    } catch (e) {
      // Errors handled by service/caller
      rethrow;
    }
  }

  void clearBundle() {
    _activeBundle = null;
    _prefs?.remove('active_auth_bundle');
    notifyListeners();
  }
}
