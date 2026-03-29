import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/services/known_issues_service.dart';
import 'package:obtainium/utils/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modal dialog shown on launch when the running app version has a known
/// critical issue.  The user can view the GitHub issue, jump to the Updates
/// tab to upgrade, or dismiss (which suppresses this issue on future launches).
class CriticalIssueDialog extends StatelessWidget {
  final KnownIssue issue;

  /// Called when the user taps "Check for Updates" — the home page uses this
  /// to switch to the Updates tab after closing the dialog.
  final VoidCallback onCheckForUpdates;

  const CriticalIssueDialog({
    super.key,
    required this.issue,
    required this.onCheckForUpdates,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final enableGlass = settings.plusEnableGlassmorphism;
    final colorScheme = Theme.of(context).colorScheme;
    final isCritical = issue.severity == 'critical';
    final accentColor = isCritical ? Colors.red.shade700 : Colors.orange;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: enableGlass ? 0.78 : 1.0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: enableGlass
                ? colorScheme.onSurface.withValues(alpha: 0.18)
                : colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: AppShadows.smooth(
            color: Colors.black,
            opacity: enableGlass ? 0.28 : 0.15,
            blurFactor: enableGlass ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ConditionalBlur(sigma: 24, enabled: enableGlass, child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(context, accentColor, enableGlass, isCritical),
                const Divider(height: 1),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(context, colorScheme),
                ),
                // Actions
                _buildActions(context, accentColor, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color accentColor, bool enableGlass, bool isCritical) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: enableGlass ? 0.2 : 0.15),
            accentColor.withValues(alpha: enableGlass ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
              color: accentColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            issue.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          issue.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (issue.fixedInVersion != null) ...[
          _InfoChip(
            icon: Icons.check_circle_outline,
            label: tr('fixedInVersion', namedArgs: {'version': issue.fixedInVersion!}),
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 8),
        ],
        _InfoChip(
          icon: Icons.open_in_new,
          label: tr('trackedOnGitHub'),
          color: colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Color accentColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action - Check for Updates
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.system_update_outlined),
              label: Text(tr('checkForUpdates')),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onCheckForUpdates,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Dismiss
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await KnownIssuesService.dismissIssue(issue.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(tr('dismiss')),
                ),
              ),
              const SizedBox(width: 8),
              // Follow Issue
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(tr('followIssue')),
                  onPressed: () async {
                    final url = Uri.parse(issue.githubIssueUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
