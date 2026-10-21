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
    bool isTV = false,
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
        sliderTheme: const SliderThemeData(year2023: false),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          year2023: false,
        ),
        focusColor: isTV ? colorScheme.primary.withValues(alpha: 0.4) : null,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );
    }
    final tvFocus = _TvFocus(isTV, colorScheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      focusColor: isTV ? colorScheme.primary.withValues(alpha: 0.4) : null,
      canvasColor: colorScheme.surfaceContainerHigh,
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: plusEnableMaterialExpressive ? 6 : 3,
        shape: _shape(
          plusEnableMaterialExpressive,
          plusEnableMaterialExpressive ? 20 : 14,
          BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: ShapeDecoration(
          color: colorScheme.inverseSurface,
          shape: _shape(
            plusEnableMaterialExpressive,
            plusEnableMaterialExpressive ? 12 : 8,
          ),
        ),
        textStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 12,
          fontWeight: plusEnableMaterialExpressive
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        textStyle: TextStyle(
          fontSize: 11,
          fontWeight: plusEnableMaterialExpressive
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
      fontFamily: useSystemFont ? 'SystemFont' : 'Montserrat',
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
      dropdownMenuTheme: _buildDropdownMenuTheme(
        colorScheme,
        plusEnableMaterialExpressive,
      ),
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
      switchTheme: _buildSwitchTheme(
        colorScheme,
        plusEnableMaterialExpressive,
        tvFocus,
      ),
      sliderTheme: _buildSliderTheme(colorScheme, plusEnableMaterialExpressive),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: colorScheme.primary,
        collapsedIconColor: colorScheme.onSurfaceVariant,
      ),
      floatingActionButtonTheme: _buildFabTheme(
        colorScheme,
        plusEnableMaterialExpressive,
      ),
      iconButtonTheme: tvFocus.enabled
          ? IconButtonThemeData(style: tvFocus.buttonStyle(0.5))
          : null,
      checkboxTheme: tvFocus.enabled
          ? CheckboxThemeData(overlayColor: tvFocus.overlay(0.5))
          : null,
      radioTheme: tvFocus.enabled
          ? RadioThemeData(overlayColor: tvFocus.overlay(0.5))
          : null,
      segmentedButtonTheme: _buildSegmentedButtonTheme(
        colorScheme,
        plusEnableMaterialExpressive,
        cornerRadius,
        tvFocus,
      ),
      menuButtonTheme: tvFocus.enabled
          ? MenuButtonThemeData(style: tvFocus.buttonStyle(0.35))
          : null,
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
      navigationBarTheme: _buildNavigationBarTheme(
        colorScheme,
        plusEnableMaterialExpressive,
      ),
      appBarTheme: _buildAppBarTheme(colorScheme, plusEnableMaterialExpressive),
      searchBarTheme: _buildSearchBarTheme(
        colorScheme,
        plusEnableMaterialExpressive,
      ),
      elevatedButtonTheme: _buildElevatedButtonTheme(
        cornerRadius,
        plusEnableMaterialExpressive,
        tvFocus,
      ),
      filledButtonTheme: _buildFilledButtonTheme(
        cornerRadius,
        plusEnableMaterialExpressive,
        tvFocus,
      ),
      textButtonTheme: _buildTextButtonTheme(
        cornerRadius,
        plusEnableMaterialExpressive,
        tvFocus,
      ),
      outlinedButtonTheme: _buildOutlinedButtonTheme(
        cornerRadius,
        plusEnableMaterialExpressive,
        tvFocus,
      ),
      chipTheme: _buildChipTheme(colorScheme, plusEnableMaterialExpressive),
      dividerTheme: _buildDividerTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(
        colorScheme,
        plusEnableMaterialExpressive,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        refreshBackgroundColor: colorScheme.surfaceContainerHigh,
        strokeWidth: 3.0,
        year2023: false,
      ),
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
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: AppOpacity.half,
          ),
          width: AppConstants.enabledBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: colorScheme.onSurfaceVariant.withValues(
            alpha: AppOpacity.half,
          ),
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
    final fontFamily = useSystemFont ? 'SystemFont' : 'Montserrat';

    if (!expressive) {
      return baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontFamily: fontFamily,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontFamily: fontFamily,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontFamily: fontFamily,
        ),
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
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.12,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.18,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.22,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        height: 1.25,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.2,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.2,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontFamily: fontFamily,
        letterSpacing: 0.35,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  /// Builds DropdownMenuThemeData with consistent text styling and squircle menu
  static DropdownMenuThemeData _buildDropdownMenuTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
    return DropdownMenuThemeData(
      textStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: expressive ? FontWeight.w600 : FontWeight.w500,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerHigh,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          _shape(
            expressive,
            expressive ? 20 : 14,
            BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  /// CardThemeData with M3 tonal elevation, subtle border contrast, and configurable radius
  static CardThemeData _buildCardTheme(
    ColorScheme colorScheme,
    bool expressive,
    double? cornerRadius,
  ) {
    final borderSide = BorderSide(
      color: colorScheme.outlineVariant.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.35 : 0.65,
      ),
      width: 0.8,
    );
    return CardThemeData(
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: _shape(
        expressive,
        cornerRadius ?? (expressive ? 24 : 12),
        borderSide,
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
      shape: _shape(
        expressive,
        cornerRadius != null
            ? (cornerRadius * 0.66).clamp(8.0, 16.0)
            : (expressive ? 16 : 12),
      ),
    );
  }

  /// Builds SwitchThemeData using M3 / M3E color tokens
  static SwitchThemeData _buildSwitchTheme(
    ColorScheme colorScheme,
    bool expressive,
    _TvFocus tvFocus,
  ) {
    return SwitchThemeData(
      overlayColor: tvFocus.overlay(0.5),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return expressive ? colorScheme.onSurfaceVariant : colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.surfaceContainerHighest.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return expressive
            ? colorScheme.outlineVariant.withValues(alpha: 0.85)
            : colorScheme.outline;
      }),
      trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return 0.0;
        }
        return expressive ? 1.5 : 2.0;
      }),
      thumbIcon: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Icon(
            Icons.check_rounded,
            size: 16,
            color: colorScheme.primary,
          );
        }
        return Icon(
          Icons.close_rounded,
          size: 16,
          color: colorScheme.surfaceContainerHighest,
        );
      }),
    );
  }

  /// Builds SliderThemeData with M3 tonal track and thumb
  static SliderThemeData _buildSliderTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
    return SliderThemeData(
      // Opts into the M3 Expressive slider (16dp track, bar handle with gap)
      // when Material 3 Expressive is active; uses sleek classic track in
      // Obtainium+ Theme mode.
      // ignore: deprecated_member_use
      year2023: !expressive,
      showValueIndicator: ShowValueIndicator.onDrag,
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: AppOpacity.hint),
      valueIndicatorColor: colorScheme.primaryContainer,
      valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
    );
  }

  /// Builds SegmentedButtonThemeData with expressive squircles or classic pills
  static SegmentedButtonThemeData _buildSegmentedButtonTheme(
    ColorScheme colorScheme,
    bool expressive,
    double? cornerRadius,
    _TvFocus tvFocus,
  ) {
    final radius = (cornerRadius ?? (expressive ? 16.0 : 12.0)).clamp(
      10.0,
      20.0,
    );
    return SegmentedButtonThemeData(
      style: ButtonStyle(
        overlayColor: tvFocus.overlay(0.45),
        shape: WidgetStateProperty.all(
          _shape(
            expressive,
            radius,
            BorderSide(
              color: colorScheme.outlineVariant.withValues(
                alpha: colorScheme.brightness == Brightness.dark ? 0.45 : 0.7,
              ),
            ),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerLow;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
        textStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 13,
          );
        }),
      ),
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
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: _shape(expressive, cornerRadius ?? (expressive ? 32 : 28)),
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
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: expressive
          ? RoundedSuperellipseBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            )
          : RoundedRectangleBorder(
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
    bool expressive,
  ) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      indicatorColor: colorScheme.primaryContainer,
      indicatorShape: expressive
          ? RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16))
          : const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.onPrimaryContainer);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: colorScheme.onSurface,
            fontSize: 12,
            fontWeight: expressive ? FontWeight.w700 : FontWeight.w500,
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
  static AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
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
        fontWeight: expressive ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: expressive ? -0.2 : 0.15,
      ),
    );
  }

  /// Builds SearchBarThemeData with proper elevation and shape
  static SearchBarThemeData _buildSearchBarTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
    return SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerHigh,
      ),
      shape: WidgetStateProperty.resolveWith((states) {
        final isFocused = states.contains(WidgetState.focused);
        return _shape(
          expressive,
          isFocused ? 18.0 : 28.0,
          BorderSide(
            color: isFocused
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isFocused ? 1.5 : 1.0,
          ),
        );
      }),
      hintStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  /// Builds ChipThemeData for consistent chip styling (M3E squircle vs classic M3)
  static ChipThemeData _buildChipTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      disabledColor: colorScheme.onSurface.withValues(alpha: AppOpacity.hint),
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontWeight: expressive ? FontWeight.w600 : FontWeight.w500,
      ),
      secondaryLabelStyle: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontWeight: expressive ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: expressive
          ? RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(12))
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: expressive
            ? colorScheme.outlineVariant.withValues(alpha: 0.55)
            : colorScheme.outline.withValues(alpha: AppOpacity.half),
      ),
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

  /// Builds SnackBarThemeData with inverse surface colors and M3 floating shape
  static SnackBarThemeData _buildSnackBarTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      actionTextColor: colorScheme.inversePrimary,
      shape: _shape(expressive, 16),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    double? cornerRadius,
    bool expressive,
    _TvFocus tvFocus,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        overlayColor: tvFocus.enabled ? tvFocus.color(0.4) : null,
        textStyle: TextStyle(
          fontWeight: expressive ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: expressive ? 0.1 : 0.2,
        ),
        shape: cornerRadius != null
            ? _shape(expressive, cornerRadius.clamp(0.0, 24.0))
            : const StadiumBorder(),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(
    double? cornerRadius,
    bool expressive,
    _TvFocus tvFocus,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        overlayColor: tvFocus.enabled ? tvFocus.color(0.4) : null,
        textStyle: TextStyle(
          fontWeight: expressive ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: expressive ? 0.1 : 0.2,
        ),
        shape: cornerRadius != null
            ? _shape(expressive, cornerRadius.clamp(0.0, 24.0))
            : const StadiumBorder(),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(
    double? cornerRadius,
    bool expressive,
    _TvFocus tvFocus,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        overlayColor: tvFocus.enabled ? tvFocus.color(0.4) : null,
        textStyle: TextStyle(
          fontWeight: expressive ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: expressive ? 0.1 : 0.2,
        ),
        shape: cornerRadius != null
            ? _shape(expressive, cornerRadius.clamp(0.0, 24.0))
            : const StadiumBorder(),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    double? cornerRadius,
    bool expressive,
    _TvFocus tvFocus,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        overlayColor: tvFocus.enabled ? tvFocus.color(0.4) : null,
        textStyle: TextStyle(
          fontWeight: expressive ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: expressive ? 0.1 : 0.2,
        ),
        shape: cornerRadius != null
            ? _shape(expressive, cornerRadius.clamp(0.0, 24.0))
            : const StadiumBorder(),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(
    ColorScheme colorScheme,
    bool expressive,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      shape: _shape(expressive, expressive ? 20 : 16),
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 8,
      highlightElevation: 6,
    );
  }

  /// Squircle corners in expressive mode, plain rounded corners otherwise.
  static OutlinedBorder _shape(
    bool expressive,
    double radius, [
    BorderSide side = BorderSide.none,
  ]) {
    final borderRadius = BorderRadius.circular(radius);
    return expressive
        ? RoundedSuperellipseBorder(borderRadius: borderRadius, side: side)
        : RoundedRectangleBorder(borderRadius: borderRadius, side: side);
  }
}

/// Strong focus overlays for TV, where the D-pad focus highlight is the only
/// cursor; the stock 12% overlay is invisible from across a room.
class _TvFocus {
  const _TvFocus(this.enabled, this.colorScheme);

  final bool enabled;
  final ColorScheme colorScheme;

  Color color(double alpha) => colorScheme.primary.withValues(alpha: alpha);

  WidgetStateProperty<Color?>? overlay(double alpha) {
    if (!enabled) return null;
    final focused = color(alpha);
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.focused)) return focused;
      if (states.contains(WidgetState.hovered)) {
        return focused.withValues(alpha: alpha * 0.4);
      }
      return null;
    });
  }

  ButtonStyle buttonStyle(double alpha) =>
      ButtonStyle(overlayColor: overlay(alpha));
}
