import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/theme_builder.dart';

// Every theme option is switchable at runtime while Material widgets are on
// screen. Walk through every combination, changing one option at a time, and
// require that no transition throws (release builds strip the asserts that
// would reveal TextStyle.lerp mismatches, so only tests can catch them).
void main() {
  ThemeData build(int bits, Brightness b) => ThemeBuilder.buildTheme(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: b),
    useSystemFont: bits & 1 != 0,
    plusEnableMaterialExpressive: bits & 2 != 0,
    cornerRadius: bits & 4 != 0 ? 8 : null,
    matchSystemMaterialStyle: bits & 8 != 0,
    isTV: bits & 16 != 0,
  );

  Widget app(int bits, Brightness b) => MaterialApp(
    theme: build(bits, b),
    home: Scaffold(
      appBar: AppBar(title: const Text('Title')),
      body: ListView(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('A')),
              ButtonSegment(value: 1, label: Text('B')),
            ],
            selected: const {0},
            onSelectionChanged: (_) {},
          ),
          const ListTile(title: Text('Tile'), subtitle: Text('Sub')),
          const Wrap(
            children: [
              Chip(label: Text('Chip')),
              FilterChip(label: Text('Filter'), onSelected: null),
            ],
          ),
          ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
          FilledButton(onPressed: () {}, child: const Text('Filled')),
          OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
          TextButton(onPressed: () {}, child: const Text('Text')),
          Switch(value: true, onChanged: (_) {}),
          Slider(value: 0.5, onChanged: (_) {}),
          const TextField(decoration: InputDecoration(labelText: 'Field')),
          const Card(child: Text('Card')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Set'),
        ],
      ),
    ),
  );

  for (final b in Brightness.values) {
    testWidgets('every option combination switches cleanly ($b)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      addTearDown(tester.view.reset);
      // Gray-code walk: consecutive themes differ in exactly one option.
      var prev = 0;
      await tester.pumpWidget(app(prev, b));
      for (var i = 1; i < 32; i++) {
        final next = i ^ (i >> 1);
        await tester.pumpWidget(app(next, b));
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          tester.takeException(),
          isNull,
          reason: 'switching options $prev -> $next',
        );
        prev = next;
      }
      // And back to the start, flipping all five at once.
      await tester.pumpWidget(app(31 ^ prev, b));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  }
}
