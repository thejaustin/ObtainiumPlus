import 'package:obtainium/utils/safe_prefs.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlusSettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  Future<void> initializeSettings(SharedPreferences prefs) async {
    _prefs = prefs;
    notifyListeners();
  }

  // Obtainium+ Features (Master Toggle)
  bool get enableAllPlusFeatures =>
      _prefs?.safeBool('enableAllPlusFeatures') ?? true;
  set enableAllPlusFeatures(bool val) {
    _prefs?.setBool('enableAllPlusFeatures', val);
    notifyListeners();
  }

  // Visual & UI Enhancements
  bool get plusEnableGridView => _prefs?.safeBool('plusEnableGridView') ?? true;
  set plusEnableGridView(bool val) {
    _prefs?.setBool('plusEnableGridView', val);
    notifyListeners();
  }

  bool get plusEnableQuickFilters =>
      _prefs?.safeBool('plusEnableQuickFilters') ?? true;
  set plusEnableQuickFilters(bool val) {
    _prefs?.setBool('plusEnableQuickFilters', val);
    notifyListeners();
  }

  bool get plusEnableIconCaching =>
      _prefs?.safeBool('plusEnableIconCaching') ?? true;
  set plusEnableIconCaching(bool val) {
    _prefs?.setBool('plusEnableIconCaching', val);
    notifyListeners();
  }

  bool get plusEnableEnhancedAnimations =>
      _prefs?.safeBool('plusEnableEnhancedAnimations') ?? true;
  set plusEnableEnhancedAnimations(bool val) {
    _prefs?.setBool('plusEnableEnhancedAnimations', val);
    notifyListeners();
  }

  bool get plusEnableMaterialExpressive =>
      _prefs?.safeBool('plusEnableMaterialExpressive') ?? true;
  set plusEnableMaterialExpressive(bool val) {
    _prefs?.setBool('plusEnableMaterialExpressive', val);
    notifyListeners();
  }

  bool get plusShowChangelogAfterUpdate =>
      _prefs?.safeBool('plusShowChangelogAfterUpdate') ?? true;
  set plusShowChangelogAfterUpdate(bool val) {
    _prefs?.setBool('plusShowChangelogAfterUpdate', val);
    notifyListeners();
  }

  String get plusLastSeenVersion =>
      _prefs?.safeString('plusLastSeenVersion') ?? '';
  set plusLastSeenVersion(String val) {
    _prefs?.setString('plusLastSeenVersion', val);
    notifyListeners();
  }

  bool get plusShowStatusHub => _prefs?.safeBool('plusShowStatusHub') ?? true;
  set plusShowStatusHub(bool val) {
    _prefs?.setBool('plusShowStatusHub', val);
    notifyListeners();
  }

  bool get plusUseCompactSettings =>
      _prefs?.safeBool('plusUseCompactSettings') ?? false;
  set plusUseCompactSettings(bool val) {
    _prefs?.setBool('plusUseCompactSettings', val);
    notifyListeners();
  }

  bool get plusShowAdvancedSettings =>
      _prefs?.safeBool('plusShowAdvancedSettings') ?? true;
  set plusShowAdvancedSettings(bool val) {
    _prefs?.setBool('plusShowAdvancedSettings', val);
    notifyListeners();
  }

  bool get plusEnableExperimentalCustomization =>
      _prefs?.safeBool('plusEnableExperimentalCustomization') ?? false;
  set plusEnableExperimentalCustomization(bool val) {
    _prefs?.setBool('plusEnableExperimentalCustomization', val);
    notifyListeners();
  }

  bool get plusEnableUpdateOwnership =>
      _prefs?.safeBool('plusEnableUpdateOwnership') ?? true;
  set plusEnableUpdateOwnership(bool val) {
    _prefs?.setBool('plusEnableUpdateOwnership', val);
    notifyListeners();
  }

  bool get plusEnableUserPreapproval =>
      _prefs?.safeBool('plusEnableUserPreapproval') ?? true;
  set plusEnableUserPreapproval(bool val) {
    _prefs?.setBool('plusEnableUserPreapproval', val);
    notifyListeners();
  }

  bool get plusEnableSmartRetries =>
      _prefs?.safeBool('plusEnableSmartRetries') ?? true;
  set plusEnableSmartRetries(bool val) {
    _prefs?.setBool('plusEnableSmartRetries', val);
    notifyListeners();
  }

  bool get plusDeduplicateRecents =>
      _prefs?.safeBool('plusDeduplicateRecents') ?? true;
  set plusDeduplicateRecents(bool val) {
    _prefs?.setBool('plusDeduplicateRecents', val);
    notifyListeners();
  }

  bool get plusEnableBouncyPhysics =>
      _prefs?.safeBool('plusEnableBouncyPhysics') ?? true;
  set plusEnableBouncyPhysics(bool val) {
    _prefs?.setBool('plusEnableBouncyPhysics', val);
    notifyListeners();
  }

  bool get plusEnableGlassmorphism =>
      _prefs?.safeBool('plusEnableGlassmorphism') ?? true;
  set plusEnableGlassmorphism(bool val) {
    _prefs?.setBool('plusEnableGlassmorphism', val);
    notifyListeners();
  }

  bool get plusEnablePopupSlider =>
      _prefs?.safeBool('plusEnablePopupSlider') ?? true;
  set plusEnablePopupSlider(bool val) {
    _prefs?.setBool('plusEnablePopupSlider', val);
    notifyListeners();
  }

  bool get plusEnableResponsiveAppLayout =>
      _prefs?.safeBool('plusEnableResponsiveAppLayout') ?? true;
  set plusEnableResponsiveAppLayout(bool val) {
    _prefs?.setBool('plusEnableResponsiveAppLayout', val);
    notifyListeners();
  }

  // Modern UI Toggles
  bool get plusEnableModernAppPage =>
      _prefs?.safeBool('plusEnableModernAppPage') ?? true;
  set plusEnableModernAppPage(bool val) {
    _prefs?.setBool('plusEnableModernAppPage', val);
    notifyListeners();
  }

  bool get plusEnableModernAddAppPage =>
      _prefs?.safeBool('plusEnableModernAddAppPage') ?? true;
  set plusEnableModernAddAppPage(bool val) {
    _prefs?.setBool('plusEnableModernAddAppPage', val);
    notifyListeners();
  }

  bool get plusEnableModernAppListTile =>
      _prefs?.safeBool('plusEnableModernAppListTile') ?? true;
  set plusEnableModernAppListTile(bool val) {
    _prefs?.setBool('plusEnableModernAppListTile', val);
    notifyListeners();
  }

  // Feature Discovery
  bool get plusEnableDiscover => _prefs?.safeBool('plusEnableDiscover') ?? true;
  set plusEnableDiscover(bool val) {
    _prefs?.setBool('plusEnableDiscover', val);
    notifyListeners();
  }

  bool get plusDiscoverSuggestions =>
      _prefs?.safeBool('plusDiscoverSuggestions') ?? true;
  set plusDiscoverSuggestions(bool val) {
    _prefs?.setBool('plusDiscoverSuggestions', val);
    notifyListeners();
  }

  // Advanced Logic
  bool get plusEnableAdvancedSorting =>
      _prefs?.safeBool('plusEnableAdvancedSorting') ?? true;
  set plusEnableAdvancedSorting(bool val) {
    _prefs?.setBool('plusEnableAdvancedSorting', val);
    notifyListeners();
  }

  bool get plusEnableCategoryReorder =>
      _prefs?.safeBool('plusEnableCategoryReorder') ?? true;
  set plusEnableCategoryReorder(bool val) {
    _prefs?.setBool('plusEnableCategoryReorder', val);
    notifyListeners();
  }

  bool get plusEnableUpdateSchedule =>
      _prefs?.safeBool('plusEnableUpdateSchedule') ?? true;
  set plusEnableUpdateSchedule(bool val) {
    _prefs?.setBool('plusEnableUpdateSchedule', val);
    notifyListeners();
  }

  bool get plusEnableSystemUpdateScanner =>
      _prefs?.safeBool('plusEnableSystemUpdateScanner') ?? false;
  set plusEnableSystemUpdateScanner(bool val) {
    _prefs?.setBool('plusEnableSystemUpdateScanner', val);
    notifyListeners();
  }

  bool get plusEnableHomeDashboard =>
      _prefs?.safeBool('plusEnableHomeDashboard') ?? true;
  set plusEnableHomeDashboard(bool val) {
    _prefs?.setBool('plusEnableHomeDashboard', val);
    notifyListeners();
  }

  bool get plusShowAppBarSearch =>
      _prefs?.safeBool('plusShowAppBarSearch') ?? true;
  set plusShowAppBarSearch(bool val) {
    _prefs?.setBool('plusShowAppBarSearch', val);
    notifyListeners();
  }

  bool get plusShowDashboardSearch =>
      _prefs?.safeBool('plusShowDashboardSearch') ?? true;
  set plusShowDashboardSearch(bool val) {
    _prefs?.setBool('plusShowDashboardSearch', val);
    notifyListeners();
  }

  bool get plusShowFloatingSearch =>
      _prefs?.safeBool('plusShowFloatingSearch') ?? true;
  set plusShowFloatingSearch(bool val) {
    _prefs?.setBool('plusShowFloatingSearch', val);
    notifyListeners();
  }

  bool get plusEnableSwipeActions =>
      _prefs?.safeBool('plusEnableSwipeActions') ?? true;
  set plusEnableSwipeActions(bool val) {
    _prefs?.setBool('plusEnableSwipeActions', val);
    notifyListeners();
  }

  bool get plusEnableExpressiveProgress =>
      _prefs?.safeBool('plusEnableExpressiveProgress') ?? true;
  set plusEnableExpressiveProgress(bool val) {
    _prefs?.setBool('plusEnableExpressiveProgress', val);
    notifyListeners();
  }

  // Range-bound prefs are clamped at the getter: imported/stale values can
  // be arbitrary, and out-of-range ones break the Sliders bound to them.
  double get plusGlobalCornerRadius =>
      (_prefs?.safeDouble('plusGlobalCornerRadius') ?? 20.0).clamp(0.0, 40.0);
  set plusGlobalCornerRadius(double val) {
    _prefs?.setDouble('plusGlobalCornerRadius', val);
    notifyListeners();
  }

  double get plusHomeCornerRadius =>
      (_prefs?.safeDouble('plusHomeCornerRadius') ?? 20.0).clamp(0.0, 40.0);
  set plusHomeCornerRadius(double val) {
    _prefs?.setDouble('plusHomeCornerRadius', val);
    notifyListeners();
  }

  double get plusSettingsCornerRadius =>
      (_prefs?.safeDouble('plusSettingsCornerRadius') ?? 16.0).clamp(0.0, 40.0);
  set plusSettingsCornerRadius(double val) {
    _prefs?.setDouble('plusSettingsCornerRadius', val);
    notifyListeners();
  }

  bool get plusOverrideIndividualCornerRadius =>
      _prefs?.safeBool('plusOverrideIndividualCornerRadius') ?? false;
  set plusOverrideIndividualCornerRadius(bool val) {
    _prefs?.setBool('plusOverrideIndividualCornerRadius', val);
    notifyListeners();
  }

  bool get plusTopUILayout => _prefs?.safeBool('plusTopUILayout') ?? false;
  set plusTopUILayout(bool val) {
    _prefs?.setBool('plusTopUILayout', val);
    notifyListeners();
  }

  // Developer Mode & UI Comparison
  bool get plusDeveloperMode => _prefs?.safeBool('plusDeveloperMode') ?? false;
  set plusDeveloperMode(bool val) {
    _prefs?.setBool('plusDeveloperMode', val);
    notifyListeners();
  }

  bool get plusShowLegacyUIComparison =>
      _prefs?.safeBool('plusShowLegacyUIComparison') ?? false;
  set plusShowLegacyUIComparison(bool val) {
    _prefs?.setBool('plusShowLegacyUIComparison', val);
    notifyListeners();
  }

  bool get playStoreVerifiedOnly =>
      _prefs?.safeBool('playStoreVerifiedOnly') ?? true;
  set playStoreVerifiedOnly(bool val) {
    _prefs?.setBool('playStoreVerifiedOnly', val);
    notifyListeners();
  }

  bool get playStoreExcludeSystemApps =>
      _prefs?.safeBool('playStoreExcludeSystemApps') ?? false;
  set playStoreExcludeSystemApps(bool val) {
    _prefs?.setBool('playStoreExcludeSystemApps', val);
    notifyListeners();
  }

  bool get playStoreNoAdsFilter =>
      _prefs?.safeBool('playStoreNoAdsFilter') ?? false;
  set playStoreNoAdsFilter(bool val) {
    _prefs?.setBool('playStoreNoAdsFilter', val);
    notifyListeners();
  }

  int get playStoreMinDownloads =>
      (_prefs?.safeInt('playStoreMinDownloads') ?? 0).clamp(0, 1000000);
  set playStoreMinDownloads(int val) {
    _prefs?.setInt('playStoreMinDownloads', val);
    notifyListeners();
  }

  bool get requireVPNForPlayStore =>
      _prefs?.safeBool('requireVPNForPlayStore') ?? false;
  set requireVPNForPlayStore(bool val) {
    _prefs?.setBool('requireVPNForPlayStore', val);
    notifyListeners();
  }

  bool get autoDiscardTokens => _prefs?.safeBool('autoDiscardTokens') ?? true;
  set autoDiscardTokens(bool val) {
    _prefs?.setBool('autoDiscardTokens', val);
    notifyListeners();
  }

  // Quick-Add FAB menu item visibility
  bool get plusFabShowSearch => _prefs?.safeBool('plusFabShowSearch') ?? true;
  set plusFabShowSearch(bool val) {
    _prefs?.setBool('plusFabShowSearch', val);
    notifyListeners();
  }

  bool get plusFabShowAddByUrl =>
      _prefs?.safeBool('plusFabShowAddByUrl') ?? true;
  set plusFabShowAddByUrl(bool val) {
    _prefs?.setBool('plusFabShowAddByUrl', val);
    notifyListeners();
  }

  bool get plusFabShowGithubStarred =>
      _prefs?.safeBool('plusFabShowGithubStarred') ?? true;
  set plusFabShowGithubStarred(bool val) {
    _prefs?.setBool('plusFabShowGithubStarred', val);
    notifyListeners();
  }

  bool get plusFabShowGithubPersonalRepos =>
      _prefs?.safeBool('plusFabShowGithubPersonalRepos') ?? true;
  set plusFabShowGithubPersonalRepos(bool val) {
    _prefs?.setBool('plusFabShowGithubPersonalRepos', val);
    notifyListeners();
  }

  bool get plusFabShowImportInstalled =>
      _prefs?.safeBool('plusFabShowImportInstalled') ?? true;
  set plusFabShowImportInstalled(bool val) {
    _prefs?.setBool('plusFabShowImportInstalled', val);
    notifyListeners();
  }

  bool get plusEnableNotificationDigest =>
      _prefs?.safeBool('plusEnableNotificationDigest') ?? false;
  set plusEnableNotificationDigest(bool val) {
    _prefs?.setBool('plusEnableNotificationDigest', val);
    notifyListeners();
  }

  bool get plusEnableNotificationQuietHours =>
      _prefs?.safeBool('plusEnableNotificationQuietHours') ?? false;
  set plusEnableNotificationQuietHours(bool val) {
    _prefs?.setBool('plusEnableNotificationQuietHours', val);
    notifyListeners();
  }

  int get plusNotificationQuietHoursStart =>
      _prefs?.safeInt('plusNotificationQuietHoursStart') ?? 22;
  set plusNotificationQuietHoursStart(int val) {
    _prefs?.setInt('plusNotificationQuietHoursStart', val);
    notifyListeners();
  }

  int get plusNotificationQuietHoursEnd =>
      _prefs?.safeInt('plusNotificationQuietHoursEnd') ?? 7;
  set plusNotificationQuietHoursEnd(int val) {
    _prefs?.setInt('plusNotificationQuietHoursEnd', val);
    notifyListeners();
  }

  bool get plusEnableMicroGHub =>
      _prefs?.safeBool('plusEnableMicroGHub') ?? true;
  set plusEnableMicroGHub(bool val) {
    _prefs?.setBool('plusEnableMicroGHub', val);
    notifyListeners();
  }

  bool get plusEnableStandaloneInstaller =>
      _prefs?.safeBool('plusEnableStandaloneInstaller') ?? true;
  set plusEnableStandaloneInstaller(bool val) {
    _prefs?.setBool('plusEnableStandaloneInstaller', val);
    notifyListeners();
  }

  bool get plusShowTagsInList => _prefs?.safeBool('plusShowTagsInList') ?? true;
  set plusShowTagsInList(bool val) {
    _prefs?.setBool('plusShowTagsInList', val);
    notifyListeners();
  }

  bool get plusEnableTags => _prefs?.safeBool('plusEnableTags') ?? true;
  set plusEnableTags(bool val) {
    _prefs?.setBool('plusEnableTags', val);
    notifyListeners();
  }

  bool get plusEnableAutoUpdateRules =>
      _prefs?.safeBool('plusEnableAutoUpdateRules') ?? true;
  set plusEnableAutoUpdateRules(bool val) {
    _prefs?.setBool('plusEnableAutoUpdateRules', val);
    notifyListeners();
  }

  bool get plusEnableNotificationEnhancements =>
      _prefs?.safeBool('plusEnableNotificationEnhancements') ?? true;
  set plusEnableNotificationEnhancements(bool val) {
    _prefs?.setBool('plusEnableNotificationEnhancements', val);
    notifyListeners();
  }

  bool get backupEncryptionEnabled =>
      _prefs?.safeBool('backupEncryptionEnabled') ?? false;
  set backupEncryptionEnabled(bool val) {
    _prefs?.setBool('backupEncryptionEnabled', val);
    notifyListeners();
  }

  List<String> get plusPinnedAppsOrder =>
      _prefs?.safeStringList('plusPinnedAppsOrder') ?? [];
  set plusPinnedAppsOrder(List<String> val) {
    _prefs?.setStringList('plusPinnedAppsOrder', val);
    notifyListeners();
  }

  bool get plusEnableBanWarnings =>
      _prefs?.safeBool('plusEnableBanWarnings') ?? false;
  set plusEnableBanWarnings(bool val) {
    _prefs?.setBool('plusEnableBanWarnings', val);
    notifyListeners();
  }

  int get plusBanWarningThreshold =>
      (_prefs?.safeInt('plusBanWarningThreshold') ?? 5).clamp(1, 50);
  set plusBanWarningThreshold(int val) {
    _prefs?.setInt('plusBanWarningThreshold', val);
    notifyListeners();
  }

  String? get plusDefaultStorePackage =>
      _prefs?.safeString('plusDefaultStorePackage');
  set plusDefaultStorePackage(String? val) {
    if (val == null) {
      _prefs?.remove('plusDefaultStorePackage');
    } else {
      _prefs?.setString('plusDefaultStorePackage', val);
    }
    notifyListeners();
  }

  String? get plusDefaultStoreName =>
      _prefs?.safeString('plusDefaultStoreName');
  set plusDefaultStoreName(String? val) {
    if (val == null) {
      _prefs?.remove('plusDefaultStoreName');
    } else {
      _prefs?.setString('plusDefaultStoreName', val);
    }
    notifyListeners();
  }

  bool get plusEnableBottomNavBar =>
      _prefs?.safeBool('plusEnableBottomNavBar') ?? false;
  set plusEnableBottomNavBar(bool val) {
    _prefs?.setBool('plusEnableBottomNavBar', val);
    notifyListeners();
  }

  bool get plusEnableFAB => _prefs?.safeBool('plusEnableFAB') ?? true;
  set plusEnableFAB(bool val) {
    _prefs?.setBool('plusEnableFAB', val);
    notifyListeners();
  }

  ScrollPhysics get scrollPhysics => plusEnableBouncyPhysics
      ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
      : const AlwaysScrollableScrollPhysics();
}
