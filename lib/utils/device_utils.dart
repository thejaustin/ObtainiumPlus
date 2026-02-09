import 'package:device_info_plus/device_info_plus.dart';

/// Shared device detection utilities.
/// Fixes issue #64: Extract Xiaomi detection to shared utility.
class DeviceUtils {
  DeviceUtils._();

  static AndroidDeviceInfo? _cachedAndroidInfo;

  /// Returns cached Android device info to avoid repeated platform calls.
  /// Fixes issue #62: Cache DeviceInfoPlugin results.
  static Future<AndroidDeviceInfo> getAndroidInfo() async {
    _cachedAndroidInfo ??= await DeviceInfoPlugin().androidInfo;
    return _cachedAndroidInfo!;
  }

  /// Checks if the device is from Xiaomi (including Redmi and Poco brands).
  static Future<bool> isXiaomiDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer?.toLowerCase() ?? '';
      final brand = info.brand?.toLowerCase() ?? '';
      return ['xiaomi', 'redmi', 'poco'].any(
        (x) => manufacturer.contains(x) || brand.contains(x),
      );
    } catch (e) {
      return false;
    }
  }
}
