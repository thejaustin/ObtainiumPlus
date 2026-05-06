import 'package:obtainium/utils/haptic_utils.dart';
import 'dart:ui';
import 'package:obtainium/components/common/conditional_blur.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/common/drag_handle.dart';
import 'package:obtainium/models/apps_filter.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:provider/provider.dart';
import 'package:obtainium/utils/app_constants.dart';

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

    final radius = settings.plusOverrideIndividualCornerRadius
        ? settings.plusHomeCornerRadius
        : settings.plusGlobalCornerRadius;
    final sheetRadius = radius.clamp(28.0, 48.0);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      child: ConditionalBlur(
        sigma: 16,
        enabled: settings.plusEnableGlassmorphism,
        child: Container(
          decoration: BoxDecoration(
            color: (isDark
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surface)
                .withOpacity(settings.plusEnableGlassmorphism ? 0.75 : 1.0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
            border: Border(
              top: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withOpacity(0.18)
                    : theme.colorScheme.outlineVariant.withOpacity(AppOpacity.subtle),
                width: 1.5,
              ),
              left: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withOpacity(0.12)
                    : Colors.transparent,
              ),
              right: BorderSide(
                color: settings.plusEnableGlassmorphism
                    ? theme.colorScheme.onSurface.withOpacity(0.12)
                    : Colors.transparent,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Glass sheen
              if (settings.plusEnableGlassmorphism)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                          Colors.black.withOpacity(0.02),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),

              SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DragHandle(margin: EdgeInsets.only(top: 10, bottom: 6)),
                    
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildAnimatedSection(0, Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tr('filterApps'),
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      AppHaptics.mediumImpact();
                                      setState(() {
                                        widget.filter.statusFilter.clear();
                                        widget.filter.categoryFilter.clear();
                                        widget.filter.tagFilter.clear();
                                        widget.filter.nameFilter = '';
                                        widget.filter.authorFilter = '';
                                        widget.filter.idFilter = '';
                                        widget.filter.sourceFilter = '';
                                        widget.filter.includeUptodate = true;
                                        widget.filter.includeNonInstalled = true;
                                      });
                                      widget.onFilterChanged();
                                    },
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: Text(tr('reset')),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )),

                            // Sort section
                            if (settings.plusEnableAdvancedSorting) ...[
                              _buildAnimatedSection(1, _buildSortSection(settingsProvider, theme, radius)),
                              const SizedBox(height: 28),
                            ],

                            // View mode section
                            _buildAnimatedSection(2, _buildViewModeSection(settingsProvider, theme, radius)),
                            const SizedBox(height: 28),

                            // Quick filters section
                            _buildAnimatedSection(3, _buildQuickFilterSection(theme, radius)),
                            const SizedBox(height: 28),

                            // Category filter section
                            if (widget.categories.isNotEmpty) ...[
                              _buildAnimatedSection(4, _buildCategorySection(theme, radius)),
                              const SizedBox(height: 28),
                            ],

                            // Tag filter section
                            _buildAnimatedSection(4, _buildTagSection(theme, radius)),
                            const SizedBox(height: 28),

                            // Advanced filters section
                            _buildAnimatedSection(4, _buildAdvancedSection(sourceProvider, theme, radius)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          begin: const Offset(0, 0.1), // Subtle slide
          end: Offset.zero,
        ).animate(_sectionAnimations[index]),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSortSection(ViewSettingsProvider sp, ThemeData theme, double radius) {
    final currentSort = sp.appSortMethod;
    final itemRadius = (radius * 0.45).clamp(10.0, 16.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('sortOptions'), theme),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppSortMethod.values.map((method) {
            final selected = currentSort == method;
            final details = _sortMethodDetails(method);
            return ChoiceChip(
              avatar: Icon(
                details.$2, 
                size: 16, 
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant
              ),
              label: Text(details.$1),
              selected: selected,
              onSelected: (val) {
                if (val) {
                  AppHaptics.selectionClick();
                  sp.appSortMethod = method;
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(itemRadius)),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  (String, IconData) _sortMethodDetails(AppSortMethod method) {
    switch (method) {
      case AppSortMethod.latestUpdates:
        return (tr('latestUpdates'), Icons.update_rounded);
      case AppSortMethod.nameAZ:
        return (tr('nameAZ'), Icons.sort_by_alpha_rounded);
      case AppSortMethod.nameZA:
        return (tr('nameZA'), Icons.sort_by_alpha_rounded);
      case AppSortMethod.recentlyAdded:
        return (tr('recentlyAdded'), Icons.history_rounded);
      case AppSortMethod.installStatus:
        return (tr('installStatus'), Icons.install_mobile_rounded);
      case AppSortMethod.defaultSort:
        return (tr('defaultSort'), Icons.sort_rounded);
    }
  }

  Widget _buildViewModeSection(ViewSettingsProvider sp, ThemeData theme, double radius) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('viewMode'), theme),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ViewMode>(
            segments: [
              ButtonSegment(
                value: ViewMode.list,
                icon: const Icon(Icons.view_list_rounded, size: 20),
                label: Text(tr('listView')),
              ),
              ButtonSegment(
                value: ViewMode.grid,
                icon: const Icon(Icons.grid_view_rounded, size: 20),
                label: Text(tr('gridView')),
              ),
            ],
            selected: {sp.globalViewMode},
            onSelectionChanged: (modes) {
              AppHaptics.selectionClick();
              sp.globalViewMode = modes.first;
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.comfortable,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFilterSection(ThemeData theme, double radius) {
    final statusFilter = widget.filter.statusFilter;
    final itemRadius = (radius * 0.4).clamp(8.0, 16.0);

    Widget buildChip(String label, bool selected, Function(bool) onSelected) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (v) {
          AppHaptics.selectionClick();
          onSelected(v);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(itemRadius)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('filter'), theme),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            buildChip(tr('installed'), statusFilter.contains('installed'), (val) {
              setState(() {
                if (val) statusFilter.add('installed'); else statusFilter.remove('installed');
              });
              widget.onFilterChanged();
            }),
            buildChip(tr('trackOnly'), statusFilter.contains('trackonly'), (val) {
              setState(() {
                if (val) statusFilter.add('trackonly'); else statusFilter.remove('trackonly');
              });
              widget.onFilterChanged();
            }),
            buildChip(tr('upToDateApps'), !widget.filter.includeUptodate, (val) {
              setState(() { widget.filter.includeUptodate = !val; });
              widget.onFilterChanged();
            }),
            buildChip(tr('nonInstalledApps'), !widget.filter.includeNonInstalled, (val) {
              setState(() { widget.filter.includeNonInstalled = !val; });
              widget.onFilterChanged();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection(ThemeData theme, double radius) {
    final cats = widget.categories;
    final selectedCats = widget.filter.categoryFilter;
    final itemRadius = (radius * 0.4).clamp(8.0, 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('categories'), theme),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cats.keys.map((cat) {
            final selected = selectedCats.contains(cat);
            final color = Color(cats[cat]!);
            return FilterChip(
              label: Text(cat),
              selected: selected,
              selectedColor: color.withOpacity(0.2),
              checkmarkColor: color,
              onSelected: (val) {
                AppHaptics.selectionClick();
                setState(() {
                  if (val) selectedCats.add(cat); else selectedCats.remove(cat);
                });
                widget.onFilterChanged();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(itemRadius)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagSection(ThemeData theme, double radius) {
    final appsProvider = context.read<AppsProvider>();
    final allTags = appsProvider.getAppValues().expand((a) => a.app.tags).toSet().toList();
    allTags.sort();
    
    final selectedTags = widget.filter.tagFilter;
    final itemRadius = (radius * 0.4).clamp(8.0, 16.0);

    if (allTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(tr('tags'), theme),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: allTags.map((tag) {
            final selected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: selected,
              onSelected: (val) {
                AppHaptics.selectionClick();
                setState(() {
                  if (val) selectedTags.add(tag); else selectedTags.remove(tag);
                });
                widget.onFilterChanged();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(itemRadius)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(
      SourceProvider sourceProvider, ThemeData theme, double radius) {
    final hasAdvancedFilters = widget.filter.nameFilter.isNotEmpty ||
        widget.filter.authorFilter.isNotEmpty ||
        widget.filter.idFilter.isNotEmpty ||
        widget.filter.sourceFilter.isNotEmpty;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: hasAdvancedFilters,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.tune_rounded, size: 20, color: theme.colorScheme.primary),
        ),
        title: Text(
          tr('filterApps'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          const SizedBox(height: 16),
          _buildTextField(tr('appName'), widget.filter.nameFilter, (v) {
            widget.filter.nameFilter = v;
            widget.onFilterChanged();
          }, theme),
          const SizedBox(height: 16),
          _buildTextField(tr('author'), widget.filter.authorFilter, (v) {
            widget.filter.authorFilter = v;
            widget.onFilterChanged();
          }, theme),
          const SizedBox(height: 16),
          _buildTextField(tr('appId'), widget.filter.idFilter, (v) {
            widget.filter.idFilter = v;
            widget.onFilterChanged();
          }, theme),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: tr('appSource'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String) onChanged, ThemeData theme) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      controller: TextEditingController(text: initialValue),
      onChanged: onChanged,
    );
  }

  String _sortMethodLabel(AppSortMethod method) {
    return _sortMethodDetails(method).$1;
  }
}
