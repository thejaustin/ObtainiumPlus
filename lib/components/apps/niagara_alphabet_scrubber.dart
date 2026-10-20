import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:obtainium/utils/card_metrics.dart';
import 'package:obtainium/utils/haptic_utils.dart';
import 'package:provider/provider.dart';

/// Niagara Launcher-inspired interactive wave alphabet scrubber for the app
/// list and grid views.
///
/// At rest, renders a whisper-quiet vertical rail of letter markers along the
/// right edge. When touched or dragged vertically, nearby letters arc inward
/// in a smooth Gaussian wave while a floating M3E squircle bubble previews the
/// active letter and first matching app name, scrolling the list in real time.
class NiagaraAlphabetScrubber extends StatefulWidget {
  final List<AppInMemory> apps;
  final ScrollController scrollController;

  const NiagaraAlphabetScrubber({
    super.key,
    required this.apps,
    required this.scrollController,
  });

  @override
  State<NiagaraAlphabetScrubber> createState() =>
      _NiagaraAlphabetScrubberState();
}

class _NiagaraAlphabetScrubberState extends State<NiagaraAlphabetScrubber> {
  double? _dragNormalizedY;
  int? _activeIndex;

  /// Builds ordered list of available section symbols (★ for pinned, A-Z, #)
  /// mapped to the first app index in [widget.apps].
  List<({String symbol, int firstAppIndex, String sampleAppName})>
  _buildBuckets() {
    final buckets =
        <({String symbol, int firstAppIndex, String sampleAppName})>[];
    final seenSymbols = <String>{};

    // Separate pinned vs unpinned in the same visual order as AppListView
    final pinned = <AppInMemory>[];
    final unpinned = <AppInMemory>[];
    for (final a in widget.apps) {
      if (a.app.pinned) {
        pinned.add(a);
      } else {
        unpinned.add(a);
      }
    }

    if (pinned.isNotEmpty) {
      buckets.add((
        symbol: '★',
        firstAppIndex: 0,
        sampleAppName: pinned.first.name,
      ));
      seenSymbols.add('★');
    }

    final baseOffset = pinned.length;
    for (int i = 0; i < unpinned.length; i++) {
      final name = unpinned[i].name.trim();
      final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '#';
      final isAlpha = RegExp(r'^[A-Z]$').hasMatch(firstChar);
      final symbol = isAlpha ? firstChar : '#';
      if (!seenSymbols.contains(symbol)) {
        seenSymbols.add(symbol);
        buckets.add((
          symbol: symbol,
          firstAppIndex: baseOffset + i,
          sampleAppName: unpinned[i].name,
        ));
      }
    }

    return buckets;
  }

  void _handleTouch(
    Offset localPosition,
    double railHeight,
    List<({String symbol, int firstAppIndex, String sampleAppName})> buckets,
  ) {
    if (buckets.isEmpty || railHeight <= 0) return;
    final normY = (localPosition.dy / railHeight).clamp(0.0, 1.0);
    final idx = (normY * buckets.length).floor().clamp(0, buckets.length - 1);

    final changed = _activeIndex != idx;
    setState(() {
      _dragNormalizedY = normY;
      _activeIndex = idx;
    });

    if (changed) {
      AppHaptics.selectionClick();
      _scrollToAppIndex(buckets[idx].firstAppIndex);
    }
  }

  void _scrollToAppIndex(int appIndex) {
    if (!widget.scrollController.hasClients || widget.apps.isEmpty) return;
    final position = widget.scrollController.position;
    final maxExtent = position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final fraction = (appIndex / math.max(1, widget.apps.length - 1)).clamp(
      0.0,
      1.0,
    );
    final target = (fraction * maxExtent).clamp(0.0, maxExtent);
    widget.scrollController.jumpTo(target);
  }

  void _clearTouch() {
    if (_dragNormalizedY != null || _activeIndex != null) {
      AppHaptics.lightImpact();
      setState(() {
        _dragNormalizedY = null;
        _activeIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apps.length < 8) return const SizedBox.shrink();
    final buckets = _buildBuckets();
    if (buckets.length < 3) return const SizedBox.shrink();

    final plusSettings = context.watch<PlusSettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isM3E = plusSettings.plusEnableMaterialExpressive;
    final isDragging = _dragNormalizedY != null && _activeIndex != null;
    final baseRadius = plusSettings.plusOverrideIndividualCornerRadius
        ? plusSettings.plusHomeCornerRadius
        : plusSettings.plusGlobalCornerRadius;
    final bubbleRadius = CardMetrics.card(baseRadius);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxRailHeight = (constraints.maxHeight * 0.58).clamp(
          180.0,
          420.0,
        );
        final itemCount = buckets.length;
        final railHeight = math.min(maxRailHeight, itemCount * 22.0 + 16.0);

        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: isDragging ? 220 : 28,
            height: railHeight + 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerRight,
              children: [
                // Floating Niagara preview pill while scrubbing
                if (isDragging)
                  Positioned(
                    right: 68,
                    top:
                        (_dragNormalizedY! * railHeight).clamp(
                          16.0,
                          railHeight - 16.0,
                        ) -
                        4,
                    child: IgnorePointer(
                      child: Material(
                        elevation: 6,
                        shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
                        color: colorScheme.primaryContainer,
                        shape: CardMetrics.shape(
                          bubbleRadius,
                          expressive: isM3E,
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                buckets[_activeIndex!].symbol,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                ),
                                child: Text(
                                  buckets[_activeIndex!].sampleAppName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Interactive vertical rail
                Positioned(
                  right: 2,
                  height: railHeight,
                  width: isDragging ? 72 : 24,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (d) =>
                        _handleTouch(d.localPosition, railHeight, buckets),
                    onVerticalDragUpdate: (d) =>
                        _handleTouch(d.localPosition, railHeight, buckets),
                    onVerticalDragEnd: (_) => _clearTouch(),
                    onVerticalDragCancel: _clearTouch,
                    onTapDown: (d) =>
                        _handleTouch(d.localPosition, railHeight, buckets),
                    onTapUp: (_) =>
                        Future.delayed(const Duration(milliseconds: 180), () {
                          if (mounted) _clearTouch();
                        }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isDragging
                            ? Colors.transparent
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.32,
                              ),
                        borderRadius: BorderRadius.circular(
                          CardMetrics.pillRadius,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(itemCount, (i) {
                          final itemNormY = (i + 0.5) / itemCount;
                          double waveOffset = 0.0;
                          double scale = 1.0;
                          final isSelected = isDragging && _activeIndex == i;

                          if (isDragging && _dragNormalizedY != null) {
                            final dist = (itemNormY - _dragNormalizedY!).abs();
                            const sigma = 0.14;
                            final gaussian = math.exp(
                              -(dist * dist) / (2 * sigma * sigma),
                            );
                            waveOffset = -34.0 * gaussian;
                            scale = 1.0 + (0.45 * gaussian);
                          }

                          return Transform.translate(
                            offset: Offset(waveOffset, 0),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 22,
                                alignment: Alignment.center,
                                child: Text(
                                  buckets[i].symbol,
                                  style: TextStyle(
                                    fontSize: isSelected ? 12.0 : 9.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant
                                              .withValues(
                                                alpha: isDragging ? 0.85 : 0.65,
                                              ),
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
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
