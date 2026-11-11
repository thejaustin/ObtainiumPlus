// Picks the HTTP client for a source request.
//
// Most requests share one embedded-Cronet client: it verifies certificates
// with Android's trust store (so user-installed CAs and the RuStore root in
// network_security_config.xml apply), honours system proxy settings, and
// reuses connections across an update check instead of opening a new
// TCP+TLS connection per request. dart:io stays for the cases Cronet can't
// handle: hosts pinned by fingerprint, "allow insecure" (Cronet cannot skip
// TLS verification), as a fallback when Cronet fails to start, and when
// Android blocks executable memory (GrapheneOS "Dynamic code loading via
// memory"): cronet_http's FFI trampolines need it and crash at launch
// without it, which no try/catch can recover from (upstream #3442).

import 'dart:io';

import 'package:cronet_http/cronet_http.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:obtainium/core/logging/app_logger.dart';
import 'package:obtainium/services/dcl_support.dart';
import 'package:obtainium/utils/source_utils.dart' show createHttpClient;

typedef HttpClientResolver =
    Future<http.Client> Function(Uri url, {bool allowInsecure});

class HttpClientFactory {
  HttpClientFactory._();

  /// Replaceable in tests (they run off Android, where Cronet is never used).
  static HttpClientResolver resolver = defaultResolver;

  static Future<http.Client> defaultResolver(
    Uri url, {
    bool allowInsecure = false,
  }) => _defaultClientFor(url, allowInsecure: allowInsecure);

  static http.Client? _cronet;
  static bool _cronetUnavailable = false;
  static bool _androidCertStoreEnabled = true;
  static bool _loggedDclRestricted = false;
  static bool _loggedCertStoreDisabled = false;
  static final Map<String, Future<http.Client>> _ioClients = {};

  /// Google Play endpoints keep the dart:io client from [createHttpClient],
  /// which checks their certificate fingerprint.
  static bool isPinnedHost(String host) =>
      host.contains('android.clients.google.com') ||
      host.contains('play.googleapis.com');

  static bool get isCronetInUse => _cronet != null;

  /// The "Use Android certificate store" setting. When off, requests use the
  /// dart:io client even if Cronet could start. Applies to new requests.
  static void setAndroidCertStoreEnabled(bool enabled) {
    _androidCertStoreEnabled = enabled;
    _loggedCertStoreDisabled = false;
  }

  /// Whether the embedded Cronet client may be used right now.
  static bool shouldUseCronet({
    required bool isAndroid,
    required bool androidCertStoreEnabled,
    required bool execmemRestricted,
    required bool cronetUnavailable,
  }) =>
      isAndroid &&
      androidCertStoreEnabled &&
      !execmemRestricted &&
      !cronetUnavailable;

  static Future<http.Client> clientFor(Uri url, {bool allowInsecure = false}) =>
      resolver(url, allowInsecure: allowInsecure);

  static Future<http.Client> _defaultClientFor(
    Uri url, {
    bool allowInsecure = false,
  }) async {
    if (isPinnedHost(url.host)) {
      return _ioClients.putIfAbsent(
        'pinned${allowInsecure ? '-insecure' : ''}',
        () async => IOClient(createHttpClient(allowInsecure: allowInsecure)),
      );
    }
    if (allowInsecure) {
      return _ioClients.putIfAbsent('insecure', () async {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 15)
          ..badCertificateCallback = (cert, host, port) => true;
        return IOClient(client);
      });
    }
    final cronet = _tryCronet();
    if (cronet != null) return cronet;
    if (_rootHost(url.host) == 'rustore.ru') {
      return _ioClients.putIfAbsent('rustore', () async {
        final context = SecurityContext(withTrustedRoots: true);
        final cert = await rootBundle.load(
          'assets/ca-certs/russian-mintsifry-root.crt',
        );
        context.setTrustedCertificatesBytes(
          cert.buffer.asUint8List(cert.offsetInBytes, cert.lengthInBytes),
        );
        return IOClient(
          HttpClient(context: context)
            ..connectionTimeout = const Duration(seconds: 15),
        );
      });
    }
    return _ioClients.putIfAbsent(
      'default',
      () async => IOClient(
        HttpClient()
          ..connectionTimeout = const Duration(seconds: 15)
          ..idleTimeout = const Duration(seconds: 30)
          ..maxConnectionsPerHost = 6,
      ),
    );
  }

  static String _rootHost(String host) {
    final parts = host.split('.');
    return parts.length > 2 ? parts.sublist(parts.length - 2).join('.') : host;
  }

  static http.Client? _tryCronet() {
    final execmemRestricted =
        _androidCertStoreEnabled && DclSupport.isExecmemRestricted;
    if (!shouldUseCronet(
      isAndroid: Platform.isAndroid,
      androidCertStoreEnabled: _androidCertStoreEnabled,
      execmemRestricted: execmemRestricted,
      cronetUnavailable: _cronetUnavailable,
    )) {
      if (Platform.isAndroid) {
        if (!_androidCertStoreEnabled) {
          if (!_loggedCertStoreDisabled) {
            _loggedCertStoreDisabled = true;
            AppLogger.info(
              'HTTP: Android certificate store disabled; using dart:io',
            );
          }
        } else if (execmemRestricted && !_loggedDclRestricted) {
          _loggedDclRestricted = true;
          AppLogger.info('HTTP: Android memory DCL restricted; using dart:io');
        }
      }
      return null;
    }
    if (_cronet != null) return _cronet;
    try {
      final engine = CronetEngine.build(
        // Sources fronted by Cloudflare fingerprint the user agent; keep the
        // one dart:io sends.
        userAgent: 'Dart/${Platform.version.split(' ').first} (dart:io)',
        enableQuic: false,
        useBuiltInDnsResolver: false,
      );
      _cronet = CronetClient.fromCronetEngine(engine);
      AppLogger.info('HTTP: using embedded Cronet');
      return _cronet;
    } catch (e, stackTrace) {
      _cronetUnavailable = true;
      AppLogger.error(
        e,
        stackTrace: stackTrace,
        message: 'HTTP: Cronet initialization failed; using dart:io',
      );
      return null;
    }
  }
}
