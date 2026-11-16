import 'package:flutter/material.dart';
import 'package:moztopia/gicho.dart';

import '../screens/fnav1/fnav1_screen.dart';
import '../screens/fnav2/fnav2_screen.dart';
import '../screens/fnav3/fnav3_screen.dart';
import '../screens/fnav4/fnav4_screen.dart';
import '../screens/config/config_screen.dart';
import '../screens/config/config_inspector_modal.dart';
import '../screens/dnav5/logging_examples_screen.dart';
import '../screens/modal_page.dart';
import '../screens/not_found_screen.dart';
import '../screens/secondary_page.dart';
import 'app_shell.dart';
import 'branch_container.dart';
import 'destination.dart';
import 'secondary_destination.dart';

final _rootKey = GlobalKey<NavigatorState>();

GichoRouter createRouter() {
  return GichoRouter(
    navigatorKey: _rootKey,
    initialLocation: destinations.first.path,
    routes: [
      StatefulShellRoute(
        builder: (_, _, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (_, shell, children) => BranchContainer(
          currentIndex: shell.currentIndex,
          children: children,
        ),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/fnav1', builder: _buildFNav1)],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/fnav2', builder: _buildFNav2)],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/fnav3', builder: _buildFNav3)],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/fnav4', builder: _buildFNav4)],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/config', builder: _buildConfig)],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/modal/:source',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: ModalPage(source: state.pathParameters['source']!, depth: 1),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/modal/:source/next',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: ModalPage(source: state.pathParameters['source']!, depth: 2),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/config/inspect',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const ConfigInspectorModal(),
        ),
      ),
      for (final destination in secondaryDestinations)
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: destination.path,
          pageBuilder: (_, state) => MaterialPage(
            key: state.pageKey,
            child: destination.path == '/dnav5'
                ? const LoggingExamplesScreen()
                : SecondaryPage(destination: destination),
          ),
        ),
    ],
    errorBuilder: (_, state) =>
        NotFoundScreen(location: state.uri.toString(), error: state.error),
  );
}

Widget _buildFNav1(BuildContext context, GoRouterState state) =>
    const FNav1Screen();

Widget _buildFNav2(BuildContext context, GoRouterState state) =>
    const FNav2Screen();

Widget _buildFNav3(BuildContext context, GoRouterState state) =>
    const FNav3Screen();

Widget _buildFNav4(BuildContext context, GoRouterState state) =>
    const FNav4Screen();

Widget _buildConfig(BuildContext context, GoRouterState state) =>
    const ConfigScreen();
