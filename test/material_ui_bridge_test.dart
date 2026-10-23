import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:obtainium/utils/material_ui_bridge.dart';

void main() {
  final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      brightness: Brightness.dark,
    ),
  );

  Future<Color> transitionFill(
    WidgetTester tester, {
    required bool bridge,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark,
        builder: bridge
            ? (context, child) => MaterialUiThemeBridge(child: child!)
            : null,
        home: SharedAxisTransition(
          animation: const AlwaysStoppedAnimation(1),
          secondaryAnimation: const AlwaysStoppedAnimation(0),
          transitionType: SharedAxisTransitionType.horizontal,
          child: const SizedBox.expand(),
        ),
      ),
    );
    return tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(SharedAxisTransition),
            matching: find.byType(ColoredBox),
          ),
        )
        .first
        .color;
  }

  // System updates tab showed a white page in dark mode: animations 3.x
  // reads material_ui's Theme, which defaulted to the light canvas.
  testWidgets('material_ui widgets follow the app theme through the bridge', (
    tester,
  ) async {
    expect(
      (await transitionFill(tester, bridge: false)).computeLuminance(),
      greaterThan(0.5),
      reason: 'sanity: without the bridge the fill is the light default',
    );
    final fill = await transitionFill(tester, bridge: true);
    expect(fill, dark.canvasColor);
  });

  test('bridge mirrors brightness and surface roles', () {
    final m = materialUiThemeFrom(dark);
    expect(m.colorScheme.brightness, Brightness.dark);
    expect(m.colorScheme.surface, dark.colorScheme.surface);
    expect(
      m.colorScheme.surfaceContainerHigh,
      dark.colorScheme.surfaceContainerHigh,
    );
    expect(m, isA<mui.ThemeData>());
  });
}
