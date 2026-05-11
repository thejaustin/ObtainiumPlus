import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:obtainium/utils/device_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/utils/app_utils.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/editable_navigation_bar.dart';
import 'package:obtainium/components/glass_dialog.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/omnibar.dart';
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
import 'package:obtainium/components/force_update_dialog.dart';
import 'package:obtainium/services/app_install_service.dart';

/// Shows the tab customization bottom sheet.
/// [allPages] can be provided when called from HomePageState (which has the map).
/// When called from settings or elsewhere, it builds its own page map.
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
            return GlassDialog(
              title: tr('note'),
              icon: Icons.info_outline,
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
        final issueUrl = await CrashTracker.getSpecificIssueUrl();
        await CrashTracker.clearPendingCrash();
        if (mounted) {
          ScaffoldMessenger.of(context).showMaterialBanner(
            MaterialBanner(
              leading: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
              content: Text(tr('crashDetectedFollowOnGitHub')),
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                  child: Text(tr('dismiss')),
                ),
                TextButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                    try {
                      await launchUrlString(
                        issueUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                  child: Text(tr('followIssue')),
                ),
              ],
            ),
          );
        }
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
            if (issue.forceUpdate) {
              await showDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (_) => ForceUpdateDialog(issue: issue),
              );
            } else {
              await showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => CriticalIssueDialog(
                  issue: issue,
                  onCheckForUpdates: () {
                    Navigator.of(context).pop();
                    final idx =
                        activePages.indexWhere((p) => p.id == 'updates');
                    if (idx != -1) switchToPage(idx);
                  },
                ),
              );
            }
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
        builder: (ctx) => GlassDialog(
          title: tr('xiaomiSetupRequired'),
          icon: Icons.battery_alert_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('xiaomiSetupDescription')),
              const SizedBox(height: 16),
              Text(
                tr('xiaomiSetupSteps'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                sp.xiaomiSetupShown = true;
                Navigator.of(ctx).pop();
              },
              child: Text(tr('done')),
            ),
          ],
        ),
      );
    } catch (e) {
      talker.warning('Device detection error (Xiaomi setup): $e');
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
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => AddAppPage(initialUrl: data),
        );
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
    if (index < 0 || index >= activePages.length) return;
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
        final speed = settingsProvider.animationSpeedMultiplier;
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: (300 * speed).round()),
          curve: settingsProvider.plusEnableMaterialExpressive
              ? AppConstants.expressiveStandard
              : AppConstants.standardStandard,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use select to avoid rebuilding the root Scaffold when unrelated provider
    // fields change (e.g. sort order, glass setting, app list updates).
    final bottomTabs = context.select<ViewSettingsProvider, List<String>>((v) => List.from(v.bottomTabs));
    final labelBehavior = context.select<ViewSettingsProvider, NavigationDestinationLabelBehavior>((v) => v.navigationLabelBehavior);
    final plusDeveloperMode = context.select<SettingsProvider, bool>((s) => s.plusDeveloperMode);
    final plusEnableMaterialExpressive = context.select<SettingsProvider, bool>((s) => s.plusEnableMaterialExpressive);

    allPages = {
      'apps': NavigationPageItem('apps', tr('appsString'), Icons.apps_outlined, Icons.apps, appsPage),
      'updates': NavigationPageItem('updates', tr('updates'), Icons.update_outlined, Icons.update, updatesPage),
      'discover': NavigationPageItem('discover', tr('discover'), Icons.explore_outlined, Icons.explore, discoverPage),
      'settings': NavigationPageItem('settings', tr('settings'), Icons.settings_outlined, Icons.settings, settingsPage),
      'more': NavigationPageItem('more', tr('more'), Icons.more_horiz_outlined, Icons.more_horiz, settingsPage), // Placeholder for submenu
    };

    activePages = bottomTabs
        .where((id) => allPages.containsKey(id))
        .map((id) => allPages[id]!)
        .toList();
    if (!activePages.any((p) => p.id == 'apps')) {
      activePages.insert(0, allPages['apps']!);
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
                curve: plusEnableMaterialExpressive
                    ? AppConstants.expressiveStandard
                    : AppConstants.standardStandard,
              );
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          floatingActionButton: Builder(builder: (context) {
            final showFab = activePages[currentIndex].id == 'apps' ||
                activePages[currentIndex].id == 'updates';
            return IgnorePointer(
              ignoring: !showFab,
              child: AnimatedOpacity(
                opacity: showFab ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: AppConstants.expressiveStandard,
                child: AnimatedScale(
                  scale: showFab ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  curve: AppConstants.expressiveDecelerate,
                  child: const AppActionsFAB(),
                ),
              ),
            );
          }),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: activePages.map((p) => p.widget).toList(),
          ),
          bottomNavigationBar: activePages.length > 1 ? EditableNavigationBar(
            activePages: activePages,
            allPages: allPages,
            selectedIndex: currentIndex,
            isEditMode: _isEditMode,
            onEditModeChanged: (editing) {
              setState(() => _isEditMode = editing);
            },
            onDestinationSelected: (int index) {
              AppHaptics.selectionClick();
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
              final vs = context.read<ViewSettingsProvider>();
              final tabs = List<String>.from(vs.bottomTabs);
              // Map from activePages indices to tab IDs
              final movedId = activePages[oldIndex].id;
              final targetId = activePages[newIndex].id;
              final fromIdx = tabs.indexOf(movedId);
              final toIdx = tabs.indexOf(targetId);
              if (fromIdx != -1 && toIdx != -1) {
                tabs.removeAt(fromIdx);
                tabs.insert(toIdx, movedId);
                vs.bottomTabs = tabs;
              }
            },
            onRemoveTab: (String id) {
              final vs = context.read<ViewSettingsProvider>();
              final tabs = List<String>.from(vs.bottomTabs);
              tabs.remove(id);
              vs.bottomTabs = tabs;
              // Adjust selected index if needed
              if (currentIndex >= tabs.length) {
                switchToPage(tabs.length - 1);
              }
            },
            onAddTab: (String id) {
              final vs = context.read<ViewSettingsProvider>();
              final tabs = List<String>.from(vs.bottomTabs);
              tabs.add(id);
              vs.bottomTabs = tabs;
            },
            labelBehavior: labelBehavior,
          ) : null,
          extendBody: true,
          extendBodyBehindAppBar: true,
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
