import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/plus_features_sheet.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? colorScheme.primary.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant.withValues(alpha: 0.18),
              width: isEnabled ? 1.2 : 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: SwitchListTile.adaptive(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: ScaleTouchWrapper(
                onTap: () {
                  AppHaptics.selectionClick();
                  showPlusFeaturesSheet(context: context);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
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
                    size: 22,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      tr('enableAllPlusFeatures'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: tr('plusFeaturesOverview'),
                      onPressed: () {
                        AppHaptics.selectionClick();
                        showPlusFeaturesSheet(context: context);
                      },
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                tr('enableAllPlusFeaturesDescription'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: isEnabled,
              onChanged: (value) {
                AppHaptics.selectionClick();
                settings.enableAllPlusFeatures = value;
              },
            ),
          ),
        );
      },
    );
  }
}

