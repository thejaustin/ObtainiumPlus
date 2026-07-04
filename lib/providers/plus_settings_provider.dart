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
      _prefs?.getBool('enableAllPlusFeatures') ?? true;
  set enableAllPlusFeatures(bool val) {
    _prefs?.setBool('enableAllPlusFeatures', val);
    notifyListeners();
  }

  // Visual & UI Enhancements
  bool get plusEnableGridView => _prefs?.getBool('plusEnableGridView') ?? true;
  set plusEnableGridView(bool val) {
    _prefs?.setBool('plusEnableGridView', val);
    notifyListeners();
  }

  bool get plusEnableQuickFilters =>
      _prefs?.getBool('plusEnableQuickFilters') ?? true;
  set plusEnableQuickFilters(bool val) {
    _prefs?.setBool('plusEnableQuickFilters', val);
    notifyListeners();
  }

  bool get plusEnableIconCaching =>
      _prefs?.getBool('plusEnableIconCaching') ?? true;
  set plusEnableIconCaching(bool val) {
    _prefs?.setBool('plusEnableIconCaching', val);
    notifyListeners();
  }

  bool get plusEnableEnhancedAnimations =>
      _prefs?.getBool('plusEnableEnhancedAnimations') ?? true;
  set plusEnableEnhancedAnimations(bool val) {
    _prefs?.setBool('plusEnableEnhancedAnimations', val);
    notifyListeners();
  }

  bool get plusEnableMaterialExpressive =>
      _prefs?.getBool('plusEnableMaterialExpressive') ?? true;
  set plusEnableMaterialExpressive(bool val) {
    _prefs?.setBool('plusEnableMaterialExpressive', val);
    notifyListeners();
  }

  String get plusLastSeenVersion =>
      _prefs?.getString('plusLastSeenVersion') ?? '';
  set plusLastSeenVersion(String val) {
    _prefs?.setString('plusLastSeenVersion', val);
    notifyListeners();
  }

  bool get plusShowStatusHub =>
      _prefs?.getBool('plusShowStatusHub') ?? true;
  set plusShowStatusHub(bool val) {
    _prefs?.setBool('plusShowStatusHub', val);
    notifyListeners();
  }

  bool get plusUseCompactSettings =>
      _prefs?.getBool('plusUseCompactSettings') ?? false;
  set plusUseCompactSettings(bool val) {
    _prefs?.setBool('plusUseCompactSettings', val);
    notifyListeners();
  }

  bool get plusShowAdvancedSettings =>
      _prefs?.getBool('plusShowAdvancedSettings') ?? true;
  set plusShowAdvancedSettings(bool val) {
    _prefs?.setBool('plusShowAdvancedSettings', val);
    notifyListeners();
  }

  bool get plusEnableExperimentalCustomization =>
      _prefs?.getBool('plusEnableExperimentalCustomization') ?? false;
  set plusEnableExperimentalCustomization(bool val) {
    _prefs?.setBool('plusEnableExperimentalCustomization', val);
    notifyListeners();
  }

  bool get plusEnableUpdateOwnership =>
      _prefs?.getBool('plusEnableUpdateOwnership') ?? true;
  set plusEnableUpdateOwnership(bool val) {
    _prefs?.setBool('plusEnableUpdateOwnership', val);
    notifyListeners();
  }

  bool get plusEnableUserPreapproval =>
      _prefs?.getBool('plusEnableUserPreapproval') ?? true;
  set plusEnableUserPreapproval(bool val) {
    _prefs?.setBool('plusEnableUserPreapproval', val);
    notifyListeners();
  }

  bool get plusEnableSmartRetries =>
      _prefs?.getBool('plusEnableSmartRetries') ?? true;
  set plusEnableSmartRetries(bool val) {
    _prefs?.setBool('plusEnableSmartRetries', val);
    notifyListeners();
  }

  bool get plusDeduplicateRecents =>
      _prefs?.getBool('plusDeduplicateRecents') ?? true;
  set plusDeduplicateRecents(bool val) {
    _prefs?.setBool('plusDeduplicateRecents', val);
    notifyListeners();
  }

  bool get plusEnableBouncyPhysics =>
      _prefs?.getBool('plusEnableBouncyPhysics') ?? true;
  set plusEnableBouncyPhysics(bool val) {
    _prefs?.setBool('plusEnableBouncyPhysics', val);
    notifyListeners();
  }

  bool get plusEnableGlassmorphism =>
      _prefs?.getBool('plusEnableGlassmorphism') ?? true;
  set plusEnableGlassmorphism(bool val) {
    _prefs?.setBool('plusEnableGlassmorphism', val);
    notifyListeners();
  }

  bool get plusEnablePopupSlider =>
      _prefs?.getBool('plusEnablePopupSlider') ?? true;
  set plusEnablePopupSlider(bool val) {
    _prefs?.setBool('plusEnablePopupSlider', val);
    notifyListeners();
  }

  bool get plusEnableResponsiveAppLayout =>
      _prefs?.getBool('plusEnableResponsiveAppLayout') ?? true;
  set plusEnableResponsiveAppLayout(bool val) {
    _prefs?.setBool('plusEnableResponsiveAppLayout', val);
    notifyListeners();
  }

  // Modern UI Toggles
  bool get plusEnableModernAppPage =>
      _prefs?.getBool('plusEnableModernAppPage') ?? true;
  set plusEnableModernAppPage(bool val) {
    _prefs?.setBool('plusEnableModernAppPage', val);
    notifyListeners();
  }

  bool get plusEnableModernAddAppPage =>
      _prefs?.getBool('plusEnableModernAddAppPage') ?? true;
  set plusEnableModernAddAppPage(bool val) {
    _prefs?.setBool('plusEnableModernAddAppPage', val);
    notifyListeners();
  }

  bool get plusEnableModernAppListTile =>
      _prefs?.getBool('plusEnableModernAppListTile') ?? true;
  set plusEnableModernAppListTile(bool val) {
    _prefs?.setBool('plusEnableModernAppListTile', val);
    notifyListeners();
  }

  // Feature Discovery
  bool get plusEnableDiscover => _prefs?.getBool('plusEnableDiscover') ?? true;
  set plusEnableDiscover(bool val) {
    _prefs?.setBool('plusEnableDiscover', val);
    notifyListeners();
  }

  // Advanced Logic
  bool get plusEnableAdvancedSorting =>
      _prefs?.getBool('plusEnableAdvancedSorting') ?? true;
  set plusEnableAdvancedSorting(bool val) {
    _prefs?.setBool('plusEnableAdvancedSorting', val);
    notifyListeners();
  }

  bool get plusEnableCategoryReorder =>
      _prefs?.getBool('plusEnableCategoryReorder') ?? true;
  set plusEnableCategoryReorder(bool val) {
    _prefs?.setBool('plusEnableCategoryReorder', val);
    notifyListeners();
  }

  bool get plusEnableUpdateSchedule =>
      _prefs?.getBool('plusEnableUpdateSchedule') ?? true;
  set plusEnableUpdateSchedule(bool val) {
    _prefs?.setBool('plusEnableUpdateSchedule', val);
    notifyListeners();
  }

  bool get plusEnableSystemUpdateScanner =>
      _prefs?.getBool('plusEnableSystemUpdateScanner') ?? false;
  set plusEnableSystemUpdateScanner(bool val) {
    _prefs?.setBool('plusEnableSystemUpdateScanner', val);
    notifyListeners();
  }

  bool get plusEnableHomeDashboard =>
      _prefs?.getBool('plusEnableHomeDashboard') ?? true;
  set plusEnableHomeDashboard(bool val) {
    _prefs?.setBool('plusEnableHomeDashboard', val);
    notifyListeners();
  }

  bool get plusShowAppBarSearch =>
      _prefs?.getBool('plusShowAppBarSearch') ?? true;
  set plusShowAppBarSearch(bool val) {
    _prefs?.setBool('plusShowAppBarSearch', val);
    notifyListeners();
  }

  bool get plusShowDashboardSearch =>
      _prefs?.getBool('plusShowDashboardSearch') ?? true;
  set plusShowDashboardSearch(bool val) {
    _prefs?.setBool('plusShowDashboardSearch', val);
    notifyListeners();
  }

  bool get plusShowFloatingSearch =>
      _prefs?.getBool('plusShowFloatingSearch') ?? true;
  set plusShowFloatingSearch(bool val) {
    _prefs?.setBool('plusShowFloatingSearch', val);
    notifyListeners();
  }

  bool get plusEnableSwipeActions =>
      _prefs?.getBool('plusEnableSwipeActions') ?? true;
  set plusEnableSwipeActions(bool val) {
    _prefs?.setBool('plusEnableSwipeActions', val);
    notifyListeners();
  }

  bool get plusEnableExpressiveProgress =>
      _prefs?.getBool('plusEnableExpressiveProgress') ?? true;
  set plusEnableExpressiveProgress(bool val) {
    _prefs?.setBool('plusEnableExpressiveProgress', val);
    notifyListeners();
  }

  double get plusGlobalCornerRadius =>
      _prefs?.safeDouble('plusGlobalCornerRadius') ?? 20.0;
  set plusGlobalCornerRadius(double val) {
    _prefs?.setDouble('plusGlobalCornerRadius', val);
    notifyListeners();
  }

  double get plusHomeCornerRadius =>
      _prefs?.safeDouble('plusHomeCornerRadius') ?? 20.0;
  set plusHomeCornerRadius(double val) {
    _prefs?.setDouble('plusHomeCornerRadius', val);
    notifyListeners();
  }

  double get plusSettingsCornerRadius =>
      _prefs?.safeDouble('plusSettingsCornerRadius') ?? 16.0;
  set plusSettingsCornerRadius(double val) {
    _prefs?.setDouble('plusSettingsCornerRadius', val);
    notifyListeners();
  }

  bool get plusOverrideIndividualCornerRadius =>
      _prefs?.getBool('plusOverrideIndividualCornerRadius') ?? false;
  set plusOverrideIndividualCornerRadius(bool val) {
    _prefs?.setBool('plusOverrideIndividualCornerRadius', val);
    notifyListeners();
  }

  bool get plusTopUILayout => _prefs?.getBool('plusTopUILayout') ?? false;
  set plusTopUILayout(bool val) {
    _prefs?.setBool('plusTopUILayout', val);
    notifyListeners();
  }

  // Developer Mode & UI Comparison
  bool get plusDeveloperMode => _prefs?.getBool('plusDeveloperMode') ?? false;
  set plusDeveloperMode(bool val) {
    _prefs?.setBool('plusDeveloperMode', val);
    notifyListeners();
  }

  bool get plusShowLegacyUIComparison =>
      _prefs?.getBool('plusShowLegacyUIComparison') ?? false;
  set plusShowLegacyUIComparison(bool val) {
    _prefs?.setBool('plusShowLegacyUIComparison', val);
    notifyListeners();
  }

  bool get playStoreVerifiedOnly =>
      _prefs?.getBool('playStoreVerifiedOnly') ?? true;
  set playStoreVerifiedOnly(bool val) {
    _prefs?.setBool('playStoreVerifiedOnly', val);
    notifyListeners();
  }

  bool get playStoreExcludeSystemApps =>
      _prefs?.getBool('playStoreExcludeSystemApps') ?? false;
  set playStoreExcludeSystemApps(bool val) {
    _prefs?.setBool('playStoreExcludeSystemApps', val);
    notifyListeners();
  }

  bool get playStoreNoAdsFilter =>
      _prefs?.getBool('playStoreNoAdsFilter') ?? false;
  set playStoreNoAdsFilter(bool val) {
    _prefs?.setBool('playStoreNoAdsFilter', val);
    notifyListeners();
  }

  int get playStoreMinDownloads => _prefs?.safeInt('playStoreMinDownloads') ?? 0;
  set playStoreMinDownloads(int val) {
    _prefs?.setInt('playStoreMinDownloads', val);
    notifyListeners();
  }

  bool get requireVPNForPlayStore =>
      _prefs?.getBool('requireVPNForPlayStore') ?? false;
  set requireVPNForPlayStore(bool val) {
    _prefs?.setBool('requireVPNForPlayStore', val);
    notifyListeners();
  }

  bool get autoDiscardTokens => _prefs?.getBool('autoDiscardTokens') ?? true;
  set autoDiscardTokens(bool val) {
    _prefs?.setBool('autoDiscardTokens', val);
    notifyListeners();
  }

  // Quick-Add FAB menu item visibility
  bool get plusFabShowSearch => _prefs?.getBool('plusFabShowSearch') ?? true;
  set plusFabShowSearch(bool val) {
    _prefs?.setBool('plusFabShowSearch', val);
    notifyListeners();
  }

  bool get plusFabShowAddByUrl =>
      _prefs?.getBool('plusFabShowAddByUrl') ?? true;
  set plusFabShowAddByUrl(bool val) {
    _prefs?.setBool('plusFabShowAddByUrl', val);
    notifyListeners();
  }

  bool get plusFabShowGithubStarred =>
      _prefs?.getBool('plusFabShowGithubStarred') ?? true;
  set plusFabShowGithubStarred(bool val) {
    _prefs?.setBool('plusFabShowGithubStarred', val);
    notifyListeners();
  }

  bool get plusFabShowGithubPersonalRepos =>
      _prefs?.getBool('plusFabShowGithubPersonalRepos') ?? true;
  set plusFabShowGithubPersonalRepos(bool val) {
    _prefs?.setBool('plusFabShowGithubPersonalRepos', val);
    notifyListeners();
  }

  bool get plusFabShowImportInstalled =>
      _prefs?.getBool('plusFabShowImportInstalled') ?? true;
  set plusFabShowImportInstalled(bool val) {
    _prefs?.setBool('plusFabShowImportInstalled', val);
    notifyListeners();
  }

  bool get plusEnableNotificationDigest =>
      _prefs?.getBool('plusEnableNotificationDigest') ?? false;
  set plusEnableNotificationDigest(bool val) {
    _prefs?.setBool('plusEnableNotificationDigest', val);
    notifyListeners();
  }

  bool get plusEnableNotificationQuietHours =>
      _prefs?.getBool('plusEnableNotificationQuietHours') ?? false;
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
      _prefs?.getBool('plusEnableMicroGHub') ?? true;
  set plusEnableMicroGHub(bool val) {
    _prefs?.setBool('plusEnableMicroGHub', val);
    notifyListeners();
  }

  bool get plusEnableStandaloneInstaller =>
      _prefs?.getBool('plusEnableStandaloneInstaller') ?? true;
  set plusEnableStandaloneInstaller(bool val) {
    _prefs?.setBool('plusEnableStandaloneInstaller', val);
    notifyListeners();
  }

  bool get plusShowTagsInList => _prefs?.getBool('plusShowTagsInList') ?? true;
  set plusShowTagsInList(bool val) {
    _prefs?.setBool('plusShowTagsInList', val);
    notifyListeners();
  }

  bool get plusEnableTags => _prefs?.getBool('plusEnableTags') ?? true;
  set plusEnableTags(bool val) {
    _prefs?.setBool('plusEnableTags', val);
    notifyListeners();
  }

  bool get plusEnableAutoUpdateRules =>
      _prefs?.getBool('plusEnableAutoUpdateRules') ?? true;
  set plusEnableAutoUpdateRules(bool val) {
    _prefs?.setBool('plusEnableAutoUpdateRules', val);
    notifyListeners();
  }

  bool get plusEnableNotificationEnhancements =>
      _prefs?.getBool('plusEnableNotificationEnhancements') ?? true;
  set plusEnableNotificationEnhancements(bool val) {
    _prefs?.setBool('plusEnableNotificationEnhancements', val);
    notifyListeners();
  }

  bool get backupEncryptionEnabled =>
      _prefs?.getBool('backupEncryptionEnabled') ?? false;
  set backupEncryptionEnabled(bool val) {
    _prefs?.setBool('backupEncryptionEnabled', val);
    notifyListeners();
  }

  List<String> get plusPinnedAppsOrder =>
      _prefs?.getStringList('plusPinnedAppsOrder') ?? [];
  set plusPinnedAppsOrder(List<String> val) {
    _prefs?.setStringList('plusPinnedAppsOrder', val);
    notifyListeners();
  }

  bool get plusEnableBanWarnings => _prefs?.getBool('plusEnableBanWarnings') ?? false;
  set plusEnableBanWarnings(bool val) {
    _prefs?.setBool('plusEnableBanWarnings', val);
    notifyListeners();
  }

  int get plusBanWarningThreshold => _prefs?.safeInt('plusBanWarningThreshold') ?? 5;
  set plusBanWarningThreshold(int val) {
    _prefs?.setInt('plusBanWarningThreshold', val);
    notifyListeners();
  }

  String? get plusDefaultStorePackage => _prefs?.getString('plusDefaultStorePackage');
  set plusDefaultStorePackage(String? val) {
    if (val == null) {
      _prefs?.remove('plusDefaultStorePackage');
    } else {
      _prefs?.setString('plusDefaultStorePackage', val);
    }
    notifyListeners();
  }

  String? get plusDefaultStoreName => _prefs?.getString('plusDefaultStoreName');
  set plusDefaultStoreName(String? val) {
    if (val == null) {
      _prefs?.remove('plusDefaultStoreName');
    } else {
      _prefs?.setString('plusDefaultStoreName', val);
    }
    notifyListeners();
  }

  ScrollPhysics get scrollPhysics => plusEnableBouncyPhysics
      ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
      : const AlwaysScrollableScrollPhysics();
}
