import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/auth_bundle.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math' as math;

enum AuthMode { anonymous, microG, hybrid }

class DeviceProfile {
  final String name;
  final String model;
  final String manufacturer;
  final int sdkVersion;

  const DeviceProfile({
    required this.name,
    required this.model,
    required this.manufacturer,
    required this.sdkVersion,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'model': model,
    'manufacturer': manufacturer,
    'sdkVersion': sdkVersion,
  };

  factory DeviceProfile.fromJson(Map<String, dynamic> json) => DeviceProfile(
    name: json['name'] ?? 'Custom',
    model: json['model'] ?? '',
    manufacturer: json['manufacturer'] ?? '',
    sdkVersion: json['sdkVersion'] ?? 33,
  );
}

class AuthProvider with ChangeNotifier {
  static const List<DeviceProfile> deviceProfiles = [
    DeviceProfile(name: 'Pixel 8 Pro', model: 'husky', manufacturer: 'Google', sdkVersion: 34),
    DeviceProfile(name: 'Galaxy S24 Ultra', model: 'SM-S928B', manufacturer: 'Samsung', sdkVersion: 34),
    DeviceProfile(name: 'Nothing Phone (2)', model: 'Pong', manufacturer: 'Nothing', sdkVersion: 33),
    DeviceProfile(name: 'Xiaomi 14', model: '23127PN0CC', manufacturer: 'Xiaomi', sdkVersion: 34),
  ];

  final _storage = const FlutterSecureStorage();
  AuthBundle? _anonymousBundle;
  AuthBundle? _personalBundle;
  List<String> _dispensers = ['https://auroraoss.com/api/auth'];
  AuthMode _authMode = AuthMode.hybrid;
  String? _microGEmail;
  String? _spoofedAndroidId;
  DeviceProfile _selectedProfile = deviceProfiles[0];
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
  String? get spoofedAndroidId => _spoofedAndroidId;
  DeviceProfile get selectedProfile => _selectedProfile;
  bool get hasActiveToken => activeBundle != null;

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    
    _dispensers = _prefs?.getStringList('play_store_dispensers') ?? ['https://auroraoss.com/api/auth'];
    _authMode = AuthMode.values[_prefs?.getInt('auth_mode') ?? 2];
    _microGEmail = _prefs?.getString('microg_email');
    _spoofedAndroidId = _prefs?.getString('spoofed_android_id');

    final profileJson = _prefs?.getString('selected_device_profile');
    if (profileJson != null) {
      try {
        _selectedProfile = DeviceProfile.fromJson(jsonDecode(profileJson));
      } catch (_) {}
    }

    // Load bundles from secure storage
    final anonJson = await _storage.read(key: 'anonymous_auth_bundle');
    if (anonJson != null) {
      try {
        _anonymousBundle = AuthBundle.fromJson(jsonDecode(anonJson));
      } catch (_) {}
    }
    
    final personalJson = await _storage.read(key: 'personal_auth_bundle');
    if (personalJson != null) {
      try {
        _personalBundle = AuthBundle.fromJson(jsonDecode(personalJson));
      } catch (_) {}
    }
    
    notifyListeners();
  }

  Future<void> rotateDeviceId() async {
    const chars = '0123456789abcdef';
    final random = math.Random();
    _spoofedAndroidId = List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
    await _prefs?.setString('spoofed_android_id', _spoofedAndroidId!);
    notifyListeners();
  }

  String get effectiveDeviceId {
    if (_authMode == AuthMode.anonymous || _authMode == AuthMode.hybrid) {
      return _spoofedAndroidId ?? '0000000000000000';
    }
    return 'native'; 
  }

  Future<void> setAuthMode(AuthMode mode) async {
    _authMode = mode;
    await _prefs?.setInt('auth_mode', mode.index);
    notifyListeners();
  }

  Future<void> setDeviceProfile(DeviceProfile profile) async {
    _selectedProfile = profile;
    await _prefs?.setString('selected_device_profile', jsonEncode(profile.toJson()));
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
      await _storage.write(key: 'personal_auth_bundle', value: jsonEncode(_personalBundle!.toJson()));
      notifyListeners();
    } else {
      throw ObtainiumError('Failed to retrieve token from microG');
    }
  }

  Future<void> refreshBundle(String dispenserUrl) async {
    try {
      final bundle = await AuthService.fetchAnonymousBundle(dispenserUrl);
      _anonymousBundle = bundle;
      await _storage.write(key: 'anonymous_auth_bundle', value: jsonEncode(bundle.toJson()));
      await rotateDeviceId();
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

  void clearBundle() async {
    _anonymousBundle = null;
    _personalBundle = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
