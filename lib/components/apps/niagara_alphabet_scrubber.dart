import 'dart:async';
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
typedef ScrubberBucket = ({
  String symbol,
  int firstAppIndex,
  String sampleAppName,
});

class NiagaraAlphabetScrubber extends StatefulWidget {
  final List<AppInMemory> apps;
  final ScrollController scrollController;

  /// Apps lifted above the name-sorted list (pending updates when "pin
  /// updates" is on); they get one ↑ entry instead of letters.
  final Set<String> leadingIds;

  /// A zero-height marker at the top of the app list. The rail shows once
  /// it scrolls above the rail, so it never covers whatever sits above the
  /// list (dashboard, tips, filters), however tall that is.
  final GlobalKey? listStartKey;

  const NiagaraAlphabetScrubber({
    super.key,
    required this.apps,
    required this.scrollController,
    this.leadingIds = const {},
    this.listStartKey,
  });

  /// Extra end padding lists/grids should reserve so the resting rail never
  /// covers (or steals taps from) the rightmost tiles.
  static const double railGutter = 20.0;

  /// Cheap pre-check mirroring [build]'s visibility rules (min app count and
  /// at least 3 distinct letter buckets), so layouts can reserve [railGutter]
  /// only when the rail will actually render.
  static bool willShow(
    List<AppInMemory> apps, {
    Set<String> leadingIds = const {},
  }) {
    if (apps.length < 8) return false;
    final buckets = buildBuckets(apps, leadingIds);
    return buckets != null && buckets.length >= 3;
  }

  static final RegExp _alpha = RegExp(r'^[A-Z]$');

  /// Rail entries in list order: ★ for pinned, ↑ for [leadingIds], then one
  /// per first letter. Returns null when the letters aren't in contiguous,
  /// one-directional runs (sorted by date, buried non-installed apps, ...):
  /// a rail would jump back and forth there, so it's hidden instead. `#`
  /// (digits, symbols, accents) may sort at either end and is exempt.
  @visibleForTesting
  static List<ScrubberBucket>? buildBuckets(
    List<AppInMemory> apps,
    Set<String> leadingIds,
  ) {
    final buckets = <ScrubberBucket>[];
    final seen = <String>{};
    String? current;
    for (var i = 0; i < apps.length; i++) {
      final a = apps[i];
      final String symbol;
      if (a.app.pinned || a.app.hasPendingRepoRename) {
        symbol = '★';
      } else if (leadingIds.contains(a.app.id)) {
        symbol = '↑';
      } else {
        final name = a.name.trim();
        final c = name.isNotEmpty ? name[0].toUpperCase() : '#';
        symbol = _alpha.hasMatch(c) ? c : '#';
      }
      if (symbol == current) continue;
      if (!seen.add(symbol)) {
        if (symbol == '#') {
          current = symbol;
          continue;
        }
        return null;
      }
      current = symbol;
      buckets.add((symbol: symbol, firstAppIndex: i, sampleAppName: a.name));
    }
    // Letters must also run one way (A-Z, or Z-A for a descending sort).
    final letters = [
      for (final b in buckets)
        if (_alpha.hasMatch(b.symbol)) b.symbol,
    ];
    if (letters.length > 1) {
      final up = letters[1].compareTo(letters[0]) > 0;
      for (var i = 1; i < letters.length; i++) {
        if ((letters[i].compareTo(letters[i - 1]) > 0) != up) return null;
      }
    }
    return buckets;
  }

  @override
  State<NiagaraAlphabetScrubber> createState() =>
      _NiagaraAlphabetScrubberState();
}

class _NiagaraAlphabetScrubberState extends State<NiagaraAlphabetScrubber> {
  double? _dragNormalizedY;
  int? _activeIndex;
  Timer? _tapClearTimer;
  List<AppInMemory>? _bucketsFor;
  Set<String>? _bucketsLeading;
  List<ScrubberBucket>? _cachedBuckets;

  /// Fallback when there's no list marker: scroll offset past which the
  /// list fills the middle of the screen where the rail sits.
  static const double _revealOffset = 220;
  final _railKey = GlobalKey();
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _onScroll();
  }

  @override
  void didUpdateWidget(NiagaraAlphabetScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
    // Content above the list can change height without a scroll (a tip
    // dismissed, filters toggled).
    _onScroll();
  }

  bool _measureScheduled = false;

  /// Scroll notifications arrive before the new layout, so measure after
  /// the frame.
  void _onScroll() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measure();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _measure() {
    if (!mounted || !widget.scrollController.hasClients) return;
    final anchor = widget.listStartKey?.currentContext?.findRenderObject();
    final rail = _railKey.currentContext?.findRenderObject();
    final bool revealed;
    if (anchor is RenderBox &&
        anchor.attached &&
        rail is RenderBox &&
        rail.attached &&
        rail.hasSize) {
      revealed =
          anchor.localToGlobal(Offset.zero).dy <=
          rail.localToGlobal(Offset.zero).dy;
    } else {
      revealed = widget.scrollController.offset > _revealOffset;
    }
    if (revealed != _revealed) setState(() => _revealed = revealed);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _tapClearTimer?.cancel();
    super.dispose();
  }

  List<ScrubberBucket> _buildBuckets() {
    // AppsPage rebuilds on every provider tick; only rebucket when the list
    // instance actually changes.
    if (identical(_bucketsFor, widget.apps) &&
        identical(_bucketsLeading, widget.leadingIds) &&
        _cachedBuckets != null) {
      return _cachedBuckets!;
    }
    _bucketsFor = widget.apps;
    _bucketsLeading = widget.leadingIds;
    _cachedBuckets =
        NiagaraAlphabetScrubber.buildBuckets(widget.apps, widget.leadingIds) ??
        const [];
    return _cachedBuckets!;
  }

  void _handleTouch(
    Offset localPosition,
    double railHeight,
    List<ScrubberBucket> buckets,
  ) {
    if (buckets.isEmpty || railHeight <= 0) return;
    _tapClearTimer?.cancel();
    final normY = (localPosition.dy / railHeight).clamp(0.0, 1.0);
    final idx = (normY * buckets.length).floor().clamp(0, buckets.length - 1);

    final changed = _activeIndex != idx;
    setState(() {
      _dragNormalizedY = normY;
      _activeIndex = idx;
    });

    if (changed) {
      AppHaptics.segmentTick();
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

    // At the top of the page the rail would sit over the dashboard and steal
    // its taps; it fades in once the list is scrolled into view.
    final visible = _revealed || isDragging;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Duration(
          milliseconds: plusSettings.plusEnableEnhancedAnimations ? 200 : 0,
        ),
        child: _buildRail(
          context,
          buckets,
          colorScheme,
          isM3E,
          isDragging,
          bubbleRadius,
        ),
      ),
    );
  }

  Widget _buildRail(
    BuildContext context,
    List<ScrubberBucket> buckets,
    ColorScheme colorScheme,
    bool isM3E,
    bool isDragging,
    double bubbleRadius,
  ) {
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
            key: _railKey,
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
                    onTapUp: (_) {
                      _tapClearTimer?.cancel();
                      _tapClearTimer = Timer(
                        const Duration(milliseconds: 180),
                        () {
                          if (mounted) _clearTouch();
                        },
                      );
                    },
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
