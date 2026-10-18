import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/notifications_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('window logic, including past midnight', () {
    expect(NotificationsProvider.hourInWindow(23, 22, 7), isTrue);
    expect(NotificationsProvider.hourInWindow(3, 22, 7), isTrue);
    expect(NotificationsProvider.hourInWindow(7, 22, 7), isFalse);
    expect(NotificationsProvider.hourInWindow(12, 22, 7), isFalse);
    expect(NotificationsProvider.hourInWindow(13, 9, 17), isTrue);
    expect(NotificationsProvider.hourInWindow(17, 9, 17), isFalse);
    expect(NotificationsProvider.hourInWindow(5, 5, 5), isFalse);
  });

  test('only active when enabled', () async {
    final night = DateTime(2026, 1, 1, 23);
    SharedPreferences.setMockInitialValues({});
    expect(await NotificationsProvider.isInQuietHours(night), isFalse);

    SharedPreferences.setMockInitialValues({
      'plusEnableNotificationQuietHours': true,
    });
    expect(await NotificationsProvider.isInQuietHours(night), isTrue);
    expect(
      await NotificationsProvider.isInQuietHours(DateTime(2026, 1, 1, 12)),
      isFalse,
    );

    SharedPreferences.setMockInitialValues({
      'plusEnableNotificationQuietHours': true,
      'enableAllPlusFeatures': false,
    });
    expect(await NotificationsProvider.isInQuietHours(night), isFalse);
  });
}
