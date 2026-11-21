import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:obtainium/models/settings_block.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';

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

  test(
    'PlusSettingsProvider in-memory caching and notification coalescing',
    () async {
      SharedPreferences.setMockInitialValues({
        'plusEnableEnhancedAnimations': true,
      });
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
      provider.plusEnableBouncyPhysics = false;
      provider.plusGlobalCornerRadius = 16.0;

      // Immediately before microtask flushes, notifications are coalesced
      expect(notifyCount, 0);

      // After microtask flushes, exactly 1 notification is fired
      await Future.microtask(() {});
      expect(notifyCount, 1);
      expect(provider.plusEnableEnhancedAnimations, false);
      expect(provider.plusEnableBouncyPhysics, false);
      expect(provider.plusGlobalCornerRadius, 16.0);
    },
  );

  test(
    'Launcher & App Grid style toggles and GridMetrics aspect ratio',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = PlusSettingsProvider();
      await provider.initializeSettings(prefs);

      expect(provider.plusGridSquareTiles, true);
      expect(provider.plusGridCardlessStyle, true);
      expect(provider.plusGridAmbientIconHalo, true);
      expect(provider.plusGridShowSourceBadge, true);
      expect(provider.plusHardwareAcceleration, true);
      expect(provider.plusFastLaunchPhase1, true);
      expect(provider.plusGridRepaintBoundaries, true);
      expect(provider.plusMaxIconMemoryEntries, 500);

      expect(
        GridMetrics.childAspectRatio(
          columnCount: 4,
          hasExtraDetails: true,
          squareTiles: provider.plusGridSquareTiles,
        ),
        1.0,
      );

      provider.plusGridSquareTiles = false;
      provider.plusGridCardlessStyle = false;
      provider.plusGridAmbientIconHalo = false;
      provider.plusGridShowSourceBadge = false;

      expect(provider.plusGridSquareTiles, false);
      expect(provider.plusGridCardlessStyle, false);
      expect(provider.plusGridAmbientIconHalo, false);
      expect(provider.plusGridShowSourceBadge, false);
      expect(
        GridMetrics.childAspectRatio(
          columnCount: 4,
          hasExtraDetails: true,
          squareTiles: provider.plusGridSquareTiles,
        ),
        lessThan(1.0),
      );
    },
  );

  test('SettingsBlockRegistry and SettingsLayoutConfiguration', () {
    expect(SettingsBlockRegistry.allBlocks.isNotEmpty, true);
    final tileBlock = SettingsBlockRegistry.findById('app_tile_design');
    expect(tileBlock != null, true);
    expect(tileBlock?.category, SettingsCategory.homeAndLibrary);

    final homeBlocks = SettingsBlockRegistry.forCategory(
      SettingsCategory.homeAndLibrary,
    );
    expect(homeBlocks.isNotEmpty, true);

    const config = SettingsLayoutConfiguration(
      preset: 'custom',
      pinnedBlocks: {'app_tile_design'},
      hiddenBlocks: {'microg_integration'},
    );
    expect(config.isPinned('app_tile_design'), true);
    expect(config.isHidden('microg_integration'), true);
    expect(config.isPinned('theme_palette'), false);

    final jsonStr = config.encode();
    final decoded = SettingsLayoutConfiguration.decode(jsonStr);
    expect(decoded.preset, 'custom');
    expect(decoded.isPinned('app_tile_design'), true);
    expect(decoded.isHidden('microg_integration'), true);
  });

  test('PlusSettingsProvider layout customization toggles and reset', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = PlusSettingsProvider();
    await provider.initializeSettings(prefs);

    expect(provider.isSettingsBlockPinned('app_tile_design'), false);
    expect(provider.isSettingsBlockHidden('app_tile_design'), false);

    provider.togglePinSettingsBlock('app_tile_design');
    expect(provider.isSettingsBlockPinned('app_tile_design'), true);
    expect(provider.isSettingsBlockPinned('home.tiles'), true);

    provider.toggleHideSettingsBlock('developer_tools');
    expect(provider.isSettingsBlockHidden('developer_tools'), true);
    expect(provider.isSettingsBlockHidden('advanced.developer'), true);

    provider.togglePinSettingsBlock('app_tile_design');
    expect(provider.isSettingsBlockPinned('app_tile_design'), false);

    provider.resetSettingsLayout();
    expect(provider.settingsLayoutConfig.pinnedBlocks.isEmpty, true);
    expect(provider.settingsLayoutConfig.hiddenBlocks.isEmpty, true);
  });
}
