import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/theme_builder.dart';

// Toggling "Match system Material style" swaps between two very different
// ThemeData objects while Material widgets are on screen; each Material
// animates its own text style, and TextStyle.lerp asserts when the two
// themes' styles disagree on `inherit`.
void main() {
  ThemeData build(bool match, Brightness b) => ThemeBuilder.buildTheme(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: b),
    useSystemFont: false,
    matchSystemMaterialStyle: match,
  );

  Widget app(bool match, Brightness b) => MaterialApp(
    theme: build(match, b),
    home: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Title'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'One'),
              Tab(text: 'Two'),
            ],
          ),
        ),
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
                ChoiceChip(label: Text('Choice'), selected: true),
              ],
            ),
            FilledButton(onPressed: () {}, child: const Text('Filled')),
            FilledButton.tonal(onPressed: () {}, child: const Text('Tonal')),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            TextButton(onPressed: () {}, child: const Text('Text')),
            Switch(value: true, onChanged: (_) {}),
            const TextField(decoration: InputDecoration(labelText: 'Field')),
            const Card(child: Text('Card')),
            const Dialog(child: Text('Dialog')),
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
    ),
  );

  for (final b in Brightness.values) {
    testWidgets('toggling match-system style does not throw ($b)', (
      tester,
    ) async {
      await tester.pumpWidget(app(false, b));
      await tester.pumpWidget(app(true, b));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(app(false, b));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });
  }
}
