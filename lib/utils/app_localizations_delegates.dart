import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as mui;

/// Delegates for the root MaterialApp, shared with widget tests.
///
/// material_ui widgets (TextField, NavigationBar, ...) look up material_ui's
/// own MaterialLocalizations type, which easy_localization's delegates do not
/// provide. The Default delegate only supports 'en', so without the Global one
/// every other locale crashed with a null check on the first TextField
/// (#336/#337). Default stays last as the fallback for unlisted languages.
List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates(
  Iterable<LocalizationsDelegate<dynamic>> easyLocalizationDelegates,
) => [
  ...easyLocalizationDelegates,
  mui.GlobalMaterialLocalizations.delegate,
  mui.DefaultMaterialLocalizations.delegate,
];
