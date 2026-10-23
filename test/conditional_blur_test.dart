import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/common/conditional_blur.dart';

void main() {
  testWidgets('the blur is clipped to its own box', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ConditionalBlur(
          enabled: true,
          sigma: 8,
          child: SizedBox(width: 10, height: 10),
        ),
      ),
    );
    // Unclipped, a BackdropFilter blurs everything behind it up to the
    // nearest clip — the whole app page in #330.
    expect(
      find.ancestor(
        of: find.byType(BackdropFilter),
        matching: find.byType(ClipRect),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no filter when disabled', (tester) async {
    await tester.pumpWidget(
      const ConditionalBlur(
        enabled: false,
        sigma: 8,
        child: SizedBox(width: 10, height: 10),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
