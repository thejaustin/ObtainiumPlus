import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('viewChangelog')),
      ),
      body: FutureBuilder<String>(
        future: _changelogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
          );
        },
      ),
    );
  }

  Future<String> _fetchChangelog() async {
    final response = await get(Uri.parse(
        'https://raw.githubusercontent.com/thejaustin/ObtainiumPlus/main/CHANGELOG_DETAILED.md'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load changelog');
    }
  }
}
