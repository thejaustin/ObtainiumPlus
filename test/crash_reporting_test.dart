import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/utils/crash_reporting.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('crash reporting is off by default', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await isCrashReportingEnabled(), isFalse);
  });

  test('crash reporting follows the stored choice', () async {
    SharedPreferences.setMockInitialValues({crashReportingPrefKey: true});
    expect(await isCrashReportingEnabled(), isTrue);
  });

  test('a wrongly typed value counts as off', () async {
    SharedPreferences.setMockInitialValues({crashReportingPrefKey: 'yes'});
    expect(await isCrashReportingEnabled(), isFalse);
  });
}
