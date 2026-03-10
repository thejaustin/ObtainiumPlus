import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/models/auth_bundle.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/custom_errors.dart';

class AuthService {
  static const _platform = MethodChannel('app.obtainiumplus/native');

  /// Fetches an anonymous AuthBundle from an Aurora-style dispenser
  static Future<AuthBundle> fetchAnonymousBundle(String dispenserUrl) async {
    try {
      talker.info('Requesting AuthBundle from: $dispenserUrl');
      
      final response = await http.get(
        Uri.parse(dispenserUrl),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'ObtainiumPlus/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        talker.info('Successfully retrieved AuthBundle for: ${data['email']}');
        return AuthBundle.fromJson(data);
      }
      } else if (response.statusCode == 429) {
        throw ObtainiumError('Dispenser rate limited (429). Try again later.');
      } else {
        // Truncate to 200 chars — prevents token fragments from a rogue
        // dispenser leaking into logs or GitHub issue reports.
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}…'
            : response.body;
        throw ObtainiumError(
            'Dispenser returned error ${response.statusCode}: $snippet');
      }
    } catch (e, stack) {
      talker.handle(e, stack, 'AuthBundle Fetch Failed');
      if (e is ObtainiumError) rethrow;
      throw ObtainiumError('Failed to connect to dispenser: $e');
    }
  }

  /// Opens the native Android account picker and returns the selected Google account email.
  /// Returns null if the user cancelled. Throws [ObtainiumError] on unexpected failure.
  static Future<String?> pickGoogleAccount() async {
    try {
      final String? email = await _platform.invokeMethod<String>('pickGoogleAccount');
      return email;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') return null;
      talker.error('pickGoogleAccount error [${e.code}]: ${e.message}');
      throw ObtainiumError(e.message ?? 'Failed to open account picker (${e.code})');
    }
  }

  /// Returns true if a VPN tunnel is currently active on the device.
  /// Throws [ObtainiumError] if the check itself fails — callers that enforce
  /// VPN requirement should treat an unknown state as blocked (fail-closed).
  static Future<bool> isVPNActive() async {
    try {
      return await _platform.invokeMethod<bool>('isVPNActive') ?? false;
    } catch (e) {
      throw ObtainiumError('Unable to determine VPN status: $e');
    }
  }

  /// Tells the Android AccountManager that [token] is stale so the next
  /// [getMicroGToken] call fetches a fresh one from microG instead of the cached copy.
  /// Call this after receiving a 401 from the Play Store API.
  static Future<void> invalidateMicroGToken(String token) async {
    try {
      await _platform.invokeMethod('invalidateMicroGToken', {'token': token});
    } catch (e) {
      talker.warning('invalidateMicroGToken failed (non-fatal): $e');
    }
  }

  /// Requests a Play Store auth token for a specific microG account via microG.
  ///
  /// Throws [ObtainiumError] with an actionable message on failure so the UI
  /// can surface exactly what went wrong (e.g. permissions not granted, account
  /// not found, network error).
  static Future<String> getMicroGToken(String email) async {
    try {
      final String? token = await _platform.invokeMethod<String>('getMicroGToken', {'email': email});
      if (token == null || token.isEmpty) {
        throw ObtainiumError('microG returned an empty token for $email. '
            'Ensure Google Play scope is enabled in microG Settings.');
      }
      talker.info('microG token retrieved for ${email.split('@').first}@…');
      return token;
    } on PlatformException catch (e) {
      talker.error('getMicroGToken platform error [${e.code}]: ${e.message}');
      // Surface the native error message directly — it's already user-friendly.
      throw ObtainiumError(e.message ?? 'Failed to retrieve microG token (${e.code})');
    } catch (e, stack) {
      talker.handle(e, stack, 'getMicroGToken unexpected error');
      throw ObtainiumError('Failed to retrieve microG token: $e');
    }
  }
}
