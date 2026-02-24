import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/pages/apps.dart';
import 'package:obtainium/pages/system_updates.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final showSystemTab = settingsProvider.plusEnableSystemUpdateScanner;

    if (!showSystemTab) {
      var updatesFilter = AppsFilter();
      updatesFilter.statusFilter = {'updates'};
      return AppsPage(
        key: const Key('updates_page_tracked_only'),
        initialFilter: updatesFilter,
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Use a preferred size widget to avoid full app bar if only tab bar is needed
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('tracked')),
            Tab(text: tr('system')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrackedUpdates(),
          const SystemUpdatesPage(),
        ],
      ),
    );
  }

  Widget _buildTrackedUpdates() {
    var updatesFilter = AppsFilter();
    updatesFilter.statusFilter = {'updates'};
    return AppsPage(
      key: const Key('updates_page_tracked_tab'),
      initialFilter: updatesFilter,
    );
  }
}
