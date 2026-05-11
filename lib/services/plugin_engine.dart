import 'package:flutter_js/flutter_js.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';

class PluginEngine {
  late JavascriptRuntime _runtime;

  PluginEngine() {
    _runtime = getJavascriptRuntime();
  }

  /// Initialize the runtime with common utilities
  void init() {
    _runtime.onMessage('httpGet', (args) async {
      talker.debug('Plugin calling httpGet: ${args['url']}');
      return {'status': 200, 'body': '...mocked...'};
    });
  }

  /// Maps a JS plugin to a functional AppSource
  Future<APKDetails?> executeSourcePlugin(String jsCode, String url) async {
    try {
      _runtime.evaluate(jsCode);
      // Expected JS function: getDetails(url) -> { version: string, name: string, apkUrls: string[] }
      final result = _runtime.evaluate('getDetails("$url")');
      final data = result.rawResult as Map<String, dynamic>;

      return APKDetails(
        data['version'] ?? 'Unknown',
        (data['apkUrls'] as List)
            .map((u) => MapEntry(u.toString(), u.toString()))
            .toList(),
        AppNames(data['name'] ?? 'Plugin App', data['name'] ?? 'Plugin App'),
      );
    } catch (e, stack) {
      talker.handle(e, stack, 'Plugin Execution Failed');
      return null;
    }
  }

  void dispose() {
    _runtime.dispose();
  }
}
