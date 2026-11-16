import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../features/localization/locale_controller/index.dart';
import '../../features/themes/controller/index.dart';

/// Material application configured with the consumer's theme and locale.
class GichoMaterialApp extends StatelessWidget {
  const GichoMaterialApp({
    super.key,
    required this.locales,
    required this.title,
    this.theme,
    this.themes,
    required this.home,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.debugShowCheckedModeBanner = false,
  }) : assert(theme != null || themes != null),
       routerConfig = null;

  const GichoMaterialApp.router({
    super.key,
    required this.locales,
    required this.title,
    this.theme,
    this.themes,
    required RouterConfig<Object> this.routerConfig,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.debugShowCheckedModeBanner = false,
  }) : assert(theme != null || themes != null),
       home = null;

  final GichoLocaleController locales;
  final String Function() title;
  final ThemeData? theme;
  final ThemeController? themes;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;
  final Widget? home;
  final RouterConfig<Object>? routerConfig;
  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([locales, ?themes]),
    builder: (context, _) {
      final config = routerConfig;
      if (config != null) {
        return MaterialApp.router(
          title: title(),
          locale: locales.locale,
          supportedLocales: locales.enabledLocales,
          localizationsDelegates: _localizationsDelegates,
          theme: themes?.lightTheme ?? theme,
          darkTheme: themes?.darkTheme ?? darkTheme,
          themeMode: themes?.mode ?? themeMode,
          debugShowCheckedModeBanner: debugShowCheckedModeBanner,
          routerConfig: config,
        );
      }
      return MaterialApp(
        title: title(),
        locale: locales.locale,
        supportedLocales: locales.enabledLocales,
        localizationsDelegates: _localizationsDelegates,
        theme: themes?.lightTheme ?? theme,
        darkTheme: themes?.darkTheme ?? darkTheme,
        themeMode: themes?.mode ?? themeMode,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        home: home,
      );
    },
  );

  static const _localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
