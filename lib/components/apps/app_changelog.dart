import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:obtainium/components/generated_form_modal.dart';
import 'package:obtainium/models/app_source.dart';
import 'package:obtainium/providers/source_provider.dart';
import 'package:obtainium/providers/apps_provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:markdown/markdown.dart' as md;

void showChangeLogDialog(
  BuildContext context,
  App app,
  String? changesUrl,
  AppSource appSource,
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
              ? GestureDetector(
                  child: Text(
                    changesUrl,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  onTap: () {
                    launchUrlString(
                      changesUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                )
              : const SizedBox.shrink(),
          changesUrl != null
              ? const SizedBox(height: 16)
              : const SizedBox.shrink(),
          appSource.changeLogIfAnyIsMarkDown
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - 350,
                  child: Markdown(
                    styleSheet: MarkdownStyleSheet(
                      blockquoteDecoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                    data: changeLog,
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrlString(
                          href.startsWith('http://') ||
                                  href.startsWith('https://')
                              ? href
                              : '${Uri.parse(app.url).origin}/$href',
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
                  ),
                )
              : Text(changeLog),
        ],
        singleNullReturnButton: tr('ok'),
      );
    },
  );
}

Null Function()? getChangeLogFn(BuildContext context, App app) {
  AppSource appSource = SourceProvider().getSource(
    app.url,
    overrideSource: app.overrideSource,
  );
  String? changesUrl = appSource.changeLogPageFromStandardUrl(app.url);
  String? changeLog = app.changeLog;
  if (changeLog?.split('\n').length == 1) {
    if (RegExp(
      r'(http|ftp|https)://([\w_-]+(?:(?:\\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?',
    ).hasMatch(changeLog!)) {
      if (changesUrl == null) {
        changesUrl = changeLog;
        changeLog = null;
      }
    }
  }
  return (changeLog == null && changesUrl == null)
      ? null
      : () {
          if (changeLog != null) {
            showChangeLogDialog(context, app, changesUrl, appSource, changeLog);
          } else {
            launchUrlString(changesUrl!, mode: LaunchMode.externalApplication);
          }
        };
}
