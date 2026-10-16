import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Generic Control Grid for Boolean Settings
/// Displays boolean settings in a compact, card-chip grid layout
class GenericBooleanControlGrid<T extends ChangeNotifier>
    extends StatelessWidget {
  final String title;
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
  });

  @override
  Widget build(BuildContext context) {
    if (settings.isEmpty) return const SizedBox.shrink();
    return Consumer2<T, PlusSettingsProvider>(
      builder: (context, provider, plusSettings, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final isCompact = plusSettings.plusUseCompactSettings;
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : (isCompact ? 3 : 2);
        final cardRadius = plusSettings.plusOverrideIndividualCornerRadius
            ? plusSettings.plusSettingsCornerRadius
            : plusSettings.plusGlobalCornerRadius;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 4.0 : 6.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cardRadius),
            child: ConditionalBlur(
              sigma: 10,
              enabled: plusSettings.plusEnableGlassmorphism,
              child: Material(
                color: colorScheme.surfaceContainerLow.withValues(
                      alpha: plusSettings.plusEnableGlassmorphism ? 0.7 : 1.0,
                    ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardRadius),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: plusSettings.plusEnableGlassmorphism ? 0.4 : 0.18,
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, isCompact ? 10 : 14, 16, isCompact ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    // Non-scrolling card grid implemented via Column and Rows
                    // Using GridView.builder(shrinkWrap: true) inside ExpansionTiles causes
                    if (!plusSettings.plusSettingsUseGridToggles)
                      Column(
                        children: settings.map((s) {
                          final val = s.getValue(provider);
                          return SwitchListTile.adaptive(
                            dense: isCompact,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: isCompact ? 0 : 2,
                            ),
                            secondary: Icon(s.icon, size: isCompact ? 20 : 24),
                            title: Text(
                              s.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            subtitle: s.description != null
                                ? Text(
                                    s.description!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : null,
                            value: val,
                            onChanged: (v) {
                              v ? AppHaptics.toggleOn() : AppHaptics.toggleOff();
                              s.setValue(provider, v);
                            },
                          );
                        }).toList(),
                      )
                    else
                      Column(
                        children: [
                          for (
                            int i = 0;
                            i < settings.length;
                            i += crossAxisCount
                          ) ...[
                            if (i > 0) const SizedBox(height: 8),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int j = 0; j < crossAxisCount; j++) ...[
                                    if (j > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: (i + j < settings.length)
                                          ? _GridToggleItem<T>(
                                              setting: settings[i + j],
                                              provider: provider,
                                              isCompact: isCompact,
                                              cardRadius: cardRadius,
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
              ),
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

  const _GridToggleItem({
    required this.setting,
    required this.provider,
    this.isCompact = false,
    this.cardRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final value = setting.getValue(provider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final animsEnabled = context
        .watch<PlusSettingsProvider>()
        .plusEnableEnhancedAnimations;
    final tileRadius = (cardRadius * 0.6).clamp(8.0, 16.0);

    return ScaleTouchWrapper(
      hapticOnPressDown: true,
      child: AnimatedContainer(
      duration: Duration(milliseconds: animsEnabled ? 200 : 0),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
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
        borderRadius: BorderRadius.circular(tileRadius),
        border: Border.all(
          color: value
              ? colorScheme.primary.withValues(alpha: 0.55)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: value ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tileRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(tileRadius),
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
                      duration: Duration(milliseconds: animsEnabled ? 200 : 0),
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
                          duration: Duration(milliseconds: animsEnabled ? 200 : 0),
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
                    color: value ? colorScheme.primary : colorScheme.onSurface,
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
    ));
  }
}

extension SwitchScale on Switch {
  Widget scaled(double scale) {
    return Transform.scale(scale: scale, child: this);
  }
}
