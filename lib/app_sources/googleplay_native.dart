import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/services/play_store_api.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/main.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/auth_provider.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:flutter/services.dart';

class GooglePlayNative extends AppSource {
  GooglePlayNative() {
    hosts = ['play.google.com'];
    name = 'Google Play (Native)';
    allowSubDomains = true;
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    final appId = Uri.parse(standardUrl).queryParameters['id'] ?? '';
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) {
      return APKDetails('Unknown', [], AppNames(appId, 'Google Play (Native)'));
    }
    final authProvider = Provider.of<AuthProvider>(ctx, listen: false);

    if (!authProvider.hasActiveToken) {
      return APKDetails('Unknown', [], AppNames(appId, 'Google Play (Native)'));
    }

    // Each call gets a fresh isolated client; dispose in finally to prevent leaks.
    final api = PlayStoreApi();
    try {
      final details = await api.getDetails(appId);
      if (details != null) {
        // Discard AFTER reading details — clears memory + invalidates AccountManager cache.
        // Awaiting ensures the APK download headers pipeline still has a valid bundle
        // if getRequestHeaders is called synchronously after this returns.
        if (Provider.of<PlusSettingsProvider>(ctx, listen: false).autoDiscardTokens) {
          await authProvider.clearBundle();
          talker.info('AuthBundle discarded after request (autoDiscardTokens)');
        }
        return APKDetails(
          'Native Version', // TODO: parse version from Protobuf response
          [],
          AppNames(appId, 'Google Play (Native)'),
        );
      }
    } on ObtainiumError {
      rethrow;
    } catch (e, stack) {
      talker.handle(e, stack, 'GooglePlayNative getLatestAPKDetails');
    } finally {
      api.dispose();
    }

    return APKDetails('Unknown', [], AppNames(appId, 'Google Play (Native)'));
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    final appId = Uri.parse(url).queryParameters['id'] ?? '';
    return 'https://play.google.com/store/apps/details?id=$appId';
  }

  @override
  Future<Map<String, String>?> getRequestHeaders(
    Map<String, dynamic> additionalSettings,
    String url, {
    bool forAPKDownload = false,
  }) async {
    if (!forAPKDownload || !url.contains('android.clients.google.com')) return null;

    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return null;
    final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
    final bundle = authProvider.activeBundle;
    if (bundle == null) return null;

    var deviceId = authProvider.effectiveDeviceId;
    if (deviceId == 'native') {
      const platform = MethodChannel('app.obtainiumplus/native');
      deviceId = await platform.invokeMethod<String>('getGsfId') ?? '0000000000000000';
    }

    final authHeader = bundle.aasToken.isNotEmpty
        ? 'GoogleLogin auth=${bundle.authToken}'
        : 'Bearer ${bundle.authToken}';

    return {
      'Authorization': authHeader,
      'User-Agent': 'Android-Finsky/38.5.18-29 [0] [PR] 561633513 '
          '(api=3,build=561633513,is_tablet=false)',
      'X-DFE-Device-Id': deviceId,
    };
  }
}
