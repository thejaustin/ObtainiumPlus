import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PlusSettingsProvider initialization and toggles', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = PlusSettingsProvider();

    await provider.initializeSettings(prefs);

    expect(provider.backupEncryptionEnabled, false);

    provider.backupEncryptionEnabled = true;
    expect(provider.backupEncryptionEnabled, true);
    expect(prefs.getBool('backupEncryptionEnabled'), true);

    // Layout mode tests
    expect(provider.plusSettingsLayoutMode.name, 'm3eCompactGrid');
    expect(provider.plusSettingsUseGridToggles, true);
    expect(provider.plusSettingsUseVisualThemePicker, true);
    expect(provider.plusSettingsUseSubmenuHub, true);
    expect(provider.plusSettingsUseHeroCards, true);

    provider.plusSettingsLayoutMode = SettingsLayoutMode.classicGrouped;
    expect(provider.plusSettingsLayoutMode, SettingsLayoutMode.classicGrouped);
    expect(provider.plusSettingsUseGridToggles, false);
    expect(provider.plusSettingsUseVisualThemePicker, false);
    expect(provider.plusSettingsUseSubmenuHub, false);

    // Granular toggle override in classic mode
    provider.plusSettingsUseGridToggles = true;
    expect(provider.plusSettingsUseGridToggles, true);
    expect(provider.plusSettingsLayoutMode, SettingsLayoutMode.classicGrouped);
  });

  test('PlusSettingsProvider in-memory caching and notification coalescing', () async {
    SharedPreferences.setMockInitialValues({'plusEnableEnhancedAnimations': true});
    final prefs = await SharedPreferences.getInstance();
    final provider = PlusSettingsProvider();
    await provider.initializeSettings(prefs);

    // Initial read populates cache
    expect(provider.plusEnableEnhancedAnimations, true);

    int notifyCount = 0;
    provider.addListener(() {
      notifyCount++;
    });

    // Mutate multiple properties synchronously
    provider.plusEnableEnhancedAnimations = false;
    provider.plusHapticsEnabled = false;
    provider.plusCornerRadius = 16.0;

    // Immediately before microtask flushes, notifications are coalesced
    expect(notifyCount, 0);

    // After microtask flushes, exactly 1 notification is fired
    await Future.microtask(() {});
    expect(notifyCount, 1);
    expect(provider.plusEnableEnhancedAnimations, false);
    expect(provider.plusHapticsEnabled, false);
    expect(provider.plusCornerRadius, 16.0);
  });
}

