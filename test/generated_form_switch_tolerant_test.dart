import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/generated_form_renderer.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('a switch whose stored value is text does not crash the form', (
    tester,
  ) async {
    final item = GeneratedFormSwitch('flag', label: 'Flag');
    item.value = 'true'; // OBTAINIUMPLUS-41: String read as bool
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: GeneratedForm(
              items: [
                [item],
              ],
              onValueChanges: (_, _, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsOneWidget);
  });
}
