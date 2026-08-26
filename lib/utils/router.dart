import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/pages/app.dart';
import 'package:obtainium/pages/settings.dart';
import 'package:obtainium/pages/add_app.dart';
import 'package:obtainium/pages/import_export.dart';
import 'package:obtainium/pages/logs_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  // Without this, an unmatched route (e.g. a malformed or truncated
  // deep link like "obtainium://app/" with no id) falls through past
  // GoRouter into Flutter's default unknown-route handler, which throws
  // a null-check TypeError there instead of showing anything useful.
  errorBuilder: (context, state) => const HomePage(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'app/:appId',
          builder: (context, state) {
            final appId = state.pathParameters['appId']!;
            return AppPage(appId: appId);
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) {
            final tab =
                int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
            return SettingsPage(initialTab: tab);
          },
        ),
        GoRoute(
          path: 'add',
          builder: (context, state) {
            final tab =
                int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
            return AddAppPage(initialTab: tab);
          },
        ),
        GoRoute(
          path: 'import_export',
          builder: (context, state) => const ImportExportPage(),
        ),
        GoRoute(path: 'logs', builder: (context, state) => const LogsPage()),
      ],
    ),
  ],
);
