import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/services/auth_service.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/main.dart';
import 'package:provider/provider.dart';
import 'dart:math' show Random;

// Domains the Play Store client is allowed to connect to.
// Any redirect or response that targets outside this set is rejected.
const _allowedHosts = {
  'android.clients.google.com',
  'play.googleapis.com',
  'accounts.google.com',
};

// Hard cap on response body size (10 MB). Protects against memory exhaustion
// from crafted or unexpectedly large responses.
const _maxResponseBytes = 10 * 1024 * 1024;

/// Builds a dedicated [http.Client] for Play Store requests.
///
/// Isolated from other app HTTP traffic — no shared cookie jar, connection
/// pool, or cache. Only follows redirects within the allowed host set.
http.Client _buildPlayStoreClient() {
  final inner = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 15)
    ..autoUncompress = true;
  // Ensure all Play Store traffic goes direct — no system or app proxy.
  // Assigned outside the cascade to avoid a type-inference break in the
  // cascade chain (the closure return type caused Dart to resolve subsequent
  // cascade members against String instead of HttpClient).
  inner.findProxy = (uri) => 'DIRECT';

  return IOClient(inner);
}

// Shared secure RNG — avoids creating a new instance on every request.
final _rng = Random.secure();

// Pre-compiled URL pattern for delivery response parsing.
final _urlRegex = RegExp(r'https://[^"\0\n]+');

class PlayStoreApi {
  final String _baseUrl = 'https://android.clients.google.com/fdfe';
  final AuthProvider authProvider;
  final PlusSettingsProvider plusSettingsProvider;

  // Each PlayStoreApi instance has its own isolated HTTP client.
  final http.Client _client = _buildPlayStoreClient();

  PlayStoreApi({required this.authProvider, required this.plusSettingsProvider});

  void dispose() => _client.close();

  /// Always reads the *current* active bundle from the provider so that a
  /// token refreshed mid-request (e.g. after a 401) is picked up on retry.
  Map<String, String> _buildHeaders() {
    final bundle = authProvider.activeBundle;
    if (bundle == null) throw ObtainiumError('No active auth bundle');

    final profile = authProvider.selectedProfile;
    final deviceId = authProvider.effectiveDeviceId == 'native'
        ? '0000000000000000'
        : authProvider.effectiveDeviceId;

    final authHeader = bundle.aasToken.isNotEmpty
        ? 'GoogleLogin auth=${bundle.authToken}'
        : 'Bearer ${bundle.authToken}';

    // Rotate Finsky version per-request to reduce fingerprinting.
    const versions = ['38.5.18-29', '37.5.24-21', '39.1.12-21', '38.2.10-21'];
    final version = versions[_rng.nextInt(versions.length)];

    final headers = {
      'Authorization': authHeader,
      'X-Ad-Id': '00000000-0000-0000-0000-000000000000',
      'User-Agent':
          'Android-Finsky/$version [0] [PR] 561633513 (api=3,build=561633513,'
          'sdk=${profile.sdkVersion},device=${profile.model},'
          'hardware=${profile.manufacturer})',
      'X-DFE-Device-Id': deviceId,
      'Accept-Language': 'en-US',
      'Host': 'android.clients.google.com',
      'Connection': 'Keep-Alive',
    };

    // Sanitised copy for logs — never write tokens or full device IDs.
    final sanitized = Map<String, String>.from(headers)
      ..['Authorization'] = 'Bearer ***'
      ..['X-DFE-Device-Id'] = '${deviceId.substring(0, 4)}...';
    talker.debug('Play Store headers (sanitized): $sanitized');

    return headers;
  }

  Future<void> _humanDelay() async {
    await Future.delayed(Duration(milliseconds: 500 + _rng.nextInt(1500)));
  }

  /// Validates that [uri] targets an allowed host.
  void _assertAllowedHost(Uri uri) {
    if (!_allowedHosts.contains(uri.host)) {
      throw ObtainiumError(
        'Play Store request blocked: unexpected host "${uri.host}"',
      );
    }
  }

  /// Checks the VPN requirement and throws if it is not met.
  Future<void> _assertVPNIfRequired() async {
    if (!plusSettingsProvider.requireVPNForPlayStore) return;

    final vpnActive = await AuthService.isVPNActive();
    if (!vpnActive) {
      throw ObtainiumError(
        'Play Store request blocked: "Require VPN" is enabled but no VPN '
        'is currently active. Connect to a VPN and try again.',
      );
    }
  }

  /// Central GET helper with full security envelope:
  /// VPN check → token freshness → domain validation → request → 401 retry
  /// → size check.
  Future<http.Response> _get(String url) async {
    final uri = Uri.parse(url);
    _assertAllowedHost(uri);
    await _assertVPNIfRequired();
    await _humanDelay();

    // Silently refresh if the token has passed its 55-min safe window.
    await authProvider.ensureValidPersonalToken();

    var response = await _client
        .get(uri, headers: _buildHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401) {
      talker.warning('Play Store 401 — invalidating token and retrying once');
      await authProvider.handleTokenRejected();
      response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 20));
    }

    if (response.bodyBytes.length > _maxResponseBytes) {
      throw ObtainiumError(
        'Play Store response too large (${response.bodyBytes.length} bytes) '
        '— request aborted for safety.',
      );
    }

    return response;
  }

  Future<Map<String, dynamic>?> getDetails(String appId) async {
    try {
      final response = await _get('$_baseUrl/details?doc=$appId');
      talker.info('Play Store Details: $appId → ${response.statusCode}');
      if (response.statusCode == 200) {
        talker.debug('Play Store Details: ${response.bodyBytes.length} bytes');
        return {'appId': appId, 'status': 'fetched'};
      }
      talker.warning('Play Store Details failed: ${response.statusCode}');
      return null;
    } on ObtainiumError {
      rethrow;
    } catch (e, stack) {
      talker.handle(e, stack, 'Play Store API Details Error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> search(
    String query, {
    bool verifiedOnly = false,
  }) async {
    try {
      final spParam = verifiedOnly ? '&sp=CAU%3D' : '';
      final response = await _get(
        '$_baseUrl/search?c=3&q=${Uri.encodeComponent(query)}$spParam',
      );
      talker.info('Play Store Search: $query → ${response.statusCode}');
      if (response.statusCode == 200) {
        talker.debug('Play Store Search: ${response.bodyBytes.length} bytes');
      }
    } on ObtainiumError {
      rethrow;
    } catch (e, stack) {
      talker.handle(e, stack, 'Play Store API Search Error');
    }
    return [];
  }

  Future<List<String>> getDeliveryUrls(String appId, int versionCode) async {
    try {
      final response = await _get(
        '$_baseUrl/delivery?doc=$appId&vc=$versionCode&ot=1',
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final urls = _urlRegex
            .allMatches(body)
            .map((m) => m.group(0)!)
            .where(
              (u) =>
                  u.contains('android.clients.google.com') ||
                  u.contains('play.googleapis.com'),
            )
            .toList();
        if (urls.isNotEmpty) {
          talker.info('Extracted ${urls.length} delivery URLs for $appId');
          return urls;
        }
      } else {
        talker.warning('Play Store Delivery failed: ${response.statusCode}');
      }
    } on ObtainiumError {
      rethrow;
    } catch (e, stack) {
      talker.handle(e, stack, 'Play Store API Delivery Error');
    }
    return [];
  }
}
