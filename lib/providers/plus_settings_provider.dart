import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlusSettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;

  Future<void> initializeSettings(SharedPreferences prefs) async {
    _prefs = prefs;
    notifyListeners();
  }

  // Obtainium+ Features (Master Toggle)
  bool get enableAllPlusFeatures => _prefs?.getBool('enableAllPlusFeatures') ?? true;
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

  bool get plusEnableQuickFilters => _prefs?.getBool('plusEnableQuickFilters') ?? true;
  set plusEnableQuickFilters(bool val) {
    _prefs?.setBool('plusEnableQuickFilters', val);
    notifyListeners();
  }

  bool get plusEnableIconCaching => _prefs?.getBool('plusEnableIconCaching') ?? true;
  set plusEnableIconCaching(bool val) {
    _prefs?.setBool('plusEnableIconCaching', val);
    notifyListeners();
  }

  bool get plusEnableEnhancedAnimations => _prefs?.getBool('plusEnableEnhancedAnimations') ?? true;
  set plusEnableEnhancedAnimations(bool val) {
    _prefs?.setBool('plusEnableEnhancedAnimations', val);
    notifyListeners();
  }

  bool get plusEnableMaterialExpressive => _prefs?.getBool('plusEnableMaterialExpressive') ?? true;
  set plusEnableMaterialExpressive(bool val) {
    _prefs?.setBool('plusEnableMaterialExpressive', val);
    notifyListeners();
  }

  bool get plusEnableUICustomization => _prefs?.getBool('plusEnableUICustomization') ?? true;
  set plusEnableUICustomization(bool val) {
    _prefs?.setBool('plusEnableUICustomization', val);
    notifyListeners();
  }

  bool get plusEnableExperimentalCustomization => _prefs?.getBool('plusEnableExperimentalCustomization') ?? false;
  set plusEnableExperimentalCustomization(bool val) {
    _prefs?.setBool('plusEnableExperimentalCustomization', val);
    notifyListeners();
  }

  bool get plusEnableGlassmorphism => _prefs?.getBool('plusEnableGlassmorphism') ?? true;
  set plusEnableGlassmorphism(bool val) {
    _prefs?.setBool('plusEnableGlassmorphism', val);
    notifyListeners();
  }

  bool get plusEnablePopupSlider => _prefs?.getBool('plusEnablePopupSlider') ?? true;
  set plusEnablePopupSlider(bool val) {
    _prefs?.setBool('plusEnablePopupSlider', val);
    notifyListeners();
  }

  bool get plusEnableResponsiveAppLayout => _prefs?.getBool('plusEnableResponsiveAppLayout') ?? true;
  set plusEnableResponsiveAppLayout(bool val) {
    _prefs?.setBool('plusEnableResponsiveAppLayout', val);
    notifyListeners();
  }

  // Modern UI Toggles
  bool get plusEnableModernSettings => _prefs?.getBool('plusEnableModernSettings') ?? true;
  set plusEnableModernSettings(bool val) {
    _prefs?.setBool('plusEnableModernSettings', val);
    notifyListeners();
  }

  bool get plusEnableModernAppPage => _prefs?.getBool('plusEnableModernAppPage') ?? true;
  set plusEnableModernAppPage(bool val) {
    _prefs?.setBool('plusEnableModernAppPage', val);
    notifyListeners();
  }

  bool get plusEnableModernAddAppPage => _prefs?.getBool('plusEnableModernAddAppPage') ?? true;
  set plusEnableModernAddAppPage(bool val) {
    _prefs?.setBool('plusEnableModernAddAppPage', val);
    notifyListeners();
  }

  bool get plusEnableModernAppListTile => _prefs?.getBool('plusEnableModernAppListTile') ?? true;
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
  bool get plusEnableAdvancedSorting => _prefs?.getBool('plusEnableAdvancedSorting') ?? true;
  set plusEnableAdvancedSorting(bool val) {
    _prefs?.setBool('plusEnableAdvancedSorting', val);
    notifyListeners();
  }

  bool get plusEnableCategoryReorder => _prefs?.getBool('plusEnableCategoryReorder') ?? true;
  set plusEnableCategoryReorder(bool val) {
    _prefs?.setBool('plusEnableCategoryReorder', val);
    notifyListeners();
  }

  bool get plusEnableUpdateSchedule => _prefs?.getBool('plusEnableUpdateSchedule') ?? true;
  set plusEnableUpdateSchedule(bool val) {
    _prefs?.setBool('plusEnableUpdateSchedule', val);
    notifyListeners();
  }

  bool get plusEnableSystemUpdateScanner => _prefs?.getBool('plusEnableSystemUpdateScanner') ?? false;
  set plusEnableSystemUpdateScanner(bool val) {
    _prefs?.setBool('plusEnableSystemUpdateScanner', val);
    notifyListeners();
  }

  bool get plusEnableSwipeActions => _prefs?.getBool('plusEnableSwipeActions') ?? true;
  set plusEnableSwipeActions(bool val) {
    _prefs?.setBool('plusEnableSwipeActions', val);
    notifyListeners();
  }

  bool get plusEnableHapticFeedback => _prefs?.getBool('plusEnableHapticFeedback') ?? true;
  set plusEnableHapticFeedback(bool val) {
    _prefs?.setBool('plusEnableHapticFeedback', val);
    notifyListeners();
  }

  // Developer Mode & UI Comparison
  bool get plusDeveloperMode => _prefs?.getBool('plusDeveloperMode') ?? false;
  set plusDeveloperMode(bool val) {
    _prefs?.setBool('plusDeveloperMode', val);
    notifyListeners();
  }

  bool get plusShowLegacyUIComparison => _prefs?.getBool('plusShowLegacyUIComparison') ?? false;
  set plusShowLegacyUIComparison(bool val) {
    _prefs?.setBool('plusShowLegacyUIComparison', val);
    notifyListeners();
  }
}
