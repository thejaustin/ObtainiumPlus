import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/generated_form_model.dart';
import 'package:obtainium/components/generated_form_renderer.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('removing a sub-form entry keeps the next entry\'s values', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final plus = PlusSettingsProvider();
    final settings = SettingsProvider();
    await tester.runAsync(() async {
      await plus.initializeSettings(await SharedPreferences.getInstance());
      await settings.initializeSettings();
    });

    final subForm = GeneratedFormSubForm(
      'entries',
      [
        [GeneratedFormTextField('name', label: 'Name')],
      ],
      label: 'Entry',
      value: [
        {'name': 'first'},
        {'name': 'second'},
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: plus),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GeneratedForm(
                items: [
                  [subForm],
                ],
                onValueChanges: (_, _, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    String fieldText(int i) =>
        tester.widget<TextField>(find.byType(TextField).at(i)).controller!.text;
    expect(find.byType(TextField), findsNWidgets(2));
    expect(fieldText(0), 'first');
    expect(fieldText(1), 'second');

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(TextField), findsOneWidget);
    expect(fieldText(0), 'second');
  });
}
