import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:obtainium/models/auth_bundle.dart';
import 'package:obtainium/utils/logger.dart';

class PlayStoreApi {
  final AuthBundle auth;
  final String _baseUrl = 'https://android.clients.google.com/fdfe';

  PlayStoreApi(this.auth);

  Map<String, String> get _headers => {
    'Authorization': 'GoogleLogin auth=${auth.authToken}',
    'X-Ad-Id': '00000000-0000-0000-0000-000000000000',
    'User-Agent': 'Android-Finsky/37.5.24-21 [0] [PR] 561633513 (api=3,build=561633513,is_tablet=false)',
    'X-DFE-Device-Id': '0000000000000000', // Should be GSF ID in hex
  };

  /// Fetch app details natively using Protobuf/JSON
  Future<Map<String, dynamic>?> getDetails(String appId) async {
    try {
      final url = '$_baseUrl/details?doc=$appId';
      talker.info('Play Store Native Details: $appId');
      final response = await http.get(Uri.parse(url), headers: _headers);
      
      if (response.statusCode == 200) {
        // In a real implementation, this would be a Protobuf response.
        // For now, we'll log the raw bytes for debugging.
        talker.debug('Play Store Details Response Length: ${response.bodyBytes.length}');
        return {'appId': appId, 'status': 'fetched'};
      } else {
        talker.warning('Play Store Details Failed: ${response.statusCode}');
        return null;
      }
    } catch (e, stack) {
      talker.handle(e, stack, 'Play Store API Details Error');
      return null;
    }
  }

  /// Request download token (the "Purchase" step for free apps)
  Future<String?> getDownloadToken(String appId, int versionCode) async {
    final url = '$_baseUrl/purchase';
    final body = {
      'doc': appId,
      'ot': 1, // Offer Type
      'vc': versionCode,
    };
    
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Parse Protobuf response for download token
      return 'mock-token';
    }
    return null;
  }
}
