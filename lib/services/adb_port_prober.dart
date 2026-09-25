import 'dart:async';
import 'dart:io';

/// Rapid active socket prober on local loopback (127.0.0.1),
/// modeled after ShizukuPlus AdbPortProber to detect local/wireless ADB.
class AdbPortProber {
  AdbPortProber._();

  /// Default ADB daemon port.
  static const int defaultAdbPort = 5555;

  /// Candidate loopback ports to probe in priority order.
  static const List<int> candidatePorts = [5555, 5557, 5559];

  /// Rapidly probes whether a given port is actively accepting TCP connections
  /// on loopback (127.0.0.1).
  /// Uses a short timeout (default 150ms) to ensure non-blocking UI responsiveness.
  static Future<bool> isPortOpen(
    int port, {
    Duration timeout = const Duration(milliseconds: 150),
  }) async {
    if (port < 1 || port > 65535) return false;
    try {
      final socket = await Socket.connect('127.0.0.1', port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks candidate loopback ports (5555, 5557, 5559) and returns the first
  /// port actively listening, or null if none are responding.
  static Future<int?> findActiveLoopbackPort({
    Duration timeout = const Duration(milliseconds: 150),
  }) async {
    for (final port in candidatePorts) {
      if (await isPortOpen(port, timeout: timeout)) {
        return port;
      }
    }
    return null;
  }
}
