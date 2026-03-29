import 'dart:convert';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hsluv/hsluv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:obtainium/providers/logs_provider.dart';

/// Push a route with a M3 Expressive shared-axis (horizontal) transition.
Future<T?> pushRoute<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    ),
  );
}

List<List<String>> stringMapListTo2DList(
  List<MapEntry<String, String>> mapList,
) => mapList.map((e) => [e.key, e.value]).toList();

List<MapEntry<String, String>> assumed2DlistToStringMapList(
  List<dynamic> arr,
) => arr.map((e) => MapEntry(e[0] as String, e[1] as String)).toList();

/// Safely decode JSON string with a fallback value if parsing fails.
/// Also handles cases where the input is already decoded (not a String).
dynamic safeJsonDecode(dynamic jsonValue, dynamic fallback) {
  if (jsonValue == null) return fallback;
  if (jsonValue is! String) {
    if ((fallback is List && jsonValue is List) || (fallback is Map && jsonValue is Map)) {
      return jsonValue;
    }
    return fallback;
  }
  try {
    return jsonDecode(jsonValue);
  } catch (e) {
    LogsProvider().add('Failed to parse JSON, using fallback: $e');
    return fallback;
  }
}

List<MapEntry<String, String>> getApkUrlsFromUrls(List<String> urls) =>
    urls.map((e) {
      var segments = e.split('/').where((el) => el.trim().isNotEmpty);
      var apkSegs = segments.where((s) => s.toLowerCase().endsWith('.apk'));
      return MapEntry(apkSegs.isNotEmpty ? apkSegs.last : segments.last, e);
    }).toList();

Future<List<MapEntry<String, String>>> filterApksByArch(
  List<MapEntry<String, String>> apkUrls,
) async {
  if (apkUrls.length > 1) {
    var abis = (await DeviceInfoPlugin().androidInfo).supportedAbis;
    for (var abi in abis) {
      var urls2 = apkUrls
          .where((element) => RegExp('.*$abi.*').hasMatch(element.key))
          .toList();
      if (urls2.isNotEmpty && urls2.length < apkUrls.length) {
        apkUrls = urls2;
        break;
      }
    }
  }
  return apkUrls;
}

String getSourceRegex(List<String> hosts) {
  return '(${hosts.join('|').replaceAll('.', '\\.')})';
}

List<String> moveStrToEnd(List<String> arr, String str, {String? strB}) {
  String? temp;
  arr.removeWhere((element) {
    bool res = element == str || element == strB;
    if (res) {
      temp = element;
    }
    return res;
  });
  if (temp != null) {
    arr = [...arr, temp!];
  }
  return arr;
}

List<MapEntry<String, int>> moveStrToEndMapEntryWithCount(
  List<MapEntry<String, int>> arr,
  MapEntry<String, int> str, {
  MapEntry<String, int>? strB,
}) {
  MapEntry<String, int>? temp;
  arr.removeWhere((element) {
    bool resA = element.key == str.key;
    bool resB = element.key == strB?.key;
    if (resA) {
      temp = str;
    } else if (resB) {
      temp = strB;
    }
    return resA || resB;
  });
  if (temp != null) {
    arr = [...arr, temp!];
  }
  return arr;
}

DateTime? tryParseDateTime(String? dateStr) {
  if (dateStr == null) return null;
  try {
    return DateTime.parse(dateStr);
  } catch (e) {
    return null;
  }
}

// Generates a color in the HSLuv (Pastel) color space
// https://pub.dev/documentation/hsluv/latest/hsluv/Hsluv/hpluvToRgb.html
Color generateRandomLightColor() {
  final randomSeed = Random().nextInt(120);
  // https://en.wikipedia.org/wiki/Golden_angle
  final goldenAngle = 180 * (3 - sqrt(5));
  // Generate next golden angle hue
  final double hue = randomSeed * goldenAngle;
  // Map from HPLuv color space to RGB, use constant saturation=100, lightness=70
  final List<double> rgbValuesDbl = Hsluv.hpluvToRgb([hue, 100, 70]);
  // Map RBG values from 0-1 to 0-255:
  final List<int> rgbValues = rgbValuesDbl
      .map((rgb) => (rgb * 255).toInt())
      .toList();
  return Color.fromARGB(255, rgbValues[0], rgbValues[1], rgbValues[2]);
}
