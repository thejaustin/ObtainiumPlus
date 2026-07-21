import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

enum NetworkQuality { good, slow, offline }

Future<NetworkQuality> checkNetworkQuality() async {
  try {
    final client = http.Client();
    final stopwatch = Stopwatch()..start();
    final response = await client
        .head(Uri.parse('https://connectivitycheck.gstatic.com/generate_204'))
        .timeout(const Duration(seconds: 3));
    stopwatch.stop();
    client.close();

    if (stopwatch.elapsedMilliseconds < 1000) {
      return NetworkQuality.good;
    } else {
      return NetworkQuality.slow;
    }
  } on TimeoutException {
    return NetworkQuality.offline;
  } on SocketException {
    return NetworkQuality.offline;
  } catch (e) {
    return NetworkQuality.offline;
  }
}

Future<http.Response> httpGetWithRetry(
  Uri url, {
  Map<String, String>? headers,
  int maxRetries = 3,
}) async {
  int attempt = 0;
  List<int> delays = [1, 2, 4];

  while (attempt < maxRetries) {
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 500 && response.statusCode < 600) {
        if (attempt == maxRetries - 1) return response;
        throw HttpException('Server error: ${response.statusCode}');
      }
      return response;
    } on TimeoutException {
      if (attempt == maxRetries - 1) rethrow;
    } on SocketException {
      if (attempt == maxRetries - 1) rethrow;
    } on HttpException {
      if (attempt == maxRetries - 1) rethrow;
    }

    await Future.delayed(Duration(seconds: delays[attempt]));
    attempt++;
  }

  throw Exception('httpGetWithRetry failed');
}
