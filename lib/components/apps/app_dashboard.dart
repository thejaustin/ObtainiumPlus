import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/omnibar.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class AppDashboard extends StatelessWidget {
  final Function(String) onSearchQuery;
  final Function(String) onUrlInput;
  final VoidCallback onCheckUpdates;

  const AppDashboard({
    super.key,
    required this.onSearchQuery,
    required this.onUrlInput,
    required this.onCheckUpdates,
  });

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.watch<AppsProvider>();
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final apps = appsProvider.getAppValues();
    final totalApps = apps.length;
    
    final updateApps = apps.where((app) => 
        app.app.installedVersion != null && 
        app.app.installedVersion != app.app.latestVersion
    ).toList();
    final updatesAvailable = updateApps.length;

    DateTime? lastCheck;
    for (var app in apps) {
      if (app.app.lastUpdateCheck != null) {
        if (lastCheck == null || app.app.lastUpdateCheck!.isAfter(lastCheck)) {
          lastCheck = app.app.lastUpdateCheck;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Omnibar - Unified Search/Add
          Omnibar(
            onSearchQuery: onSearchQuery,
            onUrlInput: onUrlInput,
          ),
          
          const SizedBox(height: 20),
          
          // Summary Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSummaryCard(
                  context,
                  icon: Icons.apps_rounded,
                  label: tr('appsString'),
                  value: totalApps.toString(),
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  context,
                  icon: Icons.update_rounded,
                  label: tr('updates'),
                  value: updatesAvailable.toString(),
                  color: updatesAvailable > 0 ? colorScheme.error : colorScheme.secondary,
                  onTap: updatesAvailable > 0 ? onCheckUpdates : null,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  context,
                  icon: Icons.history_rounded,
                  label: tr('lastCheck'),
                  value: lastCheck != null 
                      ? DateFormat.Md().add_jm().format(lastCheck.toLocal())
                      : tr('never'),
                  color: colorScheme.tertiary,
                ),
              ],
            ),
          ),
          
          // Recent Updates section
          if (updatesAvailable > 0) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  tr('recentUpdates'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (updatesAvailable > 5)
                  Text(
                    tr('plural_apps', args: [updatesAvailable.toString()]),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: updatesAvailable.clamp(0, 10),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildRecentUpdateIcon(context, updateApps[index]);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: settings.plusEnableGlassmorphism ? 12 : 0,
            sigmaY: settings.plusEnableGlassmorphism ? 12 : 0,
          ),
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(settings.plusEnableGlassmorphism ? 0.3 : 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentUpdateIcon(BuildContext context, AppInMemory app) {
    return Tooltip(
      message: app.name,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            if (app.icon != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(app.icon!, fit: BoxFit.cover, width: 64, height: 64),
              )
            else
              Center(child: Icon(Icons.apps_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.5))),
            
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
