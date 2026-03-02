import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/services/play_store_api.dart';
import 'package:obtainium/models/auth_bundle.dart';
import 'package:obtainium/providers/plugin_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/main.dart'; // To get global context if needed, but better via provider

class GooglePlayNative extends AppSource {
  GooglePlayNative() {
    hosts = ['play.google.com']; // We'll use this for native detection
    name = 'Google Play (Native)';
    allowSubDomains = true;
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    final appId = Uri.parse(standardUrl).queryParameters['id'] ?? '';
    final authProvider = Provider.of<AuthProvider>(globalNavigatorKey.currentContext!, listen: false);

    if (authProvider.hasActiveToken) {
      final api = PlayStoreApi(authProvider.activeBundle!);
      final details = await api.getDetails(appId);
      
      if (details != null) {
        // Here we would parse the Protobuf details. For now, return stub with real appId
        return APKDetails(
          'Native Version', // Extract from real Protobuf in future
          [], 
          AppNames(appId, 'Google Play (Native)'),
        );
      }
    }

    return APKDetails(
      'Unknown',
      [],
      AppNames(appId, 'Google Play (Native)'),
    );
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    Uri uri = Uri.parse(url);
    String appId = uri.queryParameters['id'] ?? '';
    return 'https://play.google.com/store/apps/details?id=$appId';
  }

  @override
  Future<Map<String, String>?> getRequestHeaders(
    Map<String, dynamic> additionalSettings,
    String url, {
    bool forAPKDownload = false,
  }) async {
    if (forAPKDownload && url.contains('android.clients.google.com')) {
      final authProvider = Provider.of<AuthProvider>(globalNavigatorKey.currentContext!, listen: false);
      if (authProvider.hasActiveToken) {
        // Basic implementation, a real system would need to fetch the FDFE delivery cookie 
        // at the time of download and inject it here, or encode it in the URL parameters.
        final deviceId = authProvider.activeBundle!.deviceConfig['androidId'] ?? '0000000000000000';
        return {
          'Authorization': 'Bearer ${authProvider.activeBundle!.authToken}',
          'User-Agent': 'Android-Finsky/38.5.18-29 [0] [PR] 561633513 (api=3,build=561633513,is_tablet=false)',
          'X-DFE-Device-Id': deviceId,
        };
      }
    }
    return null;
  }
}
