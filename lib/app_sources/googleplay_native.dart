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
    // Same as regular Google Play source
    Uri uri = Uri.parse(url);
    String appId = uri.queryParameters['id'] ?? '';
    return 'https://play.google.com/store/apps/details?id=$appId';
  }
}
