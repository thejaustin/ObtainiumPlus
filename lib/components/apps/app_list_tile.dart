import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obtainium/components/app_icon_shimmer.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/utils/source_utils.dart';
import 'package:obtainium/services/app_install_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppListTile extends StatelessWidget {
  final AppInMemory appInMemory;
  final bool isSelected;
  final bool hasUpdate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowChanges;
  final Color? categoryColor;

  const AppListTile({
    super.key,
    required this.appInMemory,
    this.isSelected = false,
    this.hasUpdate = false,
    this.onTap,
    this.onLongPress,
    this.onShowChanges,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final appsProvider = context.read<AppsProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    Widget getUpdateButton() {
      return IconButton(
        visualDensity: VisualDensity.compact,
        color: Theme.of(context).colorScheme.primary,
        tooltip: appInMemory.app.additionalSettings['trackOnly'] == true
            ? tr('markUpdated')
            : tr('update'),
        onPressed: appsProvider.areDownloadsRunning()
            ? null
            : () {
                appsProvider
                    .downloadAndInstallLatestApps([
                      appInMemory.app.id,
                    ], context)
                    .catchError((e) {
                      // Error handling should be done by the caller or via a global utility
                      return <String>[];
                    });
              },
        icon: Icon(
          appInMemory.app.additionalSettings['trackOnly'] == true
              ? Icons.check_circle_outline
              : Icons.install_mobile,
        ),
      );
    }

    Widget getAppIcon() {
      if (appInMemory.icon == null) {
        appsProvider.updateAppIcon(appInMemory.app.id);
      }

      return GestureDetector(
        child: Hero(
          tag: 'app_icon_${appInMemory.app.id}',
            child: appInMemory.icon != null
              ? Image.memory(
                  appInMemory.icon!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: (40 * MediaQuery.of(context).devicePixelRatio).round(),
                  opacity: AlwaysStoppedAnimation(
                    appInMemory.installedInfo == null ? 0.6 : 1,
                  ),
                )
              : const AppIconShimmer(size: 48),
        ),
        onDoubleTap: () {
          AppInstallService.openApp(appInMemory.app.id);
        },
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppPage(
                appId: appInMemory.app.id,
                showOppositeOfPreferredView: true,
              ),
            ),
          );
        },
      );
    }

    String getVersionText() {
      return appInMemory.app.installedVersion ?? tr('notInstalled');
    }

    String getChangesButtonString() {
      return appInMemory.app.releaseDate == null
          ? onShowChanges != null
                ? tr('changes')
                : ''
          : DateFormat(
              'yyyy-MM-dd',
            ).format(appInMemory.app.releaseDate!.toLocal());
    }

    Widget trailingRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hasUpdate ? getUpdateButton() : const SizedBox.shrink(),
        hasUpdate ? const SizedBox(width: 5) : const SizedBox.shrink(),
        GestureDetector(
          onTap: onShowChanges,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  settingsProvider.highlightTouchTargets &&
                      onShowChanges != null
                  ? (Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColorLight)
                        .withAlpha(
                          Theme.of(context).brightness == Brightness.light
                              ? 20
                              : 40,
                        )
                  : null,
            ),
            padding: settingsProvider.highlightTouchTargets
                ? const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0)
                : const EdgeInsetsDirectional.fromSTEB(24, 0, 0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (settingsProvider.displayShowVersion)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width / 4,
                        ),
                        child: Text(
                          getVersionText(),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: SourceUtils.isVersionPseudo(appInMemory.app)
                              ? const TextStyle(fontStyle: FontStyle.italic)
                              : null,
                        ),
                      ),
                    ],
                  ),
                if (settingsProvider.displayShowDate)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        getChangesButtonString(),
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

    var transparent = Theme.of(context).colorScheme.surface.withAlpha(0).value;
    List<double> stops = [
      ...appInMemory.app.categories.asMap().entries.map(
        (e) =>
            ((e.key / (appInMemory.app.categories.length - 1)) -
            0.0001),
      ),
      1,
    ];
    if (stops.length == 2) {
      stops[0] = 0.9999;
    }

    final isCompact = settingsProvider.appListDensity == AppListDensity.compact;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: stops,
          begin: const Alignment(-1, 0),
          end: const Alignment(-0.97, 0),
          colors: [
            ...appInMemory.app.categories.map(
              (e) => Color(
                settingsProvider.categories[e] ?? transparent,
              ).withAlpha(255),
            ),
            Color(transparent),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onLongPress,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: ListTile(
              visualDensity: isCompact ? VisualDensity.compact : null,
              contentPadding: isCompact ? const EdgeInsets.symmetric(horizontal: 12) : null,
              dense: isCompact,
              tileColor: appInMemory.app.pinned
                  ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                  : Colors.transparent,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(
                appInMemory.app.pinned ? 0.7 : 0.5,
              ),
              selected: isSelected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: getAppIcon(),
              title: Text(
                maxLines: 1,
                appInMemory.name,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: appInMemory.app.pinned
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: settingsProvider.displayShowAuthor ? Text(
                tr('byX', args: [appInMemory.author]),
                maxLines: 1,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: appInMemory.app.pinned
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ) : null,
              trailing: appInMemory.downloadProgress != null
                  ? SizedBox(
                      child: Text(
                        (appInMemory.downloadProgress ?? -1) >= 0
                            ? tr(
                                'percentProgress',
                                args: [
                                  appInMemory.downloadProgress ?? 0
                                      .toInt()
                                      .toString(),
                                ],
                              )
                            : tr('installing'),
                        textAlign: ((appInMemory.downloadProgress ?? -1) >= 0)
                            ? TextAlign.start
                            : TextAlign.end,
                      ),
                    )
                  : trailingRow,
            ),
          ),
        ),
      ),
    );
  }
}
