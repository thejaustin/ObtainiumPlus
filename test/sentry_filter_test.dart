import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/main.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

SentryEvent _event(String type, String value) => SentryEvent(
  exceptions: [SentryException(type: type, value: value)],
);

void main() {
  test('expected batch results are not reported', () {
    for (final v in [
      'App not found [98a638c0803c]',
      "OmniShizuku wasn't installed because Shizuku is already installed as "
          'a separate build. Open Obtainium+ to choose what to do.',
    ]) {
      expect(
        filterShizukuNoise(_event('MultiAppMultiError', v), Hint()),
        isNull,
      );
    }
  });

  test('other batch errors and real crashes still are', () {
    expect(
      filterShizukuNoise(
        _event('MultiAppMultiError', 'Something unexpected broke'),
        Hint(),
      ),
      isNotNull,
    );
    expect(
      filterShizukuNoise(_event('StateError', 'Bad state'), Hint()),
      isNotNull,
    );
  });
}
