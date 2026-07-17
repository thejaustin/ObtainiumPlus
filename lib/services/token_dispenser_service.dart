import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/utils/logger.dart';

class AuthBundle {
  final String email;
  final String token;

  AuthBundle({required this.email, required this.token});

  factory AuthBundle.fromJson(Map<String, dynamic> json) {
    return AuthBundle(
      email: json['email'] as String? ?? '',
      token: json['token'] as String? ?? (json['Auth'] as String? ?? ''),
    );
  }
}

class TokenDispenserService {
  static const List<String> _defaultDispensers = [
    'https://dispenser.auroraoss.com',
    'https://aurora.nixnet.services', // community mirror
  ];

  /// Fetches an anonymous AuthBundle from an Aurora Token Dispenser.
  static Future<AuthBundle> fetchAnonymousBundle({
    String? deviceModel,
    String? locale,
  }) async {
    for (final baseUrl in _defaultDispensers) {
      try {
        final url = Uri.parse('$baseUrl/api/auth');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                if (deviceModel != null) 'device': deviceModel,
                if (locale != null) 'locale': locale,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            final bundle = AuthBundle.fromJson(data);
            if (bundle.token.isNotEmpty) {
              talker.info('Successfully fetched anonymous token from $baseUrl');
              return bundle;
            }
          }
        }
      } catch (e) {
        talker.warning('Failed to fetch token from $baseUrl: $e');
      }
    }

    throw ObtainiumError(
      'Failed to fetch anonymous token from all available dispensers.',
    );
  }
}
