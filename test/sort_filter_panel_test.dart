import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/sort_filter_panel.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SortFilterPanel renders without crash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(sp);
    final view = ViewSettingsProvider();
    await view.initializeSettings(sp);
    final apps = AppsProvider();

    final filter = AppsFilter();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: plus),
          ChangeNotifierProvider.value(value: view),
          ChangeNotifierProvider.value(value: apps),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => SortFilterPanel.show(
                  context,
                  filter: filter,
                  onFilterChanged: () {},
                  categories: {'Games': 0xFF00FF00, 'Tools': 0xFF0000FF},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SortFilterPanel), findsOneWidget);
  });
}
