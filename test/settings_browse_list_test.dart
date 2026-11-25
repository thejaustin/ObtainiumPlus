import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/settings_browse_list.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';

void main() {
  Widget host(Widget child) => ChangeNotifierProvider(
    create: (_) => PlusSettingsProvider(),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('list shows every category and reports the tapped one', (
    tester,
  ) async {
    int? opened;
    await tester.pumpWidget(
      host(SettingsBrowseList(onOpen: (i) => opened = i)),
    );
    expect(find.byType(ListTile), findsNWidgets(kSettingsSections.length));
    await tester.tap(find.byType(ListTile).at(2));
    expect(opened, 2);
  });

  test('browse style defaults to tabs so Settings is unchanged', () {
    expect(
      PlusSettingsProvider().plusLabSettingsBrowseStyle,
      SettingsBrowseStyle.tabs,
    );
  });
}
