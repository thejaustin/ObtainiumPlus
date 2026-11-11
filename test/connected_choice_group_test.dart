import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/connected_choice_group.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String?> haptics;

  setUp(() {
    AppHaptics.enabled = true;
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String?);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<int Function()> pump(WidgetTester tester, int count) async {
    SharedPreferences.setMockInitialValues({});
    final p = PlusSettingsProvider();
    await p.initializeSettings(await SharedPreferences.getInstance());
    var value = 0;
    await tester.pumpWidget(
      ChangeNotifierProvider<PlusSettingsProvider>.value(
        value: p,
        child: MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) => ConnectedChoiceGroup<int>(
                  options: {for (var i = 0; i < count; i++) i: 'Option $i'},
                  value: value,
                  sheetTitle: 'Pick',
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => value;
  }

  testWidgets('2-4 options render connected segments', (tester) async {
    final value = await pump(tester, 3);
    expect(find.text('Option 2'), findsOneWidget);
    expect(find.byType(RadioListTile<int>), findsNothing);
    await tester.tap(find.text('Option 2'));
    await tester.pumpAndSettle();
    expect(value(), 2);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    // Re-tapping the selected option changes nothing and stays silent.
    await tester.tap(find.text('Option 2'));
    await tester.pumpAndSettle();
    expect(haptics, hasLength(1));
  });

  testWidgets('selected segment is fully round', (tester) async {
    await pump(tester, 2);
    final m = tester.widget<Material>(
      find
          .ancestor(of: find.text('Option 0'), matching: find.byType(Material))
          .first,
    );
    expect(
      (m.shape! as RoundedRectangleBorder).borderRadius,
      const BorderRadius.all(Radius.circular(20)),
    );
  });

  testWidgets('5+ options open a radio sheet', (tester) async {
    final value = await pump(tester, 5);
    expect(find.text('Option 4'), findsNothing);
    await tester.tap(find.text('Option 0'));
    await tester.pumpAndSettle();
    expect(find.byType(RadioListTile<int>), findsNWidgets(5));
    await tester.tap(find.text('Option 4'));
    await tester.pumpAndSettle();
    expect(value(), 4);
    expect(find.byType(RadioListTile<int>), findsNothing);
  });
}
