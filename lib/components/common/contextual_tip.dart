import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/utils/card_metrics.dart';

/// One tip the user can dismiss for good. [id] keys the dismissal.
class TipSpec {
  final String id;
  final String title;
  final String message;
  final IconData icon;

  const TipSpec({
    required this.id,
    required this.title,
    required this.message,
    this.icon = Icons.lightbulb_outline,
  });
}

/// Shows the first of [tips] the user hasn't dismissed, when tips are on.
class ContextualTip extends StatelessWidget {
  final List<TipSpec> tips;

  const ContextualTip({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final plusSettings = context.watch<PlusSettingsProvider>();
    TipSpec? tip;
    if (settings.enableContextualTips) {
      final dismissed = settings.dismissedTips;
      for (final t in tips) {
        if (!dismissed.contains(t.id)) {
          tip = t;
          break;
        }
      }
    }
    final anims = plusSettings.plusEnableEnhancedAnimations;
    return AnimatedSize(
      duration: Duration(milliseconds: anims ? 260 : 0),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: anims ? 200 : 0),
        child: tip == null
            ? const SizedBox(width: double.infinity)
            : _TipCard(key: ValueKey(tip.id), tip: tip),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final TipSpec tip;

  const _TipCard({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final onColor = colorScheme.onTertiaryContainer;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      color: plusSettings.plusEnableGlassmorphism
          ? colorScheme.tertiaryContainer.withValues(alpha: 0.45)
          : colorScheme.tertiaryContainer,
      elevation: 0,
      shape: CardMetrics.shape(
        CardMetrics.card(plusSettings.plusGlobalCornerRadius),
        expressive: plusSettings.plusEnableMaterialExpressive,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(tip.icon, color: onColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: onColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tip.message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: onColor),
                  ),
                ],
              ),
            ),
            ScaleTouchWrapper(
              hapticOnPressDown: true,
              scaleDownFactor: 0.88,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: tr('close'),
                color: onColor,
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    context.read<SettingsProvider>().dismissTip(tip.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
