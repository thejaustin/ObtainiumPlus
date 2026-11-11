import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/spring_expandable.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SpringExpandable keeps its expanded flag across being scrolled out of a
/// lazy list and across a tab switch, and never misreads a foreign value.
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

  Future<PlusSettingsProvider> provider({bool motion = true}) async {
    SharedPreferences.setMockInitialValues({
      'plusEnableEnhancedAnimations': motion,
    });
    final p = PlusSettingsProvider();
    await p.initializeSettings(await SharedPreferences.getInstance());
    return p;
  }

  Widget expandable() => const SpringExpandable(
    storageKey: 'test.group',
    title: Text('Header'),
    children: [ListTile(title: Text('Inside'))],
  );

  SpringExpandableState state(WidgetTester tester) =>
      tester.state<SpringExpandableState>(find.byType(SpringExpandable));

  testWidgets('state survives scrolling away and a tab switch', (tester) async {
    final p = await provider();
    final tab = ValueNotifier<int>(0);
    await tester.pumpWidget(
      ChangeNotifierProvider<PlusSettingsProvider>.value(
        value: p,
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: tab,
              builder: (context, t, _) => t == 0
                  ? ListView(
                      key: const PageStorageKey<String>('tab0'),
                      cacheExtent: 0,
                      children: [
                        expandable(),
                        for (var i = 0; i < 60; i++)
                          SizedBox(height: 80, child: Text('filler $i')),
                      ],
                    )
                  : const Center(child: Text('other tab')),
            ),
          ),
        ),
      ),
    );
    expect(state(tester).expanded, isFalse);

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(state(tester).expanded, isTrue);
    expect(find.text('Inside').hitTestable(), findsOneWidget);
    // Standard intensity: one selection click per expand.
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    // Scroll far enough that the lazy list disposes the expandable.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.byType(SpringExpandable), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 6000));
    await tester.pumpAndSettle();
    expect(state(tester).expanded, isTrue);

    // Switch tabs (disposes the whole list) and back.
    tab.value = 1;
    await tester.pumpAndSettle();
    expect(find.text('other tab'), findsOneWidget);
    tab.value = 0;
    await tester.pumpAndSettle();
    expect(state(tester).expanded, isTrue);
    expect(find.text('Inside').hitTestable(), findsOneWidget);
  });

  testWidgets('a foreign value in the storage slot is ignored', (tester) async {
    final p = await provider();
    await tester.pumpWidget(
      ChangeNotifierProvider<PlusSettingsProvider>.value(
        value: p,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              // A scroll offset written under the same identifier.
              PageStorage.of(context).writeState(
                context,
                412.5,
                identifier: 'spring_expandable:test.group',
              );
              return Scaffold(body: expandable());
            },
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(state(tester).expanded, isFalse);
  });

  testWidgets('motion off settles in one frame', (tester) async {
    final p = await provider(motion: false);
    await tester.pumpWidget(
      ChangeNotifierProvider<PlusSettingsProvider>.value(
        value: p,
        child: MaterialApp(home: Scaffold(body: expandable())),
      ),
    );
    await tester.tap(find.text('Header'));
    await tester.pump();
    // (The InkWell ripple still runs; the expand itself must be done.)
    final size = tester.widget<SizeTransition>(
      find.descendant(
        of: find.byType(SpringExpandable),
        matching: find.byType(SizeTransition),
      ),
    );
    expect(size.sizeFactor.value, 1.0);
    expect(find.text('Inside').hitTestable(), findsOneWidget);
  });
}
