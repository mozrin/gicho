import 'package:gicho/gicho.dart';
import 'package:flutter/material.dart';

GichoBootstrap<ThemeController> buildApp({
  Future<ThemeController> Function()? load,
}) {
  final locales = GichoLocaleController();

  return GichoBootstrap<ThemeController>(
    load: load ?? loadThemes,
    title: 'Theme choices',
    theme: gichoTheme(seedColor: const Color(0xFF405A91)),
    failureMessage: 'Could not load themes.',
    retryLabel: 'Retry',
    readyBuilder: (_, themes) => GichoMaterialApp(
      locales: locales,
      title: () => 'Theme choices',
      themes: themes,
      home: GichoAppShell(
        title: 'Theme choices',
        locales: locales,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ThemePicker(themes: themes, locales: locales),
          ),
        ),
      ),
    ),
  );
}

Future<ThemeController> loadThemes() async {
  final configuration = await const GichoConfigurationService()
      .loadApplication();
  final themes = ThemeController.fromConfiguration(
    catalog: await ThemeCatalog.load(),
    configuration: configuration,
  );
  await themes.restore();
  return themes;
}
