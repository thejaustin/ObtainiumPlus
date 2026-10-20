import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// Delegates for the root MaterialApp, shared with widget tests.
///
/// Provides Flutter SDK localizations (GlobalMaterialLocalizations,
/// GlobalWidgetsLocalizations, GlobalCupertinoLocalizations) as well as
/// material_ui's delegates so neither Flutter SDK nor material_ui components
/// throw null checks when looking up localizations in non-English locales (#336/#337/#338).
List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates(
  Iterable<LocalizationsDelegate<dynamic>> easyLocalizationDelegates,
) => [
  ...easyLocalizationDelegates,
  ...GlobalMaterialLocalizations.delegates,
  mui.GlobalMaterialLocalizations.delegate,
  mui.DefaultMaterialLocalizations.delegate,
];
