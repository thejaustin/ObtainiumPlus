import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/plus_features_sheet.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Master switch for all Obtainium+ features.
///
/// Individual Plus toggles live in their thematically-relevant settings
/// section (Appearance, Updates & Install, Notifications, Behavior,
/// Advanced & Debug) rather than here, so this is a single compact row
/// pinned above the section tabs — with quick access to the Plus Features
/// Overview sheet.
class PlusFeaturesSection extends StatelessWidget {
  final String? searchQuery;
  final bool? showAdvancedSettings;

  const PlusFeaturesSection({
    super.key,
    this.searchQuery,
    this.showAdvancedSettings,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery != null && searchQuery!.isNotEmpty;
    if (isSearching &&
        !tr(
          'enableAllPlusFeatures',
        ).toLowerCase().contains(searchQuery!.toLowerCase())) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<PlusSettingsProvider>(
      builder: (context, settings, child) {
        final bool isEnabled = settings.enableAllPlusFeatures;
        final bool isM3E = settings.plusEnableMaterialExpressive;
        final bool isCompact = settings.plusUseCompactSettings;
        final baseRadius = settings.plusOverrideIndividualCornerRadius
            ? settings.plusSettingsCornerRadius
            : settings.plusGlobalCornerRadius;
        final cardRadius = CardMetrics.card(baseRadius);
        final innerRadius = CardMetrics.inner(cardRadius);
        final badgeSize = isCompact ? 30.0 : 36.0;

        return AnimatedContainer(
          duration: Duration(
            milliseconds: settings.plusEnableEnhancedAnimations ? 300 : 0,
          ),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
          decoration: ShapeDecoration(
            color: isEnabled
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
            shape: CardMetrics.shape(
              cardRadius,
              expressive: isM3E,
              side: BorderSide(
                color: isEnabled
                    ? colorScheme.primary.withValues(alpha: 0.45)
                    : colorScheme.outlineVariant.withValues(alpha: 0.18),
                width: isEnabled ? 1.2 : 1.0,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            shape: CardMetrics.shape(cardRadius, expressive: isM3E),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 16,
                vertical: isCompact ? 6 : 10,
              ),
              child: Row(
                children: [
                  ScaleTouchWrapper(
                    hapticOnPressDown: true,
                    onTap: () {
                      AppHaptics.selectionClick();
                      showPlusFeaturesSheet(context: context);
                    },
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: ShapeDecoration(
                        color: isEnabled
                            ? colorScheme.primary.withValues(alpha: 0.16)
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.65,
                              ),
                        shape: CardMetrics.shape(
                          innerRadius,
                          expressive: isM3E,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: settings.plusEnableEnhancedAnimations
                              ? 250
                              : 0,
                        ),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isEnabled
                              ? Icons.auto_awesome_rounded
                              : Icons.auto_awesome_outlined,
                          key: ValueKey<bool>(isEnabled),
                          color: isEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: isCompact ? 16 : 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final next = !isEnabled;
                        next ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                        settings.enableAllPlusFeatures = next;
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tr('enableAllPlusFeatures'),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isEnabled
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isEnabled) ...[
                                const SizedBox(width: 6),
                                ScaleTouchWrapper(
                                  hapticOnPressDown: true,
                                  scaleDownFactor: 0.90,
                                  onTap: () {
                                    AppHaptics.selectionClick();
                                    showPlusFeaturesSheet(context: context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr('enableAllPlusFeaturesDescription'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isEnabled,
                    onChanged: (value) {
                      value ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                      settings.enableAllPlusFeatures = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
