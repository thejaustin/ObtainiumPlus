import 'package:flutter_js/flutter_js.dart';
import 'package:obtainium/utils/logger.dart';

class PluginEngine {
  late JavascriptRuntime _runtime;

  PluginEngine() {
    _runtime = getJavascriptRuntime();
  }

  /// Initialize the runtime with common utilities
  void init() {
    // Inject http helper for plugins
    _runtime.onMessage('httpGet', (args) async {
      // Implementation of a secure http getter exposed to JS
      talker.debug('Plugin calling httpGet: ${args['url']}');
      return {'status': 200, 'body': '...mocked...'};
    });
  }

  /// Execute a specific function in a plugin
  Future<dynamic> call(String jsCode, String functionName, List<dynamic> args) async {
    try {
      _runtime.evaluate(jsCode);
      final result = _runtime.evaluate('$functionName(...${args.map((a) => '"$a"').toList()})');
      return result.rawResult;
    } catch (e, stack) {
      talker.handle(e, stack, 'JS Plugin Execution Error: $functionName');
      return null;
    }
  }

  void dispose() {
    _runtime.dispose();
  }
}
