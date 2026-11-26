import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/utils/card_tint.dart';

void main() {
  final cs = ColorScheme.fromSeed(seedColor: Colors.teal);
  const base = Color(0xFFEEEEEE);

  test('standard leaves the card colour alone', () {
    expect(AppCardTint.standard.apply(base, cs), base);
  });

  test('stronger tints move the colour further toward the accent', () {
    double dist(Color c) =>
        (c.r - cs.primary.r).abs() +
        (c.g - cs.primary.g).abs() +
        (c.b - cs.primary.b).abs();
    final tinted = dist(AppCardTint.tinted.apply(base, cs));
    final vivid = dist(AppCardTint.vivid.apply(base, cs));
    expect(tinted, lessThan(dist(base)));
    expect(vivid, lessThan(tinted));
  });

  test('only ever append enum members (stored by index)', () {
    expect(AppCardTint.values.first, AppCardTint.standard);
  });
}
