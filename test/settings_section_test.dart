import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/components/settings/settings_row.dart';
import 'package:obtainium/components/settings/settings_section.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = PlusSettingsProvider();
    await p.initializeSettings(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ChangeNotifierProvider<PlusSettingsProvider>.value(
        value: p,
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<BorderRadius> radii(WidgetTester tester) => tester
      .widgetList<PressMorphSurface>(find.byType(PressMorphSurface))
      .map((s) => s.radius)
      .toList();

  BorderRadius r(double top, double bottom) => BorderRadius.vertical(
    top: Radius.circular(top),
    bottom: Radius.circular(bottom),
  );

  const a = ListTile(title: Text('A'));
  const b = ListTile(title: Text('B'));
  const c = ListTile(title: Text('C'));

  testWidgets('hidden rows are dropped before first/last radii', (
    tester,
  ) async {
    await pump(
      tester,
      const SettingsSection(
        title: 'Group',
        style: SettingsGroupStyle.segmented,
        children: [
          SizedBox.shrink(),
          a,
          Visibility(visible: false, child: c),
          b,
          SizedBox(),
          Offstage(child: c),
        ],
      ),
    );
    expect(find.text('C'), findsNothing);
    expect(radii(tester), [r(16, 4), r(4, 16)]);
  });

  testWidgets('three rows: outer on the ends, inner at both joints', (
    tester,
  ) async {
    await pump(
      tester,
      const SettingsSection(
        style: SettingsGroupStyle.segmented,
        children: [a, b, c],
      ),
    );
    expect(radii(tester), [r(16, 4), r(4, 4), r(4, 16)]);
  });

  testWidgets('a single row is rounded on all corners', (tester) async {
    await pump(
      tester,
      const SettingsSection(
        style: SettingsGroupStyle.segmented,
        children: [a, SizedBox.shrink()],
      ),
    );
    expect(radii(tester), [r(16, 16)]);
  });

  testWidgets('empty group is dropped, label included', (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          SettingsSection(
            title: 'Empty',
            style: SettingsGroupStyle.segmented,
            children: [
              SizedBox.shrink(),
              Visibility(visible: false, child: a),
            ],
          ),
        ],
      ),
    );
    expect(find.text('Empty'), findsNothing);
    expect(find.byType(PressMorphSurface), findsNothing);
  });

  testWidgets('a nested empty group does not take a row slot', (tester) async {
    await pump(
      tester,
      const SettingsSection(
        style: SettingsGroupStyle.segmented,
        children: [
          a,
          b,
          SettingsSection(title: 'Nested', children: [SizedBox.shrink()]),
        ],
      ),
    );
    expect(radii(tester), [r(16, 4), r(4, 16)]);
  });

  testWidgets('custom radii from settings are honoured', (tester) async {
    await pump(
      tester,
      const SettingsSection(
        style: SettingsGroupStyle.segmented,
        children: [a, b],
      ),
      prefs: {
        'plusSettingsGroupOuterRadius': 24.0,
        'plusSettingsGroupInnerRadius': 10.0,
      },
    );
    expect(radii(tester), [r(24, 10), r(10, 24)]);
    // Pressed rows squeeze to the outer radius.
    final pressed = tester
        .widgetList<PressMorphSurface>(find.byType(PressMorphSurface))
        .map((s) => s.pressedRadius)
        .toSet();
    expect(pressed, {BorderRadius.circular(24)});
  });

  testWidgets('inner radius never exceeds outer', (tester) async {
    await pump(
      tester,
      const SettingsSection(
        style: SettingsGroupStyle.segmented,
        children: [a, b],
      ),
      prefs: {
        'plusSettingsGroupOuterRadius': 6.0,
        'plusSettingsGroupInnerRadius': 20.0,
      },
    );
    expect(radii(tester), [r(6, 6), r(6, 6)]);
  });

  testWidgets('pressing a row morphs its corners and settles back', (
    tester,
  ) async {
    await pump(
      tester,
      const SettingsSection(
        style: SettingsGroupStyle.segmented,
        children: [a, b],
      ),
    );
    final gesture = await tester.startGesture(tester.getCenter(find.text('A')));
    await tester.pumpAndSettle();
    final material = tester.widget<Material>(
      find.ancestor(of: find.text('A'), matching: find.byType(Material)).first,
    );
    expect(
      (material.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(16),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    final after = tester.widget<Material>(
      find.ancestor(of: find.text('A'), matching: find.byType(Material)).first,
    );
    expect((after.shape! as RoundedRectangleBorder).borderRadius, r(16, 4));
  });

  testWidgets('default prefs: ExpressiveSettingsGroup stays the card', (
    tester,
  ) async {
    await pump(
      tester,
      const ExpressiveSettingsGroup(title: 'Group', children: [a, b]),
    );
    expect(find.byType(Card), findsOneWidget);
    expect(find.byType(SegmentedSettingsGroup), findsNothing);
    expect(find.byType(PressMorphSurface), findsNothing);
  });

  testWidgets('segmented pref renders ExpressiveSettingsGroup segmented', (
    tester,
  ) async {
    await pump(
      tester,
      const ExpressiveSettingsGroup(title: 'Group', children: [a, b]),
      prefs: {'plusSettingsGroupStyle': SettingsGroupStyle.segmented.index},
    );
    expect(find.byType(Card), findsNothing);
    expect(find.byType(SegmentedSettingsGroup), findsOneWidget);
    expect(radii(tester), [r(16, 4), r(4, 16)]);
  });

  test('visibleSettingsChildren keeps card filtering unchanged', () {
    const kids = <Widget>[a, Offstage(child: b), SizedBox.shrink()];
    expect(visibleSettingsChildren(kids, dropEmptyGroups: false), hasLength(2));
    expect(visibleSettingsChildren(kids), hasLength(1));
  });
}
