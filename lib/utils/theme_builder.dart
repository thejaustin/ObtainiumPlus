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
      fontFamily: useSystemFont ? 'SystemFont' : 'Montserrat',
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      dropdownMenuTheme: _buildDropdownMenuTheme(colorScheme),
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
}
