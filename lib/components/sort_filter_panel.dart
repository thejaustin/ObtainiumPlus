import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';

class SortFilterPanel extends StatefulWidget {
  final AppsFilter filter;
  final VoidCallback onFilterChanged;
  final Map<String, int> categories;

  const SortFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.categories,
  });

  static Future<void> show(
    BuildContext context, {
    required AppsFilter filter,
    required VoidCallback onFilterChanged,
    required Map<String, int> categories,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => SortFilterPanel(
        filter: filter,
        onFilterChanged: onFilterChanged,
        categories: categories,
      ),
    );
  }

  @override
  State<SortFilterPanel> createState() => _SortFilterPanelState();
}

class _SortFilterPanelState extends State<SortFilterPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Staggered animations for 5 sections
    _sectionAnimations = List.generate(5, (i) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<ViewSettingsProvider>();
    final settings = context.watch<SettingsProvider>();
    final sourceProvider = SourceProvider();
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: settings.plusEnableGlassmorphism ? 24 : 0,
          sigmaY: settings.plusEnableGlassmorphism ? 24 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surface)
                .withValues(alpha: settings.plusEnableGlassmorphism ? 0.72 : 1.0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.18)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
                width: 1,
              ),
              left: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              right: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort section
                    _buildAnimatedSection(0, _buildSortSection(settingsProvider, theme)),
                    const SizedBox(height: 20),

                    // View mode section
                    _buildAnimatedSection(1, _buildViewModeSection(settingsProvider, theme)),
                    const SizedBox(height: 20),

                    // Quick filters section
                    _buildAnimatedSection(2, _buildQuickFilterSection(theme)),
                    const SizedBox(height: 20),

                    // Category filter section
                    if (widget.categories.isNotEmpty) ...[
                      _buildAnimatedSection(3, _buildCategorySection(theme)),
                      const SizedBox(height: 20),
                    ],

                    // Advanced filters section
                    _buildAnimatedSection(4, _buildAdvancedSection(sourceProvider, theme)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    if (index >= _sectionAnimations.length) return child;
    return FadeTransition(
      opacity: _sectionAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_sectionAnimations[index]),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSortSection(ViewSettingsProvider sp, ThemeData theme) {
    final currentSort = sp.appSortMethod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('sortOptions'), theme),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppSortMethod.values.map((method) {
            final selected = currentSort == method;
            return ChoiceChip(
              label: Text(_sortMethodLabel(method)),
              selected: selected,
              onSelected: (val) {
                if (val) {
                  HapticFeedback.selectionClick();
                  sp.appSortMethod = method;
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildViewModeSection(ViewSettingsProvider sp, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('viewMode'), theme),
        SegmentedButton<ViewMode>(
          segments: [
            ButtonSegment(
              value: ViewMode.list,
              icon: const Icon(Icons.view_list, size: 18),
              label: Text(tr('listView')),
            ),
            ButtonSegment(
              value: ViewMode.grid,
              icon: const Icon(Icons.grid_view, size: 18),
              label: Text(tr('gridView')),
            ),
          ],
          selected: {sp.globalViewMode},
          onSelectionChanged: (modes) {
            HapticFeedback.selectionClick();
            sp.globalViewMode = modes.first;
          },
        ),
      ],
    );
  }

  Widget _buildQuickFilterSection(ThemeData theme) {
    final statusFilter = widget.filter.statusFilter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('filter'), theme),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(tr('installed')),
              selected: statusFilter.contains('installed'),
              onSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (val) {
                    statusFilter.add('installed');
                  } else {
                    statusFilter.remove('installed');
                  }
                });
                widget.onFilterChanged();
              },
            ),
            FilterChip(
              label: Text(tr('trackOnly')),
              selected: statusFilter.contains('trackonly'),
              onSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (val) {
                    statusFilter.add('trackonly');
                  } else {
                    statusFilter.remove('trackonly');
                  }
                });
                widget.onFilterChanged();
              },
            ),
            FilterChip(
              label: Text(tr('upToDateApps')),
              selected: !widget.filter.includeUptodate,
              onSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  widget.filter.includeUptodate = !val;
                });
                widget.onFilterChanged();
              },
            ),
            FilterChip(
              label: Text(tr('nonInstalledApps')),
              selected: !widget.filter.includeNonInstalled,
              onSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  widget.filter.includeNonInstalled = !val;
                });
                widget.onFilterChanged();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    final cats = widget.categories;
    final selectedCats = widget.filter.categoryFilter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('categories'), theme),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cats.keys.map((cat) {
            final selected = selectedCats.contains(cat);
            final color = Color(cats[cat]!);
            return FilterChip(
              label: Text(cat),
              selected: selected,
              selectedColor: color.withValues(alpha: 0.2),
              checkmarkColor: color,
              onSelected: (val) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (val) {
                    selectedCats.add(cat);
                  } else {
                    selectedCats.remove(cat);
                  }
                });
                widget.onFilterChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(
      SourceProvider sourceProvider, ThemeData theme) {
    final hasAdvancedFilters = widget.filter.nameFilter.isNotEmpty ||
        widget.filter.authorFilter.isNotEmpty ||
        widget.filter.idFilter.isNotEmpty ||
        widget.filter.sourceFilter.isNotEmpty;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: hasAdvancedFilters,
        leading: Icon(Icons.tune, size: 20, color: theme.colorScheme.onSurfaceVariant),
        title: Text(
          tr('filterApps'),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: tr('appName'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            controller: TextEditingController(text: widget.filter.nameFilter),
            onChanged: (val) {
              widget.filter.nameFilter = val;
              widget.onFilterChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: tr('author'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            controller: TextEditingController(text: widget.filter.authorFilter),
            onChanged: (val) {
              widget.filter.authorFilter = val;
              widget.onFilterChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: tr('appId'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            controller: TextEditingController(text: widget.filter.idFilter),
            onChanged: (val) {
              widget.filter.idFilter = val;
              widget.onFilterChanged();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: tr('appSource'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            value: widget.filter.sourceFilter.isEmpty
                ? null
                : widget.filter.sourceFilter,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(tr('none')),
              ),
              ...sourceProvider.sources.map(
                (e) => DropdownMenuItem<String>(
                  value: e.runtimeType.toString(),
                  child: Text(e.name),
                ),
              ),
            ],
            onChanged: (val) {
              widget.filter.sourceFilter = val ?? '';
              widget.onFilterChanged();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _sortMethodLabel(AppSortMethod method) {
    switch (method) {
      case AppSortMethod.latestUpdates:
        return tr('latestUpdates');
      case AppSortMethod.nameAZ:
        return tr('nameAZ');
      case AppSortMethod.nameZA:
        return tr('nameZA');
      case AppSortMethod.recentlyAdded:
        return tr('recentlyAdded');
      case AppSortMethod.installStatus:
        return tr('installStatus');
      case AppSortMethod.defaultSort:
        return tr('defaultSort');
    }
  }
}
