import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/components/settings/settings_feature_toggle.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Generic Control Grid for Boolean Settings
/// Displays boolean settings in a compact, card-chip grid layout
class GenericBooleanControlGrid<T extends ChangeNotifier>
    extends StatelessWidget {
  final String title;
  final bool embedded;
  final List<
    ({
      IconData icon,
      String label,
      String? description,
      bool Function(T) getValue,
      void Function(T, bool) setValue,
    })
  >
  settings;

  const GenericBooleanControlGrid({
    super.key,
    required this.title,
    required this.settings,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (settings.isEmpty) return const SizedBox.shrink();
    return Consumer2<T, PlusSettingsProvider>(
      builder: (context, provider, plusSettings, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final isCompact = plusSettings.plusUseCompactSettings;
        final isM3E = plusSettings.plusEnableMaterialExpressive;
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth >= 1100
            ? 5
            : (screenWidth >= 800
                  ? 4
                  : (screenWidth > 550 ? 3 : (isCompact ? 3 : 2)));
        final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
            ? plusSettings.plusSettingsCornerRadius
            : plusSettings.plusGlobalCornerRadius;
        final cardRadius = CardMetrics.card(baseRadius);

        if (!plusSettings.plusSettingsUseGridToggles) {
          final listColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!embedded)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 14 : 16,
                    isCompact ? 8 : 12,
                    isCompact ? 14 : 16,
                    4,
                  ),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ...settings.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final val = s.getValue(provider);
                return Column(
                  children: [
                    SwitchListTile.adaptive(
                      dense: isCompact,
                      visualDensity: isCompact ? VisualDensity.compact : null,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 14 : 16,
                        vertical: isCompact ? 0 : 2,
                      ),
                      secondary: buildSettingsIconBadge(
                        context,
                        s.icon,
                        active: val,
                      ),
                      title: Text(
                        s.label,
                        style: isCompact
                            ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              )
                            : Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle:
                          (s.description != null && s.description!.isNotEmpty)
                          ? Text(
                              s.description!,
                              maxLines: isCompact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: isCompact ? 11.5 : null,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            )
                          : null,
                      value: val,
                      onChanged: (v) {
                        v ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                        s.setValue(provider, v);
                      },
                    ),
                    if (idx < settings.length - 1)
                      Divider(
                        height: 1,
                        indent: isCompact ? 58 : 66,
                        endIndent: isCompact ? 14 : 16,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.2,
                        ),
                      ),
                  ],
                );
              }),
            ],
          );

          if (embedded) return listColumn;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 3.0 : 6.0),
            child: Material(
              color: colorScheme.surfaceContainerLow.withValues(
                alpha: plusSettings.plusEnableGlassmorphism ? 0.7 : 1.0,
              ),
              shape: CardMetrics.shape(
                cardRadius,
                expressive: isM3E,
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.35
                        : 0.65,
                  ),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: listColumn,
            ),
          );
        }

        final gridBody = Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 16,
            isCompact ? 8 : 12,
            isCompact ? 12 : 16,
            isCompact ? 10 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!embedded || title.isNotEmpty) ...[
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: isCompact ? 6 : 10),
              ],
              Column(
                children: [
                  for (int i = 0; i < settings.length; i += crossAxisCount) ...[
                    if (i > 0) SizedBox(height: isCompact ? 6 : 8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int j = 0; j < crossAxisCount; j++) ...[
                            if (j > 0) SizedBox(width: isCompact ? 6 : 8),
                            Expanded(
                              child: (i + j < settings.length)
                                  ? _GridToggleItem<T>(
                                      setting: settings[i + j],
                                      provider: provider,
                                      isCompact: isCompact,
                                      cardRadius: cardRadius,
                                      isM3E: isM3E,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );

        if (embedded) return gridBody;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 3.0 : 6.0),
          child: ClipPath(
            clipper: ShapeBorderClipper(
              shape: CardMetrics.shape(cardRadius, expressive: isM3E),
            ),
            child: ConditionalBlur(
              sigma: 10,
              enabled: plusSettings.plusEnableGlassmorphism,
              child: Material(
                color: colorScheme.surfaceContainerLow.withValues(
                  alpha: plusSettings.plusEnableGlassmorphism ? 0.7 : 1.0,
                ),
                shape: CardMetrics.shape(
                  cardRadius,
                  expressive: isM3E,
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.35
                          : 0.65,
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: gridBody,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Individual animated toggle chip in the grid
class _GridToggleItem<T extends ChangeNotifier> extends StatelessWidget {
  final ({
    IconData icon,
    String label,
    String? description,
    bool Function(T) getValue,
    void Function(T, bool) setValue,
  })
  setting;
  final T provider;
  final bool isCompact;
  final double cardRadius;
  final bool isM3E;

  const _GridToggleItem({
    required this.setting,
    required this.provider,
    this.isCompact = false,
    this.cardRadius = 20,
    this.isM3E = true,
  });

  @override
  Widget build(BuildContext context) {
    final value = setting.getValue(provider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final animsEnabled = context
        .watch<PlusSettingsProvider>()
        .plusEnableEnhancedAnimations;
    final tileRadius = CardMetrics.inner(cardRadius);
    final tileShape = CardMetrics.shape(
      tileRadius,
      expressive: isM3E,
      side: BorderSide(
        color: value
            ? colorScheme.primary.withValues(alpha: 0.55)
            : colorScheme.outlineVariant.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.65,
              ),
        width: value ? 1.5 : 1.0,
      ),
    );

    return ScaleTouchWrapper(
      hapticOnPressDown: false,
      child: AnimatedContainer(
        duration: Duration(milliseconds: animsEnabled ? 200 : 0),
        curve: Curves.easeOutCubic,
        decoration: ShapeDecoration(
          gradient: value
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.72),
                    colorScheme.primary.withValues(alpha: 0.16),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
                  ],
                ),
          shape: tileShape,
        ),
        child: Material(
          color: Colors.transparent,
          shape: CardMetrics.shape(tileRadius, expressive: isM3E),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: CardMetrics.shape(tileRadius, expressive: isM3E),
            onTap: () {
              value ? AppHaptics.toggleOff() : AppHaptics.toggleOn();
              setting.setValue(provider, !value);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: isCompact ? 6 : 10,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon + checkmark overlay
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: Duration(
                          milliseconds: animsEnabled ? 200 : 0,
                        ),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: value
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.onSurface.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          setting.icon,
                          size: 18,
                          color: value
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // Animated checkmark badge when active
                      if (value)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: AnimatedScale(
                            scale: value ? 1.0 : 0.0,
                            duration: Duration(
                              milliseconds: animsEnabled ? 200 : 0,
                            ),
                            curve: Curves.easeOutBack,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 8,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 4 : 6),
                  Text(
                    setting.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: value ? FontWeight.bold : FontWeight.w500,
                      color: value
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      letterSpacing: value ? 0.0 : 0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isCompact && setting.description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      setting.description!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension SwitchScale on Switch {
  Widget scaled(double scale) {
    return Transform.scale(scale: scale, child: this);
  }
}
