import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/models/app.dart';
import 'package:obtainium/models/app_in_memory.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/providers/view_settings_provider.dart';
import 'package:obtainium/providers/behavior_settings_provider.dart';
import 'package:provider/provider.dart';

class AppListTileClassic extends StatelessWidget {
  final int index;
  final AppInMemory appInMemory;
  final bool hasUpdate;
  final bool trackOnly;
  final bool needsInstall;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowChanges;
  final Widget updateButton;
  final Widget appIcon;
  final Widget authorText;
  final Widget? repoMovedRow;
  final String versionText;
  final String changesButtonString;

  const AppListTileClassic({
    super.key,
    required this.index,
    required this.appInMemory,
    required this.hasUpdate,
    required this.trackOnly,
    required this.needsInstall,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onShowChanges,
    required this.updateButton,
    required this.appIcon,
    required this.authorText,
    required this.repoMovedRow,
    required this.versionText,
    required this.changesButtonString,
  });

  bool isVersionPseudo(App app) {
    if (app.additionalSettings['versionDetection'] == null &&
        app.installedVersion != null &&
        app.installedVersion == app.latestVersion) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    final viewSettings = context.read<ViewSettingsProvider>();
    final behaviorSettings = context.read<BehaviorSettingsProvider>();

    Widget trailingRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (hasUpdate || needsInstall) ? updateButton : const SizedBox.shrink(),
        (hasUpdate || needsInstall)
            ? const SizedBox(width: 5)
            : const SizedBox.shrink(),
        InkWell(
          onTap: onShowChanges,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  behaviorSettings.highlightTouchTargets &&
                      onShowChanges != null
                  ? (Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColorLight)
                        .withValues(
                          alpha:
                              Theme.of(context).brightness == Brightness.light
                              ? 20 / 255
                              : 40 / 255,
                        )
                  : null,
            ),
            padding: behaviorSettings.highlightTouchTargets
                ? const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0)
                : const EdgeInsetsDirectional.fromSTEB(24, 0, 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width / 4,
                      ),
                      child: Text(
                        versionText,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: isVersionPseudo(appInMemory.app)
                            ? const TextStyle(fontStyle: FontStyle.italic)
                            : null,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      changesButtonString,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        decoration: onShowChanges != null
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    var transparent = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0).value;
    List<double> stops = [
      ...appInMemory.app.categories.asMap().entries.map(
        (e) => ((e.key / (appInMemory.app.categories.length - 1)) - 0.0001),
      ),
      1,
    ];
    if (stops.length == 2) {
      stops[0] = 0.9999;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: stops,
          begin: const Alignment(-1, 0),
          end: const Alignment(-0.97, 0),
          colors: [
            ...appInMemory.app.categories.map(
              (e) => Color(
                viewSettings.categories[e] ?? transparent,
              ).withValues(alpha: 1),
            ),
            Color(transparent),
          ],
        ),
      ),
      child: ListTile(
        autofocus: index == 0 && settingsProvider.isTV,
        tileColor: appInMemory.app.pinned
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.transparent,
        selectedTileColor: Theme.of(context).colorScheme.primary.withValues(
          alpha: appInMemory.app.pinned ? 0.2 : 0.1,
        ),
        selected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
        leading: (settingsProvider.isTV)
            ? Checkbox(
                value: isSelected,
                onChanged: (_) {
                  if (onLongPress != null) onLongPress!();
                },
              )
            : appIcon,
        title: Text(
          appInMemory.name,
          maxLines: 1,
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            fontWeight: appInMemory.app.pinned
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: appInMemory.app.hasPendingRepoRename
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [authorText, if (repoMovedRow != null) repoMovedRow!],
              )
            : authorText,
        trailing: ValueListenableBuilder<double?>(
          valueListenable: appInMemory.downloadProgressNotifier,
          builder: (context, downloadProgress, child) {
            return downloadProgress != null
                ? SizedBox(
                    child: Text(
                      downloadProgress >= 0
                          ? tr(
                              'percentProgress',
                              args: [downloadProgress.toStringAsFixed(1)],
                            )
                          : tr('downloading'),
                    ),
                  )
                : trailingRow;
          },
        ),
      ),
    );
  }
}
