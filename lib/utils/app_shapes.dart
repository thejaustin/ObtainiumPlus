import 'package:flutter/material.dart';

/// Corner geometry. Flutter's squircle has no smoothing parameter, so the
/// "in between" look is a family choice rather than a continuous blend.
enum ShapeFamily { rounded, squircle, bevel }

/// UI element groups that can carry their own corner override.
enum ShapeRole {
  pill,
  button,
  card,
  collection,
  dialog,
  sheet,
  input,
  chip,
  fab,
  segmented,
}

extension ShapeRoleX on ShapeRole {
  /// Multiplier on the global radius when a role has no override.
  double get defaultScale => switch (this) {
    ShapeRole.input || ShapeRole.chip => 0.5,
    _ => 1.0,
  };
}

/// Resolved corner shapes for the whole app. Lives in [ThemeData.extensions]
/// so widgets read it with `AppShapes.of(context)`.
@immutable
class AppShapes extends ThemeExtension<AppShapes> {
  const AppShapes({
    this.radius = 28,
    this.family = ShapeFamily.rounded,
    this.radiusOverrides = const {},
    this.familyOverrides = const {},
  });

  final double radius;
  final ShapeFamily family;
  final Map<ShapeRole, double> radiusOverrides;
  final Map<ShapeRole, ShapeFamily> familyOverrides;

  static const fallback = AppShapes();

  static AppShapes of(BuildContext context) =>
      Theme.of(context).extension<AppShapes>() ?? fallback;

  double radiusOf(ShapeRole role) =>
      (radiusOverrides[role] ?? radius * role.defaultScale).clamp(0.0, 64.0);

  ShapeFamily familyOf(ShapeRole role) => familyOverrides[role] ?? family;

  BorderRadius borderRadiusOf(ShapeRole role) =>
      BorderRadius.circular(radiusOf(role));

  OutlinedBorder borderOf(ShapeRole role, {BorderSide side = BorderSide.none}) {
    final r = borderRadiusOf(role);
    return switch (familyOf(role)) {
      ShapeFamily.rounded => RoundedRectangleBorder(
        borderRadius: r,
        side: side,
      ),
      ShapeFamily.squircle => RoundedSuperellipseBorder(
        borderRadius: r,
        side: side,
      ),
      ShapeFamily.bevel => BeveledRectangleBorder(borderRadius: r, side: side),
    };
  }

  @override
  AppShapes copyWith({
    double? radius,
    ShapeFamily? family,
    Map<ShapeRole, double>? radiusOverrides,
    Map<ShapeRole, ShapeFamily>? familyOverrides,
  }) => AppShapes(
    radius: radius ?? this.radius,
    family: family ?? this.family,
    radiusOverrides: radiusOverrides ?? this.radiusOverrides,
    familyOverrides: familyOverrides ?? this.familyOverrides,
  );

  @override
  AppShapes lerp(ThemeExtension<AppShapes>? other, double t) {
    if (other is! AppShapes) return this;
    final src = t < 0.5 ? this : other;
    double at(ShapeRole r) =>
        (radiusOf(r) + (other.radiusOf(r) - radiusOf(r)) * t);
    return AppShapes(
      radius: radius + (other.radius - radius) * t,
      family: src.family,
      radiusOverrides: {for (final r in ShapeRole.values) r: at(r)},
      familyOverrides: {for (final r in ShapeRole.values) r: src.familyOf(r)},
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppShapes &&
      other.radius == radius &&
      other.family == family &&
      _mapEq(other.radiusOverrides, radiusOverrides) &&
      _mapEq(other.familyOverrides, familyOverrides);

  @override
  int get hashCode => Object.hash(
    radius,
    family,
    Object.hashAllUnordered(
      radiusOverrides.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(
      familyOverrides.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  static bool _mapEq<V>(Map<ShapeRole, V> a, Map<ShapeRole, V> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}

ButtonStyle? _shaped(ButtonStyle? s, OutlinedBorder shape) =>
    (s ?? const ButtonStyle()).copyWith(shape: WidgetStatePropertyAll(shape));

InputBorder? _inputBorder(InputBorder? b, BorderRadius r) =>
    b is OutlineInputBorder ? b.copyWith(borderRadius: r) : b;

/// Applies [shapes] to the component themes of [base] and attaches the
/// extension. Keeps both theme builders untouched.
ThemeData applyAppShapes(ThemeData base, AppShapes shapes) {
  final button = shapes.borderOf(ShapeRole.button);
  final inputR = shapes.borderRadiusOf(ShapeRole.input);
  final input = base.inputDecorationTheme;
  return base.copyWith(
    extensions: [
      ...base.extensions.values.where((e) => e is! AppShapes),
      shapes,
    ],
    filledButtonTheme: FilledButtonThemeData(
      style: _shaped(base.filledButtonTheme.style, button),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _shaped(base.elevatedButtonTheme.style, button),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _shaped(base.outlinedButtonTheme.style, button),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _shaped(base.textButtonTheme.style, button),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: _shaped(base.iconButtonTheme.style, button),
    ),
    cardTheme: base.cardTheme.copyWith(
      shape: shapes.borderOf(
        ShapeRole.card,
        side: base.cardTheme.shape is OutlinedBorder
            ? (base.cardTheme.shape! as OutlinedBorder).side
            : BorderSide.none,
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      shape: shapes.borderOf(ShapeRole.dialog),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      shape: shapes.borderOf(ShapeRole.sheet),
    ),
    searchBarTheme: base.searchBarTheme.copyWith(
      shape: WidgetStatePropertyAll(shapes.borderOf(ShapeRole.pill)),
    ),
    chipTheme: base.chipTheme.copyWith(shape: shapes.borderOf(ShapeRole.chip)),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      shape: shapes.borderOf(ShapeRole.fab),
    ),
    segmentedButtonTheme: base.segmentedButtonTheme.copyWith(
      style: _shaped(
        base.segmentedButtonTheme.style,
        shapes.borderOf(ShapeRole.segmented),
      ),
    ),
    inputDecorationTheme: input.copyWith(
      border: _inputBorder(input.border, inputR),
      enabledBorder: _inputBorder(input.enabledBorder, inputR),
      focusedBorder: _inputBorder(input.focusedBorder, inputR),
    ),
  );
}
