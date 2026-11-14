import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/page_storage_utils.dart';

// OBTAINIUMPLUS-39 / 3R: a TextField in a keyed ExpansionTile body restored
// the tile's expanded flag as its scroll offset (and the reverse).
Widget _page({required bool isolate}) {
  final body = <Widget>[const TextField()];
  return MaterialApp(
    home: Scaffold(
      body: ListView(
        key: const PageStorageKey<String>('page_scroll'),
        children: [
          ExpansionTile(
            key: const PageStorageKey<String>('group'),
            title: const Text('Group'),
            children: isolate ? body.withOwnPageStorage() : body,
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('without isolation the body reads the tile state', (
    tester,
  ) async {
    await tester.pumpWidget(_page(isolate: false));
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<TypeError>());
  });

  testWidgets('withOwnPageStorage keeps body and tile state apart', (
    tester,
  ) async {
    await tester.pumpWidget(_page(isolate: true));
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}
