import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_constants.dart';

/// Utility class for building Material 3 themes with consistent styling
class ThemeBuilder {
  ThemeBuilder._();

  /// Builds a ThemeData instance with the app's Material 3 design system
  static ThemeData buildTheme({
    required ColorScheme colorScheme,
    required bool useSystemFont,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: useSystemFont ? 'SystemFont' : 'Roboto',
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      dropdownMenuTheme: _buildDropdownMenuTheme(colorScheme),
      textTheme: _buildTextTheme(useSystemFont, colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      switchTheme: _buildSwitchTheme(colorScheme),
      sliderTheme: _buildSliderTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      searchBarTheme: _buildSearchBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
    );
  }

  /// Builds InputDecorationTheme with enhanced contrast and Material 3 styling
  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: BorderSide(
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          width: AppConstants.enabledBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: BorderSide(
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          width: AppConstants.enabledBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: AppConstants.focusedBorderWidth,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.inputHorizontalPadding,
        vertical: AppConstants.inputVerticalPadding,
      ),
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds custom text theme with improved readability and spacing
  static TextTheme _buildTextTheme(bool useSystemFont, ColorScheme colorScheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final fontFamily = useSystemFont ? 'SystemFont' : 'Roboto';

    return baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.2, // Increased letter spacing for better readability
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.15,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.15,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.15, // Improved letter spacing for body text
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.15,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
    );
  }

  /// Builds DropdownMenuThemeData with consistent text styling
  static DropdownMenuThemeData _buildDropdownMenuTheme(ColorScheme colorScheme) {
    return DropdownMenuThemeData(
      textStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Builds CardThemeData with M3 tonal elevation
  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  /// Builds ListTileThemeData with proper M3 styling
  static ListTileThemeData _buildListTileTheme(ColorScheme colorScheme) {
    return ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Builds SwitchThemeData using M3 color tokens
  static SwitchThemeData _buildSwitchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return colorScheme.outline;
      }),
    );
  }

  /// Builds SliderThemeData with M3 tonal track and thumb
  static SliderThemeData _buildSliderTheme(ColorScheme colorScheme) {
    return SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withOpacity(0.12),
      valueIndicatorColor: colorScheme.primaryContainer,
      valueIndicatorTextStyle: TextStyle(
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// Builds DialogThemeData with M3 surface container high and rounded corners
  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),
      contentTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  /// Builds BottomSheetThemeData with M3 surface container low and rounded top
  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      modalBackgroundColor: colorScheme.surfaceContainerLow,
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      dragHandleColor: colorScheme.onSurfaceVariant.withOpacity(0.4),
      dragHandleSize: const Size(32, 4),
      showDragHandle: true,
    );
  }

  /// Builds NavigationBarThemeData with proper M3 icon/label theming
  static NavigationBarThemeData _buildNavigationBarTheme(ColorScheme colorScheme) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.onSecondaryContainer);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }
        return TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
      }),
    );
  }

  /// Builds AppBarTheme for consistent app bar styling
  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }

  /// Builds SearchBarThemeData with proper elevation and shape
  static SearchBarThemeData _buildSearchBarTheme(ColorScheme colorScheme) {
    return SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerHigh),
      shape: WidgetStateProperty.all(const StadiumBorder()),
      hintStyle: WidgetStateProperty.all(TextStyle(
        color: colorScheme.onSurfaceVariant,
      )),
      textStyle: WidgetStateProperty.all(TextStyle(
        color: colorScheme.onSurface,
      )),
    );
  }

  /// Builds ChipThemeData for consistent chip styling
  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      disabledColor: colorScheme.onSurface.withOpacity(0.12),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
    );
  }

  /// Builds DividerThemeData with outlineVariant color
  static DividerThemeData _buildDividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    );
  }

  /// Builds SnackBarThemeData with inverse surface colors
  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      actionTextColor: colorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    );
  }
}
