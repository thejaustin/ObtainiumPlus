import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/custom_app_bar.dart';
import 'package:obtainium/components/settings/expressive_settings_group.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Developer options for A/B testing visual choices in-app. Every option
/// defaults to the shipped look; older variants are opt-in.
class VisualLabPage extends StatelessWidget {
  const VisualLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plus = context.watch<PlusSettingsProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final double adaptiveMargin = screenWidth > 1040
        ? ((screenWidth - 1040) / 2).clamp(16.0, double.infinity)
        : 16.0;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: adaptiveMargin,
      vertical: 8.0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        key: const PageStorageKey<String>('visual_lab_page_scroll'),
        physics: plus.scrollPhysics,
        slivers: [
          CustomAppBar(
            title: tr('visualLab'),
            actions: [
              ScaleTouchWrapper(
                hapticOnPressDown: true,
                scaleDownFactor: 0.88,
                child: IconButton(
                  tooltip: tr('visualLabResetAll'),
                  icon: const Icon(Icons.restart_alt_rounded),
                  onPressed: () => _resetAll(context, plus),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: contentPadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      tr('visualLabDescription'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ExpressiveSettingsGroup(
                    title: tr('visualLabGroupNavigation'),
                    persistKey: 'visualLab:navigation',
                    icon: Icons.space_dashboard_rounded,
                    children: [
                      _ChoiceOption<SettingsNavPlacement>(
                        title: tr('visualLabNavPlacement'),
                        description: tr('visualLabNavPlacementDesc'),
                        value: plus.plusSettingsNavPlacement,
                        defaultValue: SettingsNavPlacement.bottom,
                        options: {
                          SettingsNavPlacement.bottom: tr('visualLabBottom'),
                          SettingsNavPlacement.top: tr('visualLabTop'),
                          SettingsNavPlacement.merged: tr('visualLabMerged'),
                        },
                        onChanged: (v) => plus.plusSettingsNavPlacement = v,
                      ),
                      _ChoiceOption<NavBarBlurStrength>(
                        title: tr('visualLabNavBlur'),
                        description: tr('visualLabNavBlurDesc'),
                        value: plus.plusLabNavBarBlur,
                        defaultValue: NavBarBlurStrength.strong,
                        options: {
                          NavBarBlurStrength.off: tr('visualLabOff'),
                          NavBarBlurStrength.soft: tr('visualLabSoft'),
                          NavBarBlurStrength.strong: tr('visualLabStrong'),
                        },
                        onChanged: (v) => plus.plusLabNavBarBlur = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ExpressiveSettingsGroup(
                    title: tr('visualLabGroupSettingsPage'),
                    persistKey: 'visualLab:settingsPage',
                    icon: Icons.settings_rounded,
                    children: [
                      _ChoiceOption<SettingsHeaderSize>(
                        title: tr('visualLabHeaderSize'),
                        description: tr('visualLabHeaderSizeDesc'),
                        value: plus.plusLabSettingsHeaderSize,
                        defaultValue: SettingsHeaderSize.large,
                        options: {
                          SettingsHeaderSize.large: tr('visualLabLarge'),
                          SettingsHeaderSize.compact: tr('visualLabCompact'),
                        },
                        onChanged: (v) => plus.plusLabSettingsHeaderSize = v,
                      ),
                      _ChoiceOption<SettingsAppBarActionsStyle>(
                        title: tr('visualLabAppBarActions'),
                        description: tr('visualLabAppBarActionsDesc'),
                        value: plus.plusLabSettingsAppBarActions,
                        defaultValue: SettingsAppBarActionsStyle.icons,
                        options: {
                          SettingsAppBarActionsStyle.icons: tr(
                            'visualLabIcons',
                          ),
                          SettingsAppBarActionsStyle.labelledChips: tr(
                            'visualLabLabelledChips',
                          ),
                        },
                        onChanged: (v) => plus.plusLabSettingsAppBarActions = v,
                      ),
                      _ChoiceOption<PlusFeaturesEntry>(
                        title: tr('visualLabPlusEntry'),
                        description: tr('visualLabPlusEntryDesc'),
                        value: plus.plusLabPlusFeaturesEntry,
                        defaultValue: PlusFeaturesEntry.sheet,
                        options: {
                          PlusFeaturesEntry.sheet: tr('visualLabSheet'),
                          PlusFeaturesEntry.jumpToSection: tr('visualLabJump'),
                        },
                        onChanged: (v) => plus.plusLabPlusFeaturesEntry = v,
                      ),
                      _ChoiceOption<bool>(
                        title: tr('visualLabHero'),
                        description: tr('visualLabHeroDesc'),
                        value: plus.plusLabShowSettingsHero,
                        defaultValue: true,
                        options: {
                          true: tr('visualLabShow'),
                          false: tr('visualLabHide'),
                        },
                        onChanged: (v) => plus.plusLabShowSettingsHero = v,
                      ),
                      _ChoiceOption<bool>(
                        title: tr('visualLabHeroChips'),
                        description: tr('visualLabHeroChipsDesc'),
                        value: plus.plusLabShowHeroTopicChips,
                        defaultValue: true,
                        options: {
                          true: tr('visualLabShow'),
                          false: tr('visualLabHide'),
                        },
                        onChanged: (v) => plus.plusLabShowHeroTopicChips = v,
                      ),
                      _ChoiceOption<int>(
                        title: tr('visualLabDescriptionLines'),
                        description: tr('visualLabDescriptionLinesDesc'),
                        value: plus.plusLabCompactDescriptionLines,
                        defaultValue: 2,
                        options: const {1: '1', 2: '2', 3: '3'},
                        onChanged: (v) =>
                            plus.plusLabCompactDescriptionLines = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _resetAll(context, plus),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(tr('visualLabResetAll')),
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetAll(BuildContext context, PlusSettingsProvider plus) {
    AppHaptics.mediumImpact();
    plus.resetVisualLab();
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(tr('visualLabResetDone'))));
  }
}

/// One Visual Lab option: title, description, default hint and a wrap of
/// choice chips (wraps instead of overflowing at large text sizes).
class _ChoiceOption<T> extends StatelessWidget {
  final String title;
  final String description;
  final T value;
  final T defaultValue;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _ChoiceOption({
    required this.title,
    required this.description,
    required this.value,
    required this.defaultValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = context.select<PlusSettingsProvider, double>(
      (s) => s.plusGlobalCornerRadius,
    );
    final isM3E = context.select<PlusSettingsProvider, bool>(
      (s) => s.plusEnableMaterialExpressive,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tr('visualLabDefaultIs', args: [options[defaultValue] ?? '']),
            style: theme.textTheme.labelSmall?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.entries.map((e) {
              final selected = e.key == value;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: CardMetrics.shape(
                  CardMetrics.pill(radius),
                  expressive: isM3E,
                  side: BorderSide(
                    color: selected
                        ? cs.primary.withValues(alpha: 0.38)
                        : cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                selectedColor: cs.primaryContainer,
                onSelected: (_) {
                  if (selected) return;
                  AppHaptics.selectionClick();
                  onChanged(e.key);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
