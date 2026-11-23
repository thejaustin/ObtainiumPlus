import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:obtainium/utils/theme_style.dart';
import 'package:obtainium/utils/upstream_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

ColorScheme _scheme(AppThemeStyle style, Brightness brightness) =>
    applyPlusAccent(
      ColorScheme.fromSeed(
        seedColor: obtainiumSeedColor,
        brightness: brightness,
        dynamicSchemeVariant: defaultVariantFor(style),
      ),
      style,
    );

void main() {
  for (final style in AppThemeStyle.values) {
    for (final brightness in Brightness.values) {
      test('${style.name} ${brightness.name}: contrast and theme build', () {
        final s = _scheme(style, brightness);
        expect(_contrast(s.primary, s.onPrimary), greaterThanOrEqualTo(4.5));
        expect(_contrast(s.tertiary, s.onTertiary), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(s.tertiaryContainer, s.onTertiaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        final data = style.isExpressive
            ? ThemeBuilder.buildTheme(colorScheme: s, useSystemFont: false)
            : buildUpstreamTheme(s, useSystemFont: false);
        expect(data.colorScheme, s);
        expect(data.useMaterial3, isTrue);
      });
    }
  }

  test('Plus styles tint tertiary gold-ward, others keep the seed scheme', () {
    final plain = _scheme(AppThemeStyle.obtainium, Brightness.light);
    final plus = _scheme(AppThemeStyle.obtainiumPlus, Brightness.light);
    expect(plus.primary, plain.primary);
    expect(plus.tertiary, isNot(plain.tertiary));
  });

  group('migration', () {
    Future<ThemeSettingsProvider> load(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final p = ThemeSettingsProvider();
      await p.initializeSettings(await SharedPreferences.getInstance());
      return p;
    }

    test('fresh install defaults to Obtainium+', () async {
      expect((await load({})).themeStyle, AppThemeStyle.obtainiumPlus);
    });

    test('existing install keeps its look', () async {
      expect(
        (await load({'theme': 1})).themeStyle,
        AppThemeStyle.expressivePlus,
      );
      expect(
        (await load({
          'theme': 1,
          'plusEnableMaterialExpressive': false,
          'plusEnableGlassmorphism': false,
        })).themeStyle,
        AppThemeStyle.obtainium,
      );
    });

    test('type-flipped value falls back to the default', () async {
      expect(
        (await load({'appThemeStyle': 'junk'})).themeStyle,
        AppThemeStyle.obtainiumPlus,
      );
    });
  });
}
