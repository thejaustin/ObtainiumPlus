import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/services/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppInMemory _aim(
  String id, {
  bool disabled = false,
  List<String> categories = const [],
}) => AppInMemory(
  App(
    id,
    'https://github.com/example/$id',
    'Author',
    id,
    '1.0',
    '1.0',
    const [],
    0,
    const {},
    null,
    false,
    disabled: disabled,
    categories: categories,
  ),
  null,
  null,
  null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('background check list skips disabled apps and excluded categories', () {
    final apps = {
      for (final a in [
        _aim('plain'),
        _aim('off', disabled: true),
        _aim('skipped', categories: ['Archive']),
        _aim('kept', categories: ['Other']),
      ])
        a.app.id: a,
    };
    expect(AppUpdateService.getAppsSortedByUpdateCheckTime(apps).toSet(), {
      'plain',
      'skipped',
      'kept',
    });
    expect(
      AppUpdateService.getAppsSortedByUpdateCheckTime(
        apps,
        excludedCategories: {'Archive'},
      ).toSet(),
      {'plain', 'kept'},
    );
  });

  test('pruneCategoryExclusions drops removed categories only', () async {
    SharedPreferences.setMockInitialValues({
      'categoriesExcludedFromChecks': '["Work","Games"]',
    });
    final prefs = await SharedPreferences.getInstance();
    pruneCategoryExclusions(prefs, ['Games']);
    expect(prefs.getString('categoriesExcludedFromChecks'), '["Games"]');
  });

  test('pruneCategoryExclusions ignores missing or corrupt data', () async {
    SharedPreferences.setMockInitialValues({
      'categoriesExcludedFromChecks': 'not json',
    });
    final prefs = await SharedPreferences.getInstance();
    pruneCategoryExclusions(prefs, ['Games']);
    expect(prefs.getString('categoriesExcludedFromChecks'), 'not json');
    pruneCategoryExclusions(null, ['Games']);
  });
}
