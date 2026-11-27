import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/human_first_asset_loader.dart';

void main() {
  test('machine text fills only strings still in English', () {
    final merged = overlayMachineTranslations(
      {'a': 'Hello', 'b': 'Hallo (human)', 'c': 'Cat'},
      {'a': 'Hello', 'b': 'Bye', 'c': 'Cat'},
      {'a': 'Hallo (machine)', 'b': 'Tschüss (machine)', 'x': 'ignored?'},
    );
    expect(merged['a'], 'Hallo (machine)');
    expect(merged['b'], 'Hallo (human)'); // human wins
    expect(merged['c'], 'Cat'); // no machine text: stays English
  });
}
