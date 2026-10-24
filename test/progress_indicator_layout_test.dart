import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The Logs page shows this spinner in a SliverFillRemaining while loading;
  // that asks for intrinsic sizes, which a LayoutBuilder can't give.
  testWidgets('spinner lays out inside SliverFillRemaining', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: plus,
        child: const MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: ExpressiveCircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ExpressiveCircularProgressIndicator)),
      const Size(48, 48),
    );
  });
}
