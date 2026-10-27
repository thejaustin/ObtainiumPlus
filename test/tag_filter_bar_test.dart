import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/apps/tag_filter_bar.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/tag_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAppsProvider extends ChangeNotifier implements AppsProvider {
  @override
  Map<String, AppInMemory> apps = {};

  @override
  int appsRevision = 1;

  @override
  Iterable<AppInMemory> getAppValues({bool deepCopy = false}) => apps.values;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final translations =
        jsonDecode(File('assets/translations/en.json').readAsStringSync())
            as Map<String, dynamic>;
    Localization.load(
      const Locale('en'),
      translations: Translations(translations),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppInMemory makeApp(String id, String name, {List<String>? tags}) {
    final app = App(
      id,
      'https://github.com/example/$id',
      'Author',
      name,
      '1.0.0',
      '1.0.0',
      const [MapEntry('https://example.com/app.apk', 'app.apk')],
      0,
      const {},
      null,
      false,
    )..tags = tags ?? [];
    return AppInMemory(app, null, null, null);
  }

  testWidgets('TagFilterBar renders tag pills, counts, and handles selection', (
    WidgetTester tester,
  ) async {
    final appsProvider = _TestAppsProvider();
    appsProvider.apps = {
      'app1': makeApp('app1', 'App One', tags: ['tools', 'foss']),
      'app2': makeApp('app2', 'App Two', tags: ['foss']),
    };

    final tagProvider = TagProvider(appsProvider);
    final plusSettings = PlusSettingsProvider();

    String? selectedTag;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsProvider>.value(value: appsProvider),
          ChangeNotifierProvider<TagProvider>.value(value: tagProvider),
          ChangeNotifierProvider<PlusSettingsProvider>.value(
            value: plusSettings,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return TagFilterBar(
                      activeTag: selectedTag,
                      onTagSelected: (tag) {
                        setState(() => selectedTag = tag);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('foss'), findsOneWidget);
    expect(find.text('tools'), findsOneWidget);

    await tester.tap(find.text('foss'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(selectedTag, 'foss');
  });
}
