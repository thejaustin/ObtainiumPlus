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
 else if (response.statusCode == 429) {
        throw ObtainiumError('Dispenser rate limited (429). Try again later.');
      } else {
        throw ObtainiumError('Dispenser returned error ${response.statusCode}: ${response.body}');
      }
    } catch (e, stack) {
      talker.handle(e, stack, 'AuthBundle Fetch Failed');
      if (e is ObtainiumError) rethrow;
      throw ObtainiumError('Failed to connect to dispenser: $e');
    }
  }

  /// Lists Google accounts managed by microG on the device
  static Future<List<String>> getMicroGAccounts() async {
    try {
      final List<dynamic>? accounts = await _platform.invokeMethod('getAccounts');
      return accounts?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      talker.error('Failed to list microG accounts: $e');
      return [];
    }
  }

  /// Requests a Play Store auth token for a specific microG account
  static Future<String?> getMicroGToken(String email) async {
    try {
      final String? token = await _platform.invokeMethod('getMicroGToken', {'email': email});
      return token;
    } catch (e) {
      talker.error('Failed to retrieve microG token for $email: $e');
      return null;
    }
  }
}
