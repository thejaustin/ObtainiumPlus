import 'package:flutter/material.dart';
import 'package:obtainium/services/known_issues_service.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final isCritical = issue.severity == 'critical';
    final accentColor = isCritical ? Colors.red.shade700 : Colors.orange;

    return AlertDialog(
      icon: Icon(
        isCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
        color: accentColor,
        size: 36,
      ),
      title: Text(
        issue.title,
        style: TextStyle(color: accentColor),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(issue.description),
          if (issue.fixedInVersion != null) ...[
            const SizedBox(height: 12),
            _InfoChip(
              icon: Icons.check_circle_outline,
              label: 'Fixed in ${issue.fixedInVersion}',
              color: Colors.green.shade700,
            ),
          ],
          const SizedBox(height: 8),
          _InfoChip(
            icon: Icons.open_in_new,
            label: 'Tracked on GitHub',
            color: colorScheme.primary,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        // Dismiss — suppresses this issue on future launches
        TextButton(
          onPressed: () async {
            await KnownIssuesService.dismissIssue(issue.id);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Dismiss'),
        ),

        // View Issue — opens the GitHub issue so the user can subscribe
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Follow Issue'),
          onPressed: () async {
            final url = Uri.parse(issue.githubIssueUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),

        // Check for Updates — switches to the Updates tab
        FilledButton.icon(
          icon: const Icon(Icons.system_update_outlined),
          label: const Text('Check for Updates'),
          style: FilledButton.styleFrom(backgroundColor: accentColor),
          onPressed: onCheckForUpdates,
        ),
      ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
