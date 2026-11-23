import 'package:flutter/material.dart';

/// The upstream Obtainium look (rounded superellipse shapes, stadium buttons,
/// borderless filled inputs, fade-forwards transitions) used by the
/// Obtainium and Obtainium+ styles. [radiusScale] stays at 1 for the pure
/// upstream look; Obtainium+ passes a value below 1 for sharper corners.
ThemeData buildUpstreamTheme(
  ColorScheme colorScheme, {
  required bool useSystemFont,
  bool isTV = false,
  double radiusScale = 1,
}) {
  double r(double v) => v * radiusScale;
  RoundedSuperellipseBorder shape(double radius) => RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(r(radius)),
  );

  final cardShape = shape(24);
  final dialogShape = shape(28);
  final fieldShape = shape(16);
  const buttonShape = StadiumBorder();

  WidgetStateProperty<Color?>? focusOverlay(double alpha) {
    if (!isTV) return null;
    final focused = colorScheme.primary.withValues(alpha: alpha);
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.focused)) return focused;
      if (states.contains(WidgetState.hovered)) {
        return focused.withValues(alpha: alpha * 0.4);
      }
      return null;
    });
  }

  final pillButtonStyle = ButtonStyle(
    shape: const WidgetStatePropertyAll(buttonShape),
    minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
    overlayColor: focusOverlay(0.4),
  );

  const inputDecoration = InputDecorationThemeData(
    filled: true,
    contentPadding: EdgeInsets.all(16),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: useSystemFont ? 'SystemFont' : 'Montserrat',
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: cardShape,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(shape: dialogShape),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape(16),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r(28))),
      ),
    ),
    appBarTheme: const AppBarThemeData(centerTitle: false),
    expansionTileTheme: ExpansionTileThemeData(
      shape: cardShape,
      collapsedShape: cardShape,
    ),
    listTileTheme: ListTileThemeData(shape: fieldShape),
    chipTheme: const ChipThemeData(shape: StadiumBorder()),
    focusColor: isTV ? colorScheme.primary.withValues(alpha: 0.4) : null,
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(overlayColor: focusOverlay(0.5)),
    ),
    searchBarTheme: const SearchBarThemeData(
      elevation: WidgetStatePropertyAll(0),
    ),
    filledButtonTheme: FilledButtonThemeData(style: pillButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: pillButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: pillButtonStyle),
    textButtonTheme: TextButtonThemeData(style: pillButtonStyle),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: shape(20),
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
      highlightElevation: 6,
    ),
    inputDecorationTheme: inputDecoration,
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: inputDecoration,
      menuStyle: MenuStyle(shape: WidgetStatePropertyAll(shape(16))),
    ),
    sliderTheme: const SliderThemeData(
      // ignore: deprecated_member_use
      year2023: false,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      // ignore: deprecated_member_use
      year2023: false,
    ),
  );
}
