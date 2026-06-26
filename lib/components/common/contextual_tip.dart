import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/settings_provider.dart';

class ContextualTip extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;

  const ContextualTip({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lightbulb_outline,
  });

  @override
  State<ContextualTip> createState() => _ContextualTipState();
}

class _ContextualTipState extends State<ContextualTip> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (!settings.enableContextualTips || _dismissed) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: settings.plusEnableGlassmorphism
          ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.45)
          : Theme.of(context).colorScheme.tertiaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.icon,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              onPressed: () => setState(() => _dismissed = true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
