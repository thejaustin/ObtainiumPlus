import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/installers/installer.dart';
import 'package:obtainium/models/app.dart';

App _app(Map<String, dynamic> additionalSettings) => App(
  'com.example.app',
  'https://example.com/app',
  'Author',
  'App',
  null,
  '1.0',
  const [MapEntry('placeholder', 'placeholder')],
  0,
  additionalSettings,
  null,
  false,
);

void main() {
  test('an app with its own install method uses it', () {
    expect(
      installerModeFor(_app({'installerMode': 'shizuku'}), 'system'),
      'shizuku',
    );
    expect(
      installerModeFor(_app({'installerMode': 'system'}), 'root'),
      'system',
    );
  });

  test('otherwise the global install method is used', () {
    expect(installerModeFor(null, 'root'), 'root');
    expect(installerModeFor(_app({}), 'shizuku'), 'shizuku');
    expect(
      installerModeFor(_app({'installerMode': ''}), 'external'),
      'external',
    );
    expect(
      installerModeFor(_app({'installerMode': 'bogus'}), 'system'),
      'system',
    );
  });
}
