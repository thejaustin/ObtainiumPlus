import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/components/ui_widgets.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/plus_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:markdown/markdown.dart' as md;

void showChangeLogDialog(
  BuildContext context,
  App app,
  String? changesUrl,
  AppSource? appSource,
  String changeLog,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return GeneratedFormModal(
        title: tr('changes'),
        items: const [],
        message: app.latestVersion,
        additionalWidgets: [
          changesUrl != null
              ? LinkText(
                  text: changesUrl,
                  url: changesUrl,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                )
              : const SizedBox.shrink(),
          changesUrl != null
              ? const SizedBox(height: 16)
              : const SizedBox.shrink(),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: (appSource?.changeLogIfAnyIsMarkDown ?? true)
                ? Markdown(
                    key: const PageStorageKey<String>('changelog_dialog_md'),
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      blockquoteDecoration: BoxDecoration(
                        color:
                            context
                                .watch<PlusSettingsProvider>()
                                .plusEnableGlassmorphism
                            ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4)
                            : Theme.of(context).cardColor,
                      ),
                    ),
                    data: changeLog,
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrlString(
                          resolveChangeLogLink(app.url, href),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    extensionSet: md.ExtensionSet(
                      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                      [
                        md.EmojiSyntax(),
                        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    key: const PageStorageKey<String>('changelog_dialog_text'),
                    child: Text(changeLog),
                  ),
          ),
        ],
        singleNullReturnButton: tr('ok'),
      );
    },
  );
}

/// Resolves a (possibly relative) link from release notes against the
/// origin of the app's source URL.
String resolveChangeLogLink(String appUrl, String href) {
  if (href.startsWith('http://') || href.startsWith('https://')) return href;
  try {
    final uri = Uri.parse(appUrl);
    if (uri.hasScheme && uri.host.isNotEmpty) return '${uri.origin}/$href';
  } catch (_) {}
  return href;
}

AppSource? _sourceOrNull(App app) {
  try {
    return SourceProvider().getSource(
      app.url,
      overrideSource: app.overrideSource,
    );
  } catch (_) {
    return null;
  }
}

final RegExp _singleUrlChangeLog = RegExp(
  r'(http|ftp|https)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?',
);

/// The "show changes" action for [app], or null when there is nothing to
/// show. A single-line URL changelog (e.g. F-Droid's Changelog link) opens
/// in the browser; other notes open in a dialog.
///
/// With [requireNotes] (app list tiles) the action exists only when the app
/// has stored notes, and the source is resolved lazily on tap so list builds
/// stay cheap. Otherwise (app page) the source's changes page is offered
/// even without stored notes.
Null Function()? getChangeLogFn(
  BuildContext context,
  App app, {
  bool requireNotes = false,
}) {
  String? changesUrl;
  String? changeLog = app.changeLog;
  if (changeLog != null &&
      changeLog.split('\n').length == 1 &&
      _singleUrlChangeLog.hasMatch(changeLog)) {
    changesUrl = changeLog;
    changeLog = null;
  }
  if (changeLog == null && changesUrl == null) {
    if (requireNotes) return null;
    changesUrl = _sourceOrNull(app)?.changeLogPageFromStandardUrl(app.url);
    if (changesUrl == null) return null;
  }
  return () {
    if (changeLog != null) {
      final appSource = _sourceOrNull(app);
      changesUrl ??= appSource?.changeLogPageFromStandardUrl(app.url);
      showChangeLogDialog(context, app, changesUrl, appSource, changeLog);
    } else if (changesUrl != null) {
      launchUrlString(changesUrl!, mode: LaunchMode.externalApplication);
    }
  };
}
