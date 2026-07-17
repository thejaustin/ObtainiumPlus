import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
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
    return Consumer2<T, PlusSettingsProvider>(
      builder: (context, provider, plusSettings, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorScheme = Theme.of(context).colorScheme;
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: ConditionalBlur(
              sigma: 10,
              enabled: plusSettings.plusEnableGlassmorphism,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? colorScheme.surfaceContainerLow
                              : colorScheme.surface)
                          .withValues(
                            alpha: plusSettings.plusEnableGlassmorphism
                                ? 0.7
                                : 1.0,
                          ),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(
                      alpha: plusSettings.plusEnableGlassmorphism ? 0.4 : 0.18,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header: upper-cased label with primary accent
                    Text(
                      title.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.7,
                      ),
                      itemCount: settings.length,
                      itemBuilder: (context, index) {
                        final setting = settings[index];
                        return _GridToggleItem<T>(
                          setting: setting,
                          provider: provider,
                        );
                      },
                    ),
                  ],
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

  const _GridToggleItem({required this.setting, required this.provider});

  @override
  Widget build(BuildContext context) {
    final value = setting.getValue(provider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: value
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? colorScheme.primary.withValues(alpha: 0.55)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: value ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setting.setValue(provider, !value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon + checkmark overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
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
                          duration: const Duration(milliseconds: 200),
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
                const SizedBox(height: 5),
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
              ],
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
