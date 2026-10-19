import 'package:flutter/material.dart';
import 'package:obtainium/models/settings_enums.dart';
import 'package:obtainium/providers/apps_provider.dart';

export 'package:obtainium/components/apps/app_list_tile.dart';

class AppListRowCard extends StatelessWidget {
  final Widget child;

  const AppListRowCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Card(clipBehavior: Clip.antiAlias, child: child),
    );
  }
}

class AppTileMetrics {
  final AppListDensity density;

  const AppTileMetrics(this.density);

  bool get isCompact => density == AppListDensity.compact;
  bool get isDense => false;
  bool get isStandard => density == AppListDensity.comfortable;

  VisualDensity? get visualDensity =>
      isCompact ? const VisualDensity(horizontal: -2, vertical: -2) : null;

  double get minVerticalPadding => isCompact ? 2 : 4;

  double get iconSize => isCompact ? 36 : 44;
}

class AppIconWidget extends StatefulWidget {
  final String appId;
  final bool installed;
  final AppsProvider appsProvider;
  final double size;

  const AppIconWidget({
    super.key,
    required this.appId,
    required this.installed,
    required this.appsProvider,
    this.size = 40,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  late final Future<void> _iconFuture;

  @override
  void initState() {
    super.initState();
    _iconFuture = widget.appsProvider.updateAppIcon(widget.appId);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: FutureBuilder(
        future: _iconFuture,
        builder: (ctx, val) {
          var icon = widget.appsProvider.apps[widget.appId]?.icon;
          return icon != null
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Image.memory(
                    icon,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    fit: BoxFit.contain,
                    opacity: AlwaysStoppedAnimation(widget.installed ? 1 : 0.6),
                  ),
                )
              : SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Center(
                    child: Image(
                      image: const AssetImage('assets/graphics/icon_small.png'),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.3),
                      colorBlendMode: BlendMode.modulate,
                      gaplessPlayback: true,
                    ),
                  ),
                );
        },
      ),
    );
  }
}

class AppListBuilder {
  static List<AppInMemory> reorder(
    List<AppInMemory> apps,
    bool pinUpdates,
    bool buryNonInstalled,
    Set<String> existingUpdates,
  ) {
    if (pinUpdates) {
      final temp = <AppInMemory>[];
      apps = apps.where((sa) {
        if (existingUpdates.contains(sa.app.id)) {
          temp.add(sa);
          return false;
        }
        return true;
      }).toList();
      apps = [...temp, ...apps];
    }

    if (buryNonInstalled) {
      final temp = <AppInMemory>[];
      apps = apps.where((sa) {
        if (sa.app.installedVersion == null) {
          temp.add(sa);
          return false;
        }
        return true;
      }).toList();
      apps = [...apps, ...temp];
    }

    final tempRenamed = <AppInMemory>[];
    final tempPinned = <AppInMemory>[];
    final tempNotPinned = <AppInMemory>[];
    final tempDisabled = <AppInMemory>[];
    for (var a in apps) {
      if (a.app.disabled) {
        tempDisabled.add(a);
      } else if (a.app.hasPendingRepoRename) {
        tempRenamed.add(a);
      } else if (a.app.pinned) {
        tempPinned.add(a);
      } else {
        tempNotPinned.add(a);
      }
    }
    apps = [...tempRenamed, ...tempPinned, ...tempNotPinned, ...tempDisabled];

    return apps;
  }
}
