import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/apps/collapsible_about.dart';

void main() {
  test('only long descriptions collapse', () {
    expect(CollapsibleAbout.isLong('A short tagline.'), isFalse);
    expect(CollapsibleAbout.isLong('word ' * 100), isTrue);
    expect(
      CollapsibleAbout.isLong(List.filled(7, '- point').join('\n')),
      isTrue,
    );
    expect(CollapsibleAbout.isLong('one\ntwo\nthree'), isFalse);
  });
}
