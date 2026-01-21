import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:obtainium/providers/logs_provider.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/models/app_source_helpers.dart';
import 'package:obtainium/providers/source_provider.dart' hide isEnglish, lowerCaseIfEnglish;
import 'package:obtainium/utils/language_utils.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ObtainiumError {
  late String message;
  bool unexpected;
  ObtainiumError(this.message, {this.unexpected = false});
  @override
  String toString() {
    return message;
  }
}

class FixAction {
  final String label;
  final VoidCallback action;
  FixAction(this.label, this.action);
}

class ErrorResolution {
  final String tip;
  final FixAction? fix;
  ErrorResolution(this.tip, {this.fix});
}

class RateLimitError extends ObtainiumError {
  late int remainingMinutes;
  RateLimitError(this.remainingMinutes)
    : super(plural('tooManyRequestsTryAgainInMinutes', remainingMinutes));
}

class InvalidURLError extends ObtainiumError {
  String? appId;
  InvalidURLError(String sourceName, {this.appId})
    : super(tr('invalidURLForSource', args: [sourceName]));
}

class CredsNeededError extends ObtainiumError {
  CredsNeededError(String sourceName)
    : super(tr('requiresCredentialsInSettings', args: [sourceName]));
}

class NoReleasesError extends ObtainiumError {
  String? appId;
  NoReleasesError({String? note, this.appId})
    : super(
        '${tr('noReleaseFound')}${note?.isNotEmpty == true ? '\n\n$note' : ''}',
      );
}

class NoAPKError extends ObtainiumError {
  String? appId;
  NoAPKError({this.appId}) : super(tr('noAPKFound'));
}

class NoVersionError extends ObtainiumError {
  String? appId;
  NoVersionError({this.appId}) : super(tr('noVersionFound'));
}

class UnsupportedURLError extends ObtainiumError {
  UnsupportedURLError() : super(tr('urlMatchesNoSource'));
}

class DowngradeError extends ObtainiumError {
  String? appId;
  DowngradeError(int currentVersionCode, int newVersionCode, {this.appId})
    : super(
        '${tr('cantInstallOlderVersion')} (versionCode $currentVersionCode ➔ $newVersionCode)',
      );
}

class InstallError extends ObtainiumError {
  final int code;
  final String? appId;
  InstallError(this.code, {this.appId})
    : super(PackageInstallerStatus.byCode(code).name.substring(7));
}

class IDChangedError extends ObtainiumError {
  String? appId;
  String newId;
  IDChangedError(this.newId, {this.appId}) : super('${tr('appIdMismatch')} - $newId');
}

class BadDownloadError extends ObtainiumError {
  String? appId;
  BadDownloadError({this.appId}) : super(tr('badDownload'));
}

class NotImplementedError extends ObtainiumError {
  NotImplementedError() : super(tr('functionNotImplemented'));
}

class MultiAppMultiError extends ObtainiumError {
  Map<String, dynamic> rawErrors = {};
  Map<String, StackTrace?> stackTraces = {};
  Map<String, List<String>> idsByErrorString = {};
  Map<String, String> appIdNames = {};

  MultiAppMultiError() : super(tr('placeholder'), unexpected: true);

  void add(String appId, dynamic error, {String? appName, StackTrace? stackTrace}) {
    if (error is SocketException) {
      error = error.message;
    }
    // Propagate appId to IDChangedError if missing
    if (error is IDChangedError && error.appId == null) {
      error.appId = appId;
    }
    rawErrors[appId] = error;
    stackTraces[appId] = stackTrace ?? (error is Error ? error.stackTrace : null);
    var string = error.toString();
    var tempIds = idsByErrorString.remove(string);
    tempIds ??= [];
    tempIds.add(appId);
    idsByErrorString.putIfAbsent(string, () => tempIds!);
    if (appName != null) {
      appIdNames[appId] = appName;
    }
  }

  String errorString(String appId, {bool includeIdsWithNames = false}) =>
      '${appIdNames.containsKey(appId) ? '${appIdNames[appId]}${includeIdsWithNames ? ' ($appId)' : ''}' : appId}: ${rawErrors[appId].toString()}';

  String errorsAppsString(
    String errString,
    List<String> appIds, {
    bool includeIdsWithNames = false,
  }) =>
      '$errString [${list2FriendlyString(appIds.map((id) => appIdNames.containsKey(id) == true ? '${appIdNames[id]}${includeIdsWithNames ? ' ($id)' : ''}' : id).toList())}]';

  @override
  String toString() => idsByErrorString.entries
      .map((e) => errorsAppsString(e.key, e.value))
      .join('\n\n');
}

Future<ErrorResolution?> getResolutionForError(dynamic e, BuildContext context) async {
  String s = e.toString().toLowerCase();
  
  if (e is CredsNeededError || e is RateLimitError || s.contains('rate limit')) {
     return ErrorResolution(
       tr('rateLimitTip'), 
       fix: FixAction(tr('openSettings'), () {
         Navigator.of(context).push(
           MaterialPageRoute(builder: (context) => const SettingsPage()),
         );
       })
     );
  }

  if (e is InstallError) {
    if (s.contains('storage') || s.contains('space')) {
      return ErrorResolution(
        tr('checkStorage'),
        fix: FixAction(tr('openStorageSettings'), () {
          const AndroidIntent intent = AndroidIntent(
            action: 'android.settings.INTERNAL_STORAGE_SETTINGS',
          );
          intent.launch();
        })
      );
    }
    
    // Conflict (5) or Incompatible (7) - usually signature mismatch
    if ((e.code == 5 || e.code == 7) && e.appId != null) {
      return ErrorResolution(
        tr('signatureMismatchTip'),
        fix: FixAction(tr('uninstallApp'), () {
          AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.DELETE',
            data: 'package:${e.appId}',
          );
          intent.launch();
        })
      );
    }

    // Check for Install Permission
    if (!(await Permission.requestInstallPackages.isGranted)) {
       return ErrorResolution(
          tr('installPermissionMissingTip'),
          fix: FixAction(tr('allowUnknownApps'), () {
            // We use standard intent as permission_handler request sometimes flakely redirects
             const AndroidIntent intent = AndroidIntent(
                action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
                data: 'package:dev.imranr.obtainium', 
              );
              intent.launch();
          })
       );
    }

    return ErrorResolution(
      tr('installErrorTip'),
      fix: FixAction(tr('openInstallUnknownApps'), () {
         const AndroidIntent intent = AndroidIntent(
            action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
            data: 'package:dev.imranr.obtainium', 
          );
          intent.launch();
      })
    );
  }

  if (e is DowngradeError) {
    var res = ErrorResolution(tr('downgradeErrorTip'));
    if (e.appId != null) {
      return ErrorResolution(
        tr('downgradeErrorTip'),
        fix: FixAction(tr('uninstallApp'), () {
          AndroidIntent intent = AndroidIntent(
            action: 'android.intent.action.DELETE',
            data: 'package:${e.appId}',
          );
          intent.launch();
        })
      );
    }
    return res;
  }

  if (e is IDChangedError && e.appId != null) {
    return ErrorResolution(
      tr('idChangedErrorTip'),
      fix: FixAction(tr('openAppInfo'), () {
        AndroidIntent intent = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:${e.appId}',
        );
        intent.launch();
      })
    );
  }

  if (e is BadDownloadError && e.appId != null) {
    return ErrorResolution(
      tr('badDownloadTip'),
      fix: FixAction(tr('clearCache'), () {
        var appsProvider = Provider.of<AppsProvider>(context, listen: false);
        appsProvider.clearAppCache(e.appId!);
        Navigator.of(context).pop();
        showMessage(tr('cacheCleared'), context);
      })
    );
  }

  if ((e is NoReleasesError && e.appId != null) || (e is NoAPKError && e.appId != null) || (e is NoVersionError && e.appId != null)) {
    String? appId = (e as dynamic).appId;
    var appsProvider = Provider.of<AppsProvider>(context, listen: false);
    var app = appsProvider.apps[appId]?.app;
    if (app != null) {
      return ErrorResolution(
        tr('sourceErrorTip'),
        fix: FixAction(tr('openSourceWebsite'), () {
          launchUrlString(
            app.url,
            mode: LaunchMode.externalApplication,
          );
        })
      );
    }
  }

  if (e is InvalidURLError && e.appId != null) {
    return ErrorResolution(
      tr('sourceErrorTip'),
      fix: FixAction(tr('editApp'), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddAppPage(
              mode: AddAppMode.edit,
              appId: e.appId,
            ),
          ),
        );
      })
    );
  }

  if (e is SocketException || s.contains('socketexception') || s.contains('connection refused') || s.contains('timed out')) {
    return ErrorResolution(tr('checkInternet'));
  }
  if (s.contains('storage') || s.contains('space') || s.contains('permission')) {
    return ErrorResolution(tr('checkStorage'));
  }
  if (e is InvalidURLError || e is UnsupportedURLError || s.contains('404') || s.contains('not found')) {
    return ErrorResolution(tr('sourceErrorTip'));
  }
  
  // Generic fallback: Search Online
  return ErrorResolution(
    tr('unknownErrorTip'),
    fix: FixAction(tr('searchOnline'), () {
       launchUrlString(
         'https://www.google.com/search?q=Obtainium+${Uri.encodeComponent(e.toString())}',
         mode: LaunchMode.externalApplication,
       );
    })
  );
}

Future<void> showMessage(dynamic e, BuildContext context, {bool isError = false, StackTrace? stackTrace}) async {
  var settings = Provider.of<SettingsProvider>(context, listen: false);
  String logMessage = e.toString();
  
  if (settings.enableDeepLogging && isError) {
    if (stackTrace != null) {
      logMessage += '\nStack Trace:\n$stackTrace';
    } else if (e is Error) {
      logMessage += '\nStack Trace:\n${e.stackTrace}';
    } else if (e is MultiAppMultiError) {
      e.stackTraces.forEach((appId, st) {
        if (st != null) {
          logMessage += '\n--- Stack Trace for $appId ---\n$st';
        }
      });
    }
  }

  Provider.of<LogsProvider>(
    context,
    listen: false,
  ).add(logMessage, level: isError ? LogLevels.error : LogLevels.info);
  if (e is String || (e is ObtainiumError && !e.unexpected)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  } else {
    ErrorResolution? resolution = isError ? await getResolutionForError(e, context) : null;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          scrollable: true,
          title: Text(
            e is MultiAppMultiError
                ? tr(isError ? 'someErrors' : 'updates')
                : tr(isError ? 'unexpectedError' : 'unknown'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: logMessage));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
                },
                child: Text(e.toString()),
              ),
              if (resolution != null) ...[
                const SizedBox(height: 16),
                Text(
                  '${tr('potentialFix')}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(resolution.tip),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: logMessage));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(tr('copiedToClipboard'))));
              },
              child: Text(tr('copy')),
            ),
            if (resolution?.fix != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                  resolution!.fix!.action();
                },
                child: Text(resolution!.fix!.label),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: Text(tr('ok')),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showError(dynamic e, BuildContext context, {StackTrace? stackTrace}) async {
  await showMessage(e, context, isError: true, stackTrace: stackTrace);
}

String list2FriendlyString(List<String> list) {
  var isUsingEnglish = isEnglish();
  return list.length == 2
      ? '${list[0]} ${tr('and')} ${list[1]}'
      : list
            .asMap()
            .entries
            .map(
              (e) =>
                  e.value +
                  (e.key == list.length - 1
                      ? ''
                      : e.key == list.length - 2
                      ? '${isUsingEnglish ? ',' : ''} and '
                      : ', '),
            )
            .join('');
}
