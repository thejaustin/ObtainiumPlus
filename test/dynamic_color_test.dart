import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:obtainium/utils/dynamic_color_utils.dart';

void main() {
  test('core palette maps to complete light and dark schemes', () {
    final palette = CorePalette.of(0xFF3F51B5);
    final light = corePaletteToColorScheme(palette);
    final dark = corePaletteToColorScheme(palette, brightness: Brightness.dark);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    // Surfaces come from the neutral palette, so light is light and dark dark.
    expect(light.surface.computeLuminance(), greaterThan(0.8));
    expect(dark.surface.computeLuminance(), lessThan(0.1));
    expect(light.surfaceContainerHighest, isNot(light.surface));
    expect(light.primary, isNot(dark.primary));
  });
}
