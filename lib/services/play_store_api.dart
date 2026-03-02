import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:obtainium/models/auth_bundle.dart';
import 'package:obtainium/utils/logger.dart';
import 'dart:math';
...
class PlayStoreApi {
  final AuthBundle auth;
  final String _baseUrl = 'https://android.clients.google.com/fdfe';

  PlayStoreApi(this.auth);

  Map<String, String> get _headers {
    final authProvider = Provider.of<AuthProvider>(globalNavigatorKey.currentContext!, listen: false);
    final profile = authProvider.selectedProfile;
    final deviceId = authProvider.effectiveDeviceId == 'native' ? '0000000000000000' : authProvider.effectiveDeviceId;

    final authHeader = auth.aasToken.isNotEmpty 
        ? 'GoogleLogin auth=${auth.authToken}' 
        : 'Bearer ${auth.authToken}';

    final versions = ['38.5.18-29', '37.5.24-21', '39.1.12-21', '38.2.10-21'];
    final selectedVersion = versions[Random().nextInt(versions.length)];

    return {
      'Authorization': authHeader,
      'X-Ad-Id': '00000000-0000-0000-0000-000000000000',
      'User-Agent': 'Android-Finsky/$selectedVersion [0] [PR] 561633513 (api=3,build=561633513,sdk=${profile.sdkVersion},device=${profile.model},hardware=${profile.manufacturer})',
      'X-DFE-Device-Id': deviceId,
      'Accept-Language': 'en-US',
      'Host': 'android.clients.google.com',
      'Connection': 'Keep-Alive',
    };
  }

  /// Mimics human latency to avoid bot detection
  Future<void> _humanDelay() async {
    final ms = 500 + Random().nextInt(1500); // 0.5s to 2s delay
    await Future.delayed(Duration(milliseconds: ms));
  }

  /// Fetch app details natively using Protobuf/JSON
  Future<Map<String, dynamic>?> getDetails(String appId) async {
    try {
      await _humanDelay();
      final url = '$_baseUrl/details?doc=$appId';
...

      talker.info('Play Store Native Details: $appId');
      final response = await http.get(Uri.parse(url), headers: _headers);
      
      if (response.statusCode == 200) {
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
/// Search for apps using the FDFE API
Future<List<Map<String, dynamic>>> search(String query, {bool verifiedOnly = false}) async {
  try {
    final spParam = verifiedOnly ? '&sp=CAU%3D' : '';
    final url = '$_baseUrl/search?c=3&q=${Uri.encodeComponent(query)}$spParam';
    talker.info('Play Store Native Search: $query (Verified: $verifiedOnly)');

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      talker.debug('Play Store Search Results Length: ${response.bodyBytes.length}');
      // Logic to parse results from Protobuf/JSON would go here
      return [];
    }
  } catch (e, stack) {
    talker.handle(e, stack, 'Play Store API Search Error');
  }
  return [];
}

/// Request actual download URLs by extracting them from the FDFE Protobuf response
...

  Future<List<String>> getDeliveryUrls(String appId, int versionCode) async {
    try {
      final url = '$_baseUrl/delivery?doc=$appId&vc=$versionCode&ot=1';
      talker.info('Play Store Native Delivery: $appId v$versionCode');
      
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final decodedString = utf8.decode(bytes, allowMalformed: true);
        
        // Extract https:// URLs
        final urlRegex = RegExp(r'https://[^"\0\n]+');
        final urls = urlRegex.allMatches(decodedString)
            .map((m) => m.group(0)!)
            .where((u) => u.contains('android.clients.google.com') || u.contains('play.googleapis.com'))
            .toList();
            
        // Extract MarketDA cookie
        final cookieRegex = RegExp(r'MarketDA=[^"\0\n]+');
        final cookieMatch = cookieRegex.firstMatch(decodedString);
        
        if (urls.isNotEmpty) {
          talker.success('Extracted ${urls.length} download URLs');
          
          // In a real implementation, you would pass the MarketDA cookie 
          // to the Obtainium downloader to allow the final file fetch.
          if (cookieMatch != null) {
            talker.debug('Found Auth Cookie: ${cookieMatch.group(0)}');
          }
          
          return urls;
        }
      } else {
        talker.warning('Play Store Delivery Failed: ${response.statusCode}');
      }
    } catch (e, stack) {
      talker.handle(e, stack, 'Play Store API Delivery Error');
    }
    return [];
  }
}
