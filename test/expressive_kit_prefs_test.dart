import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expressive-kit keys: defaults preserve today's look, and every key
/// survives a type-flipped value from Obtainium data import (#217).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(AppHaptics.resetPreviewOptions);

  Future<PlusSettingsProvider> load(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final p = PlusSettingsProvider();
    await p.initializeSettings(prefs);
    return p;
  }

  void expectDefaults(PlusSettingsProvider p) {
    expect(p.plusSettingsGroupStyle, SettingsGroupStyle.card);
    expect(p.plusSettingsGroupOuterRadius, 16);
    expect(p.plusSettingsGroupInnerRadius, 4);
    expect(p.plusSwitchStyle, SettingsSwitchStyle.classic);
    expect(p.plusIconMorphOnToggle, isFalse);
    expect(p.plusIconMorphShape, IconMorphShape.squircle);
    expect(p.plusIconMorphStyle, IconMorphStyle.morph);
    expect(p.plusReduceShapeMorphs, isFalse);
    expect(p.plusHapticIntensity, HapticIntensity.standard);
    expect(p.plusHapticFollowSystem, isFalse);
    expect(p.plusNativeHaptics, isFalse);
  }

  const enumKeys = [
    'plusSettingsGroupStyle',
    'plusSwitchStyle',
    'plusIconMorphShape',
    'plusIconMorphStyle',
    'plusHapticIntensity',
  ];
  const boolKeys = [
    'plusIconMorphOnToggle',
    'plusReduceShapeMorphs',
    'plusHapticFollowSystem',
    'plusNativeHaptics',
  ];
  const doubleKeys = [
    'plusSettingsGroupOuterRadius',
    'plusSettingsGroupInnerRadius',
  ];

  test('defaults are the shipped look', () async {
    final p = await load({});
    expectDefaults(p);
    expect(AppHaptics.intensity, HapticIntensity.standard);
    expect(AppHaptics.useNative, isFalse);
    expect(AppHaptics.followSystem, isFalse);
  });

  test('string stored for every new key falls back to defaults', () async {
    final p = await load({
      for (final k in [...enumKeys, ...boolKeys, ...doubleKeys]) k: 'garbage',
    });
    expectDefaults(p);
  });

  test('wrong primitive types fall back to defaults', () async {
    final p = await load({
      for (final k in enumKeys) k: true,
      for (final k in boolKeys) k: 3,
      for (final k in doubleKeys) k: <String>['x'],
    });
    expectDefaults(p);
  });

  test('out-of-range enum index falls back to defaults', () async {
    final p = await load({for (final k in enumKeys) k: 99});
    expectDefaults(p);
    final q = await load({for (final k in enumKeys) k: -1});
    expectDefaults(q);
  });

  test('int stored for the radii is coerced', () async {
    final p = await load({
      'plusSettingsGroupOuterRadius': 20,
      'plusSettingsGroupInnerRadius': 8,
    });
    expect(p.plusSettingsGroupOuterRadius, 20.0);
    expect(p.plusSettingsGroupInnerRadius, 8.0);
  });

  test('radii are clamped: outer 0-28, inner never above outer', () async {
    final p = await load({
      'plusSettingsGroupOuterRadius': 99.0,
      'plusSettingsGroupInnerRadius': -3.0,
    });
    expect(p.plusSettingsGroupOuterRadius, 28.0);
    expect(p.plusSettingsGroupInnerRadius, 0.0);

    final q = await load({
      'plusSettingsGroupOuterRadius': 6.0,
      'plusSettingsGroupInnerRadius': 12.0,
    });
    expect(q.plusSettingsGroupInnerRadius, 6.0);
  });

  test('"true"/"false" strings for bools are honoured', () async {
    final p = await load({for (final k in boolKeys) k: 'true'});
    expect(p.plusIconMorphOnToggle, isTrue);
    expect(p.plusReduceShapeMorphs, isTrue);
    expect(p.plusHapticFollowSystem, isTrue);
    expect(p.plusNativeHaptics, isTrue);
    expect(AppHaptics.useNative, isTrue);
    expect(AppHaptics.followSystem, isTrue);
  });

  test('haptic statics follow setters, clearCache and reset', () async {
    final p = await load({});
    p.plusHapticIntensity = HapticIntensity.strong;
    p.plusNativeHaptics = true;
    expect(AppHaptics.intensity, HapticIntensity.strong);
    expect(AppHaptics.useNative, isTrue);

    // Import rewrites prefs then calls clearCache: statics must follow.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('plusHapticIntensity', HapticIntensity.subtle.index);
    await prefs.setBool('plusNativeHaptics', false);
    p.clearCache();
    expect(AppHaptics.intensity, HapticIntensity.subtle);
    expect(AppHaptics.useNative, isFalse);

    p.plusSwitchStyle = SettingsSwitchStyle.shapeThumb;
    p.plusSettingsGroupStyle = SettingsGroupStyle.segmented;
    p.resetVisualLab();
    expectDefaults(p);
    expect(AppHaptics.intensity, HapticIntensity.standard);
  });
}
