import 'package:device_info_plus/device_info_plus.dart';

enum DeviceOEM {
  samsung,
  xiaomi,
  oneplus,
  oppo,
  realme,
  nothing,
  vivo,
  transsion,
  huawei,
  pixel,
  motorola,
  generic,
}

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

  /// Checks if the device is from Samsung.
  static Future<bool> isSamsungDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return manufacturer.contains('samsung') || brand.contains('samsung');
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is from Xiaomi (including Redmi and Poco brands).
  static Future<bool> isXiaomiDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return [
        'xiaomi',
        'redmi',
        'poco',
      ].any((x) => manufacturer.contains(x) || brand.contains(x));
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is from OnePlus, OPPO, or Realme (ColorOS / OxygenOS / Realme UI).
  static Future<bool> isOppoOnePlusRealmeDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return [
        'oneplus',
        'oppo',
        'realme',
      ].any((x) => manufacturer.contains(x) || brand.contains(x));
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is from Nothing (Nothing OS).
  static Future<bool> isNothingDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return manufacturer.contains('nothing') || brand.contains('nothing');
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is from Vivo or iQOO (Funtouch OS / OriginOS).
  static Future<bool> isVivoDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return [
        'vivo',
        'iqoo',
      ].any((x) => manufacturer.contains(x) || brand.contains(x));
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is from Transsion (Tecno, Infinix, or Itel).
  static Future<bool> isTranssionDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return [
        'transsion',
        'tecno',
        'infinix',
        'itel',
      ].any((x) => manufacturer.contains(x) || brand.contains(x));
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is from Huawei or Honor (EMUI / MagicOS).
  static Future<bool> isHuaweiHonorDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return [
        'huawei',
        'honor',
      ].any((x) => manufacturer.contains(x) || brand.contains(x));
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is a Google Pixel.
  static Future<bool> isPixelDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return manufacturer.contains('google') || brand.contains('google');
    } catch (_) {
      return false;
    }
  }

  /// Checks if the device is a Motorola device.
  static Future<bool> isMotorolaDevice() async {
    try {
      final info = await getAndroidInfo();
      final manufacturer = info.manufacturer.toLowerCase();
      final brand = info.brand.toLowerCase();
      return manufacturer.contains('motorola') || brand.contains('motorola') || brand.contains('moto');
    } catch (_) {
      return false;
    }
  }

  /// Returns the detected OEM enum.
  static Future<DeviceOEM> getDeviceOEM() async {
    if (await isSamsungDevice()) return DeviceOEM.samsung;
    if (await isXiaomiDevice()) return DeviceOEM.xiaomi;
    try {
      final info = await getAndroidInfo();
      final m = info.manufacturer.toLowerCase();
      final b = info.brand.toLowerCase();
      if (m.contains('oneplus') || b.contains('oneplus')) return DeviceOEM.oneplus;
      if (m.contains('oppo') || b.contains('oppo')) return DeviceOEM.oppo;
      if (m.contains('realme') || b.contains('realme')) return DeviceOEM.realme;
    } catch (_) {}
    if (await isNothingDevice()) return DeviceOEM.nothing;
    if (await isVivoDevice()) return DeviceOEM.vivo;
    if (await isTranssionDevice()) return DeviceOEM.transsion;
    if (await isHuaweiHonorDevice()) return DeviceOEM.huawei;
    if (await isPixelDevice()) return DeviceOEM.pixel;
    if (await isMotorolaDevice()) return DeviceOEM.motorola;
    return DeviceOEM.generic;
  }

  /// Returns a human-friendly name for the device's OEM software platform.
  static Future<String> getDeviceOEMName() async {
    final oem = await getDeviceOEM();
    switch (oem) {
      case DeviceOEM.samsung:
        return 'Samsung One UI';
      case DeviceOEM.xiaomi:
        return 'Xiaomi HyperOS / MIUI';
      case DeviceOEM.oneplus:
        return 'OnePlus OxygenOS';
      case DeviceOEM.oppo:
        return 'OPPO ColorOS';
      case DeviceOEM.realme:
        return 'Realme UI';
      case DeviceOEM.nothing:
        return 'Nothing OS';
      case DeviceOEM.vivo:
        return 'Vivo Funtouch / OriginOS';
      case DeviceOEM.transsion:
        return 'Transsion HiOS / XOS';
      case DeviceOEM.huawei:
        return 'Huawei EMUI / MagicOS';
      case DeviceOEM.pixel:
        return 'Google Pixel';
      case DeviceOEM.motorola:
        return 'Motorola MyUX';
      case DeviceOEM.generic:
        return 'Android';
    }
  }

  /// Returns a short diagnostic summary of the current device.
  static Future<String> getDeviceSummary() async {
    try {
      final info = await getAndroidInfo();
      final oemName = await getDeviceOEMName();
      return '${info.manufacturer} ${info.model} ($oemName, Android ${info.version.release}, API ${info.version.sdkInt})';
    } catch (_) {
      return 'Android Device';
    }
  }
}
