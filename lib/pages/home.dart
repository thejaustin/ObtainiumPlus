import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/editable_navigation_bar.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/discover.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';
import 'package:obtainium/pages/onboarding.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/pages/updates.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/services/deep_link_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:obtainium/utils/url_validator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:obtainium/utils/crash_tracker.dart';
import 'package:obtainium/services/known_issues_service.dart';
import 'package:obtainium/components/critical_issue_dialog.dart';
import 'package:obtainium/services/app_install_service.dart';

/// Shows the tab customization bottom sheet.
/// [allPages] can be provided when called from HomePageState (which has the map).
/// When called from settings or elsewhere, it builds its own page map.
void showTabCustomization(BuildContext context, [Map<String, NavigationPageItem>? allPages]) {
  final sp = context.read<SettingsProvider>();
  final allPageIds = ['apps', 'updates', 'add', 'discover', 'settings', 'import_export', 'logs'];

  // Build a minimal page info map if not provided
  final pages = allPages ?? {
    'apps': NavigationPageItem('apps', tr('appsString'), Icons.apps_outlined, Icons.apps, const SizedBox()),
    'updates': NavigationPageItem('updates', tr('updates'), Icons.update_outlined, Icons.update, const SizedBox()),
    'add': NavigationPageItem('add', tr('addApp'), Icons.add_circle_outline, Icons.add_circle, const SizedBox()),
    'discover': NavigationPageItem('discover', tr('discover'), Icons.explore_outlined, Icons.explore, const SizedBox()),
    'settings': NavigationPageItem('settings', tr('settings'), Icons.settings_outlined, Icons.settings, const SizedBox()),
    'import_export': NavigationPageItem('import_export', tr('importExport'), Icons.swap_vert_outlined, Icons.swap_vert, const SizedBox()),
    'logs': NavigationPageItem('logs', tr('appLogs'), Icons.article_outlined, Icons.article, const SizedBox()),
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final currentTabs = List<String>.from(sp.bottomTabs);
          final availableTabs = allPageIds.where((id) => !currentTabs.contains(id)).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('customizeTabs'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  // YOUR TABS section header
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('activeTabs').toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ),
                  // Reorderable tab list
                  Expanded(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        HapticFeedback.mediumImpact();
                        if (newIndex > oldIndex) newIndex--;
                        final item = currentTabs.removeAt(oldIndex);
                        currentTabs.insert(newIndex, item);
                        sp.bottomTabs = currentTabs;
                        setSheetState(() {});
                      },
                      children: currentTabs.map((id) {
                        final item = pages[id];
                        return ListTile(
                          key: ValueKey(id),
                          leading: Icon(item?.icon ?? Icons.tab),
                          title: Text(item?.title ?? id),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                color: currentTabs.length > 2
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                            onPressed: currentTabs.length > 2
                                ? () {
                                    HapticFeedback.lightImpact();
                                    currentTabs.remove(id);
                                    sp.bottomTabs = currentTabs;
                                    setSheetState(() {});
                                  }
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // AVAILABLE section
                  if (availableTabs.isNotEmpty) ...[
                    const Divider(indent: 24, endIndent: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tr('availableTabs').toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableTabs.map((id) {
                          final item = pages[id];
                          return ActionChip(
                            avatar: Icon(item?.icon ?? Icons.tab, size: 18),
                            label: Text(item?.title ?? id),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              currentTabs.add(id);
                              sp.bottomTabs = currentTabs;
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      );
    },
  );
}

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
  late PageController _pageController;
  bool _isEditMode = false;

  late Widget appsPage;
  late Widget updatesPage;
  late Widget logsPage;
  late Widget addAppPage;
  late Widget discoverPage;
  late Widget settingsPage;
  late Widget importExportPage;
  late Map<String, NavigationPageItem> allPages;
  late List<NavigationPageItem> activePages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    appsPage = AppsPage(key: GlobalKey<AppsPageState>());
    updatesPage = const UpdatesPage();
    logsPage = const LogsPage();
    addAppPage = AddAppPage(key: GlobalKey<AddAppPageState>());
    discoverPage = DiscoverPage();
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
          DateTime.now().year >= 2026) {
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
      if (!sp.xiaomiSetupShown) {
        await _showXiaomiSetupDialogIfNeeded(context, sp);
      }
      // Show follow-issue banner if a crash was recorded in the last session.
      if (await CrashTracker.hasPendingCrash() && mounted) {
        await CrashTracker.clearPendingCrash();
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            content: const Text(
              'A crash was detected in your last session. Follow the issue on GitHub to be notified when it\'s fixed.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: const Text('Dismiss'),
              ),
              TextButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  try {
                    await launchUrlString(
                      CrashTracker.issueTrackerUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                },
                child: const Text('Follow Issue'),
              ),
            ],
          ),
        );
      }

      // Show critical issue dialogs for the running version.
      if (mounted) {
        final appInfo = await AppInstallService.getInstalledInfo(obtainiumId);
        if (appInfo != null && mounted) {
          final activeIssues = await KnownIssuesService.getActiveIssues(
            appInfo.versionName ?? '',
            appInfo.versionCode ?? 0,
          );
          for (final issue in activeIssues) {
            if (!mounted) break;
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => CriticalIssueDialog(
                issue: issue,
                onCheckForUpdates: () {
                  Navigator.of(context).pop();
                  final idx = activePages.indexWhere((p) => p.id == 'updates');
                  if (idx != -1) switchToPage(idx);
                },
              ),
            );
          }
        }
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
      var sp = context.read<SettingsProvider>();
      var currentTabs = sp.bottomTabs;
      var index = currentTabs.indexOf('add');

      if (index != -1) {
        switchToPage(index);
        int attempts = 0;
        while ((addAppPage.key as GlobalKey<AddAppPageState>?)?.currentState == null && attempts < 300) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
          if (!mounted) return;
        }
        (addAppPage.key as GlobalKey<AddAppPageState>?)?.currentState?.linkFn(data);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => addAppPage),
        ).then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            (addAppPage.key as GlobalKey<AddAppPageState>?)?.currentState?.linkFn(data);
          });
        });
      }
    }

    interpretLink(Uri uri) async {
      isLinkActivity = true;
      await DeepLinkService.interpretLink(
        uri: uri,
        context: context,
        goToAddApp: goToAddApp,
        appsProvider: context.read<AppsProvider>(),
      );
    }

    final appLink = await _appLinks.getInitialLink();
    var initLinked = false;
    if (appLink != null) {
      await interpretLink(appLink);
      initLinked = true;
    }
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
      setState(() {
        selectedIndexHistory.clear();
      });
    } else if (selectedIndexHistory.isEmpty ||
        selectedIndexHistory.last != index) {
      setState(() {
        int existingInd = selectedIndexHistory.indexOf(index);
        if (existingInd >= 0) {
          selectedIndexHistory.removeAt(existingInd);
        }
        selectedIndexHistory.add(index);
      });
    }

    if (_pageController.hasClients) {
      final settingsProvider = context.read<SettingsProvider>();
      if (settingsProvider.disablePageTransitions) {
        _pageController.jumpToPage(index);
      } else {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: settingsProvider.plusEnableMaterialExpressive 
              ? AppConstants.expressiveStandard 
              : AppConstants.standardStandard,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.select<AppsProvider, int>((a) => a.apps.length);
    final viewSettings = context.watch<ViewSettingsProvider>();

    allPages = {
      'apps': NavigationPageItem('apps', tr('appsString'), Icons.apps_outlined, Icons.apps, appsPage),
      'updates': NavigationPageItem('updates', tr('updates'), Icons.update_outlined, Icons.update, updatesPage),
      'add': NavigationPageItem('add', tr('addApp'), Icons.add_circle_outline, Icons.add_circle, addAppPage),
      'discover': NavigationPageItem('discover', tr('discover'), Icons.explore_outlined, Icons.explore, discoverPage),
      'settings': NavigationPageItem('settings', tr('settings'), Icons.settings_outlined, Icons.settings, settingsPage),
      'import_export': NavigationPageItem('import_export', tr('importExport'), Icons.swap_vert_outlined, Icons.swap_vert, importExportPage),
      'logs': NavigationPageItem('logs', tr('appLogs'), Icons.article_outlined, Icons.article, logsPage),
    };

    activePages = viewSettings.bottomTabs
        .where((id) => allPages.containsKey(id))
        .map((id) => allPages[id]!)
        .toList();
    if (!activePages.any((p) => p.id == 'apps')) {
      activePages.insert(0, allPages['apps']!);
    }
    if (!activePages.any((p) => p.id == 'settings')) {
      activePages.add(allPages['settings']!);
    }

    int currentIndex = selectedIndexHistory.isEmpty ? 0 : selectedIndexHistory.last;
    if (currentIndex >= activePages.length) {
      currentIndex = 0;
      selectedIndexHistory = [0];
    }

    bool canPopNow() {
      if (isLinkActivity && selectedIndexHistory.length > 1) {
        return true;
      }
      if (selectedIndexHistory.isNotEmpty && selectedIndexHistory.length > 1) {
        return false;
      }
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
          if (selectedIndexHistory.isNotEmpty) {
            final targetIndex = selectedIndexHistory.length >= 2
                ? selectedIndexHistory.reversed.toList()[1]
                : 0;
            setIsReversing(targetIndex);
            setState(() {
              selectedIndexHistory.removeLast();
            });
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: settingsProvider.plusEnableMaterialExpressive 
                    ? AppConstants.expressiveStandard 
                    : AppConstants.standardStandard,
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          floatingActionButton: activePages[currentIndex].id == 'apps'
              ? FloatingActionButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => const AddAppPage(),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: activePages.map((p) => p.widget).toList(),
          ),
          bottomNavigationBar: EditableNavigationBar(
            activePages: activePages,
            allPages: allPages,
            selectedIndex: currentIndex,
            isEditMode: _isEditMode,
            onEditModeChanged: (editing) {
              setState(() => _isEditMode = editing);
            },
            onDestinationSelected: (int index) {
              HapticFeedback.selectionClick();
              if (index == currentIndex) {
                if (activePages[index].widget == appsPage) {
                  (appsPage.key as GlobalKey<AppsPageState>?)
                      ?.currentState
                      ?.scrollController
                      .animateTo(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                }
              } else {
                switchToPage(index);
              }
            },
            onReorder: (oldIndex, newIndex) {
              final tabs = List<String>.from(viewSettings.bottomTabs);
              // Map from activePages indices to tab IDs
              final movedId = activePages[oldIndex].id;
              final targetId = activePages[newIndex].id;
              final fromIdx = tabs.indexOf(movedId);
              final toIdx = tabs.indexOf(targetId);
              if (fromIdx != -1 && toIdx != -1) {
                tabs.removeAt(fromIdx);
                tabs.insert(toIdx, movedId);
                viewSettings.bottomTabs = tabs;
              }
            },
            onRemoveTab: (String id) {
              final tabs = List<String>.from(viewSettings.bottomTabs);
              tabs.remove(id);
              viewSettings.bottomTabs = tabs;
              // Adjust selected index if needed
              if (currentIndex >= tabs.length) {
                switchToPage(tabs.length - 1);
              }
            },
            onAddTab: (String id) {
              final tabs = List<String>.from(viewSettings.bottomTabs);
              tabs.add(id);
              viewSettings.bottomTabs = tabs;
            },
            labelBehavior: viewSettings.navigationLabelBehavior,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}
