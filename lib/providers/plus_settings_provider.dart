import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/utils/safe_prefs.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlusSettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  final Map<String, Object?> _cache = {};
  bool _notifyScheduled = false;

  void _scheduleNotify() {
    if (!_notifyScheduled) {
      _notifyScheduled = true;
      Future.microtask(() {
        _notifyScheduled = false;
        notifyListeners();
      });
    }
  }

  Future<void> initializeSettings(SharedPreferences prefs) async {
    _prefs = prefs;
    _cache.clear();
    notifyListeners();
  }

  void clearCache() {
    _cache.clear();
    _scheduleNotify();
  }

  bool _getBool(String key, {required bool defaultValue}) {
    final cached = _cache[key];
    if (cached is bool) return cached;
    final val = _prefs?.safeBool(key) ?? defaultValue;
    _cache[key] = val;
    return val;
  }

  void _setBool(String key, bool val) {
    _cache[key] = val;
    _prefs?.setBool(key, val);
    _scheduleNotify();
  }

  String _getString(String key, {required String defaultValue}) {
    final cached = _cache[key];
    if (cached is String) return cached;
    final val = _prefs?.safeString(key) ?? defaultValue;
    _cache[key] = val;
    return val;
  }

  void _setString(String key, String val) {
    _cache[key] = val;
    _prefs?.setString(key, val);
    _scheduleNotify();
  }

  String? _getNullableString(String key) {
    if (_cache.containsKey(key)) {
      return _cache[key] as String?;
    }
    final val = _prefs?.safeString(key);
    _cache[key] = val;
    return val;
  }

  void _setNullableString(String key, String? val) {
    _cache[key] = val;
    if (val == null) {
      _prefs?.remove(key);
    } else {
      _prefs?.setString(key, val);
    }
    _scheduleNotify();
  }

  int _getInt(String key, {required int defaultValue}) {
    final cached = _cache[key];
    if (cached is int) return cached;
    final val = _prefs?.safeInt(key) ?? defaultValue;
    _cache[key] = val;
    return val;
  }

  void _setInt(String key, int val) {
    _cache[key] = val;
    _prefs?.setInt(key, val);
    _scheduleNotify();
  }

  double _getDouble(String key, {required double defaultValue}) {
    final cached = _cache[key];
    if (cached is double) return cached;
    final val = _prefs?.safeDouble(key) ?? defaultValue;
    _cache[key] = val;
    return val;
  }

  void _setDouble(String key, double val) {
    _cache[key] = val;
    _prefs?.setDouble(key, val);
    _scheduleNotify();
  }

  List<String> _getStringList(String key, {required List<String> defaultValue}) {
    final cached = _cache[key];
    if (cached is List<String>) return cached;
    final val = _prefs?.safeStringList(key) ?? defaultValue;
    _cache[key] = val;
    return val;
  }

  void _setStringList(String key, List<String> val) {
    _cache[key] = val;
    _prefs?.setStringList(key, val);
    _scheduleNotify();
  }

  // Obtainium+ Features (Master Toggle)
    bool get enableAllPlusFeatures => _getBool('enableAllPlusFeatures', defaultValue: true);
  set enableAllPlusFeatures(bool val) => _setBool('enableAllPlusFeatures', val);

  // Visual & UI Enhancements
    bool get plusEnableOneHandedMode => _getBool('plusEnableOneHandedMode', defaultValue: true);
  set plusEnableOneHandedMode(bool val) => _setBool('plusEnableOneHandedMode', val);

    bool get plusEnableGridView => _getBool('plusEnableGridView', defaultValue: true);
  set plusEnableGridView(bool val) => _setBool('plusEnableGridView', val);

    bool get plusEnableQuickFilters => _getBool('plusEnableQuickFilters', defaultValue: true);
  set plusEnableQuickFilters(bool val) => _setBool('plusEnableQuickFilters', val);

    bool get plusEnableIconCaching => _getBool('plusEnableIconCaching', defaultValue: true);
  set plusEnableIconCaching(bool val) => _setBool('plusEnableIconCaching', val);

    bool get plusEnableEnhancedAnimations => _getBool('plusEnableEnhancedAnimations', defaultValue: true);
  set plusEnableEnhancedAnimations(bool val) => _setBool('plusEnableEnhancedAnimations', val);

    bool get plusEnableMaterialExpressive => _getBool('plusEnableMaterialExpressive', defaultValue: true);
  set plusEnableMaterialExpressive(bool val) => _setBool('plusEnableMaterialExpressive', val);

    bool get plusDevUseThirdPartyLoadingIndicator => _getBool('plusDevUseThirdPartyLoadingIndicator', defaultValue: false);
  set plusDevUseThirdPartyLoadingIndicator(bool val) => _setBool('plusDevUseThirdPartyLoadingIndicator', val);

    bool get plusShowChangelogAfterUpdate => _getBool('plusShowChangelogAfterUpdate', defaultValue: true);
  set plusShowChangelogAfterUpdate(bool val) => _setBool('plusShowChangelogAfterUpdate', val);

    String get plusLastSeenVersion => _getString('plusLastSeenVersion', defaultValue: '');
  set plusLastSeenVersion(String val) => _setString('plusLastSeenVersion', val);

    bool get plusShowStatusHub => _getBool('plusShowStatusHub', defaultValue: true);
  set plusShowStatusHub(bool val) => _setBool('plusShowStatusHub', val);

    bool get plusUseCompactSettings => _getBool('plusUseCompactSettings', defaultValue: false);
  set plusUseCompactSettings(bool val) => _setBool('plusUseCompactSettings', val);

  // Settings Layout Style (M3 Expressive Compact Grid vs Classic One UI Grouped)
  SettingsLayoutMode get plusSettingsLayoutMode {
    final val = _getString('plusSettingsLayoutMode', defaultValue: 'm3eCompactGrid');
    if (val == 'classicGrouped') return SettingsLayoutMode.classicGrouped;
    return SettingsLayoutMode.m3eCompactGrid;
  }

  set plusSettingsLayoutMode(SettingsLayoutMode mode) {
    _setString('plusSettingsLayoutMode', mode.name);
    // When changing layout mode, align granular defaults
    if (mode == SettingsLayoutMode.classicGrouped) {
      _setBool('plusSettingsUseGridToggles', false);
      _setBool('plusSettingsUseVisualThemePicker', false);
      _setBool('plusSettingsUseSubmenuHub', false);
    } else {
      _setBool('plusSettingsUseGridToggles', true);
      _setBool('plusSettingsUseVisualThemePicker', true);
      _setBool('plusSettingsUseSubmenuHub', true);
    }
  }

  // Granular toggles to customize / bring back elements of the old UI
  bool get plusSettingsUseGridToggles =>
      _getBool(
        'plusSettingsUseGridToggles',
        defaultValue: plusSettingsLayoutMode == SettingsLayoutMode.m3eCompactGrid,
      );
  set plusSettingsUseGridToggles(bool val) =>
      _setBool('plusSettingsUseGridToggles', val);

  bool get plusSettingsUseVisualThemePicker =>
      _getBool(
        'plusSettingsUseVisualThemePicker',
        defaultValue: plusSettingsLayoutMode == SettingsLayoutMode.m3eCompactGrid,
      );
  set plusSettingsUseVisualThemePicker(bool val) =>
      _setBool('plusSettingsUseVisualThemePicker', val);

  bool get plusSettingsUseSubmenuHub =>
      _getBool(
        'plusSettingsUseSubmenuHub',
        defaultValue: plusSettingsLayoutMode == SettingsLayoutMode.m3eCompactGrid,
      );
  set plusSettingsUseSubmenuHub(bool val) =>
      _setBool('plusSettingsUseSubmenuHub', val);

    bool get plusSettingsUseHeroCards => _getBool('plusSettingsUseHeroCards', defaultValue: true);
  set plusSettingsUseHeroCards(bool val) => _setBool('plusSettingsUseHeroCards', val);

    bool get plusSettingsBottomNavBar => _getBool('plusSettingsBottomNavBar', defaultValue: true);
  set plusSettingsBottomNavBar(bool val) => _setBool('plusSettingsBottomNavBar', val);

    bool get plusShowAdvancedSettings => _getBool('plusShowAdvancedSettings', defaultValue: true);
  set plusShowAdvancedSettings(bool val) => _setBool('plusShowAdvancedSettings', val);

    bool get plusEnableExperimentalCustomization => _getBool('plusEnableExperimentalCustomization', defaultValue: false);
  set plusEnableExperimentalCustomization(bool val) => _setBool('plusEnableExperimentalCustomization', val);

    bool get plusEnableUpdateOwnership => _getBool('plusEnableUpdateOwnership', defaultValue: true);
  set plusEnableUpdateOwnership(bool val) => _setBool('plusEnableUpdateOwnership', val);

    bool get plusEnableUserPreapproval => _getBool('plusEnableUserPreapproval', defaultValue: true);
  set plusEnableUserPreapproval(bool val) => _setBool('plusEnableUserPreapproval', val);

    bool get plusEnableSmartRetries => _getBool('plusEnableSmartRetries', defaultValue: true);
  set plusEnableSmartRetries(bool val) => _setBool('plusEnableSmartRetries', val);

    bool get plusDeduplicateRecents => _getBool('plusDeduplicateRecents', defaultValue: true);
  set plusDeduplicateRecents(bool val) => _setBool('plusDeduplicateRecents', val);

    bool get plusEnableBouncyPhysics => _getBool('plusEnableBouncyPhysics', defaultValue: true);
  set plusEnableBouncyPhysics(bool val) => _setBool('plusEnableBouncyPhysics', val);

    bool get plusEnableGlassmorphism => _getBool('plusEnableGlassmorphism', defaultValue: true);
  set plusEnableGlassmorphism(bool val) => _setBool('plusEnableGlassmorphism', val);

    bool get plusEnablePopupSlider => _getBool('plusEnablePopupSlider', defaultValue: true);
  set plusEnablePopupSlider(bool val) => _setBool('plusEnablePopupSlider', val);

    bool get plusEnableResponsiveAppLayout => _getBool('plusEnableResponsiveAppLayout', defaultValue: true);
  set plusEnableResponsiveAppLayout(bool val) => _setBool('plusEnableResponsiveAppLayout', val);

  // Modern UI Toggles
    bool get plusEnableModernAppPage => _getBool('plusEnableModernAppPage', defaultValue: true);
  set plusEnableModernAppPage(bool val) => _setBool('plusEnableModernAppPage', val);

    bool get plusEnableModernAddAppPage => _getBool('plusEnableModernAddAppPage', defaultValue: true);
  set plusEnableModernAddAppPage(bool val) => _setBool('plusEnableModernAddAppPage', val);

    bool get plusEnableModernAppListTile => _getBool('plusEnableModernAppListTile', defaultValue: true);
  set plusEnableModernAppListTile(bool val) => _setBool('plusEnableModernAppListTile', val);

  // Feature Discovery
    bool get plusEnableDiscover => _getBool('plusEnableDiscover', defaultValue: true);
  set plusEnableDiscover(bool val) => _setBool('plusEnableDiscover', val);

    bool get plusDiscoverSuggestions => _getBool('plusDiscoverSuggestions', defaultValue: true);
  set plusDiscoverSuggestions(bool val) => _setBool('plusDiscoverSuggestions', val);

  // Advanced Logic
    bool get plusEnableAdvancedSorting => _getBool('plusEnableAdvancedSorting', defaultValue: true);
  set plusEnableAdvancedSorting(bool val) => _setBool('plusEnableAdvancedSorting', val);

    bool get plusEnableCategoryReorder => _getBool('plusEnableCategoryReorder', defaultValue: true);
  set plusEnableCategoryReorder(bool val) => _setBool('plusEnableCategoryReorder', val);

    bool get plusEnableUpdateSchedule => _getBool('plusEnableUpdateSchedule', defaultValue: true);
  set plusEnableUpdateSchedule(bool val) => _setBool('plusEnableUpdateSchedule', val);

    bool get plusEnableSystemUpdateScanner => _getBool('plusEnableSystemUpdateScanner', defaultValue: false);
  set plusEnableSystemUpdateScanner(bool val) => _setBool('plusEnableSystemUpdateScanner', val);

    bool get plusEnableHomeDashboard => _getBool('plusEnableHomeDashboard', defaultValue: true);
  set plusEnableHomeDashboard(bool val) => _setBool('plusEnableHomeDashboard', val);

    bool get plusShowAppBarSearch => _getBool('plusShowAppBarSearch', defaultValue: true);
  set plusShowAppBarSearch(bool val) => _setBool('plusShowAppBarSearch', val);

    bool get plusShowDashboardSearch => _getBool('plusShowDashboardSearch', defaultValue: true);
  set plusShowDashboardSearch(bool val) => _setBool('plusShowDashboardSearch', val);

    bool get plusShowFloatingSearch => _getBool('plusShowFloatingSearch', defaultValue: true);
  set plusShowFloatingSearch(bool val) => _setBool('plusShowFloatingSearch', val);

    bool get plusEnableSwipeActions => _getBool('plusEnableSwipeActions', defaultValue: true);
  set plusEnableSwipeActions(bool val) => _setBool('plusEnableSwipeActions', val);

    bool get plusEnableExpressiveProgress => _getBool('plusEnableExpressiveProgress', defaultValue: true);
  set plusEnableExpressiveProgress(bool val) => _setBool('plusEnableExpressiveProgress', val);

  // Range-bound prefs are clamped at the getter: imported/stale values can
  // be arbitrary, and out-of-range ones break the Sliders bound to them.
    double get plusGlobalCornerRadius => _getDouble('plusGlobalCornerRadius', defaultValue: 22.0).clamp(0.0, 40.0);
  set plusGlobalCornerRadius(double val) => _setDouble('plusGlobalCornerRadius', val);

    double get plusHomeCornerRadius => _getDouble('plusHomeCornerRadius', defaultValue: 22.0).clamp(0.0, 40.0);
  set plusHomeCornerRadius(double val) => _setDouble('plusHomeCornerRadius', val);

    double get plusSettingsCornerRadius => _getDouble('plusSettingsCornerRadius', defaultValue: 24.0).clamp(0.0, 40.0);
  set plusSettingsCornerRadius(double val) => _setDouble('plusSettingsCornerRadius', val);

    bool get plusOverrideIndividualCornerRadius => _getBool('plusOverrideIndividualCornerRadius', defaultValue: false);
  set plusOverrideIndividualCornerRadius(bool val) => _setBool('plusOverrideIndividualCornerRadius', val);

    bool get plusTopUILayout => _getBool('plusTopUILayout', defaultValue: false);
  set plusTopUILayout(bool val) => _setBool('plusTopUILayout', val);

  // Developer Mode & UI Comparison
    bool get plusDeveloperMode => _getBool('plusDeveloperMode', defaultValue: false);
  set plusDeveloperMode(bool val) => _setBool('plusDeveloperMode', val);

    bool get plusShowLegacyUIComparison => _getBool('plusShowLegacyUIComparison', defaultValue: false);
  set plusShowLegacyUIComparison(bool val) => _setBool('plusShowLegacyUIComparison', val);

    bool get playStoreVerifiedOnly => _getBool('playStoreVerifiedOnly', defaultValue: true);
  set playStoreVerifiedOnly(bool val) => _setBool('playStoreVerifiedOnly', val);

    bool get playStoreExcludeSystemApps => _getBool('playStoreExcludeSystemApps', defaultValue: false);
  set playStoreExcludeSystemApps(bool val) => _setBool('playStoreExcludeSystemApps', val);

    bool get playStoreNoAdsFilter => _getBool('playStoreNoAdsFilter', defaultValue: false);
  set playStoreNoAdsFilter(bool val) => _setBool('playStoreNoAdsFilter', val);

    int get playStoreMinDownloads => _getInt('playStoreMinDownloads', defaultValue: 0).clamp(0, 1000000);
  set playStoreMinDownloads(int val) => _setInt('playStoreMinDownloads', val);

    bool get requireVPNForPlayStore => _getBool('requireVPNForPlayStore', defaultValue: false);
  set requireVPNForPlayStore(bool val) => _setBool('requireVPNForPlayStore', val);

    bool get autoDiscardTokens => _getBool('autoDiscardTokens', defaultValue: true);
  set autoDiscardTokens(bool val) => _setBool('autoDiscardTokens', val);

  // Quick-Add FAB menu item visibility
    bool get plusFabShowSearch => _getBool('plusFabShowSearch', defaultValue: true);
  set plusFabShowSearch(bool val) => _setBool('plusFabShowSearch', val);

    bool get plusFabShowAddByUrl => _getBool('plusFabShowAddByUrl', defaultValue: true);
  set plusFabShowAddByUrl(bool val) => _setBool('plusFabShowAddByUrl', val);

  // Niche bulk-import power-tools — off by default so the everyday Add
  // menu stays to Search/Add-by-URL/Import-installed; still toggleable
  // back on in Settings for anyone who uses them.
    bool get plusFabShowGithubStarred => _getBool('plusFabShowGithubStarred', defaultValue: false);
  set plusFabShowGithubStarred(bool val) => _setBool('plusFabShowGithubStarred', val);

    bool get plusFabShowGithubPersonalRepos => _getBool('plusFabShowGithubPersonalRepos', defaultValue: false);
  set plusFabShowGithubPersonalRepos(bool val) => _setBool('plusFabShowGithubPersonalRepos', val);

    bool get plusFabShowImportInstalled => _getBool('plusFabShowImportInstalled', defaultValue: true);
  set plusFabShowImportInstalled(bool val) => _setBool('plusFabShowImportInstalled', val);

    bool get plusEnableNotificationDigest => _getBool('plusEnableNotificationDigest', defaultValue: false);
  set plusEnableNotificationDigest(bool val) => _setBool('plusEnableNotificationDigest', val);

    bool get plusEnableNotificationQuietHours => _getBool('plusEnableNotificationQuietHours', defaultValue: false);
  set plusEnableNotificationQuietHours(bool val) => _setBool('plusEnableNotificationQuietHours', val);

    int get plusNotificationQuietHoursStart => _getInt('plusNotificationQuietHoursStart', defaultValue: 22);
  set plusNotificationQuietHoursStart(int val) => _setInt('plusNotificationQuietHoursStart', val);

    int get plusNotificationQuietHoursEnd => _getInt('plusNotificationQuietHoursEnd', defaultValue: 7);
  set plusNotificationQuietHoursEnd(int val) => _setInt('plusNotificationQuietHoursEnd', val);

    bool get plusEnableMicroGHub => _getBool('plusEnableMicroGHub', defaultValue: true);
  set plusEnableMicroGHub(bool val) => _setBool('plusEnableMicroGHub', val);

    bool get plusEnableStandaloneInstaller => _getBool('plusEnableStandaloneInstaller', defaultValue: true);
  set plusEnableStandaloneInstaller(bool val) => _setBool('plusEnableStandaloneInstaller', val);

    bool get plusShowTagsInList => _getBool('plusShowTagsInList', defaultValue: true);
  set plusShowTagsInList(bool val) => _setBool('plusShowTagsInList', val);

    bool get plusEnableTags => _getBool('plusEnableTags', defaultValue: true);
  set plusEnableTags(bool val) => _setBool('plusEnableTags', val);

    bool get plusEnableAutoUpdateRules => _getBool('plusEnableAutoUpdateRules', defaultValue: true);
  set plusEnableAutoUpdateRules(bool val) => _setBool('plusEnableAutoUpdateRules', val);

    bool get plusEnableNotificationEnhancements => _getBool('plusEnableNotificationEnhancements', defaultValue: true);
  set plusEnableNotificationEnhancements(bool val) => _setBool('plusEnableNotificationEnhancements', val);

    bool get backupEncryptionEnabled => _getBool('backupEncryptionEnabled', defaultValue: false);
  set backupEncryptionEnabled(bool val) => _setBool('backupEncryptionEnabled', val);

    List<String> get plusPinnedAppsOrder => _getStringList('plusPinnedAppsOrder', defaultValue: const []);
  set plusPinnedAppsOrder(List<String> val) => _setStringList('plusPinnedAppsOrder', val);

    bool get plusEnableBanWarnings => _getBool('plusEnableBanWarnings', defaultValue: false);
  set plusEnableBanWarnings(bool val) => _setBool('plusEnableBanWarnings', val);

    int get plusBanWarningThreshold => _getInt('plusBanWarningThreshold', defaultValue: 5).clamp(1, 50);
  set plusBanWarningThreshold(int val) => _setInt('plusBanWarningThreshold', val);

    String? get plusDefaultStorePackage => _getNullableString('plusDefaultStorePackage');
  set plusDefaultStorePackage(String? val) => _setNullableString('plusDefaultStorePackage', val);

    String? get plusDefaultStoreName => _getNullableString('plusDefaultStoreName');
  set plusDefaultStoreName(String? val) => _setNullableString('plusDefaultStoreName', val);

    bool get plusEnableBottomNavBar => _getBool('plusEnableBottomNavBar', defaultValue: true);
  set plusEnableBottomNavBar(bool val) => _setBool('plusEnableBottomNavBar', val);

    bool get plusEnableFAB => _getBool('plusEnableFAB', defaultValue: true);
  set plusEnableFAB(bool val) => _setBool('plusEnableFAB', val);

  // ── Visual Polish Toggles (all additive — never remove existing behaviour) ──

  /// Float the bottom nav bar as a pill-shaped frosted dock (vs. flat edge bar).
    bool get plusFloatingNavBar => _getBool('plusFloatingNavBar', defaultValue: false);
  set plusFloatingNavBar(bool val) => _setBool('plusFloatingNavBar', val);

  /// Always show labels on all nav-bar destinations (vs. selected-only).
    bool get plusNavBarAlwaysShowLabels => _getBool('plusNavBarAlwaysShowLabels', defaultValue: false);
  set plusNavBarAlwaysShowLabels(bool val) => _setBool('plusNavBarAlwaysShowLabels', val);

  /// Show a prominent thicker border on pinned-app tiles instead of relying
  /// solely on the pin icon, giving a subtle but instantly-readable highlight.
    bool get plusPinnedBorderAccent => _getBool('plusPinnedBorderAccent', defaultValue: true);
  set plusPinnedBorderAccent(bool val) => _setBool('plusPinnedBorderAccent', val);

  /// Draw a left-edge category-color accent ribbon on list tiles to make
  /// categorised apps immediately identifiable at a glance.
    bool get plusCategoryAccentRibbon => _getBool('plusCategoryAccentRibbon', defaultValue: false);
  set plusCategoryAccentRibbon(bool val) => _setBool('plusCategoryAccentRibbon', val);

  /// Replace the small circular download icon on updatable tiles with an
  /// expressive pill chip showing the target version (e.g. "↓ 2.4.0").
    bool get plusUpdateExpressiveBadge => _getBool('plusUpdateExpressiveBadge', defaultValue: false);
  set plusUpdateExpressiveBadge(bool val) => _setBool('plusUpdateExpressiveBadge', val);

  /// Add a subtle rim border to app icons so icons with transparent or white
  /// backgrounds don't dissolve into the card background.
    bool get plusIconRimBorder => _getBool('plusIconRimBorder', defaultValue: false);
  set plusIconRimBorder(bool val) => _setBool('plusIconRimBorder', val);

  /// Show a contextual status subtitle under the large OneUI header title
  /// (e.g. "18 apps · 3 updates ready") that fades as the header collapses.
    bool get plusHeaderContextSubtitle => _getBool('plusHeaderContextSubtitle', defaultValue: true);
  set plusHeaderContextSubtitle(bool val) => _setBool('plusHeaderContextSubtitle', val);

  /// Display the App Detail install/update bar as a floating pill capsule
  /// hovering above the nav bar instead of a pinned full-width strip.
    bool get plusFloatingActionBar => _getBool('plusFloatingActionBar', defaultValue: false);
  set plusFloatingActionBar(bool val) => _setBool('plusFloatingActionBar', val);

  /// Use fully-rounded pill (StadiumBorder) filter chips on the tag filter bar
  /// instead of the default rounded-rectangle shape.
    bool get plusExpressiveFilterChips => _getBool('plusExpressiveFilterChips', defaultValue: true);
  set plusExpressiveFilterChips(bool val) => _setBool('plusExpressiveFilterChips', val);

  ScrollPhysics get scrollPhysics => plusEnableBouncyPhysics
      ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
      : const AlwaysScrollableScrollPhysics();
}
