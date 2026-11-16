import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

/// Gicho's standard facade over GoRouter.
///
/// Consumers own the route list. Gicho owns the supported GoRouter version
/// and provides consistent defaults while retaining the full GoRouter escape
/// hatch through [goRouter].
final class GichoRouter {
  GichoRouter({
    required List<RouteBase> routes,
    OnEnter? onEnter,
    Codec<Object?, Object?>? extraCodec,
    GoExceptionHandler? onException,
    GoRouterPageBuilder? errorPageBuilder,
    GoRouterWidgetBuilder? errorBuilder,
    GoRouterRedirect? redirect,
    int redirectLimit = 5,
    Listenable? refreshListenable,
    bool routerNeglect = false,
    String initialLocation = '/',
    bool overridePlatformDefaultLocation = false,
    Object? initialExtra,
    List<NavigatorObserver>? observers,
    bool debugLogDiagnostics = kDebugMode,
    GlobalKey<NavigatorState>? navigatorKey,
    String? restorationScopeId,
    bool requestFocus = true,
  }) : _goRouter = GoRouter(
         routes: routes,
         onEnter: onEnter,
         extraCodec: extraCodec,
         onException: onException,
         errorPageBuilder: errorPageBuilder,
         errorBuilder: errorBuilder,
         redirect: redirect,
         redirectLimit: redirectLimit,
         refreshListenable: refreshListenable,
         routerNeglect: routerNeglect,
         initialLocation: initialLocation,
         overridePlatformDefaultLocation: overridePlatformDefaultLocation,
         initialExtra: initialExtra,
         observers: observers,
         debugLogDiagnostics: debugLogDiagnostics,
         navigatorKey: navigatorKey,
         restorationScopeId: restorationScopeId,
         requestFocus: requestFocus,
       );

  final GoRouter _goRouter;

  GoRouter get config => _goRouter;
  GoRouter get goRouter => _goRouter;

  void go(String location, {Object? extra}) =>
      _goRouter.go(location, extra: extra);

  Future<T?> push<T extends Object?>(String location, {Object? extra}) =>
      _goRouter.push<T>(location, extra: extra);

  void pop<T extends Object?>([T? result]) => _goRouter.pop<T>(result);

  void dispose() => _goRouter.dispose();
}
