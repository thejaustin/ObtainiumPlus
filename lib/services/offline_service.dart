import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:obtainium/providers/settings_provider.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  // Callback to process queue when back online
  Function(List<String>)? onOnline;

  Future<void> initialize(SettingsProvider settingsProvider, Function(List<String>) onOnlineCallback) async {
    onOnline = onOnlineCallback;
    
    // Initial check
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      bool wasOffline = _isOffline;
      _updateStatus(result);
      
      if (wasOffline && !_isOffline) {
        // Back online, process queue
        final queue = settingsProvider.offlineQueue;
        if (queue.isNotEmpty) {
          onOnline?.call(List.from(queue));
          // Clear queue after handing off (or let callback clear it)
          settingsProvider.offlineQueue = [];
        }
      }
    });
  }

  void _updateStatus(List<ConnectivityResult> result) {
    _isOffline = result.contains(ConnectivityResult.none) || 
                 result.isEmpty || 
                 (result.contains(ConnectivityResult.vpn) && result.length == 1); // Assume VPN-only might be flaky/no-net depending on context, but usually fine. Sticking to simple logic: none/empty = offline.
                 
    // Refined logic: if ANY interface is available (wifi, mobile, ethernet), we are online.
    if (result.contains(ConnectivityResult.wifi) || 
        result.contains(ConnectivityResult.mobile) || 
        result.contains(ConnectivityResult.ethernet)) {
      _isOffline = false;
    } else if (result.length == 1 && result.contains(ConnectivityResult.vpn)) {
       // VPN only - assume online for now, but strict check would be ping.
       _isOffline = false; 
    } else {
      _isOffline = true;
    }
  }

  void addToQueue(String appId, SettingsProvider settingsProvider) {
    final queue = settingsProvider.offlineQueue;
    if (!queue.contains(appId)) {
      queue.add(appId);
      settingsProvider.offlineQueue = queue;
    }
  }

  void removeFromQueue(String appId, SettingsProvider settingsProvider) {
    final queue = settingsProvider.offlineQueue;
    if (queue.contains(appId)) {
      queue.remove(appId);
      settingsProvider.offlineQueue = queue;
    }
  }

  // --- Retry Queue Logic ---

  void addAppToRetryQueue(String appId, SettingsProvider settingsProvider, {String? reason}) {
    final queue = settingsProvider.retryQueue;
    int currentPersistentAttempts = queue[appId]?['attempts'] ?? 0;
    
    // Exponential backoff: 15min * 2^attempts
    int nextBackoffMinutes = (15 * pow(2, min(currentPersistentAttempts, 6))).toInt();
    int nextRetryTime = DateTime.now().add(Duration(minutes: nextBackoffMinutes)).millisecondsSinceEpoch;
    
    queue[appId] = {
      'attempts': currentPersistentAttempts + 1,
      'nextRetry': nextRetryTime,
      'reason': reason ?? 'Unknown error',
      'lastAttempt': DateTime.now().millisecondsSinceEpoch,
    };
    
    settingsProvider.retryQueue = queue;
  }

  List<String> getDueRetries(SettingsProvider settingsProvider) {
    final queue = settingsProvider.retryQueue;
    int now = DateTime.now().millisecondsSinceEpoch;
    List<String> dueRetries = [];
    
    queue.forEach((appId, data) {
      if ((data['nextRetry'] ?? 0) <= now) {
        dueRetries.add(appId);
      }
    });
    
    return dueRetries;
  }

  void clearAppFromRetryQueue(String appId, SettingsProvider settingsProvider) {
    final queue = settingsProvider.retryQueue;
    if (queue.containsKey(appId)) {
      queue.remove(appId);
      settingsProvider.retryQueue = queue;
    }
  }

  void dispose() {
    unawaited(_subscription?.cancel() ?? Future.value());
  }
}
