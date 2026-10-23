import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final reverse in [false, true]) {
    for (final expressive in [false, true]) {
      testWidgets('pushed page ends fully visible '
          '(reverse: $reverse, expressive: $expressive)', (tester) async {
        SharedPreferences.setMockInitialValues({
          'reversePageTransitions': reverse,
          'plusEnableMaterialExpressive': expressive,
        });
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsProvider(prefs);
        final plus = PlusSettingsProvider();
        await plus.initializeSettings(prefs);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: plus),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => pushRoute(
                    context,
                    const Scaffold(body: Center(child: Text('target'))),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('target'), findsOneWidget);
        // #340: a reversed route animation left the page at opacity 0.
        final fades = tester.widgetList<FadeTransition>(
          find.ancestor(
            of: find.text('target'),
            matching: find.byType(FadeTransition),
          ),
        );
        for (final f in fades) {
          expect(f.opacity.value, closeTo(1, 0.001));
        }
        final scales = tester.widgetList<ScaleTransition>(
          find.ancestor(
            of: find.text('target'),
            matching: find.byType(ScaleTransition),
          ),
        );
        for (final s in scales) {
          expect(s.scale.value, closeTo(1, 0.001));
        }
      });
    }
  }
}
