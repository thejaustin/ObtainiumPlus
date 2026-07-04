import 'package:obtainium/utils/safe_prefs.dart';
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
    DeviceProfile(
      name: 'Pixel 8 Pro',
      model: 'husky',
      manufacturer: 'Google',
      sdkVersion: 34,
    ),
    DeviceProfile(
      name: 'Galaxy S24 Ultra',
      model: 'SM-S928B',
      manufacturer: 'Samsung',
      sdkVersion: 34,
    ),
    DeviceProfile(
      name: 'Nothing Phone (2)',
      model: 'Pong',
      manufacturer: 'Nothing',
      sdkVersion: 33,
    ),
    DeviceProfile(
      name: 'Xiaomi 14',
      model: '23127PN0CC',
      manufacturer: 'Xiaomi',
      sdkVersion: 34,
    ),
  ];

  // Secure storage keys — all sensitive data lives here, not in SharedPreferences
  static const _kAnonBundle = 'anonymous_auth_bundle';
  static const _kPersonalBundle = 'personal_auth_bundle';
  static const _kMicroGEmail = 'microg_email';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthBundle? _anonymousBundle;
  AuthBundle? _personalBundle;
  List<String> _dispensers = [];
  AuthMode _authMode = AuthMode.hybrid;
  String? _microGEmail;
  String? _spoofedAndroidId;
  DeviceProfile _selectedProfile = deviceProfiles[0];
  SharedPreferences? _prefs;

  // ── Getters ──────────────────────────────────────────────────────────────

  AuthBundle? get personalBundle => _personalBundle;
  AuthBundle? get anonymousBundle => _anonymousBundle;
  List<String> get dispensers => _dispensers;
  AuthMode get authMode => _authMode;
  String? get microGEmail => _microGEmail;
  String? get spoofedAndroidId => _spoofedAndroidId;
  DeviceProfile get selectedProfile => _selectedProfile;
  bool get hasActiveToken => activeBundle != null;

  /// Returns the bundle to use for the current auth mode.
  /// - anonymous: only the anonymous bundle; never exposes personal credentials.
  /// - microG: personal bundle only — returns null (not anon fallback) so
  ///   callers know unambiguously when the personal token is missing.
  /// - hybrid: anonymous for general traffic; callers that need personal access
  ///   (e.g. paid-app download) must read [personalBundle] directly.
  /// Call [ensureValidPersonalToken] before using in microG / hybrid mode.
  AuthBundle? get activeBundle {
    switch (_authMode) {
      case AuthMode.anonymous:
        return _anonymousBundle;
      case AuthMode.microG:
        // Intentionally no anon fallback — callers can check hasActiveToken
        // and surface a "link a microG account" prompt when null.
        return _personalBundle;
      case AuthMode.hybrid:
        return _anonymousBundle;
    }
  }

  /// True if the stored personal OAuth2 token is past its 55-minute safe window.
  bool get isPersonalTokenExpired => _personalBundle?.isExpired ?? false;

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;

    _dispensers =
        _prefs?.getStringList('play_store_dispensers') ??
        [];

    // Migrate existing users off the default auroraoss.com dispenser to honor the maintainer's request
    if (_dispensers.contains('https://auroraoss.com/api/auth')) {
      _dispensers.remove('https://auroraoss.com/api/auth');
      await _prefs?.setStringList('play_store_dispensers', _dispensers);
    }

    _authMode = AuthMode.values[_prefs?.safeInt('auth_mode') ?? 2];
    _spoofedAndroidId = _prefs?.getString('spoofed_android_id');

    final profileJson = _prefs?.getString('selected_device_profile');
    if (profileJson != null) {
      try {
        _selectedProfile = DeviceProfile.fromJson(jsonDecode(profileJson));
      } catch (_) {}
    }

    // One-time migration: move email from SharedPreferences → secure storage.
    // Uses try/finally so the plaintext key is always removed even if the
    // secure write fails (prefer losing the value over leaving it in plaintext).
    final legacyEmail = _prefs?.getString('microg_email');
    if (legacyEmail != null) {
      try {
        await _storage.write(key: _kMicroGEmail, value: legacyEmail);
      } finally {
        await _prefs?.remove('microg_email');
      }
    }

    // Email and tokens stored in encrypted secure storage — never in SharedPreferences
    _microGEmail = await _storage.read(key: _kMicroGEmail);

    final anonJson = await _storage.read(key: _kAnonBundle);
    if (anonJson != null) {
      try {
        _anonymousBundle = AuthBundle.fromJson(jsonDecode(anonJson));
      } catch (_) {}
    }

    final personalJson = await _storage.read(key: _kPersonalBundle);
    if (personalJson != null) {
      try {
        _personalBundle = AuthBundle.fromJson(jsonDecode(personalJson));
      } catch (_) {}
    }

    notifyListeners();
  }

  // ── microG token management ───────────────────────────────────────────────

  Future<void> setMicroGEmail(String? email) async {
    _microGEmail = email;
    if (email != null) {
      await _storage.write(key: _kMicroGEmail, value: email);
    } else {
      await _storage.delete(key: _kMicroGEmail);
      // Clear personal bundle when account is removed
      _personalBundle = null;
      await _storage.delete(key: _kPersonalBundle);
    }
    notifyListeners();
  }

  /// Fetches a fresh microG OAuth2 token and stores it with a timestamp.
  Future<void> refreshMicroGToken() async {
    if (_microGEmail == null)
      throw ObtainiumError('No microG account selected');

    final token = await AuthService.getMicroGToken(_microGEmail!);
    _personalBundle = AuthBundle(
      email: _microGEmail!,
      aasToken: '', // empty = OAuth2 Bearer flow, not AAS
      authToken: token,
      deviceConfig: {},
      tokenIssuedAt: DateTime.now(),
    );
    await _storage.write(
      key: _kPersonalBundle,
      value: jsonEncode(_personalBundle!.toJson()),
    );
    notifyListeners();
  }

  /// Refreshes the personal token only if it has expired (55-min window).
  /// Safe to call before every Play Store API request — no-op when still valid.
  Future<void> ensureValidPersonalToken() async {
    if (_microGEmail != null && isPersonalTokenExpired) {
      talker.info('microG token expired — refreshing silently');
      try {
        await refreshMicroGToken();
      } catch (e, stack) {
        talker.handle(e, stack, 'Silent microG token refresh failed');
      }
    }
  }

  /// Returns true if microG or Google Play Services is detected.
  Future<bool> checkMicroGAvailability() async {
    return await AuthService.isMicroGAvailable();
  }

  /// Call after receiving a 401 from the Play Store API.
  /// Invalidates the token in the AccountManager so microG issues a fresh one,
  /// then immediately re-fetches.
  Future<void> handleTokenRejected() async {
    if (_microGEmail == null || _personalBundle == null) return;
    talker.warning(
      'microG token rejected (401) — invalidating and re-fetching',
    );
    await AuthService.invalidateMicroGToken(_personalBundle!.authToken);
    try {
      await refreshMicroGToken();
    } catch (e, stack) {
      talker.handle(e, stack, 'microG token refresh after 401 failed');
    }
  }

  // ── Anonymous / dispenser ─────────────────────────────────────────────────

  Future<void> refreshBundle(String dispenserUrl) async {
    final bundle = await AuthService.fetchAnonymousBundle(dispenserUrl);
    _anonymousBundle = bundle;
    await _storage.write(key: _kAnonBundle, value: jsonEncode(bundle.toJson()));
    await rotateDeviceId();
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

  /// Clears auth tokens only — does NOT touch other secure storage entries.
  /// Also invalidates the microG AccountManager token cache so the old token
  /// cannot be reused from outside this app.
  Future<void> clearBundle() async {
    // Invalidate microG's cached token before nulling our reference.
    if (_personalBundle != null) {
      await AuthService.invalidateMicroGToken(_personalBundle!.authToken);
    }
    _anonymousBundle = null;
    _personalBundle = null;
    await _storage.delete(key: _kAnonBundle);
    await _storage.delete(key: _kPersonalBundle);
    notifyListeners();
  }

  // ── Device spoofing ────────────────────────────────────────────────────────

  Future<void> rotateDeviceId() async {
    const chars = '0123456789abcdef';
    final random = math.Random.secure();
    _spoofedAndroidId = List.generate(
      16,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
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
    await _prefs?.setString(
      'selected_device_profile',
      jsonEncode(profile.toJson()),
    );
    notifyListeners();
  }
}
