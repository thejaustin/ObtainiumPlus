import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/expressive_progress_indicator.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChangelogPage extends StatefulWidget {
  final bool isModal;
  const ChangelogPage({super.key, this.isModal = false});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  late Future<String> _changelogFuture;

  @override
  void initState() {
    super.initState();
    _changelogFuture = _fetchChangelog();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.isModal ? Colors.transparent : colorScheme.surface,
      appBar: widget.isModal ? null : AppBar(title: Text(tr('viewChangelog'))),
      body: FutureBuilder<String>(
        future: _changelogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ExpressiveCircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${tr('error')}: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(tr('noLogs')));
          }

          return Markdown(
            data: snapshot.data!,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrlString(href, mode: LaunchMode.externalApplication);
              }
            },
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
              h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          );
        },
      ),
    );
  }

  Future<String> _fetchChangelog() async {
    try {
      final response = await get(
        Uri.parse(
          'https://raw.githubusercontent.com/thejaustin/ObtainiumPlus/main/CHANGELOG_USER.md',
        ),
      );
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      // Ignore network errors and fallback
    }

    return '''
# What's New in Obtainium+

## Version 1.4.3
*   **Smoother Onboarding**: We fixed an issue where the Google login prompt would appear unexpectedly during setup.
*   **Increased Stability**: Resolved several crash issues that occurred during file downloads from unstable sources and when verifying installed apps.
*   **Settings Reorganization**: We've cleaned up the Settings menu! You'll find a new "Installation" hub, and we've removed duplicate toggles so it's easier to customize your experience.
*   **UI Polish**: The "Add App" page is now a unified, scrollable view instead of separate tabs, making it much easier to use.
*   **Offline Mode**: Obtainium+ now supports queuing updates when you are offline; it will automatically check when your connection is restored.
*   **Statistics Dashboard**: Check out the new Statistics page in the Troubleshooting section to see your update history and track app installations.

## Earlier Updates
*   **Improved Grid View**: We've significantly reduced the memory footprint when scrolling through large libraries of apps in Grid View.
*   **Better Haptics**: Tactile feedback is now consistent across the entire app.
*   **Modern Visuals**: The App Details and Add App screens now fully support "Glassmorphism" for a beautiful, modern look.
''';
  }
}
