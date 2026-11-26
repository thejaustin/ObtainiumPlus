import 'package:flutter/material.dart';
import 'package:obtainium/models/settings_enums.dart';

extension AppCardTintColor on AppCardTint {
  /// How much of the accent colour is mixed into a card.
  double get strength => switch (this) {
    AppCardTint.standard => 0,
    AppCardTint.tinted => 0.07,
    AppCardTint.vivid => 0.16,
  };

  /// [base] with the scheme's accent colour mixed in.
  Color apply(Color base, ColorScheme cs) => strength == 0
      ? base
      : Color.alphaBlend(cs.primary.withValues(alpha: strength), base);
}
