import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:async';

import 'package:animations/animations.dart';
import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/pages/changelog.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:obtainium/utils/version_constant.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

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

class HomePageState extends State<HomePage> {
  List<int> selectedIndexHistory = [];
  bool isReversing = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  late List<NavigationPageItem> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      NavigationPageItem(
        'appsString',
        Icons.apps_rounded,
        AppsPage(key: GlobalKey<AppsPageState>()),
      ),
      NavigationPageItem(
        'importExport',
        Icons.import_export_rounded,
        const ImportExportPage(),
      ),
      NavigationPageItem(
        'settings',
        Icons.settings_rounded,
        const SettingsPage(),
      ),
    ];

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
        // Show Changelog on update
        await showDialog(
          context: context,
          builder: (context) => GlassDialog(
            title: "What's New in Obtainium+",
            icon: Icons.auto_awesome_rounded,
            content: const SizedBox(
              height: 400,
              width: double.maxFinite,
              child: ChangelogPage(isModal: true),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('ok')),
              ),
            ],
          ),
        );
        plusSettings.plusLastSeenVersion = currentVersion;
      } else if (!sp.welcomeShown) {
        await showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return GeneratedFormModal(
              title: tr('welcome'),
              items: const [],
              message:
                  "Welcome to Obtainium+!\n\nThis app allows you to install and update apps directly from their sources, bypassing traditional app stores.\n\nTo get started, tap the '+' button to add your first app.",
              singleNullReturnButton: tr('ok'),
            );
          },
        );
        sp.welcomeShown = true;
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
                InkWell(
                  onTap: () {
                    launchUrlString(
                      'https://keepandroidopen.org/',
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      tr('googleVerificationWarningP2'),
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              singleNullReturnButton: tr('ok'),
            );
          },
        );
        sp.googleVerificationWarningShown = true;
      }
    });
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    goToAddApp(String data) async {
      // Add App is no longer a tab; open it as a pushed route and let
      // AddAppPage feed the URL into its form via initialUrl -> linkFn.
      if (!mounted) return;
      await pushRoute(context, AddAppPage(initialUrl: data));
    }

    goToExistingApp(String appId) async {
      // Go to Apps page
      switchToPage(0);
      while ((pages[0].widget.key as GlobalKey<AppsPageState>?)?.currentState ==
          null) {
        await Future.delayed(const Duration(microseconds: 1));
      }

      // Navigate to the app
      (pages[0].widget.key as GlobalKey<AppsPageState>?)?.currentState
          ?.openAppById(appId);
    }

    interpretLink(Uri uri) async {
      var action = uri.host;
      var data = uri.path.length > 1 ? uri.path.substring(1) : "";
      try {
        if (action == 'add') {
          // Ensure apps are loaded
          AppsProvider appsProvider = context.read<AppsProvider>();
          while (appsProvider.loadingApps) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
          if (!mounted) return;

          // See if we already have this app
          String standardizedUrl = SourceProvider()
              .getSource(data)
              .standardizeUrl(data);

          AppInMemory? existingApp = appsProvider.apps.values
              .where((AppInMemory a) => a.app.url == standardizedUrl)
              .firstOrNull;

          if (existingApp != null) {
            await goToExistingApp(existingApp.app.id);
          } else {
            await goToAddApp(data);
          }
        } else if (action == 'app' || action == 'apps') {
          var dataStr = Uri.decodeComponent(data);
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
                      ExpansionTile(
                        title: const Text('Raw JSON'),
                        children: [
                          Text(
                            dataStr,
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
              action == 'app'
                  ? '{ "apps": [$dataStr] }'
                  : '{ "apps": $dataStr }',
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
        } else {
          throw ObtainiumError(tr('unknown'));
        }
      } catch (e) {
        if (mounted) showError(e, context);
      }
    }

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialLink();
    var initLinked = false;
    if (appLink != null) {
      await interpretLink(appLink);
      initLinked = true;
    }
    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (!initLinked) {
        await interpretLink(uri);
      } else {
        initLinked = false;
      }
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
    setIsReversing(index);
    if (index == 0) {
      while ((pages[0].widget.key as GlobalKey<AppsPageState>).currentState !=
          null) {
        // Avoid duplicate GlobalKey error
        await Future.delayed(const Duration(microseconds: 1));
      }
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

    final showNavBar = plusSettings.plusEnableBottomNavBar;
    final currentIndex = showNavBar
        ? (selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last)
        : 0;

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
            child: pages.elementAt(currentIndex).widget,
          );

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
        final clearSelected = (pages[0].widget.key as GlobalKey<AppsPageState>)
            .currentState!
            .clearSelected();
        if (!clearSelected) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        // The omnibar "+" — the single entry point for the combined
        // add/search/discover flow, visible on every tab.
        floatingActionButton: plusSettings.plusEnableFAB && !settingsProvider.isTV
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
            : pageBody,
        bottomNavigationBar: settingsProvider.isTV || !showNavBar
            ? null
            : FocusTraversalGroup(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      NavigationBar(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        indicatorColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.onlyShowSelected,
                        animationDuration: const Duration(milliseconds: 300),
                        destinations: pages
                            .map(
                              (e) => NavigationDestination(
                                icon: Icon(e.icon),
                                selectedIcon: Icon(
                                  e.icon,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
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
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _linkSubscription?.cancel();
  }
}
