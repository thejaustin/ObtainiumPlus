import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/pages/app_additional_options.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:obtainium/utils/update_health.dart';
import 'package:provider/provider.dart';

/// Whether the app page should show the update-health note for [app].
bool shouldShowUpdateHealthNote(App app, SettingsProvider settings) {
  if (!settings.showUpdateHealthAppNote || app.disabled) return false;
  final config = resolveUpdateHealthConfig(app.additionalSettings, settings);
  return isUpdateHealthIgnored(app) ||
      evaluateUpdateHealthReasons(app, config).isNotEmpty;
}

/// A tappable note on the app page that links to the app's "Update health
/// detection" options section. Opt-in (off by default).
class UpdateHealthNote extends StatelessWidget {
  final App app;

  const UpdateHealthNote({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (!shouldShowUpdateHealthNote(app, settings)) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final ignored = isUpdateHealthIgnored(app);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          AppHaptics.selectionClick();
          unawaited(
            showAppAdditionalOptions(
              context,
              app.id,
              scrollToSection: updateHealthSectionId,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(
                ignored ? Icons.info_outline : Icons.warning_amber_rounded,
                size: 16,
                color: ignored ? cs.onSurfaceVariant : cs.error,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  ignored
                      ? tr('updateHealthIgnoredNote')
                      : tr('updateHealthViewDetails'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
