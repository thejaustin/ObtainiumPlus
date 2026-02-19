import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/pages/home.dart';

class EditableNavigationBar extends StatefulWidget {
  final List<NavigationPageItem> activePages;
  final Map<String, NavigationPageItem> allPages;
  final int selectedIndex;
  final bool isEditMode;
  final ValueChanged<bool> onEditModeChanged;
  final ValueChanged<int> onDestinationSelected;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String id) onRemoveTab;
  final void Function(String id) onAddTab;
  final NavigationDestinationLabelBehavior labelBehavior;

  const EditableNavigationBar({
    super.key,
    required this.activePages,
    required this.allPages,
    required this.selectedIndex,
    required this.isEditMode,
    required this.onEditModeChanged,
    required this.onDestinationSelected,
    required this.onReorder,
    required this.onRemoveTab,
    required this.onAddTab,
    required this.labelBehavior,
  });

  @override
  State<EditableNavigationBar> createState() => _EditableNavigationBarState();
}

class _EditableNavigationBarState extends State<EditableNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _wiggleController;
  int? _dragFromIndex;
  int? _dragOverIndex;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(EditableNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditMode && !oldWidget.isEditMode) {
      _wiggleController.repeat(reverse: true);
    } else if (!widget.isEditMode && oldWidget.isEditMode) {
      _wiggleController.stop();
      _wiggleController.reset();
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableTabs = widget.allPages.keys
        .where((id) => !widget.activePages.any((p) => p.id == id))
        .toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: widget.isEditMode
          ? null
          : () {
              HapticFeedback.heavyImpact();
              widget.onEditModeChanged(true);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
          border: widget.isEditMode
              ? Border(
                  top: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                )
              : null,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabRow(context, colorScheme),
                ),
                if (widget.isEditMode) ...[
                  if (availableTabs.isNotEmpty)
                    _buildAddButton(context, colorScheme, availableTabs),
                  _buildDoneButton(context, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabRow(BuildContext context, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemCount = widget.activePages.length;
        final itemWidth = constraints.maxWidth / math.max(itemCount, 1);

        return Stack(
          children: List.generate(itemCount, (index) {
            final page = widget.activePages[index];
            final isSelected = index == widget.selectedIndex;
            final isDragTarget = _dragOverIndex == index && _dragFromIndex != index;

            return AnimatedPositioned(
              duration: _dragFromIndex != null
                  ? const Duration(milliseconds: 200)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              left: index * itemWidth,
              top: 0,
              bottom: 0,
              width: itemWidth,
              child: _buildDraggableTab(
                context,
                colorScheme,
                page,
                index,
                isSelected,
                isDragTarget,
                itemWidth,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDraggableTab(
    BuildContext context,
    ColorScheme colorScheme,
    NavigationPageItem page,
    int index,
    bool isSelected,
    bool isDragTarget,
    double itemWidth,
  ) {
    final tabContent = _buildTabContent(
      context,
      colorScheme,
      page,
      index,
      isSelected,
      isDragTarget,
      itemWidth,
    );

    if (!widget.isEditMode) {
      return tabContent;
    }

    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 100),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        setState(() => _dragFromIndex = index);
      },
      onDragEnd: (_) {
        setState(() {
          _dragFromIndex = null;
          _dragOverIndex = null;
        });
      },
      onDraggableCanceled: (_, __) {
        setState(() {
          _dragFromIndex = null;
          _dragOverIndex = null;
        });
      },
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: itemWidth,
          height: 80,
          child: Transform.scale(
            scale: 1.1,
            child: Opacity(
              opacity: 0.85,
              child: _buildTabIcon(
                context,
                colorScheme,
                page,
                true,
                showRemoveBadge: false,
                index: index,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: tabContent,
      ),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          if (details.data != index) {
            setState(() => _dragOverIndex = index);
            HapticFeedback.selectionClick();
          }
          return details.data != index;
        },
        onLeave: (_) {
          setState(() {
            if (_dragOverIndex == index) _dragOverIndex = null;
          });
        },
        onAcceptWithDetails: (details) {
          final fromIndex = details.data;
          widget.onReorder(fromIndex, index);
          HapticFeedback.mediumImpact();
          setState(() {
            _dragFromIndex = null;
            _dragOverIndex = null;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return tabContent;
        },
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    ColorScheme colorScheme,
    NavigationPageItem page,
    int index,
    bool isSelected,
    bool isDragTarget,
    double itemWidth,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isEditMode
          ? null
          : () => widget.onDestinationSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: isDragTarget
            ? BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: widget.isEditMode
            ? AnimatedBuilder(
                animation: _wiggleController,
                builder: (context, child) {
                  final wiggle = math.sin(
                        _wiggleController.value * 2 * math.pi +
                            index * 0.7,
                      ) *
                      0.02;
                  return Transform.rotate(
                    angle: wiggle,
                    child: child,
                  );
                },
                child: _buildTabIcon(
                  context,
                  colorScheme,
                  page,
                  isSelected,
                  showRemoveBadge: true,
                  index: index,
                ),
              )
            : _buildTabIcon(
                context,
                colorScheme,
                page,
                isSelected,
                showRemoveBadge: false,
                index: index,
              ),
      ),
    );
  }

  Widget _buildTabIcon(
    BuildContext context,
    ColorScheme colorScheme,
    NavigationPageItem page,
    bool isSelected, {
    required bool showRemoveBadge,
    required int index,
  }) {
    final showLabels = widget.labelBehavior ==
            NavigationDestinationLabelBehavior.alwaysShow ||
        (widget.labelBehavior ==
                NavigationDestinationLabelBehavior.onlyShowSelected &&
            isSelected);

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? page.selectedIcon : page.icon,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              if (showLabels) ...[
                const SizedBox(height: 4),
                Text(
                  page.title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ],
            ],
          ),
          if (showRemoveBadge && widget.activePages.length > 2)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onRemoveTab(page.id);
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: colorScheme.onError,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    ColorScheme colorScheme,
    List<String> availableTabs,
  ) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        onSelected: (id) {
          HapticFeedback.lightImpact();
          widget.onAddTab(id);
        },
        offset: const Offset(0, -200),
        itemBuilder: (context) {
          return availableTabs.map((id) {
            final page = widget.allPages[id]!;
            return PopupMenuItem<String>(
              value: id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(page.icon, size: 20),
                  const SizedBox(width: 12),
                  Text(page.title),
                ],
              ),
            );
          }).toList();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('add'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: 48,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onEditModeChanged(false);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('ok'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

}
