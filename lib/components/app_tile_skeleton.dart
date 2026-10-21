import 'package:flutter/material.dart';
import 'package:obtainium/utils/motion.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:provider/provider.dart';

class AppTileSkeleton extends StatefulWidget {
  final bool isGrid;

  const AppTileSkeleton({super.key, required this.isGrid});

  @override
  State<AppTileSkeleton> createState() => _AppTileSkeletonState();
}

class _AppTileSkeletonState extends State<AppTileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animsEnabled = AppMotion.enabledForDependencies(context);
    if (animsEnabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!animsEnabled) {
      _controller.stop();
      _controller.value = 0.65;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plusSettings = context.watch<PlusSettingsProvider>();
    final radius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final cardRadius = CardMetrics.card(radius);
    final innerRadius = CardMetrics.inner(radius);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final alpha = _animation.value;

        if (widget.isGrid) {
          final isCardless = plusSettings.plusGridCardlessStyle;
          final isM3E = plusSettings.plusEnableMaterialExpressive;
          return Container(
            decoration: ShapeDecoration(
              color: isCardless
                  ? Colors.transparent
                  : colorScheme.surfaceContainerLow.withValues(
                      alpha: alpha * 0.6 + 0.3,
                    ),
              shape: CardMetrics.shape(
                cardRadius,
                expressive: isM3E,
                side: isCardless
                    ? BorderSide.none
                    : BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.25,
                        ),
                      ),
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: ShapeDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: alpha,
                        ),
                        shape: CardMetrics.shape(
                          innerRadius,
                          expressive: isM3E,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 72,
                      height: 11,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: alpha,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 48,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: alpha * 0.7,
                        ),
                        borderRadius: BorderRadius.circular(
                          CardMetrics.pillRadius,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow.withValues(
                alpha: alpha * 0.6 + 0.3,
              ),
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: alpha,
                    ),
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 13,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: alpha,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: alpha * 0.7,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 54,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: alpha * 0.5,
                    ),
                    borderRadius: BorderRadius.circular(CardMetrics.pillRadius),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
