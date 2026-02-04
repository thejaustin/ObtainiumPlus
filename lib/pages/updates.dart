import 'package:flutter/material.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/pages/apps.dart';

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var updatesFilter = AppsFilter();
    updatesFilter.statusFilter = {'updates'};
    return AppsPage(
      key: const Key('updates_page'),
      initialFilter: updatesFilter,
    );
  }
}
