import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/services/app_update_service.dart';

AppInMemory _aim(String id, {String? installed, bool disabled = false}) =>
    AppInMemory(
      App(
        id,
        'https://github.com/example/$id',
        'Author',
        id,
        installed,
        '2.0.0',
        const [MapEntry('app.apk', 'https://example.com/app.apk')],
        0,
        const {},
        null,
        false,
        disabled: disabled,
      ),
      null,
      null,
      null,
    );

void main() {
  // A disabled app keeps an update found before it was disabled; it must not
  // be offered in "update all" or picked up by background installs.
  final apps = {
    'on': _aim('on', installed: '1.0.0'),
    'off': _aim('off', installed: '1.0.0', disabled: true),
    'newOff': _aim('newOff', disabled: true),
    'newOn': _aim('newOn'),
  };

  test('findExistingUpdates skips disabled apps', () {
    expect(AppUpdateService.findExistingUpdates(apps), ['on', 'newOn']);
    expect(
      AppUpdateService.findExistingUpdates(apps, installedOnly: true),
      ['on'],
    );
  });

  test('findAllPendingUpdates skips disabled apps', () {
    final r = AppUpdateService.findAllPendingUpdates(apps);
    expect(r.updates, {'on'});
    expect(r.newInstalls, ['newOn']);
  });
}
