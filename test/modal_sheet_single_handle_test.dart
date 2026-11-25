import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/modal_utils.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('draggable modal sheet draws one handle, not two', (
    tester,
  ) async {
    // The app theme turns the system drag handle on; the helper draws its
    // own, so it must switch the system one off or the sheet shows two bars.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlusSettingsProvider(),
        child: MaterialApp(
          theme: ThemeData(
            bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDraggableModalBottomSheet<void>(
                context: context,
                builder: (_, c) => ListView(controller: c),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.showDragHandle, isFalse);
  });
}
