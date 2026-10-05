import 'dart:math';
import 'package:obtainium/providers/update_settings_provider.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // --- Retry Queue Logic ---

  void addAppToRetryQueue(
    String appId,
    UpdateSettingsProvider settingsProvider, {
    String? reason,
  }) {
    final queue = settingsProvider.retryQueue;
    int currentPersistentAttempts = queue[appId]?['attempts'] ?? 0;

    // Exponential backoff: 15min * 2^attempts, capped at 2^6 (960 min)
    int nextBackoffMinutes = (15 * pow(2, min(currentPersistentAttempts, 6)))
        .toInt();
    int nextRetryTime = DateTime.now()
        .add(Duration(minutes: nextBackoffMinutes))
        .millisecondsSinceEpoch;

    queue[appId] = {
      'attempts': currentPersistentAttempts + 1,
      'nextRetry': nextRetryTime,
      'reason': reason ?? 'Unknown error',
      'lastAttempt': DateTime.now().millisecondsSinceEpoch,
    };

    settingsProvider.retryQueue = queue;
  }

  List<String> getDueRetries(UpdateSettingsProvider settingsProvider) {
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

  void clearAppFromRetryQueue(
    String appId,
    UpdateSettingsProvider settingsProvider,
  ) {
    final queue = settingsProvider.retryQueue;
    if (queue.containsKey(appId)) {
      queue.remove(appId);
      settingsProvider.retryQueue = queue;
    }
  }

  /// Removes all retry-queue entries for the given app IDs. Call when apps
  /// are deleted so stale entries don't accumulate in SharedPreferences.
  void clearAppsFromRetryQueue(
    List<String> appIds,
    UpdateSettingsProvider settingsProvider,
  ) {
    if (appIds.isEmpty) return;
    final queue = settingsProvider.retryQueue;
    bool changed = false;
    for (final id in appIds) {
      if (queue.remove(id) != null) changed = true;
    }
    if (changed) settingsProvider.retryQueue = queue;
  }
}
