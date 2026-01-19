import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Quick Toggles Dashboard - A grid of important settings toggles
/// Placed at the top of the settings page for quick access
class QuickTogglesDashboard extends StatelessWidget {
  const QuickTogglesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('quickToggles'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickToggle(
                    context: context,
                    icon: settingsProvider.theme == ThemeSettings.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    label: tr('theme'),
                    value: settingsProvider.theme == ThemeSettings.dark,
                    onChanged: (value) {
                      settingsProvider.theme = value
                          ? ThemeSettings.dark
                          : ThemeSettings.light;
                    },
                  ),
                  _buildQuickToggle(
                    context: context,
                    icon: Icons.sync_outlined,
                    label: tr('backgroundUpdates'),
                    value: settingsProvider.updateInterval > 0,
                    onChanged: (value) {
                      settingsProvider.updateInterval = value ? 60 : 0; // Default to 1 hour if enabled
                    },
                  ),
                  _buildQuickToggle(
                    context: context,
                    icon: Icons.bug_report_outlined,
                    label: tr('deepLogging'),
                    value: settingsProvider.enableDeepLogging,
                    onChanged: (value) {
                      settingsProvider.enableDeepLogging = value;
                    },
                  ),
                  _buildQuickToggle(
                    context: context,
                    icon: Icons.auto_awesome_outlined,
                    label: tr('materialYou'),
                    value: settingsProvider.useMaterialYou,
                    onChanged: (value) {
                      settingsProvider.useMaterialYou = value;
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickToggle({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      width: 140, // Fixed width for consistent grid appearance
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: value ? 2 : 1,
        ),
      ),
      child: Semantics(
        checked: value,
        label: '$label: ${value ? tr('enabled') : tr('disabled')}',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: value
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}