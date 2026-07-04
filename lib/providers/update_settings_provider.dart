import 'package:obtainium/utils/safe_prefs.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateSettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;

  List<int> updateIntervalNodes = [
    15,
    30,
    60,
    120,
    180,
    360,
    720,
    1440,
    4320,
    10080,
    20160,
    43200,
  ];
  late SplineInterpolation updateIntervalInterpolator;
  String updateIntervalLabel = '';

  Future<void> initializeSettings(SharedPreferences p) async {
    prefs = p;
    initUpdateIntervalInterpolator();
    processIntervalSliderValue(
      updateIntervalSliderVal,
      notify: false,
      skipLabel: true,
    );
    notifyListeners();
  }

  void initUpdateIntervalInterpolator() {
    List<InterpolationNode> nodes = [];
    for (final (index, element) in updateIntervalNodes.indexed) {
      nodes.add(
        InterpolationNode(x: index.toDouble() + 1, y: element.toDouble()),
      );
    }
    updateIntervalInterpolator = SplineInterpolation(nodes: nodes);
  }

  void processIntervalSliderValue(
    double val, {
    bool notify = true,
    bool skipLabel = false,
  }) {
    if (val < 0.5) {
      prefs?.setInt('updateInterval', 0);
      if (!skipLabel) updateIntervalLabel = tr('neverManualOnly');
      if (notify) notifyListeners();
      return;
    }
    int valInterpolated = 0;
    if (val < 1) {
      valInterpolated = 15;
    } else {
      valInterpolated = updateIntervalInterpolator.compute(val).round();
    }
    if (valInterpolated < 60) {
      prefs?.setInt('updateInterval', valInterpolated);
      if (!skipLabel) updateIntervalLabel = plural('minute', valInterpolated);
    } else if (valInterpolated < 8 * 60) {
      int valRounded = (valInterpolated / 15).floor() * 15;
      prefs?.setInt('updateInterval', valRounded);
      if (!skipLabel) {
        updateIntervalLabel = plural('hour', valRounded ~/ 60);
        int mins = valRounded % 60;
        if (mins != 0) updateIntervalLabel += " ${plural('minute', mins)}";
      }
    } else if (valInterpolated < 24 * 60) {
      int valRounded = (valInterpolated / 30).floor() * 30;
      prefs?.setInt('updateInterval', valRounded);
      if (!skipLabel) updateIntervalLabel = plural('hour', valRounded / 60);
    } else if (valInterpolated < 7 * 24 * 60) {
      int valRounded = (valInterpolated / (12 * 60)).floor() * 12 * 60;
      prefs?.setInt('updateInterval', valRounded);
      if (!skipLabel)
        updateIntervalLabel = plural('day', valRounded / (24 * 60));
    } else {
      int valRounded = (valInterpolated / (24 * 60)).floor() * 24 * 60;
      prefs?.setInt('updateInterval', valRounded);
      if (!skipLabel)
        updateIntervalLabel = plural('day', valRounded ~/ (24 * 60));
    }
    if (notify) notifyListeners();
  }

  int get updateInterval {
    return prefs?.safeInt('updateInterval') ?? 360;
  }

  set updateInterval(int min) {
    prefs?.setInt('updateInterval', min);
    notifyListeners();
  }

  double get updateIntervalSliderVal {
    return prefs?.safeDouble('updateIntervalSliderVal') ?? 6.0;
  }

  set updateIntervalSliderVal(double val) {
    prefs?.setDouble('updateIntervalSliderVal', val);
    notifyListeners();
  }

  bool get checkOnStart {
    return prefs?.getBool('checkOnStart') ?? false;
  }

  set checkOnStart(bool checkOnStart) {
    prefs?.setBool('checkOnStart', checkOnStart);
    notifyListeners();
  }

  bool get onlyCheckInstalledOrTrackOnlyApps {
    return prefs?.getBool('onlyCheckInstalledOrTrackOnlyApps') ?? false;
  }

  set onlyCheckInstalledOrTrackOnlyApps(bool val) {
    prefs?.setBool('onlyCheckInstalledOrTrackOnlyApps', val);
    notifyListeners();
  }

  bool get checkUpdateOnDetailPage {
    return prefs?.getBool('checkUpdateOnDetailPage') ?? true;
  }

  set checkUpdateOnDetailPage(bool show) {
    prefs?.setBool('checkUpdateOnDetailPage', show);
    notifyListeners();
  }

  bool get enableBackgroundUpdates {
    return prefs?.getBool('enableBackgroundUpdates') ?? true;
  }

  set enableBackgroundUpdates(bool val) {
    prefs?.setBool('enableBackgroundUpdates', val);
    notifyListeners();
  }

  bool get bgUpdatesOnWiFiOnly {
    return prefs?.getBool('bgUpdatesOnWiFiOnly') ?? false;
  }

  set bgUpdatesOnWiFiOnly(bool val) {
    prefs?.setBool('bgUpdatesOnWiFiOnly', val);
    notifyListeners();
  }

  bool get bgUpdatesWhileChargingOnly {
    return prefs?.getBool('bgUpdatesWhileChargingOnly') ?? false;
  }

  set bgUpdatesWhileChargingOnly(bool val) {
    prefs?.setBool('bgUpdatesWhileChargingOnly', val);
    notifyListeners();
  }

  bool get useUpdateSchedule {
    return prefs?.getBool('useUpdateSchedule') ?? false;
  }

  set useUpdateSchedule(bool val) {
    prefs?.setBool('useUpdateSchedule', val);
    notifyListeners();
  }

  int get updateScheduleStartHour {
    return prefs?.safeInt('updateScheduleStartHour') ?? 9;
  }

  set updateScheduleStartHour(int val) {
    prefs?.setInt('updateScheduleStartHour', val.clamp(0, 23));
    notifyListeners();
  }

  int get updateScheduleEndHour {
    return prefs?.safeInt('updateScheduleEndHour') ?? 23;
  }

  set updateScheduleEndHour(int val) {
    prefs?.setInt('updateScheduleEndHour', val.clamp(0, 23));
    notifyListeners();
  }

  List<int> get updateScheduleDays {
    String? stored = prefs?.getString('updateScheduleDays');
    if (stored == null) return [1, 2, 3, 4, 5, 6, 7];
    return stored.split(',').map((e) => int.tryParse(e) ?? 1).toList();
  }

  set updateScheduleDays(List<int> val) {
    prefs?.setString('updateScheduleDays', val.join(','));
    notifyListeners();
  }

  bool isWithinUpdateSchedule() {
    if (!useUpdateSchedule) return true;
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentDay = now.weekday;
    if (!updateScheduleDays.contains(currentDay)) return false;
    if (updateScheduleStartHour <= updateScheduleEndHour) {
      return currentHour >= updateScheduleStartHour &&
          currentHour < updateScheduleEndHour;
    } else {
      return currentHour >= updateScheduleStartHour ||
          currentHour < updateScheduleEndHour;
    }
  }

  String getScheduleDescription() {
    if (!useUpdateSchedule) return tr('always');
    final dayNames = [
      '',
      tr('mon'),
      tr('tue'),
      tr('wed'),
      tr('thu'),
      tr('fri'),
      tr('sat'),
      tr('sun'),
    ];
    final days = updateScheduleDays.map((d) => dayNames[d]).join(', ');
    final startHour = updateScheduleStartHour.toString().padLeft(2, '0');
    final endHour = updateScheduleEndHour.toString().padLeft(2, '0');
    return '$days, $startHour:00 - $endHour:00';
  }

  DateTime get lastCompletedBGCheckTime {
    int? temp = prefs?.safeInt('lastCompletedBGCheckTime');
    return temp != null
        ? DateTime.fromMillisecondsSinceEpoch(temp)
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  set lastCompletedBGCheckTime(DateTime val) {
    prefs?.setInt('lastCompletedBGCheckTime', val.millisecondsSinceEpoch);
    notifyListeners();
  }

  bool get useFGService {
    return prefs?.getBool('useFGService') ?? false;
  }

  set useFGService(bool val) {
    prefs?.setBool('useFGService', val);
    notifyListeners();
  }

  String get obtainiumReleaseChannel {
    return prefs?.getString('obtainiumReleaseChannel') ?? 'latest';
  }

  set obtainiumReleaseChannel(String channel) {
    prefs?.setString('obtainiumReleaseChannel', channel);
    notifyListeners();
  }

  Map<String, dynamic> get autoUpdateRules {
    String? stored = prefs?.getString('autoUpdateRules');
    if (stored == null) return {};
    try {
      return jsonDecode(stored) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  set autoUpdateRules(Map<String, dynamic> val) {
    prefs?.setString('autoUpdateRules', jsonEncode(val));
    notifyListeners();
  }

  // --- Offline queue (app IDs to retry when back online) ---
  List<String> get offlineQueue {
    final stored = prefs?.getString('offlineQueue');
    if (stored == null) return [];
    try {
      return List<String>.from(jsonDecode(stored) as List);
    } catch (_) {
      return [];
    }
  }

  set offlineQueue(List<String> val) {
    prefs?.setString('offlineQueue', jsonEncode(val));
    notifyListeners();
  }

  // --- Persistent retry queue (app IDs with backoff info) ---
  Map<String, dynamic> get retryQueue {
    final stored = prefs?.getString('retryQueue');
    if (stored == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(stored) as Map);
    } catch (_) {
      return {};
    }
  }

  set retryQueue(Map<String, dynamic> val) {
    prefs?.setString('retryQueue', jsonEncode(val));
    notifyListeners();
  }
}
