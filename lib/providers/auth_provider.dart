import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/auth_bundle.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/custom_errors.dart';

enum AuthMode { anonymous, microG, hybrid }

class AuthProvider with ChangeNotifier {
  AuthBundle? _anonymousBundle;
  AuthBundle? _personalBundle;
  List<String> _dispensers = ['https://auroraoss.com/api/auth'];
  AuthMode _authMode = AuthMode.hybrid;
  String? _microGEmail;
  SharedPreferences? _prefs;

  AuthBundle? get activeBundle {
    if (_authMode == AuthMode.hybrid || _authMode == AuthMode.anonymous) {
      return _anonymousBundle ?? _personalBundle;
    }
    return _personalBundle ?? _anonymousBundle;
  }

  AuthBundle? get personalBundle => _personalBundle;
  AuthBundle? get anonymousBundle => _anonymousBundle;
  List<String> get dispensers => _dispensers;
  AuthMode get authMode => _authMode;
  String? get microGEmail => _microGEmail;
  bool get hasActiveToken => activeBundle != null;

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    
    _dispensers = _prefs?.getStringList('play_store_dispensers') ?? ['https://auroraoss.com/api/auth'];
    _authMode = AuthMode.values[_prefs?.getInt('auth_mode') ?? 2]; // Default to Hybrid
    _microGEmail = _prefs?.getString('microg_email');

    final anonJson = _prefs?.getString('anonymous_auth_bundle');
    if (anonJson != null) {
      try {
        _anonymousBundle = AuthBundle.fromJson(jsonDecode(anonJson));
      } catch (_) {}
    }
    
    final personalJson = _prefs?.getString('personal_auth_bundle');
    if (personalJson != null) {
      try {
        _personalBundle = AuthBundle.fromJson(jsonDecode(personalJson));
      } catch (_) {}
    }
    
    notifyListeners();
  }

  Future<void> setAuthMode(AuthMode mode) async {
    _authMode = mode;
    await _prefs?.setInt('auth_mode', mode.index);
    notifyListeners();
  }

  Future<void> setMicroGEmail(String? email) async {
    _microGEmail = email;
    if (email != null) {
      await _prefs?.setString('microg_email', email);
    } else {
      await _prefs?.remove('microg_email');
    }
    notifyListeners();
  }

  Future<void> refreshMicroGToken() async {
    if (_microGEmail == null) throw ObtainiumError('No microG account selected');
    
    final token = await AuthService.getMicroGToken(_microGEmail!);
    if (token != null) {
      _personalBundle = AuthBundle(
        email: _microGEmail!,
        aasToken: '',
        authToken: token,
        deviceConfig: {}, 
      );
      await _prefs?.setString('personal_auth_bundle', jsonEncode(_personalBundle!.toJson()));
      notifyListeners();
    } else {
      throw ObtainiumError('Failed to retrieve token from microG');
    }
  }

  Future<void> refreshBundle(String dispenserUrl) async {
    try {
      final bundle = await AuthService.fetchAnonymousBundle(dispenserUrl);
      _anonymousBundle = bundle;
      await _prefs?.setString('anonymous_auth_bundle', jsonEncode(bundle.toJson()));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
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

  void clearBundle() {
    _anonymousBundle = null;
    _personalBundle = null;
    _prefs?.remove('anonymous_auth_bundle');
    _prefs?.remove('personal_auth_bundle');
    notifyListeners();
  }
}
