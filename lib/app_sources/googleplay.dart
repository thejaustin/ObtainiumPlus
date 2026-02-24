import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/app_sources/apkpure.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';

class GooglePlay extends AppSource {
  GooglePlay() {
    hosts = ['play.google.com'];
    name = 'Google Play';
    allowSubDomains = true;
    naiveStandardVersionDetection = true;
  }

  @override
  String sourceSpecificStandardizeURL(String url, {bool forSelection = false}) {
    Uri? uri = Uri.tryParse(url);
    if (uri == null) throw InvalidURLError(name);
    
    String? appId;
    if (uri.scheme == 'market') {
      appId = uri.queryParameters['id'];
    } else if (uri.host.contains('play.google.com')) {
      appId = uri.queryParameters['id'];
    }

    if (appId == null) {
      throw InvalidURLError(name);
    }
    return 'https://play.google.com/store/apps/details?id=$appId';
  }

  @override
  Future<String?> tryInferringAppId(
    String standardUrl, {
    Map<String, dynamic> additionalSettings = const {},
  }) async {
    return Uri.parse(standardUrl).queryParameters['id'];
  }

  @override
  Future<APKDetails> getLatestAPKDetails(
    String standardUrl,
    Map<String, dynamic> additionalSettings,
  ) async {
    String? appId = await tryInferringAppId(standardUrl);
    if (appId == null) throw InvalidURLError(name);

    // Use APKPure as the backend for Google Play apps
    APKPure backend = APKPure();
    try {
      return await backend.getLatestAPKDetails(
        'https://apkpure.com/any-name/$appId',
        additionalSettings,
      );
    } catch (e) {
      if (e is ObtainiumError) {
        throw ObtainiumError('${tr('googlePlayMirrorError')}: ${e.message}');
      }
      rethrow;
    }
  }
}
