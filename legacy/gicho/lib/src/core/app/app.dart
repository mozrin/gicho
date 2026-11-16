import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../localization/localization_state.dart';
import '../../routing/gicho_router.dart';
import '../../theme/configured_theme.dart';

/// The standard Gicho [MaterialApp.router] wrapper.
///
/// It applies the configured theme and localization to a consumer-owned router.
/// Place it below [GichoBootstrap] in simple-mode applications.
///
/// This widget does not create a scaffold, app bar, navigation shell, or page.
/// All layout comes from the routes in the consumer-provided [router].
final class GichoMaterialApp extends StatelessWidget {
  const GichoMaterialApp.router({
    super.key,
    required this.router,
    this.title = '',
    this.debugShowCheckedModeBanner = false,
    this.builder,
  });

  final GichoRouter router;
  final String title;
  final bool debugShowCheckedModeBanner;

  /// An optional final composition hook passed to [MaterialApp.router].
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final localizationEnabled =
        GichoLocalization.maybeOf(context)?.isAvailable ?? true;
    return _ConfiguredMaterialApp(
      title: title,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      localizationEnabled: localizationEnabled,
      routerConfig: router.config,
      builder: builder,
    );
  }
}

class _ConfiguredMaterialApp extends StatelessWidget {
  const _ConfiguredMaterialApp({
    required this.routerConfig,
    required this.title,
    required this.debugShowCheckedModeBanner,
    required this.localizationEnabled,
    this.builder,
  });

  final RouterConfig<Object> routerConfig;
  final String title;
  final bool debugShowCheckedModeBanner;
  final bool localizationEnabled;
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: moztopiaTheme,
    builder: (context, _) => MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      theme: moztopiaTheme.lightTheme,
      darkTheme: moztopiaTheme.darkTheme,
      themeMode: moztopiaTheme.mode,
      localizationsDelegates: localizationEnabled
          ? context.localizationDelegates
          : null,
      supportedLocales: localizationEnabled
          ? context.supportedLocales
          : const <Locale>[Locale('en', 'US')],
      locale: localizationEnabled ? context.locale : null,
      routerConfig: routerConfig,
      builder: builder,
    ),
  );
}
