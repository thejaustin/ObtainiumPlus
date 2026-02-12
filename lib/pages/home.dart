import 'dart:async';

import 'package:animations/animations.dart';
import 'package:app_links/app_links.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';
import 'package:obtainium/pages/onboarding.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/pages/updates.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/url_validator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class NavigationPageItem {
  final String id;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget widget;

  NavigationPageItem(this.id, this.title, this.icon, this.selectedIcon, this.widget);
}

class HomePageState extends State<HomePage> {
  List<int> selectedIndexHistory = [];
  bool isReversing = false;
  int prevAppCount = -1;
  bool prevIsLoading = true;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool isLinkActivity = false;

  late Widget appsPage;
  late Widget updatesPage;
  late Widget logsPage;
  late Widget addAppPage;
  late Widget settingsPage;
  late Widget importExportPage;
  late Map<String, NavigationPageItem> allPages;
  late List<NavigationPageItem> activePages;

  @override
  void initState() {
    super.initState();
    appsPage = AppsPage(key: GlobalKey<AppsPageState>());
    updatesPage = const UpdatesPage();
    logsPage = const LogsPage();
    addAppPage = AddAppPage(key: GlobalKey<AddAppPageState>());
    settingsPage = const SettingsPage();
    importExportPage = const ImportExportPage();

    initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var sp = context.read<SettingsProvider>();
      if (!sp.welcomeShown) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingPage(
              onDone: () {
                sp.welcomeShown = true;
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
      if (!sp.googleVerificationWarningShown &&
          DateTime.now().year >=
              2026 /* Gives some time to translators between now and Jan */ ) {
        await showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text(tr('note')),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  Text(tr('googleVerificationWarningP1')),
                  GestureDetector(
                    onTap: () {
                      launchUrlString(
                        'https://keepandroidopen.org/',
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Text(
                      tr('googleVerificationWarningP2'),
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(tr('googleVerificationWarningP3')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    sp.googleVerificationWarningShown = true;
                    Navigator.of(context).pop(null);
                  },
                  child: Text(tr('ok')),
                ),
              ],
            );
          },
        );
      }
      // Show Xiaomi setup dialog if needed
      if (!sp.xiaomiSetupShown) {
        await _showXiaomiSetupDialogIfNeeded(context, sp);
      }
    });
  }

  Future<void> _showXiaomiSetupDialogIfNeeded(BuildContext context, SettingsProvider sp) async {
    try {
      final isXiaomi = await DeviceUtils.isXiaomiDevice();

      if (!isXiaomi) return;
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.battery_alert_outlined, color: Colors.orange, size: 48),
          title: Text(tr('xiaomiSetupRequired')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('xiaomiSetupDescription')),
              const SizedBox(height: 16),
              Text(
                tr('xiaomiSetupSteps'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await AppInstallService.openXiaomiAutostartSettings();
                  },
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: Text(tr('enableAutoStart')),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AppInstallService.openXiaomiBatterySaverSettings();
                  },
                  icon: const Icon(Icons.battery_saver_outlined),
                  label: Text(tr('disableBatterySaver')),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    sp.xiaomiSetupShown = true;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(tr('done')),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      // Ignore errors in device detection
    }
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    goToAddApp(String data) async {
      // Find where AddAppPage is in the current pages list (if at all)
      // This requires accessing the current pages list which is dynamic.
      // We'll handle this by checking if it's in the tabs in the main build method logic
      // But we need to switch to it.
      
      // Accessing settings provider directly here might be slightly racy if build hasn't run, 
      // but usually fine in async callback.
      var sp = context.read<SettingsProvider>();
      var currentTabs = sp.bottomTabs;
      var index = currentTabs.indexOf('add');

      if (index != -1) {
        switchToPage(index);
        // Wait for frame/state with timeout to prevent infinite loop
        int attempts = 0;
        while ((addAppPage.key as GlobalKey<AddAppPageState>?)?.currentState == null && attempts < 300) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
          if (!mounted) return;
        }
        (addAppPage.key as GlobalKey<AddAppPageState>?)?.currentState?.linkFn(data);
      } else {
        // If not a tab, push it
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => addAppPage),
        ).then((_) {
          // Wait for mount? Push is sync-ish for route creation but async for animation.
          // We can't easily call linkFn on a pushed route's state without a key that is mounted.
          // Since we use a GlobalKey for addAppPage, it should be fine as long as we don't duplicate it.
          // Using the SAME GlobalKey for a pushed route while it might be elsewhere is tricky,
          // but here we know it's NOT in the tabs (index == -1).
          WidgetsBinding.instance.addPostFrameCallback((_) {
             (addAppPage.key as GlobalKey<AddAppPageState>?)?.currentState?.linkFn(data);
          });
        });
      }
    }

    interpretLink(Uri uri) async {
      // SECURITY: Validate deep link before processing
      if (!URLValidator.isValidDeepLink(uri)) {
        showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text(tr('error')),
              content: Text('Invalid or unauthorized deep link. This link may be malicious.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(tr('ok')),
                ),
              ],
            );
          },
        );
        return;
      }

      isLinkActivity = true;
      var action = uri.host;
      var data = uri.path.length > 1 ? uri.path.substring(1) : "";

      // SECURITY: Sanitize input data
      data = URLValidator.sanitizeInput(data);

      try {
        if (action == 'add') {
          await goToAddApp(data);
        } else if (action == 'app' || action == 'apps') {
          var dataStr = Uri.decodeComponent(data);

          // SECURITY: Validate JSON input
          if (!URLValidator.isValidJSONInput(dataStr)) {
            showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: Text(tr('error')),
                  content: Text('Invalid or potentially malicious JSON data.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(tr('ok')),
                    ),
                  ],
                );
              },
            );
            return;
          }

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
        showError(e, context);
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
    // If switching to index 0 (assumed home/apps), clear history logic same as before?
    // With dynamic tabs, index 0 is just the first tab.
    // We should probably clear history if we tap the *current* tab again (reset stack)
    // or if we go to the "main" tab. Let's assume the first tab is "main".
    
    if (index == 0) {
      // Logic for "main" tab reset
      // We need to identify if the widget at index 0 is AppsPage to pop its state
      // Accessing activePages here is tricky without passing it or storing it.
      // We'll rely on the fact that build rebuilds activePages.
      
      // For now, simpler history management:
      setState(() {
        if (selectedIndexHistory.contains(index)) {
             // If we go back to a tab already in history, we might want to unwind to it?
             // Or just add it. Standard nav bar usually just switches.
             // Android back button often unwinds.
        }
        
        // Specific logic for resetting AppsPage selection if it's the target
        // We can do this in build or here if we have reference.
        // Since we have appsPage widget instance, we can check its key.
        if (appsPage.key is GlobalKey<AppsPageState>) {
             // We can check if index corresponds to appsPage, but we don't know index here easily
             // without recalculating activePages.
             // Let's defer "reset" logic to when the user taps the same tab again?
             // Standard behavior: Tap active tab -> reset/scroll to top.
        }
      });
    }

    if (selectedIndexHistory.isEmpty ||
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
    AppsProvider appsProvider = context.watch<AppsProvider>();
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();

    // Refresh allPages map to ensure translations are up to date
    // Using M3 icon pattern: outlined for unselected, filled for selected
    allPages = {
      'apps': NavigationPageItem('apps', tr('appsString'), Icons.apps_outlined, Icons.apps, appsPage),
      'updates': NavigationPageItem('updates', tr('updates'), Icons.update_outlined, Icons.update, updatesPage),
      'add': NavigationPageItem('add', tr('addApp'), Icons.add_circle_outline, Icons.add_circle, addAppPage),
      'settings': NavigationPageItem('settings', tr('settings'), Icons.settings_outlined, Icons.settings, settingsPage),
      'import_export': NavigationPageItem('import_export', tr('importExport'), Icons.swap_vert_outlined, Icons.swap_vert, importExportPage),
      'logs': NavigationPageItem('logs', tr('appLogs'), Icons.article_outlined, Icons.article, logsPage),
    };

    // Build active pages from user's configured tab order
    activePages = settingsProvider.bottomTabs
        .where((id) => allPages.containsKey(id))
        .map((id) => allPages[id]!)
        .toList();
    // Ensure at least apps and settings are always present
    if (!activePages.any((p) => p.id == 'apps')) {
      activePages.insert(0, allPages['apps']!);
    }
    if (!activePages.any((p) => p.id == 'settings')) {
      activePages.add(allPages['settings']!);
    }

    // Determine current index
    int currentIndex = selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last;
    if (currentIndex >= activePages.length) {
      currentIndex = 0;
      selectedIndexHistory = [0];
    }
    
    // Logic to handle "Add App" deep links or actions
    // Since Add is no longer a tab, we need to push it as a route
    // This is handled by `goToAddApp` logic, which needs updating.

    // Determine if we can pop
    bool canPopNow() {
      if (isLinkActivity && selectedIndexHistory.length > 1) {
        return true;
      }
      if (selectedIndexHistory.isNotEmpty && selectedIndexHistory.length > 1) {
        return false; // Allow popping history
      }
      
      // Check if current page allows popping (e.g. AppsPage selection clearing)
      Widget currentPage = activePages[currentIndex].widget;
      if (currentPage == appsPage) {
        final key = appsPage.key as GlobalKey<AppsPageState>?;
        if (key?.currentState != null) {
          return !key!.currentState!.clearSelected();
        }
      }
      
      return true;
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: PopScope(
        canPop: canPopNow(),
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;

          // Handle navigation history
          if (selectedIndexHistory.isNotEmpty) {
            setIsReversing(
              selectedIndexHistory.length >= 2
                  ? selectedIndexHistory.reversed.toList()[1]
                  : 0,
            );
            setState(() {
              selectedIndexHistory.removeLast();
            });
          }
        },
        child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        floatingActionButton: activePages[currentIndex].id == 'apps'
            ? FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              tr('addAppOptions'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.link),
                            title: Text(tr('appSourceURL')),
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (context) => const AddAppPage(initialTab: 0),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.explore_outlined),
                            title: Text(tr('discover')),
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (context) => const AddAppPage(initialTab: 1),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.import_export),
                            title: Text(tr('importExport')),
                            onTap: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (context) => const ImportExportPage(),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              tr('githubImportNotice'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
        body: PageTransitionSwitcher(
          duration: Duration(
            milliseconds: settingsProvider.disablePageTransitions
                ? 0
                : AppConstants.expressiveAnimationMs,
          ),
          reverse: settingsProvider.reversePageTransitions
              ? !isReversing
              : isReversing,
          transitionBuilder:
              (
                Widget child,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: AppConstants.expressiveStandard,
                );
                return SharedAxisTransition(
                  animation: curvedAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
          child: activePages[currentIndex].widget,
        ),
        bottomNavigationBar: NavigationBar(
          elevation: 3,
          surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
          indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
          animationDuration: const Duration(milliseconds: 300),
          labelBehavior: settingsProvider.navigationLabelBehavior,
          destinations: activePages
              .map(
                (e) =>
                    NavigationDestination(
                      icon: Icon(e.icon),
                      selectedIcon: Icon(e.selectedIcon),
                      label: e.title,
                    ),
              )
              .toList(),
          onDestinationSelected: (int index) async {
            HapticFeedback.selectionClick();
            // Check if user tapped the already active tab
            if (index == currentIndex) {
               // Optional: Reset logic (scroll to top, etc.)
               // For AppsPage:
               if (activePages[index].widget == appsPage) {
                 (appsPage.key as GlobalKey<AppsPageState>?)?.currentState?.scrollController.animateTo(
                   0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
               }
            } else {
              switchToPage(index);
            }
          },
          selectedIndex: currentIndex,
        ),
      ),
    ),
  );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
