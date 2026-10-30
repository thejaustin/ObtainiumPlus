import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/connected_setting_container.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PlusSettingsProvider>(
        create: (_) => PlusSettingsProvider(),
      ),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('ToggleTile toggles when the whole row is tapped', (
    WidgetTester tester,
  ) async {
    bool value = false;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => ToggleTile(
            label: 'Row Toggle',
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Row Toggle'));
    await tester.pump();
    expect(value, isTrue);

    await tester.tap(find.text('Row Toggle'));
    await tester.pump();
    expect(value, isFalse);
  });

  testWidgets('ToggleTile row tap is inert when disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ToggleTile(label: 'Disabled', value: false, onChanged: null),
      ),
    );
    await tester.tap(find.text('Disabled'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ConnectedSettingContainer hosts ListTile on a clipped Material surface',
    (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          ConnectedSettingContainer(
            label: 'Parent Toggle',
            child: ListTile(
              title: const Text('Nested Setting'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Parent Toggle'), findsOneWidget);
      final materialFinder = find.descendant(
        of: find.byType(ConnectedSettingContainer),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsWidgets);
      final material = tester.widget<Material>(materialFinder.first);
      expect(material.clipBehavior, Clip.antiAlias);
      expect(material.shape, isNotNull);

      await tester.tap(find.text('Nested Setting'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
