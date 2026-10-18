import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/pages/onboarding.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/components/force_update_dialog.dart';
import 'package:obtainium/components/critical_issue_dialog.dart';
import 'package:obtainium/services/known_issues_service.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/components/add_app_sheet.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/pages/system_updates.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/core/logging/app_logger.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/version_constant.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/nav/plus_floating_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class NavigationPageItem {
  late String title;
  late IconData icon;
  late Widget widget;

  NavigationPageItem(this.title, this.icon, this.widget);
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<int> selectedIndexHistory = [];
  bool isReversing = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final GlobalKey<AppsPageState> _appsPageKey = GlobalKey<AppsPageState>();
  late List<NavigationPageItem> pages;

  bool _providersInitialized = false;
  late SourceProvider sourceProvider;
  late SettingsProvider settingsProvider;
  late AppsProvider appsProvider;

  // Measured height of the floating bottom nav bar (divider + NavigationBar
  // + its own safe-area inset). extendBody:true lets page content draw
  // behind the translucent bar for the frosted-glass look, so each page
  // needs this as bottom padding or its last items/buttons render hidden
  // underneath the bar instead of above it.
  final GlobalKey _bottomNavBarKey = GlobalKey();
  double _bottomNavBarHeight = 0;

  void _measureBottomNavBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _bottomNavBarKey.currentContext?.size?.height;
      if (height != null && height != _bottomNavBarHeight) {
        setState(() {
          _bottomNavBarHeight = height;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_providersInitialized) {
      sourceProvider = context.read<SourceProvider>();
      settingsProvider = context.read<SettingsProvider>();
      appsProvider = context.read<AppsProvider>();
      _providersInitialized = true;
    }
  }

  bool _systemPageShown = false;

  List<NavigationPageItem> _buildPages(bool withSystemUpdates) => [
    NavigationPageItem(
      'appsString',
      Icons.apps_rounded,
      AppsPage(key: _appsPageKey),
    ),
    if (withSystemUpdates)
      NavigationPageItem(
        'systemUpdates',
        Icons.system_update_alt_rounded,
        const SystemUpdatesPage(),
      ),
    NavigationPageItem(
      'importExport',
      Icons.import_export_rounded,
      const ImportExportPage(),
    ),
    NavigationPageItem('settings', Icons.settings_rounded, const SettingsPage()),
  ];

  /// Adds/removes the System updates destination when its setting changes,
  /// keeping the user on the same page.
  void _syncSystemUpdatesPage(bool show) {
    if (show == _systemPageShown) return;
    _systemPageShown = show;
    final oldTitles = pages.map((p) => p.title).toList();
    pages = _buildPages(show);
    final newTitles = pages.map((p) => p.title).toList();
    selectedIndexHistory = selectedIndexHistory
        .map((i) => i < oldTitles.length ? newTitles.indexOf(oldTitles[i]) : -1)
        .where((i) => i >= 0)
        .toList();
    final old = _tabController;
    _tabController = TabController(
      length: pages.length,
      vsync: this,
      initialIndex: selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void initState() {
    super.initState();
    pages = _buildPages(false);

    _tabController = TabController(length: pages.length, vsync: this);
    initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var sp = context.read<SettingsProvider>();
      var plusSettings = context.read<PlusSettingsProvider>();
      const currentVersion = currentObtainiumPlusVersion;

      if (plusSettings.plusLastSeenVersion.isEmpty && !sp.welcomeShown) {
        // Fresh install: record the current version silently so the
        // "What's New" dialog only appears after a real update, and let
        // the welcome dialog below take over.
        plusSettings.plusLastSeenVersion = currentVersion;
      }

      if (plusSettings.plusLastSeenVersion != currentVersion &&
          !plusSettings.plusShowChangelogAfterUpdate) {
        // User opted out of the post-update changelog; still mark the
        // version as seen so re-enabling the toggle later doesn't
        // surface an outdated prompt.
        plusSettings.plusLastSeenVersion = currentVersion;
      }

      if (plusSettings.plusLastSeenVersion != currentVersion) {
        // Show What's New bottom sheet on update
        if (context.mounted) {
          await showWhatsNewSheet(context, targetVersion: currentVersion);
        }
        plusSettings.plusLastSeenVersion = currentVersion;
        // Don't follow up with the verification warning on the same launch —
        // two consecutive startup modals after an update is terrible UX.
        sp.googleVerificationWarningShown = true;
      } else if (!sp.welcomeShown) {
        // First run: the guided onboarding (permissions, installer, tracking
        // Obtainium+ itself) replaces the old one-line welcome dialog.
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (routeContext) => OnboardingPage(
                onDone: () => Navigator.of(routeContext).pop(),
              ),
            ),
          );
          // Also when backed out of, so it never nags on later launches.
          sp.welcomeShown = true;
        }
      }
      if (!mounted) return;
      if (!sp.googleVerificationWarningShown && DateTime.now().year == 2026) {
        await showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return GeneratedFormModal(
              title: tr('note'),
              items: const [],
              message:
                  "${tr('googleVerificationWarningP1')}\n\n${tr('googleVerificationWarningP3')}",
              additionalWidgets: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: LinkText(
                    text: tr('googleVerificationWarningP2'),
                    url: 'https://keepandroidopen.org/',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              singleNullReturnButton: tr('ok'),
            );
          },
        );
        sp.googleVerificationWarningShown = true;
      }
      await _showKnownIssues();
    });
  }

  /// Remote known-issues notices for the running build (known_issues.json in
  /// the repo). Fetched after first frame with a timeout and cached; any
  /// failure shows nothing.
  Future<void> _showKnownIssues() async {
    try {
      final info = await AppInstallService.getInstalledInfo(
        AppConstants.obtainiumPlusId,
        printErr: false,
      );
      if (info == null || !mounted) return;
      final issues = await KnownIssuesService.getActiveIssues(
        info.versionName ?? '',
        info.versionCode ?? 0,
      );
      for (final issue in issues) {
        if (!mounted) return;
        if (issue.forceUpdate) {
          await showDialog<void>(
            context: context,
            builder: (_) => ForceUpdateDialog(issue: issue),
          );
        } else {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => CriticalIssueDialog(
              issue: issue,
              onCheckForUpdates: () {
                Navigator.of(dialogContext).pop();
                switchToPage(0);
                context.read<AppsProvider>().checkUpdates().catchError(
                  (_) => <App>[],
                );
              },
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error(e, message: 'Known-issues check failed');
    }
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    goToAddApp(String data) async {
      // Add App is no longer a tab; open it as a bottom sheet and let
      // AddAppPage feed the URL into its form via initialUrl -> linkFn.
      if (!mounted) return;
      showAddAppSheet(context: context, initialUrl: data);
    }

    goToExistingApp(String appId) async {
      switchToPage(0);
      var attempts = 0;
      while (_appsPageKey.currentState == null) {
        if (++attempts > 50) return;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Navigate to the app
      _appsPageKey.currentState?.openAppById(appId);
    }

    interpretLink(Uri uri) async {
      var action = uri.host;
      // Also accept a `?url=` query param as an alternative to the path
      // segment, for deep links that prefer explicit query encoding.
      var data =
          uri.queryParameters['url'] ??
          (uri.path.length > 1 ? uri.path.substring(1) : "");
      try {
        if (action == 'add') {
          // Ensure apps are loaded
          AppsProvider appsProvider = context.read<AppsProvider>();
          await appsProvider.waitForAppsToLoad();
          if (!mounted) return;

          // See if we already have this app
          String? standardizedUrl;
          try {
            standardizedUrl = SourceProvider()
                .getSource(data)
                .standardizeUrl(data);
          } catch (_) {
            standardizedUrl = null;
          }

          AppInMemory? existingApp = appsProvider.apps.values
              .where(
                (AppInMemory a) =>
                    a.app.url == standardizedUrl || a.app.url == data,
              )
              .firstOrNull;

          if (existingApp != null) {
            await goToExistingApp(existingApp.app.id);
          } else {
            await goToAddApp(data);
          }
        } else if (action == 'app' || action == 'apps') {
          dynamic parsedData;
          try {
            parsedData = jsonDecode(data);
          } catch (e) {
            AppLogger.error(e, message: 'Failed to decode deep-link JSON');
            throw ObtainiumError(tr('invalidInput'));
          }
          final apps = action == 'app' ? [parsedData] : parsedData;
          if (apps is! List) throw ObtainiumError(tr('invalidInput'));
          // A link must not be able to weaken security on the apps it adds.
          final stripped = stripLinkUnsafeSettings(apps);
          if (await showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return GeneratedFormModal(
                    title: tr(
                      'importX',
                      args: [
                        (action == 'app' ? tr('app') : tr('appsString'))
                            .toLowerCase(),
                      ],
                    ),
                    items: const [],
                    additionalWidgets: [
                      for (final app in apps.whereType<Map>())
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${app['name'] ?? app['id'] ?? '?'}'),
                          subtitle: Text(
                            '${app['url'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (stripped > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Security overrides in this link (insecure connections, '
                            'certificate pinning, signer allow-lists) were ignored.',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                        ),
                      ExpansionTile(
                        title: Text(tr('rawJson')),
                        children: [
                          Text(
                            data,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ) !=
              null) {
            if (!mounted) return;
            var appsProvider = context.read<AppsProvider>();
            var result = await appsProvider.import(
              safeJsonEncode({'apps': apps}),
            );
            if (!mounted) return;
            showMessage(
              tr(
                'importedX',
                args: [plural('apps', result.key.length).toLowerCase()],
              ),
              context,
            );
          }
        } else if (action == 'refresh') {
          final targetId = uri.queryParameters['id'];
          await appsProvider.checkUpdates(
            specificIds: targetId != null ? [targetId] : null,
          );
        } else {
          throw ObtainiumError(tr('unknown'));
        }
      } catch (e) {
        if (mounted) showError(e, context);
      }
    }

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialLink();
    if (appLink != null) {
      await interpretLink(appLink);
    }
    // Handle link when app is in warm state (front or background). Compare
    // against the initial link (rather than a one-shot skip flag) so a
    // genuinely new link arriving right after cold start isn't swallowed.
    var dedupeInitial = appLink != null;
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (dedupeInitial) {
        dedupeInitial = false;
        if (uri == appLink) {
          return;
        }
      }
      await interpretLink(uri);
    });
  }

  void setIsReversing(int targetIndex) {
    bool reversing =
        selectedIndexHistory.isNotEmpty &&
        selectedIndexHistory.last > targetIndex;
    setState(() {
      isReversing = reversing;
    });
  }

  Future<void> switchToPage(int index) async {
    final currentTab =
        selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last;
    if (_tabController.index == index && currentTab == index) {
      return;
    }
    _tabController.animateTo(index);
    setIsReversing(index);
    if (index == 0) {
      setState(() {
        selectedIndexHistory.clear();
      });
    } else if (selectedIndexHistory.isEmpty ||
        (selectedIndexHistory.isNotEmpty &&
            selectedIndexHistory.last != index)) {
      setState(() {
        int existingInd = selectedIndexHistory.indexOf(index);
        if (existingInd >= 0) {
          selectedIndexHistory.removeAt(existingInd);
        }
        selectedIndexHistory.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final behaviorSettings = context.watch<BehaviorSettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    final isSelecting = context.select<AppsProvider, bool>(
      (p) => p.selectedAppIds.isNotEmpty,
    );

    _syncSystemUpdatesPage(
      plusSettings.enableAllPlusFeatures &&
          plusSettings.plusEnableSystemUpdateScanner,
    );
    final isTopNav = plusSettings.plusTopUILayout && !settingsProvider.isTV;
    final showNavBar = plusSettings.plusEnableBottomNavBar && !isTopNav;
    if (showNavBar && !settingsProvider.isTV) {
      _measureBottomNavBar();
    }
    final currentIndex = (showNavBar || isTopNav)
        ? (selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last)
        : 0;
    // The add-app FAB belongs to the Apps tab only (index 0).
    final showAddFab =
        plusSettings.plusEnableFAB && !settingsProvider.isTV && currentIndex == 0;

    // With transitions disabled, render the page directly:
    // PageTransitionSwitcher with Duration.zero can leave the incoming
    // page at opacity 0 — a blank tab with no exception thrown.
    final pageBody = behaviorSettings.disablePageTransitions
        ? pages.elementAt(currentIndex).widget
        : PageTransitionSwitcher(
            duration: const Duration(milliseconds: 300),
            reverse: behaviorSettings.reversePageTransitions
                ? !isReversing
                : isReversing,
            transitionBuilder:
                (
                  Widget child,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
            child: KeyedSubtree(
              key: ValueKey(currentIndex),
              child: pages.elementAt(currentIndex).widget,
            ),
          );

    if (isTopNav) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          setIsReversing(
            selectedIndexHistory.length >= 2
                ? selectedIndexHistory.reversed.toList()[1]
                : 0,
          );
          if (selectedIndexHistory.isNotEmpty) {
            setState(() {
              selectedIndexHistory.removeLast();
            });
            _tabController.animateTo(
              selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last,
            );
            return;
          }
          final clearSelected =
              _appsPageKey.currentState?.clearSelected() ?? false;
          if (!clearSelected) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              tr(pages[currentIndex].title),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              onTap: (index) {
                AppHaptics.selectionClick();
                switchToPage(index);
              },
              tabs: pages
                  .map((e) => Tab(icon: Icon(e.icon), text: tr(e.title)))
                  .toList(),
            ),
            actions: [
              ScaleTouchWrapper(
                hapticOnPressDown: true,
                scaleDownFactor: 0.88,
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: tr('settings'),
                  onPressed: () {
                    AppHaptics.selectionClick();
                    pushRoute(context, const SettingsPage());
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: showAddFab ? const AppActionsFAB() : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: pageBody,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (showNavBar) {
          setIsReversing(
            selectedIndexHistory.length >= 2
                ? selectedIndexHistory.reversed.toList()[1]
                : 0,
          );
          if (selectedIndexHistory.isNotEmpty) {
            setState(() {
              selectedIndexHistory.removeLast();
            });
            return;
          }
        }
        final clearSelected =
            _appsPageKey.currentState?.clearSelected() ?? false;
        if (!clearSelected) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        // The omnibar "+" — the single entry point for the combined
        // add/search/discover flow, visible on every tab.
        floatingActionButton: showAddFab && !isSelecting
            ? const AppActionsFAB()
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: settingsProvider.isTV && showNavBar
            ? Row(
                children: [
                  FocusTraversalGroup(
                    child: NavigationRail(
                      destinations: pages
                          .map(
                            (e) => NavigationRailDestination(
                              icon: Icon(e.icon),
                              label: Text(tr(e.title)),
                            ),
                          )
                          .toList(),
                      selectedIndex: currentIndex,
                      onDestinationSelected: switchToPage,
                      labelType: NavigationRailLabelType.all,
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: pageBody),
                ],
              )
            : showNavBar
            ? Padding(
                padding: EdgeInsets.only(bottom: _bottomNavBarHeight),
                child: pageBody,
              )
            : pageBody,
        bottomNavigationBar: settingsProvider.isTV || !showNavBar
            ? null
            : _buildBottomNavBar(
                context,
                plusSettings,
                currentIndex,
              ),
      ),
    );
  }

  Widget _buildBottomNavBar(
    BuildContext context,
    PlusSettingsProvider plusSettings,
    int currentIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFloating = plusSettings.plusFloatingNavBar;
    final labelBehavior = plusSettings.plusNavBarAlwaysShowLabels
        ? NavigationDestinationLabelBehavior.alwaysShow
        : NavigationDestinationLabelBehavior.onlyShowSelected;

    // Shared keyboard focus handler
    Widget wrapWithFocus(Widget child) => FocusTraversalGroup(
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                switchToPage((currentIndex + 1) % pages.length);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                switchToPage(
                  (currentIndex - 1 + pages.length) % pages.length,
                );
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: child,
          ),
        );

    final navBar = NavigationBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: labelBehavior,
      animationDuration: Duration(
        milliseconds: plusSettings.plusEnableEnhancedAnimations ? 400 : 250,
      ),
      destinations: pages
          .map(
            (e) => NavigationDestination(
              icon: Icon(e.icon),
              selectedIcon: Icon(
                e.icon,
                color: colorScheme.onPrimaryContainer,
              ),
              label: tr(e.title),
            ),
          )
          .toList(),
      onDestinationSelected: (int index) async {
        AppHaptics.selectionClick();
        switchToPage(index);
      },
      selectedIndex: currentIndex,
    );

    final plusNavBar = PlusFloatingNavBar(
      // Rebuilt when destinations are added/removed: it sizes per-tab
      // animation controllers once.
      key: ValueKey(pages.length),
      pages: pages,
      currentIndex: currentIndex,
      onDestinationSelected: switchToPage,
      animationsEnabled: AppMotion.enabled(context),
      alwaysShowLabels: plusSettings.plusNavBarAlwaysShowLabels,
    );

    final enableGlass = plusSettings.plusEnableGlassmorphism;

    if (isFloating) {
      // Floating pill dock — frosted when glassmorphism is on, solid otherwise.
      return RepaintBoundary(
        key: _bottomNavBarKey,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            // Shadows outside ClipRRect so they aren't clipped.
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 36,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                  if (enableGlass)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: Offset.zero,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: ConditionalBlur(
                  enabled: enableGlass,
                  sigma: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(
                        alpha: enableGlass ? 0.72 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: enableGlass
                            ? colorScheme.primary.withValues(alpha: 0.18)
                            : colorScheme.outlineVariant.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Inner top-edge highlight beneath nav content
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colorScheme.primaryContainer.withValues(
                                    alpha: enableGlass ? 0.10 : 0.04,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45],
                              ),
                            ),
                          ),
                        ),
                        wrapWithFocus(plusNavBar),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Classic flat-edge bar — frosted when glassmorphism is on, solid otherwise.
    return RepaintBoundary(
      key: _bottomNavBarKey,
      child: ClipRRect(
        child: ConditionalBlur(
          enabled: enableGlass,
          sigma: 16,
          child: Container(
            color: colorScheme.surface.withValues(alpha: enableGlass ? 0.78 : 1.0),
            child: wrapWithFocus(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  navBar,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }
}

/// Per-app settings a shared link must never set: they only weaken security.
const _linkUnsafeSettings = {
  'allowInsecure',
  'allowInsecureRedirects',
  'allowedSigningCertHashes',
  'enableCertificatePinning',
};

/// Removes [_linkUnsafeSettings] from each app's additionalSettings (stored
/// either as a map or as a JSON string). Returns how many were removed.
int stripLinkUnsafeSettings(List<dynamic> apps) {
  var removed = 0;
  for (final app in apps) {
    if (app is! Map) continue;
    final raw = app['additionalSettings'];
    Map<String, dynamic>? settings;
    if (raw is Map) {
      settings = Map<String, dynamic>.from(raw);
    } else if (raw is String) {
      try {
        settings = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    if (settings == null) continue;
    final before = settings.length;
    settings.removeWhere((k, _) => _linkUnsafeSettings.contains(k));
    removed += before - settings.length;
    app['additionalSettings'] = raw is String ? safeJsonEncode(settings) : settings;
  }
  return removed;
}
