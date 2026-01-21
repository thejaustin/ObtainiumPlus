import 'dart:async';

import 'package:animations/animations.dart';
import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
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
  final Widget widget;

  NavigationPageItem(this.id, this.title, this.icon, this.widget);
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

  @override
  void initState() {
    super.initState();
    appsPage = AppsPage(key: GlobalKey<AppsPageState>());
    // Create an AppsFilter for updates
    var updatesFilter = AppsFilter();
    updatesFilter.statusFilter = {'updates'};
    updatesPage = AppsPage(
      key: GlobalKey<AppsPageState>(),
      initialFilter: updatesFilter,
    );
    logsPage = const LogsPage();
    addAppPage = AddAppPage(key: GlobalKey<AddAppPageState>());
    settingsPage = const SettingsPage();
    importExportPage = const ImportExportPage();

    initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var sp = context.read<SettingsProvider>();
      if (!sp.welcomeShown) {
        await showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text(tr('welcome')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  Text(tr('documentationLinksNote')),
                  GestureDetector(
                    onTap: () {
                      launchUrlString(
                        'https://github.com/ImranR98/Obtainium/blob/main/README.md',
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Text(
                      'https://github.com/ImranR98/Obtainium/blob/main/README.md',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    sp.welcomeShown = true;
                    Navigator.of(context).pop(null);
                  },
                  child: Text(tr('ok')),
                ),
              ],
            );
          },
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
    });
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
        // Wait for frame/state
        while ((addAppPage.key as GlobalKey<AddAppPageState>?)?.currentState == null) {
          await Future.delayed(const Duration(milliseconds: 10));
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

  void showCustomizeTabsDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomizeTabsDialog(
        allPages: allPages,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppsProvider appsProvider = context.watch<AppsProvider>();
    SettingsProvider settingsProvider = context.watch<SettingsProvider>();

    // Refresh allPages map to ensure translations are up to date
    allPages = {
      'apps': NavigationPageItem('apps', tr('appsString'), Icons.apps, appsPage),
      'updates': NavigationPageItem('updates', tr('updates'), Icons.system_update, updatesPage),
      'add': NavigationPageItem('add', tr('addApp'), Icons.add, addAppPage),
      'settings': NavigationPageItem('settings', tr('settings'), Icons.settings, settingsPage),
      'import_export': NavigationPageItem('import_export', tr('importExport'), Icons.import_export, importExportPage),
      'logs': NavigationPageItem('logs', tr('appLogs'), Icons.notes, logsPage),
    };

    List<String> tabIds = settingsProvider.bottomTabs;
    List<NavigationPageItem> activePages = [];
    for (var id in tabIds) {
      if (allPages.containsKey(id)) {
        activePages.add(allPages[id]!);
      }
    }
    
    // Ensure at least one tab (Apps) if something goes wrong or list is empty
    if (activePages.isEmpty) {
      activePages.add(allPages['apps']!);
      if (tabIds.isEmpty) {
        // Fix settings if empty
        settingsProvider.bottomTabs = ['apps'];
      }
    }

    if (!prevIsLoading &&
        prevAppCount >= 0 &&
        appsProvider.apps.length > prevAppCount &&
        !isLinkActivity) {
          // If a new app was added, try to switch to Apps tab
          int appsIndex = activePages.indexWhere((p) => p.widget == appsPage);
          if (appsIndex != -1 && (selectedIndexHistory.isEmpty || selectedIndexHistory.last != appsIndex)) {
            switchToPage(appsIndex);
          }
    }
    prevAppCount = appsProvider.apps.length;
    prevIsLoading = appsProvider.loadingApps;

    // Determine current index
    int currentIndex = selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last;
    if (currentIndex >= activePages.length) {
      currentIndex = 0;
      selectedIndexHistory = [0];
    }

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

    return PopScope(
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
          shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
          indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
          animationDuration: const Duration(milliseconds: 300),
          labelBehavior: settingsProvider.navigationLabelBehavior,
          destinations: activePages
              .map(
                (e) =>
                    NavigationDestination(
                      icon: GestureDetector(
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          showCustomizeTabsDialog();
                        },
                        child: Icon(e.icon),
                      ),
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
    );
  }

  @override
  void dispose() {
    super.dispose();
    _linkSubscription?.cancel();
  }
}

class CustomizeTabsDialog extends StatefulWidget {
  final Map<String, NavigationPageItem> allPages;

  const CustomizeTabsDialog({super.key, required this.allPages});

  @override
  State<CustomizeTabsDialog> createState() => _CustomizeTabsDialogState();
}

class _CustomizeTabsDialogState extends State<CustomizeTabsDialog> {
  late List<String> currentTabs;
  late List<String> availableHiddenTabs;

  @override
  void initState() {
    super.initState();
    var sp = context.read<SettingsProvider>();
    currentTabs = List.from(sp.bottomTabs);
    
    availableHiddenTabs = widget.allPages.keys
        .where((id) => !currentTabs.contains(id))
        .toList();
  }

  void _save() {
    context.read<SettingsProvider>().bottomTabs = currentTabs;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('customizeTabs') /* Use a key if available or generic text */),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('activeTabs'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final String item = currentTabs.removeAt(oldIndex);
                    currentTabs.insert(newIndex, item);
                  });
                },
                children: [
                  for (final id in currentTabs)
                    ListTile(
                      key: ValueKey(id),
                      leading: Icon(widget.allPages[id]?.icon ?? Icons.error),
                      title: Text(widget.allPages[id]?.title ?? id),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (currentTabs.length <= 1) {
                            // Don't allow removing last tab
                            return; 
                          }
                          setState(() {
                            currentTabs.remove(id);
                            availableHiddenTabs.add(id);
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (availableHiddenTabs.isNotEmpty) ...[
              const Divider(),
              Text(tr('availableTabs'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: availableHiddenTabs.map((id) {
                  return ActionChip(
                    avatar: Icon(widget.allPages[id]?.icon, size: 16),
                    label: Text(widget.allPages[id]?.title ?? id),
                    onPressed: () {
                      setState(() {
                        availableHiddenTabs.remove(id);
                        currentTabs.add(id);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: _save,
          child: Text(tr('save')),
        ),
      ],
    );
  }
}