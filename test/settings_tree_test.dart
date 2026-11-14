import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/components/settings/appearance_hub.dart';
import 'package:obtainium/components/settings/plus_features_section.dart';
import 'package:obtainium/components/settings/settings_row.dart';
import 'package:obtainium/components/settings/settings_sections.dart';
import 'package:obtainium/components/settings/settings_slider_tile.dart';
import 'package:obtainium/components/settings/settings_tab_content.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/theme_settings_provider.dart';
import 'package:obtainium/providers/update_settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/utils/app_localizations_delegates.dart';
import 'package:obtainium/utils/theme_builder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings tree: browsing the five sections and every subpage they
/// link to (hub cards, More… pages, the tokens page) shows each setting
/// exactly once, and searching for a setting's title finds it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;
  String tr(String key) => t[key] as String;
  String preview(String key) =>
      (t['previewSuffix'] as String).replaceFirst('{}', tr(key));

  /// Provider key → the row title it is shown under.
  final manifest = <String, String>{
    // Look & motion → Theme & colour
    'theme': tr('theme'),
    'useBlackTheme': tr('useBlackTheme'),
    'matchSystemMaterialStyle': tr('matchSystemMaterialStyle'),
    'themeVariant': tr('themeStyle'),
    'forcedLocale': tr('language'),
    'navigationLabelBehavior': tr('navigationLabels'),
    'plusEnableMaterialExpressive': tr('designSystemThemeStyle'),
    'plusEnableGlassmorphism': tr('glassmorphismUI'),
    // Shapes
    'plusGlobalCornerRadius': tr('plusGlobalCornerRadius'),
    'plusOverrideIndividualCornerRadius': tr(
      'plusOverrideIndividualCornerRadius',
    ),
    'plusHomeCornerRadius': tr('plusHomeCornerRadius'),
    'plusSettingsCornerRadius': tr('plusSettingsCornerRadius'),
    // Motion & haptics
    'plusEnableEnhancedAnimations': tr('plusEnhancedAnimations'),
    'animationSpeedMultiplier': tr('animationSpeed'),
    'reversePageTransitions': tr('reversePageTransitions'),
    'disablePageTransitions': tr('disablePageTransitions'),
    'plusEnableBouncyPhysics': tr('plusBouncyPhysics'),
    'plusEnableExpressiveProgress': tr('plusExpressiveProgress'),
    'enableHapticFeedback': tr('enableHapticFeedback'),
    'plusHapticIntensity': preview('hapticIntensity'),
    'plusHapticFollowSystem': preview('hapticFollowSystem'),
    'plusNativeHaptics': preview('nativeHaptics'),
    'plusSwitchStyle': tr('switchStyle'),
    'plusIconMorphOnToggle': tr('iconMorphOnToggle'),
    'plusIconMorphShape': tr('iconMorphShape'),
    'plusIconMorphStyle': tr('iconMorphStyle'),
    'plusReduceShapeMorphs': tr('reduceShapeMorphs'),
    // Settings page
    'plusSettingsNavPlacement': tr('visualLabNavPlacement'),
    'plusUseCompactSettings': tr('plusUseCompactSettings'),
    'plusLabCompactDescriptionLines': tr('visualLabDescriptionLines'),
    'plusSettingsUseGridToggles': tr('settingsUseGridToggles'),
    'plusSettingsUseVisualThemePicker': tr('settingsUseVisualThemePicker'),
    'plusSettingsUseHeroCards': tr('settingsUseHeroCards'),
    'plusSettingsGroupStyle': tr('settingsGroupStyle'),
    'plusSettingsGroupOuterRadius': tr('settingsGroupOuterRadius'),
    'plusSettingsGroupInnerRadius': tr('settingsGroupInnerRadius'),
    // Look & motion → More…
    'plusEnableOneHandedMode': tr('plusOneHandedMode'),
    'plusTopUILayout': tr('plusTopUILayout'),
    // Home & library
    'globalViewMode': tr('defaultViewMode'),
    'appListDensity': tr('listDensity'),
    'appBarStyle': tr('appBarStyle'),
    'displayShowAuthor': tr('showAuthor'),
    'displayShowVersion': tr('showVersion'),
    'displayShowDate': tr('showDate'),
    'plusGridShowSourceBadge': tr('plusGridShowSourceBadge'),
    'plusShowTagsInList': tr('plusShowTagsInList'),
    'plusGridSquareTiles': tr('plusGridSquareTiles'),
    'plusGridCardlessStyle': tr('plusGridCardlessStyle'),
    'plusGridAmbientIconHalo': tr('plusGridAmbientIconHalo'),
    'plusPinnedBorderAccent': tr('plusPinnedBorderAccent'),
    'plusCategoryAccentRibbon': tr('plusCategoryAccentRibbon'),
    'plusUpdateExpressiveBadge': tr('plusUpdateExpressiveBadge'),
    'plusIconRimBorder': tr('plusIconRimBorder'),
    'plusEnableModernAppListTile': tr('plusEnableModernAppListTile'),
    'groupByCategory': tr('groupByCategory'),
    'categoriesCollapsedByDefault': tr('collapseCategoriesByDefault'),
    'categoryIconCount': tr('iconCount'),
    'plusEnableCategoryReorder': tr('plusCategoryReorder'),
    'plusEnableQuickFilters': tr('plusQuickFilters'),
    'plusEnableTags': tr('plusEnableTags'),
    'plusEnableAdvancedSorting': tr('plusAdvancedSorting'),
    'buryNonInstalled': tr('buryNonInstalled'),
    'enableSwipeGestures': tr('enableSwipeGestures'),
    'plusEnableSwipeActions': tr('expressiveSwipeStyle'),
    'enableUndoForAppRemoval': tr('enableUndoForAppRemoval'),
    'plusEnableBottomNavBar': tr('plusEnableBottomNavBar'),
    'plusFloatingNavBar': tr('plusFloatingNavBar'),
    'plusHideBottomBarOnScroll': tr('plusHideBottomBarOnScroll'),
    'plusShowStatusHub': tr('plusShowStatusHub'),
    'plusShowAppBarSearch': tr('showAppBarSearch'),
    'plusShowDashboardSearch': tr('showDashboardSearch'),
    'plusExpressiveFilterChips': tr('plusExpressiveFilterChips'),
    'displayShowFilterChips': tr('showFilterChips'),
    'displayShowAppCount': tr('showAppCount'),
    'plusEnableFAB': tr('plusEnableFAB'),
    'plusFloatingActionBar': tr('plusFloatingActionBar'),
    'plusFabShowAddByUrl': tr('fabShowAddByUrl'),
    'plusFabShowGithubStarred': tr('fabShowGithubStarred'),
    'plusFabShowGithubPersonalRepos': tr('fabShowGithubPersonalRepos'),
    'plusFabShowImportInstalled': tr('fabShowImportInstalled'),
    'plusEnableModernAddAppPage': tr('plusModernAddAppPage'),
    'plusEnableHomeDashboard': tr('plusHomeDashboard'),
    'plusHeaderContextSubtitle': tr('plusHeaderContextSubtitle'),
    'plusEnableResponsiveAppLayout': tr('plusResponsiveLayout'),
    'plusEnablePopupSlider': tr('plusCollapsibleAbout'),
    'removeOnExternalUninstall': tr('removeOnExternalUninstall'),
    'plusEnableDiscover': tr('plusDiscover'),
    'plusDiscoverSuggestions': tr('plusDiscoverSuggestions'),
    // Updates & notifications
    'checkOnStart': tr('checkOnStart'),
    'updateInterval': tr('bgUpdateCheckInterval'),
    'checkUpdateOnDetailPage': tr('checkUpdateOnDetailPage'),
    'plusEnableUpdateSchedule': tr('plusEnableUpdateSchedule'),
    'bgGuardOnWiFi': tr('whenNotOnWiFi'),
    'bgGuardWhileCharging': tr('whenNotCharging'),
    'onlyCheckInstalledOrTrackOnlyApps': tr(
      'onlyCheckInstalledOrTrackOnlyApps',
    ),
    'useFGService': tr('foregroundServiceTitle'),
    'obtainiumReleaseChannel': tr('releaseChannel'),
    'plusEnableAutoUpdateRules': tr('plusEnableAutoUpdateRules'),
    'allowAddingAppsWithoutCheck': tr('allowAddingAppsWithoutCheck'),
    'categoriesExcludedFromChecks': tr('excludedCategoriesFromChecks'),
    'plusEnableNotificationEnhancements': tr(
      'plusEnableNotificationEnhancements',
    ),
    'plusEnableNotificationDigest': tr('enableNotificationDigest'),
    'plusEnableNotificationQuietHours': tr('enableQuietHours'),
    'updateCheckConcurrencyLimit': tr('plusUpdateCheckConcurrency'),
    'plusEnableSystemUpdateScanner': tr('plusSystemUpdateScanner'),
    // Install & safety
    'parallelDownloads': tr('parallelDownloads'),
    'updateDownloadConcurrencyLimit': tr('plusDownloadConcurrency'),
    'askAboutOtherInstalledBuilds': tr('askAboutOtherInstalledBuilds'),
    'beforeNewInstallsShareToAppVerifier': tr(
      'beforeNewInstallsShareToAppVerifier',
    ),
    'allowThirdPartySources': tr('allowThirdPartySources'),
    'usePlayStoreAppLinks': tr('usePlayStoreAppLinks'),
    'plusEnableMicroGHub': tr('plusEnableMicroGHub'),
    'useAndroidCertStore': tr('androidCertStore'),
    'plusEnableBanWarnings': tr('plusEnableBanWarnings'),
    'plusBanWarningThreshold': tr('plusBanWarningThreshold'),
    'plusEnableStandaloneInstaller': tr('plusEnableStandaloneInstaller'),
    'plusEnableSmartRetries': tr('plusSmartRetries'),
    'plusEnableUpdateOwnership': tr('plusUpdateOwnership'),
    'plusEnableUserPreapproval': tr('plusUserPreapproval'),
    // Advanced
    'plusShowAdvancedSettings': tr('showAdvancedSettings'),
    'enableAllPlusFeatures': tr('enableAllPlusFeatures'),
    'autoExportOnChanges': tr('autoExportOnChanges'),
    'backupEncryptionEnabled': tr('backupEncryption'),
    'github-creds': tr('plusGithubToken'),
    'gitlab-creds': tr('plusGitlabToken'),
    'hideTrackOnlyWarning': tr('dontShowTrackOnlyWarnings'),
    'hideAPKOriginWarning': tr('dontShowAPKOriginWarnings'),
    'enableContextualTips': tr('enableContextualTips'),
    'plusShowChangelogAfterUpdate': tr('plusShowChangelogAfterUpdate'),
    'enableDeepLogging': tr('enableDeepLogging'),
    'highlightTouchTargets': tr('highlightTouchTargets'),
  };

  // Every optional row on: advanced rows, Obtainium+, masters whose
  // children only show while on, and the segmented style (its corner
  // sliders only show with it).
  final prefs = <String, Object>{
    'plusSettingsNavPlacement': SettingsNavPlacement.top.index,
    'enableAllPlusFeatures': true,
    'plusShowAdvancedSettings': true,
    'plusSettingsGroupStyle': SettingsGroupStyle.segmented.index,
    'plusOverrideIndividualCornerRadius': true,
    'plusEnableTags': true,
    'plusEnableBanWarnings': true,
    'plusEnableNotificationEnhancements': true,
    'useMaterialYou': true,
    // List rows (the grid tiles and the visual theme cards carry the same
    // settings without a ListTile title).
    'plusSettingsUseGridToggles': false,
    'plusSettingsUseVisualThemePicker': false,
  };

  Future<Widget> buildApp(Widget home) async {
    final sp = await SharedPreferences.getInstance();
    final settings = SettingsProvider();
    await settings.initializeSettings();
    final plus = PlusSettingsProvider();
    await plus.initializeSettings(sp);
    final theme = ThemeSettingsProvider();
    await theme.initializeSettings(sp);
    final behavior = BehaviorSettingsProvider();
    await behavior.initializeSettings(sp);
    final view = ViewSettingsProvider();
    await view.initializeSettings(sp);
    final update = UpdateSettingsProvider();
    await update.initializeSettings(sp);
    const locale = Locale('en');
    return EasyLocalization(
      supportedLocales: const [locale],
      startLocale: locale,
      path: 'assets/translations',
      fallbackLocale: locale,
      assetLoader: _MemoryAssetLoader(t),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: plus),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: behavior),
          ChangeNotifierProvider.value(value: view),
          ChangeNotifierProvider.value(value: update),
          ChangeNotifierProvider<AppsProvider>(
            create: (_) => AppsProvider(),
            lazy: true,
          ),
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: appLocalizationsDelegates(
              context.localizationDelegates,
            ),
            supportedLocales: const [locale],
            locale: locale,
            theme: ThemeBuilder.buildTheme(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useSystemFont: false,
              cornerRadius: plus.plusGlobalCornerRadius,
            ),
            home: home,
          ),
        ),
      ),
    );
  }

  /// Swaps the app's body for [body] (the providers stay mounted).
  late ValueNotifier<Widget> body;

  Future<void> mount(WidgetTester tester) async {
    body = ValueNotifier<Widget>(const SizedBox.shrink());
    late Widget app;
    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      app = await buildApp(
        Scaffold(
          body: ValueListenableBuilder<Widget>(
            valueListenable: body,
            builder: (context, child, _) => SingleChildScrollView(child: child),
          ),
        ),
      );
    });
    await tester.pumpWidget(app);
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byType(SingleChildScrollView))) break;
    }
  }

  Future<void> show(WidgetTester tester, Widget child) async {
    body.value = KeyedSubtree(key: UniqueKey(), child: child);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  }

  Widget tab(int section, {String query = ''}) => SettingsTabContent(
    section: section,
    searchQuery: query,
    androidInfoFuture: null,
    showIntervalLabel: true,
    onIntervalLabelChange: (_) {},
    onSetState: (fn) => fn(),
  );

  /// A setting's title counts only inside a row, not as a group label,
  /// hub card or page header.
  final rows = find.byWidgetPredicate(
    (w) =>
        w is ListTile ||
        w is SettingsSliderTile ||
        w is SettingsRow ||
        w is PlusFeaturesSection,
  );
  int countIn(String title) =>
      find.descendant(of: rows, matching: find.text(title)).evaluate().length;

  setUp(() {
    SharedPreferences.setMockInitialValues(prefs);
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'browsing shows every setting exactly once, and every page fits 360dp '
    'at 1.3x text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await mount(tester);

      final counts = {for (final k in manifest.keys) k: <String>[]};
      void record(String where) {
        manifest.forEach((key, title) {
          for (var i = 0; i < countIn(title); i++) {
            counts[key]!.add(where);
          }
        });
      }

      for (var s = 0; s < kSettingsSections.length; s++) {
        await show(tester, tab(s));
        record('tab $s');
        // Pages this tab links to: hub cards, More…, tokens.
        final pages = <Widget>[
          for (final hub in tester.widgetList<AppearanceHub>(
            find.byType(AppearanceHub),
          ))
            ...hub.contents,
          for (final link in tester.widgetList<SettingsSubpageLink>(
            find.byType(SettingsSubpageLink),
          ))
            link.child,
        ];
        for (var p = 0; p < pages.length; p++) {
          await show(tester, pages[p]);
          record('tab $s page $p');
        }
      }

      final wrong = {
        for (final e in counts.entries)
          if (e.value.length != 1) e.key: e.value,
      };
      expect(wrong, isEmpty, reason: 'settings not shown exactly once');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  // Rows inside a preview group drop the "(preview)" suffix while browsing
  // (the group header says it); search results, which have no group header,
  // keep it.
  final searchTitles = <String, String>{
    'plusSwitchStyle': preview('switchStyle'),
    'plusIconMorphOnToggle': preview('iconMorphOnToggle'),
    'plusIconMorphShape': preview('iconMorphShape'),
    'plusIconMorphStyle': preview('iconMorphStyle'),
    'plusReduceShapeMorphs': preview('reduceShapeMorphs'),
    'plusSettingsGroupStyle': preview('settingsGroupStyle'),
    'plusSettingsGroupOuterRadius': preview('settingsGroupOuterRadius'),
    'plusSettingsGroupInnerRadius': preview('settingsGroupInnerRadius'),
  };

  testWidgets('searching a setting\'s title finds it', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester);
    final missing = <String>[];
    for (final e in manifest.entries) {
      // Every section is searched at once, as on the page.
      await show(tester, tab(0, query: e.value));
      if (countIn(searchTitles[e.key] ?? e.value) == 0) missing.add(e.key);
    }
    expect(missing, isEmpty, reason: 'not found by searching their title');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

class _MemoryAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;
  const _MemoryAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
