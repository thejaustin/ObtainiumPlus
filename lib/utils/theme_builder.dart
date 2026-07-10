import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:obtainium/utils/app_constants.dart';

/// Utility class for building Material 3 themes with consistent styling
class ThemeBuilder {
  ThemeBuilder._();

  /// Builds a ThemeData instance with the app's Material 3 design system
  static ThemeData buildTheme({
    required ColorScheme colorScheme,
    required bool useSystemFont,
    bool plusEnableMaterialExpressive = true,
    double? cornerRadius,
    bool matchSystemMaterialStyle = false,
  }) {
    // "Match system Material style": follow the device look as closely as
    // possible — the (untouched) dynamic colour scheme, the system font, and
    // stock Material 3 component shapes/elevations/motion. This is a
    // presentation-time override only: the user's other saved toggles are
    // simply not applied while it is on and take effect again when it is
    // turned off.
    if (matchSystemMaterialStyle) {
      return ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'SystemFont',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: useSystemFont ? 'SystemFont' : 'Roboto',
      // M3 sparkle ripple is the expressive touch feedback; shader-based, so
      // it also avoids the clipped-ripple artifacts of the legacy ink splash
      splashFactory: plusEnableMaterialExpressive
          ? InkSparkle.splashFactory
          : InkRipple.splashFactory,
      inputDecorationTheme: _buildInputDecorationTheme(
        colorScheme,
        plusEnableMaterialExpressive,
        cornerRadius,
      ),
      dropdownMenuTheme: _buildDropdownMenuTheme(colorScheme),
      textTheme: _buildTextTheme(
        useSystemFont,
        colorScheme,
        plusEnableMaterialExpressive,
      ),
      cardTheme: _buildCardTheme(
        colorScheme,
        plusEnableMaterialExpressive,
        cornerRadius,
      ),
      listTileTheme: _buildListTileTheme(
        colorScheme,
        plusEnableMaterialExpressive,
        cornerRadius,
      ),
      switchTheme: _buildSwitchTheme(colorScheme),
      sliderTheme: _buildSliderTheme(colorScheme),
      dialogTheme: _buildDialogTheme(
        colorScheme,
        plusEnableMaterialExpressive,
        cornerRadius,
      ),
      bottomSheetTheme: _buildBottomSheetTheme(
        colorScheme,
        plusEnableMaterialExpressive,
        cornerRadius,
      ),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      searchBarTheme: _buildSearchBarTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(cornerRadius),
      filledButtonTheme: _buildFilledButtonTheme(cornerRadius),
      textButtonTheme: _buildTextButtonTheme(cornerRadius),
      outlinedButtonTheme: _buildOutlinedButtonTheme(cornerRadius),
      chipTheme: _buildChipTheme(colorScheme, plusEnableMaterialExpressive),
      dividerTheme: _buildDividerTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      progressIndicatorTheme: const ProgressIndicatorThemeData(),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        opacity: 1.0,
        size: 24,
      ),
      primaryIconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        opacity: 1.0,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          // Expressive mode gets the modern M3 emphasized forward-fade
          // transition; otherwise fall back to the system predictive-back
          // transition
          TargetPlatform.android: plusEnableMaterialExpressive
              ? const FadeForwardsPageTransitionsBuilder()
              : const PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Builds InputDecorationTheme with enhanced contrast and Material 3 styling
  static InputDecorationTheme _buildInputDecorationTheme(
    ColorScheme colorScheme,
    bool expressive,
    double? cornerRadius,
  ) {
    final borderRadius =
        cornerRadius ?? (expressive ? AppConstants.defaultBorderRadius : 12.0);
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: colorScheme.onSurfaceVariant.withValues(alpha: AppOpacity.half),
          width: AppConstants.enabledBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: colorScheme.onSurfaceVariant.withValues(alpha: AppOpacity.half),
          width: AppConstants.enabledBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
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
  static TextTheme _buildTextTheme(
    bool useSystemFont,
    ColorScheme colorScheme,
    bool expressive,
  ) {
    final baseTextTheme = colorScheme.brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final fontFamily = useSystemFont ? 'SystemFont' : 'Roboto';

    if (!expressive) {
      return baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontFamily: fontFamily,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontFamily: fontFamily,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontFamily: fontFamily,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: fontFamily),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontFamily: fontFamily,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: fontFamily),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: fontFamily),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: fontFamily),
        bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: fontFamily),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: fontFamily),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontFamily: fontFamily,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: fontFamily),
      );
    }

    return baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.25,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.25,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.4,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Builds DropdownMenuThemeData with consistent text styling
  static DropdownMenuThemeData _buildDropdownMenuTheme(
    ColorScheme colorScheme,
  ) {
    return DropdownMenuThemeData(
      textStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// CardThemeData with M3 tonal elevation and configurable radius
  static CardThemeData _buildCardTheme(
    ColorScheme colorScheme,
    bool expressive,
    double? cornerRadius,
  ) {
    return CardThemeData(
      color: colorScheme.surfaceContainerLow,
      // M3 tonal elevation: hierarchy comes from the surface container
      // colour, not shadows (heavy shadows also read muddy on the pure-black
      // AMOLED theme)
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          cornerRadius ?? (expressive ? 24 : 12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  /// ListTileThemeData with proper M3 styling and configurable radius
  static ListTileThemeData _buildListTileTheme(
    ColorScheme colorScheme,
    bool expressive,
    double? cornerRadius,
  ) {
    return ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          cornerRadius != null
              ? (cornerRadius * 0.66).clamp(8.0, 16.0)
              : (expressive ? 16 : 12),
        ),
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
      overlayColor: colorScheme.primary.withValues(alpha: AppOpacity.hint),
      valueIndicatorColor: colorScheme.primaryContainer,
      valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
    );
  }

  /// DialogThemeData with M3 surface container high and configurable radius
  static DialogThemeData _buildDialogTheme(
    ColorScheme colorScheme,
    bool expressive,
    double? cornerRadius,
  ) {
    return DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          cornerRadius ?? (expressive ? 32 : 28),
        ),
      ),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 24,
        fontWeight: expressive ? FontWeight.w600 : FontWeight.w400,
      ),
      contentTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  /// BottomSheetThemeData with M3 surface container low and configurable radius
  static BottomSheetThemeData _buildBottomSheetTheme(
    ColorScheme colorScheme,
    bool expressive,
    double? cornerRadius,
  ) {
    final radius = cornerRadius ?? (expressive ? 32 : 28);
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      modalBackgroundColor: colorScheme.surfaceContainerLow,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      dragHandleColor: colorScheme.onSurfaceVariant.withValues(
        alpha: AppOpacity.moderate,
      ),
      dragHandleSize: Size(expressive ? 40 : 32, 4),
      showDragHandle: true,
    );
  }

  /// Builds NavigationBarThemeData with proper M3 icon/label theming
  static NavigationBarThemeData _buildNavigationBarTheme(
    ColorScheme colorScheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      elevation: 3,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
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
      backgroundColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerHigh,
      ),
      shape: WidgetStateProperty.all(const StadiumBorder()),
      hintStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  /// Builds ChipThemeData for consistent chip styling
  static ChipThemeData _buildChipTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.secondaryContainer,
      disabledColor: colorScheme.onSurface.withValues(alpha: AppOpacity.hint),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
      shape: expressive
          ? const StadiumBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: colorScheme.outline.withValues(alpha: AppOpacity.half)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(double? cornerRadius) {
    if (cornerRadius == null) return const ElevatedButtonThemeData();
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius.clamp(0.0, 20.0)),
        ),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(double? cornerRadius) {
    if (cornerRadius == null) return const FilledButtonThemeData();
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius.clamp(0.0, 20.0)),
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(double? cornerRadius) {
    if (cornerRadius == null) return const TextButtonThemeData();
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius.clamp(0.0, 20.0)),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(double? cornerRadius) {
    if (cornerRadius == null) return const OutlinedButtonThemeData();
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius.clamp(0.0, 20.0)),
        ),
      ),
    );
  }
}
