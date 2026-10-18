import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/error_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The startup crash screen runs when nothing is initialised: no providers,
// no EasyLocalization. It must render on its own, in any locale.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final locale in const [Locale('en'), Locale('zh')]) {
    testWidgets('ErrorApp renders without providers ($locale)', (tester) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        const ErrorApp(error: 'StateError: boom', stackTrace: '#0 main'),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('boom'), findsWidgets);
    });
  }
}
