import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> open(
    WidgetTester tester, {
    required Size size,
    required bool responsive,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'plusEnableResponsiveAppLayout': responsive,
    });
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: plus,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAdaptiveDetailSheet(
                context: context,
                builder: (_, controller) => ListView(
                  controller: controller,
                  children: const [Text('details')],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('details'), findsOneWidget);
  }

  testWidgets('wide screens get a side sheet when enabled', (tester) async {
    await open(tester, size: const Size(1200, 800), responsive: true);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    final rect = tester.getRect(find.text('details'));
    expect(rect.left, greaterThan(600));
  });

  testWidgets('phones keep the bottom sheet', (tester) async {
    await open(tester, size: const Size(400, 800), responsive: true);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('wide screens keep the bottom sheet when disabled', (
    tester,
  ) async {
    await open(tester, size: const Size(1200, 800), responsive: false);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });
}
